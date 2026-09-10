import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../models/enums.dart';
import 'action_buttons.dart';
import 'command_queue.dart' show getIconForCommand, getColorForCommand;

/// CommandDeck: Bảng điều khiển cố định ở nửa dưới màn hình chuẩn Mobile Game UX.
/// - Không bao giờ làm nở chiều cao của màn hình.
/// - Tích hợp Tab chuyển đổi Main / F1.
/// - Hàng lệnh (Queue) cuộn ngang 1 dòng mỏng (Single-Row Horizontal Queue), tự cuộn sang phải khi thêm lệnh.
/// - Bảng nút bấm chọn lệnh (Palette) 2 hàng cố định, vừa tầm với ngón tay cái.
/// - Nút Chạy / Đặt lại (ActionButtons) ghim cố định ở đáy.
class CommandDeck extends StatefulWidget {
  final GameEngine engine;
  final VoidCallback? onRun;

  const CommandDeck({
    super.key,
    required this.engine,
    this.onRun,
  });

  @override
  State<CommandDeck> createState() => _CommandDeckState();
}

class _CommandDeckState extends State<CommandDeck> {
  bool _isF1Tab = false;
  final ScrollController _scrollController = ScrollController();
  int _prevCommandCount = 0;

  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_onEngineUpdate);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngineUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _onEngineUpdate() {
    final currentList = _isF1Tab
        ? widget.engine.function1List
        : widget.engine.commandList;

    // Tự động cuộn sang phải khi có lệnh mới được thêm
    if (currentList.length > _prevCommandCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    // Tự động cuộn theo lệnh đang thực thi
    final activeIdx = _isF1Tab
        ? widget.engine.currentF1CommandIndex
        : widget.engine.currentCommandIndex;
    if (widget.engine.isExecuting && activeIdx != null && activeIdx >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final targetOffset = (activeIdx * 80.0).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    _prevCommandCount = currentList.length;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        final engine = widget.engine;
        final level = engine.currentLevel;
        final bool locked = engine.isExecuting;

        final currentList = _isF1Tab ? engine.function1List : engine.commandList;
        final maxCount = _isF1Tab
            ? level.maxFunction1Commands
            : level.maxCommandsAllowed;
        final activeIndex = _isF1Tab
            ? engine.currentF1CommandIndex
            : engine.currentCommandIndex;

        final themeColor = _isF1Tab
            ? const Color(0xFFFB923C)
            : const Color(0xFF818CF8);
        final themeBg = _isF1Tab
            ? const Color(0xFF271307)
            : const Color(0xFF0F172A);
        final themeBorder = _isF1Tab
            ? const Color(0xFF9A3412)
            : const Color(0xFF3730A3);

        return Container(
          decoration: BoxDecoration(
            color: themeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeBorder.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 1. Tab Switcher Header (Main vs F1) + Clear buttons ─────────
              _buildTabsHeader(engine, locked, themeColor),
              const SizedBox(height: 6),

              // ── 2. Hàng lệnh cuộn ngang (Single-Row Horizontal Queue) ──────
              _buildHorizontalQueue(
                currentList: currentList,
                maxCount: maxCount,
                activeIndex: activeIndex,
                locked: locked,
                themeColor: themeColor,
              ),
              const SizedBox(height: 8),

              // ── 3. Bảng phím lệnh (Command Palette - 2 hàng x 3 cột) ───────
              _buildCommandButtonsGrid(locked),
              const SizedBox(height: 8),

              // ── 4. Nút Chạy & Đặt lại (ActionButtons) ───────────────────────
              ActionButtons(
                engine: engine,
                onRun: widget.onRun,
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Header: Tabs chọn Main / F1 + Nút xóa ─────────────────────────────────
  Widget _buildTabsHeader(GameEngine engine, bool locked, Color themeColor) {
    final int mainCount = engine.commandList.length;
    final int mainMax = engine.currentLevel.maxCommandsAllowed;
    final int f1Count = engine.function1List.length;
    final int f1Max = engine.currentLevel.maxFunction1Commands;

    return Row(
      children: [
        // Tab Main Routine
        Expanded(
          child: _TabButton(
            label: 'Main',
            count: mainCount,
            max: mainMax,
            isActive: !_isF1Tab,
            activeColor: const Color(0xFF818CF8),
            activeBg: const Color(0xFF1E1B4B),
            icon: Icons.code_rounded,
            onTap: locked ? null : () => setState(() => _isF1Tab = false),
          ),
        ),
        const SizedBox(width: 6),

        // Tab Function F1
        Expanded(
          child: _TabButton(
            label: 'F1 (Hàm)',
            count: f1Count,
            max: f1Max,
            isActive: _isF1Tab,
            activeColor: const Color(0xFFFB923C),
            activeBg: const Color(0xFF431407),
            icon: Icons.functions_rounded,
            onTap: locked ? null : () => setState(() => _isF1Tab = true),
          ),
        ),
        const SizedBox(width: 6),

        // Nút Xóa lệnh cuối
        _MiniIconButton(
          icon: Icons.backspace_outlined,
          tooltip: 'Xóa lệnh gần nhất',
          color: Colors.amberAccent,
          onTap: locked
              ? null
              : () {
                  final list = _isF1Tab
                      ? engine.function1List
                      : engine.commandList;
                  if (list.isNotEmpty) {
                    if (_isF1Tab) {
                      engine.removeFunction1At(list.length - 1);
                    } else {
                      engine.removeCommandAt(list.length - 1);
                    }
                  }
                },
        ),
        const SizedBox(width: 4),

        // Nút Xóa hết
        _MiniIconButton(
          icon: Icons.delete_sweep_rounded,
          tooltip: 'Xóa tất cả lệnh trong tab này',
          color: Colors.redAccent,
          onTap: locked
              ? null
              : () {
                  final list = _isF1Tab
                      ? engine.function1List
                      : engine.commandList;
                  if (list.isNotEmpty) {
                    if (_isF1Tab) {
                      engine.clearFunction1();
                    } else {
                      engine.clearCommands();
                    }
                  }
                },
        ),
      ],
    );
  }

  // ─── Hàng lệnh cuộn ngang ──────────────────────────────────────────────────
  Widget _buildHorizontalQueue({
    required List<CommandType> currentList,
    required int maxCount,
    required int? activeIndex,
    required bool locked,
    required Color themeColor,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF060D18).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: currentList.isEmpty
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 14, color: themeColor.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Text(
                    _isF1Tab
                        ? 'Chạm nút bên dưới để thêm lệnh vào Hàm F1'
                        : 'Chạm nút bên dưới để thêm lệnh vào Main',
                    style: TextStyle(
                      fontSize: 11,
                      color: themeColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: currentList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cmd = currentList[index];
                final bool isActive = activeIndex == index;

                return _CommandChipCompact(
                  index: index,
                  cmd: cmd,
                  isActive: isActive,
                  locked: locked,
                  onTap: locked
                      ? null
                      : () {
                          if (_isF1Tab) {
                            widget.engine.removeFunction1At(index);
                          } else {
                            widget.engine.removeCommandAt(index);
                          }
                        },
                );
              },
            ),
    );
  }

  // ─── Lưới 6 nút lệnh chọn nhanh (2 hàng x 3 cột) ───────────────────────────
  Widget _buildCommandButtonsGrid(bool locked) {
    const row1 = [
      _CmdInfo(CommandType.moveForward, 'Tiến', Icons.arrow_upward_rounded,
          Color(0xFF4ADE80)),
      _CmdInfo(CommandType.turnLeft, 'Trái', Icons.rotate_left_rounded,
          Color(0xFF38BDF8)),
      _CmdInfo(CommandType.turnRight, 'Phải', Icons.rotate_right_rounded,
          Color(0xFFA78BFA)),
    ];

    const row2 = [
      _CmdInfo(CommandType.jump, 'Nhảy', Icons.upload_rounded,
          Color(0xFFF472B6)),
      _CmdInfo(CommandType.collectEnergy, 'Nhặt', Icons.bolt_rounded,
          Color(0xFFFBBF24)),
      _CmdInfo(CommandType.callFunction1, 'F1', Icons.functions_rounded,
          Color(0xFFFB923C)),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: row1.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _CommandTile(
                  info: item,
                  isDisabled: locked,
                  onTap: () => _addCommand(item.cmd),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          children: row2.map((item) {
            final bool isF1Cmd = item.cmd == CommandType.callFunction1;
            final bool isDisabled = locked || (_isF1Tab && isF1Cmd);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _CommandTile(
                  info: item,
                  isDisabled: isDisabled,
                  onTap: () => _addCommand(item.cmd),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _addCommand(CommandType cmd) {
    if (_isF1Tab) {
      widget.engine.addToFunction1(cmd);
    } else {
      widget.engine.addCommand(cmd);
    }
  }
}

// ─── Model thông tin lệnh ───────────────────────────────────────────────────
class _CmdInfo {
  final CommandType cmd;
  final String label;
  final IconData icon;
  final Color color;

  const _CmdInfo(this.cmd, this.label, this.icon, this.color);
}

// ─── Nút bấm lệnh gọn gàng trong Grid ────────────────────────────────────────
class _CommandTile extends StatelessWidget {
  final _CmdInfo info;
  final bool isDisabled;
  final VoidCallback onTap;

  const _CommandTile({
    required this.info,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          decoration: BoxDecoration(
            color: isDisabled
                ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                : info.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDisabled
                  ? const Color(0xFF334155).withValues(alpha: 0.5)
                  : info.color.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                info.icon,
                size: 17,
                color: isDisabled ? Colors.white24 : info.color,
              ),
              const SizedBox(width: 5),
              Text(
                info.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDisabled ? Colors.white24 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chip lệnh trong hàng cuộn ngang ─────────────────────────────────────────
class _CommandChipCompact extends StatelessWidget {
  final int index;
  final CommandType cmd;
  final bool isActive;
  final bool locked;
  final VoidCallback? onTap;

  const _CommandChipCompact({
    required this.index,
    required this.cmd,
    required this.isActive,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = getIconForCommand(cmd);
    final color = getColorForCommand(cmd);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.3)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.white : color.withValues(alpha: 0.6),
            width: isActive ? 2.0 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Số thứ tự lệnh
            Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.white54,
              ),
            ),
            const SizedBox(width: 5),
            Icon(icon, size: 16, color: color),
            if (!locked) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.close_rounded,
                size: 12,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tab Button trên Header Deck ────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final bool isActive;
  final Color activeColor;
  final Color activeBg;
  final IconData icon;
  final VoidCallback? onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.max,
    required this.isActive,
    required this.activeColor,
    required this.activeBg,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isActive ? activeColor : Colors.white38),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? activeColor : Colors.white54,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.25)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count/$max',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? activeColor : Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mini Icon Button ───────────────────────────────────────────────────────
class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 15, color: onTap != null ? color : Colors.white24),
          ),
        ),
      ),
    );
  }
}
