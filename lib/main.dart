import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';
import 'data/levels_data.dart';
import 'engine/game_engine.dart';
import 'models/enums.dart';
import 'screens/level_selection_screen.dart';
import 'services/level_manager.dart';
import 'services/player_manager.dart';
import 'widgets/action_buttons.dart';
import 'widgets/command_palette.dart';
import 'widgets/command_queue.dart';
import 'widgets/game_board_widget.dart';
import 'widgets/top_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isWindows) {
    try {
      SharedPreferencesWindows.registerWith();
    } catch (_) {}
  }
  runApp(const GridPuzzleApp());
}

class GridPuzzleApp extends StatelessWidget {
  const GridPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Bot Logic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'monospace',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF060D18),
      ),
      home: const GameScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GameScreen
// ─────────────────────────────────────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  final Duration stepDelay;

  const GameScreen({
    super.key,
    this.stepDelay = const Duration(milliseconds: 400),
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine _engine;
  late final PlayerManager _playerManager;
  late final LevelManager _levelManager;
  int _selectedLevelIndex = 0;
  bool _hasShownResultDialog = false;

  @override
  void initState() {
    super.initState();
    _playerManager = PlayerManager();
    _playerManager.addListener(_onPlayerStateChanged);
    _playerManager.init().then((_) {
      if (mounted && _playerManager.justClaimedDailyReward) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showDailyRewardDialog();
        });
      }
    });

    _levelManager = LevelManager();
    _levelManager.loadLevelsFromJson().then((_) {
      if (mounted && _levelManager.levels.isNotEmpty) {
        setState(() {
          _engine.loadLevel(_levelManager.getLevel(_selectedLevelIndex));
        });
      }
    });

    _engine = GameEngine(
      level: sampleLevels[_selectedLevelIndex],
      stepDelay: widget.stepDelay,
    );
    _engine.addListener(_handleEngineStateChange);
  }

  void _onPlayerStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _levelManager.dispose();
    _playerManager.removeListener(_onPlayerStateChanged);
    _playerManager.dispose();
    _engine.removeListener(_handleEngineStateChange);
    _engine.dispose();
    super.dispose();
  }

  void _handleEngineStateChange() {
    if (!mounted) return;
    if (_engine.isWon && !_hasShownResultDialog) {
      _hasShownResultDialog = true;
      _playerManager.unlockNextLevel(_selectedLevelIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWinDialog();
      });
    } else if (_engine.isLost && !_hasShownResultDialog) {
      _hasShownResultDialog = true;
      _playerManager.loseLife();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLostDialog();
      });
    } else if (!_engine.isWon && !_engine.isLost) {
      _hasShownResultDialog = false;
    }
  }

  void _onSelectLevel(int index) {
    if (_engine.isExecuting) return;
    setState(() {
      _selectedLevelIndex = index;
      _hasShownResultDialog = false;
      _engine.loadLevel(_levelManager.getLevel(index));
    });
  }

  // ─── Tính số sao (1–3) dựa trên số lệnh đã dùng ─────────────────────────
  int _calcStars() {
    final int used = _engine.commandList.length +
        (_engine.function1List.isEmpty ? 0 : _engine.function1List.length);
    final currentLevel = _engine.currentLevel;

    // Nếu level có định nghĩa optimalCommands từ JSON thì ưu tiên dùng
    if (currentLevel.optimalCommands != null) {
      final int opt = currentLevel.optimalCommands!;
      if (used <= opt) return 3;
      if (used <= opt + 2) return 2;
      return 1;
    }

    final int maxMain = currentLevel.maxCommandsAllowed;
    if (used <= (maxMain * 0.5).floor()) return 3;
    if (used <= (maxMain * 0.75).floor()) return 2;
    return 1;
  }

  // ─── Win Dialog ───────────────────────────────────────────────────────────
  void _showWinDialog() {
    final int stars = _calcStars();
    // Lưu số sao đạt được vào PlayerManager
    _playerManager.setLevelStars(_selectedLevelIndex, stars);

    final int totalCount = _levelManager.totalLevels > 0
        ? _levelManager.totalLevels
        : sampleLevels.length;
    final bool hasNext = _selectedLevelIndex < totalCount - 1;
    final level = _levelManager.getLevel(_selectedLevelIndex);
    final int usedMain = _engine.commandList.length;
    final int usedF1 = _engine.function1List.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _WinDialogContent(
          levelName: level.name ?? 'Màn ${_selectedLevelIndex + 1}',
          stars: stars,
          usedMain: usedMain,
          maxMain: level.maxCommandsAllowed,
          usedF1: usedF1,
          maxF1: level.maxFunction1Commands,
          energyCollected: _engine.collectedEnergyCount,
          totalEnergy: level.totalEnergyCount,
          hasNext: hasNext,
          onPlayAgain: () {
            Navigator.of(ctx).pop();
            _engine.resetLevel();
          },
          onOptimize: () {
            // "Thử tối ưu lại": giữ nguyên lệnh, reset vị trí
            Navigator.of(ctx).pop();
            _engine.resetLevel();
          },
          onNextLevel: () {
            Navigator.of(ctx).pop();
            _onSelectLevel(_selectedLevelIndex + 1);
          },
        ),
      ),
    );
  }

  // ─── Xử lý Chạy Lệnh có kiểm tra Mạng sống ─────────────────────────────────
  void _handleRunCommands() {
    if (_engine.isExecuting || _engine.commandList.isEmpty) return;
    if (_playerManager.lives == 0) {
      _showNoLivesDialog();
      return;
    }
    _engine.runCommands();
  }

  // ─── Xử lý Gợi ý (Bóng đèn) ───────────────────────────────────────────────
  void _handleHintPress() {
    if (_playerManager.hints > 0) {
      _showHintStepsDialog();
    } else {
      _showNoHintsDialog();
    }
  }

  // ─── Xử lý nhấn Mạng (Trái tim) ───────────────────────────────────────────
  void _handleLivesPress() {
    if (_playerManager.lives < PlayerManager.maxLives) {
      _showWatchAdForLivesDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mạng của bạn đang đầy (5/5 ❤️)!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Dialog khi hết mạng ──────────────────────────────────────────────────
  void _showNoLivesDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _ConfirmAdDialog(
          title: 'Hết Mạng!',
          icon: Icons.heart_broken_rounded,
          iconColor: const Color(0xFFEF4444),
          message: 'Hết mạng. Xem quảng cáo để nhận 3 mạng?',
          actionLabel: 'Xem Quảng Cáo (+3 ❤️)',
          onConfirm: () {
            Navigator.of(ctx).pop();
            _playRewardedAd(
              rewardTitle: '3 Mạng ❤️',
              onReward: () => _playerManager.addLives(3),
            );
          },
        ),
      ),
    );
  }

  // ─── Dialog hồi phục mạng khi còn ít mạng ──────────────────────────────────
  void _showWatchAdForLivesDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _ConfirmAdDialog(
          title: 'Hồi Phục Mạng',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFEF4444),
          message:
              'Bạn hiện có ${_playerManager.lives}/${PlayerManager.maxLives} mạng. Xem một đoạn quảng cáo ngắn (3s) để nhận ngay 3 mạng?',
          actionLabel: 'Xem Quảng Cáo (+3 ❤️)',
          onConfirm: () {
            Navigator.of(ctx).pop();
            _playRewardedAd(
              rewardTitle: '3 Mạng ❤️',
              onReward: () => _playerManager.addLives(3),
            );
          },
        ),
      ),
    );
  }

  // ─── Dialog khi hết gợi ý ─────────────────────────────────────────────────
  void _showNoHintsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _ConfirmAdDialog(
          title: 'Hết Gợi Ý!',
          icon: Icons.lightbulb_outline_rounded,
          iconColor: const Color(0xFFF59E0B),
          message: 'Xem quảng cáo để nhận 1 gợi ý?',
          actionLabel: 'Xem Quảng Cáo (+1 💡)',
          onConfirm: () {
            Navigator.of(ctx).pop();
            _playRewardedAd(
              rewardTitle: '1 Gợi Ý 💡',
              onReward: () => _playerManager.addHints(1),
            );
          },
        ),
      ),
    );
  }

  // ─── Dialog hiển thị 3 bước đi đầu tiên của màn chơi ──────────────────────
  void _showHintStepsDialog() {
    final level = _levelManager.getLevel(_selectedLevelIndex);
    final List<CommandType> hints = level.initialHints;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _HintStepsDialogContent(
          levelName: level.name ?? 'Màn ${_selectedLevelIndex + 1}',
          hints: hints,
          onApplyHint: () {
            if (_playerManager.useHint()) {
              Navigator.of(ctx).pop();
              for (final cmd in hints) {
                if (_engine.commandList.length < level.maxCommandsAllowed) {
                  _engine.addCommand(cmd);
                }
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã trừ 1 💡 và điền 3 bước gợi ý vào hàng lệnh!'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF0D9488),
                ),
              );
            }
          },
          onClose: () {
            if (_playerManager.useHint()) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã trừ 1 💡 gợi ý.'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // ─── Giả lập xem Quảng Cáo (Rewarded Ad) ──────────────────────────────────
  void _playRewardedAd({
    required String rewardTitle,
    required VoidCallback onReward,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => _AdSimulationDialog(
        rewardTitle: rewardTitle,
        playerManager: _playerManager,
        onComplete: () {
          Navigator.of(ctx).pop();
          onReward();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Chúc mừng! $rewardTitle đã được cộng thành công!'),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF059669),
            ),
          );
        },
      ),
    );
  }

  // ─── Dialog nhận quà điểm danh hàng ngày ──────────────────────────────────
  void _showDailyRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _DailyRewardDialogContent(
          onClaim: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  // ─── Lost Dialog ──────────────────────────────────────────────────────────
  void _showLostDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _LostDialogContent(
          message: _engine.statusMessage ??
              'Robot đã va chạm! Kiểm tra lại chuỗi lệnh.',
          livesLeft: _playerManager.lives,
          onRetry: () {
            Navigator.of(ctx).pop();
            _engine.resetLevel();
          },
          onWatchAdForLives: () {
            Navigator.of(ctx).pop();
            _playRewardedAd(
              rewardTitle: '3 Mạng ❤️',
              onReward: () {
                _playerManager.addLives(3);
                _engine.resetLevel();
              },
            );
          },
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D18),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _engine,
          builder: (context, _) {
            return LayoutBuilder(builder: (context, constraints) {
              final double boardSize =
                  (constraints.maxHeight * 0.37).clamp(180.0, 340.0);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 0. TopBar: Mạng (❤️) + Gợi ý (💡)
                        TopBar(
                          playerManager: _playerManager,
                          onTapHint: _handleHintPress,
                          onTapLives: _handleLivesPress,
                        ),
                        const SizedBox(height: 6),

                        // 1. Level info + stats
                        _buildLevelHeader(),
                        const SizedBox(height: 8),

                        // 2. Bàn cờ
                        Center(
                          child: GameBoardWidget(
                            engine: _engine,
                            maxBoardSize: boardSize,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 3. Status banner
                        _buildStatusBanner(),
                        const SizedBox(height: 8),

                        // 4. Queue (Main + F1 cùng lúc)
                        CommandQueue(engine: _engine),
                        const SizedBox(height: 8),

                        // 5. Palette (tab Main / F1)
                        CommandPalette(engine: _engine),
                        const SizedBox(height: 10),

                        // 6. Action buttons
                        ActionButtons(
                          engine: _engine,
                          onRun: _handleRunCommands,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Mini Bot Logic',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        // Nút mở LevelSelectionScreen (100 màn chơi)
        IconButton(
          tooltip: 'Chọn trong 100 màn chơi',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: Colors.white, size: 18),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LevelSelectionScreen(
                  levelManager: _levelManager,
                  playerManager: _playerManager,
                  currentSelectedLevelIndex: _selectedLevelIndex,
                  onSelectLevel: _onSelectLevel,
                ),
              ),
            );
          },
        ),
        // Level selector nhanh
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedLevelIndex.clamp(
                    0,
                    (_levelManager.totalLevels > 0
                            ? _levelManager.totalLevels
                            : sampleLevels.length) -
                        1),
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white60, size: 18),
                items: List.generate(
                  _levelManager.totalLevels > 0
                      ? _levelManager.totalLevels
                      : sampleLevels.length,
                  (i) {
                    final isLocked = i >= _playerManager.unlockedLevels;
                    return DropdownMenuItem(
                      value: i,
                      child: Text(
                        isLocked ? 'Màn ${i + 1} 🔒' : 'Màn ${i + 1}',
                        style: TextStyle(
                          color: isLocked ? Colors.white38 : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                onChanged: (val) {
                  if (val != null) {
                    if (val < _playerManager.unlockedLevels) {
                      _onSelectLevel(val);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Vượt qua Màn ${_playerManager.unlockedLevels} để mở khóa màn này!'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Level header + stats ─────────────────────────────────────────────────
  Widget _buildLevelHeader() {
    final level = _levelManager.getLevel(_selectedLevelIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.name ?? 'Màn ${_selectedLevelIndex + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (level.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    level.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white54),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Stat chips
          _statChip(Icons.bolt_rounded, Colors.amber,
              '${_engine.collectedEnergyCount}/${level.totalEnergyCount}',
              'Pin'),
          const SizedBox(width: 6),
          _statChip(Icons.code_rounded, const Color(0xFF818CF8),
              '${_engine.commandList.length}/${level.maxCommandsAllowed}',
              'Main'),
          if (_engine.botElevation > 0) ...[
            const SizedBox(width: 6),
            _statChip(Icons.layers_rounded, const Color(0xFF6366F1),
                '+${_engine.botElevation}', 'Cao'),
          ],
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, Color color, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        Text(label,
            style: const TextStyle(fontSize: 9, color: Colors.white38)),
      ],
    );
  }

  // ─── Status Banner ────────────────────────────────────────────────────────
  Widget _buildStatusBanner() {
    if (_engine.isWon) {
      return _banner(
        gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF065F46)]),
        border: const Color(0xFF10B981),
        icon: Icons.emoji_events_rounded,
        iconColor: Colors.amberAccent,
        text: '🎉  XUẤT SẮC! Bạn đã chiến thắng!',
      );
    }
    if (_engine.isLost) {
      return _banner(
        gradient: const LinearGradient(
            colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)]),
        border: const Color(0xFFEF4444),
        icon: Icons.error_outline_rounded,
        iconColor: Colors.white,
        text: _engine.statusMessage ?? 'Va chạm! Thử lại nhé.',
      );
    }
    if (_engine.statusMessage != null && _engine.isExecuting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF818CF8)),
            ),
            const SizedBox(width: 8),
            Text(_engine.statusMessage!,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _banner({
    required Gradient gradient,
    required Color border,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Win Dialog Content
// ─────────────────────────────────────────────────────────────────────────────
class _WinDialogContent extends StatelessWidget {
  final String levelName;
  final int stars;
  final int usedMain;
  final int maxMain;
  final int usedF1;
  final int maxF1;
  final int energyCollected;
  final int totalEnergy;
  final bool hasNext;
  final VoidCallback onPlayAgain;
  final VoidCallback onOptimize;
  final VoidCallback onNextLevel;

  const _WinDialogContent({
    required this.levelName,
    required this.stars,
    required this.usedMain,
    required this.maxMain,
    required this.usedF1,
    required this.maxF1,
    required this.energyCollected,
    required this.totalEnergy,
    required this.hasNext,
    required this.onPlayAgain,
    required this.onOptimize,
    required this.onNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tiêu đề ──────────────────────────────────────────────────
          const Text(
            'NHIỆM VỤ HOÀN THÀNH!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF34D399),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            levelName,
            style: const TextStyle(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 20),

          // ── Sao ──────────────────────────────────────────────────────
          _StarRow(stars: stars),
          const SizedBox(height: 6),
          Text(
            _starLabel(stars),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _starLabelColor(stars),
            ),
          ),
          const SizedBox(height: 20),

          // ── Stats ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                _statRow(Icons.bolt_rounded, Colors.amber, 'Năng lượng',
                    '$energyCollected / $totalEnergy'),
                const SizedBox(height: 8),
                _statRow(Icons.code_rounded, const Color(0xFF818CF8),
                    'Lệnh Main', '$usedMain / $maxMain'),
                if (usedF1 > 0) ...[
                  const SizedBox(height: 8),
                  _statRow(Icons.functions_rounded,
                      const Color(0xFFFB923C), 'Lệnh F1',
                      '$usedF1 / $maxF1'),
                ],
              ],
            ),
          ),

          // ── Gợi ý nếu chưa đạt 3 sao ────────────────────────────────
          if (stars < 3) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      color: Color(0xFFFBBF24), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _optimizeHint(stars, maxMain),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFFDE68A)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Nút hành động ────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nút chính: Màn tiếp / Chơi lại từ đầu
              _ActionBtn(
                label: hasNext ? '▶  Màn tiếp theo' : '⟳  Chơi lại từ đầu',
                gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)]),
                onTap: hasNext ? onNextLevel : onPlayAgain,
              ),
              const SizedBox(height: 8),

              // Nút phụ: phụ thuộc số sao
              if (stars < 3) ...[
                _ActionBtn(
                  label: '✦  Thử tối ưu lại  (${_targetCommands(maxMain)} lệnh để ★★★)',
                  gradient: LinearGradient(colors: [
                    const Color(0xFF78350F).withValues(alpha: 0.7),
                    const Color(0xFF92400E).withValues(alpha: 0.7),
                  ]),
                  border: const Color(0xFFFBBF24),
                  onTap: onOptimize,
                ),
                const SizedBox(height: 8),
              ],

              _ActionBtn(
                label: '↺  Chơi lại màn này',
                gradient: LinearGradient(colors: [
                  const Color(0xFF334155).withValues(alpha: 0.6),
                  const Color(0xFF1E293B).withValues(alpha: 0.6),
                ]),
                border: const Color(0xFF475569),
                onTap: onPlayAgain,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _starLabel(int s) {
    if (s == 3) return '⭐ Hoàn hảo!';
    if (s == 2) return '✦ Tốt lắm!';
    return '• Hoàn thành';
  }

  Color _starLabelColor(int s) {
    if (s == 3) return const Color(0xFFFBBF24);
    if (s == 2) return const Color(0xFF60A5FA);
    return const Color(0xFF94A3B8);
  }

  String _optimizeHint(int s, int max) {
    final target = _targetCommands(max);
    if (s == 1) return 'Dùng ≤ $target lệnh để đạt ★★★. Hãy thử rút gọn!';
    return 'Gần 3 sao rồi! Dùng ≤ $target lệnh Main để đạt ★★★.';
  }

  int _targetCommands(int max) => (max * 0.5).floor();

  Widget _statRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }
}

// ─── Hàng ngôi sao ───────────────────────────────────────────────────────────
class _StarRow extends StatelessWidget {
  final int stars;

  const _StarRow({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final bool filled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + i * 200),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(
              scale: v,
              child: child,
            ),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? const Color(0xFFFBBF24) : Colors.white24,
              size: filled ? 44 : 36,
            ),
          ),
        );
      }),
    );
  }
}

// ─── Nút hành động ───────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final Color? border;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.gradient,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          border: border != null
              ? Border.all(color: border!, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lost Dialog Content
// ─────────────────────────────────────────────────────────────────────────────
class _LostDialogContent extends StatelessWidget {
  final String message;
  final int livesLeft;
  final VoidCallback onRetry;
  final VoidCallback? onWatchAdForLives;

  const _LostDialogContent({
    required this.message,
    required this.livesLeft,
    required this.onRetry,
    this.onWatchAdForLives,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfLives = livesLeft == 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1F0A0A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEF4444), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated crash icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (_, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7F1D1D).withValues(alpha: 0.5),
                border: Border.all(
                    color: const Color(0xFFEF4444), width: 2),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.redAccent, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'VA CHẠM!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF87171),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 12),
          // Hiển thị số mạng còn lại
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOutOfLives
                  ? const Color(0xFF450A0A)
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOutOfLives
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF334155),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOutOfLives
                      ? Icons.heart_broken_rounded
                      : Icons.favorite_rounded,
                  color: const Color(0xFFEF4444),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isOutOfLives
                      ? 'Đã hết mạng (0/5 ❤️)!'
                      : 'Mạng còn lại: $livesLeft/5 ❤️',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOutOfLives
                        ? const Color(0xFFFCA5A5)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isOutOfLives && onWatchAdForLives != null) ...[
            _ActionBtn(
              label: '📺  Xem quảng cáo (+3 ❤️)',
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
              ),
              onTap: onWatchAdForLives!,
            ),
            const SizedBox(height: 10),
          ],
          _ActionBtn(
            label: isOutOfLives ? 'Đóng' : '⟳  Thử lại',
            gradient: isOutOfLives
                ? const LinearGradient(
                    colors: [Color(0xFF334155), Color(0xFF1E293B)])
                : const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog xác nhận xem quảng cáo nhận thưởng
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmAdDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String actionLabel;
  final VoidCallback onConfirm;

  const _ConfirmAdDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.actionLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: iconColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.2),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Color(0xFF334155)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Để sau'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog xem 3 bước đi gợi ý
// ─────────────────────────────────────────────────────────────────────────────
class _HintStepsDialogContent extends StatelessWidget {
  final String levelName;
  final List<CommandType> hints;
  final VoidCallback onApplyHint;
  final VoidCallback onClose;

  const _HintStepsDialogContent({
    required this.levelName,
    required this.hints,
    required this.onApplyHint,
    required this.onClose,
  });

  IconData _iconForCommand(CommandType cmd) {
    switch (cmd) {
      case CommandType.moveForward:
        return Icons.arrow_upward_rounded;
      case CommandType.turnLeft:
        return Icons.rotate_left_rounded;
      case CommandType.turnRight:
        return Icons.rotate_right_rounded;
      case CommandType.collectEnergy:
        return Icons.bolt_rounded;
      case CommandType.jump:
        return Icons.upload_rounded;
      case CommandType.callFunction1:
        return Icons.functions_rounded;
    }
  }

  Color _colorForCommand(CommandType cmd) {
    switch (cmd) {
      case CommandType.moveForward:
        return const Color(0xFF38BDF8);
      case CommandType.turnLeft:
        return const Color(0xFFA78BFA);
      case CommandType.turnRight:
        return const Color(0xFFC084FC);
      case CommandType.collectEnergy:
        return const Color(0xFFFBBF24);
      case CommandType.jump:
        return const Color(0xFF34D399);
      case CommandType.callFunction1:
        return const Color(0xFFF97316);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E1E38)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_rounded,
                    color: Color(0xFFF59E0B), size: 24),
              ),
              const SizedBox(width: 10),
              const Text(
                'GỢI Ý 3 BƯỚC ĐẦU',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFDE68A),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            levelName,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          // Danh sách 3 bước
          ...List.generate(hints.length, (i) {
            final cmd = hints[i];
            final color = _colorForCommand(cmd);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_iconForCommand(cmd), color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cmd.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF334155)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Đã hiểu'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onApplyHint,
                  icon: const Icon(Icons.playlist_add_rounded, size: 18),
                  label: const Text(
                    'Điền vào lệnh',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog nhận quà điểm danh hàng ngày
// ─────────────────────────────────────────────────────────────────────────────
class _DailyRewardDialogContent extends StatelessWidget {
  final VoidCallback onClaim;

  const _DailyRewardDialogContent({required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.25),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: Color(0xFF34D399), size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'QUÀ ĐIỂM DANH MỖI NGÀY!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF6EE7B7),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chào mừng bạn đến với ngày mới! Bạn nhận được các phần thưởng:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF059669).withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_rounded,
                        color: Color(0xFFEF4444), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Hồi 5 Mạng',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Text('+',
                    style: TextStyle(color: Colors.white38, fontSize: 18)),
                Row(
                  children: [
                    Icon(Icons.lightbulb_rounded,
                        color: Color(0xFFF59E0B), size: 22),
                    SizedBox(width: 8),
                    Text(
                      '+1 Gợi Ý',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'NHẬN NGAY',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog giả lập xem quảng cáo trong 3 giây
// ─────────────────────────────────────────────────────────────────────────────
class _AdSimulationDialog extends StatefulWidget {
  final String rewardTitle;
  final PlayerManager playerManager;
  final VoidCallback onComplete;

  const _AdSimulationDialog({
    required this.rewardTitle,
    required this.playerManager,
    required this.onComplete,
  });

  @override
  State<_AdSimulationDialog> createState() => _AdSimulationDialogState();
}

class _AdSimulationDialogState extends State<_AdSimulationDialog> {
  int _secondsLeft = 3;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  Future<void> _startCountdown() async {
    for (int i = 2; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _secondsLeft = i;
      });
    }
    if (mounted) {
      widget.playerManager.showRewardedAd(widget.onComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.ondemand_video_rounded,
                  color: Color(0xFF818CF8), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'ĐANG XEM QUẢNG CÁO...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Phần thưởng: ${widget.rewardTitle}',
              style: const TextStyle(fontSize: 13, color: Color(0xFFA5B4FC)),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: (3 - _secondsLeft) / 3.0,
                    strokeWidth: 4,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    backgroundColor: Colors.white12,
                  ),
                ),
                Text(
                  '${_secondsLeft}s',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Vui lòng không tắt màn hình trong giây lát',
              style: TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
