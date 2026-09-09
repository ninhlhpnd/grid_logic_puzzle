import 'package:flutter/material.dart';
import '../models/game_level.dart';
import '../services/level_manager.dart';
import '../services/player_manager.dart';

/// Màn hình chọn màn chơi (Level Selection Screen).
/// Hiển thị GridView gồm 100 ô level:
/// - Khóa (làm mờ nhạt màu, vô hiệu hóa) các level > [unlockedLevels].
/// - Hiển thị số Sao đã đạt được (1-3 sao ⭐) ở dưới mỗi level đã hoàn thành.
class LevelSelectionScreen extends StatelessWidget {
  final LevelManager levelManager;
  final PlayerManager playerManager;
  final int currentSelectedLevelIndex;
  final void Function(int levelIndex) onSelectLevel;

  const LevelSelectionScreen({
    super.key,
    required this.levelManager,
    required this.playerManager,
    required this.currentSelectedLevelIndex,
    required this.onSelectLevel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([levelManager, playerManager]),
      builder: (context, _) {
        final int totalLevels =
            levelManager.totalLevels > 0 ? levelManager.totalLevels : 100;
        final int unlocked = playerManager.unlockedLevels;
        final int totalStars = playerManager.totalStarsEarned;
        final int maxStarsPossible = totalLevels * 3;

        return Scaffold(
          backgroundColor: const Color(0xFF060D18),
          appBar: _buildAppBar(context, totalStars, maxStarsPossible),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Tính toán số cột responsive
                final int crossAxisCount = constraints.maxWidth > 700
                    ? 6
                    : constraints.maxWidth > 480
                        ? 5
                        : 4;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      children: [
                        // Header thông tin tiến trình
                        _buildProgressHeader(unlocked, totalLevels, totalStars),

                        // Lưới 100 Level
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.88,
                            ),
                            itemCount: totalLevels,
                            itemBuilder: (context, index) {
                              final bool isUnlocked = index < unlocked;
                              final bool isCurrent = index == (unlocked - 1);
                              final bool isSelected =
                                  index == currentSelectedLevelIndex;
                              final int stars = playerManager.getLevelStars(index);

                              // Lấy thông tin level nếu đã load
                              GameLevel? level;
                              if (index < levelManager.totalLevels) {
                                level = levelManager.getLevel(index);
                              }

                              return _LevelCard(
                                index: index,
                                isUnlocked: isUnlocked,
                                isCurrent: isCurrent,
                                isSelected: isSelected,
                                stars: stars,
                                levelName: level?.name,
                                onTap: isUnlocked
                                    ? () {
                                        onSelectLevel(index);
                                        Navigator.of(context).pop();
                                      }
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: _buildBottomQuickPlay(context, unlocked, totalLevels),
        );
      },
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
      BuildContext context, int totalStars, int maxStarsPossible) {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Row(
        children: [
          Icon(Icons.grid_view_rounded, color: Color(0xFF818CF8), size: 20),
          SizedBox(width: 8),
          Text(
            'CHỌN MÀN CHƠI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        // Badge tổng sao
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
              const SizedBox(width: 4),
              Text(
                '$totalStars',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Color(0xFFFDE68A),
                ),
              ),
              Text(
                '/$maxStarsPossible',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Badge Mạng mini
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 3),
              Text(
                '${playerManager.lives}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Header Tiến trình ────────────────────────────────────────────────────
  Widget _buildProgressHeader(int unlocked, int totalLevels, int totalStars) {
    final double percent = (unlocked / totalLevels).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF312E81)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến trình khám phá: Màn $unlocked / $totalLevels',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF818CF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Nút Quick Play dưới đáy ──────────────────────────────────────────────
  Widget _buildBottomQuickPlay(
      BuildContext context, int unlocked, int totalLevels) {
    final int targetIndex = (unlocked - 1).clamp(0, totalLevels - 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
      child: SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            onSelectLevel(targetIndex);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 24),
          label: Text(
            'TIẾP TỤC CHƠI: MÀN $unlocked',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card hiển thị từng Level trong GridView
// ─────────────────────────────────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final int index;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isSelected;
  final int stars;
  final String? levelName;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.index,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isSelected,
    required this.stars,
    this.levelName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int displayLevelNumber = index + 1;

    // Màu sắc và hiệu ứng dựa trên trạng thái
    final Color borderColor = isSelected
        ? const Color(0xFF38BDF8)
        : isCurrent
            ? const Color(0xFF818CF8)
            : isUnlocked
                ? const Color(0xFF334155)
                : Colors.white.withValues(alpha: 0.05);

    final Gradient gradient = isUnlocked
        ? (isCurrent
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ))
        : const LinearGradient(
            colors: [Color(0xFF0B1120), Color(0xFF070B14)],
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: isUnlocked ? const Color(0xFF6366F1).withValues(alpha: 0.3) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isCurrent || isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Nội dung chính
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isUnlocked) ...[
                    // Số màn chơi
                    Text(
                      '$displayLevelNumber',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isCurrent
                            ? const Color(0xFFE0E7FF)
                            : isSelected
                                ? const Color(0xFF38BDF8)
                                : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Cụm 3 sao
                    _buildStarsRow(stars),
                  ] else ...[
                    // Màn bị khóa: làm mờ nhạt màu + icon khóa
                    Icon(
                      Icons.lock_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$displayLevelNumber',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ],
              ),

              // Huy hiệu màn đang chơi / chọn
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hàng hiển thị 3 sao ⭐⭐⭐ ──────────────────────────────────────────
  Widget _buildStarsRow(int earnedStars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (starIdx) {
        final bool isFilled = starIdx < earnedStars;
        return Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 13,
          color: isFilled
              ? const Color(0xFFFBBF24)
              : Colors.white.withValues(alpha: 0.2),
        );
      }),
    );
  }
}
