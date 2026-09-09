import 'package:flutter/material.dart';
import '../services/player_manager.dart';

/// Widget TopBar hiển thị thông tin người chơi:
/// - Mạng sống (Trái tim ❤️)
/// - Gợi ý (Bóng đèn 💡)
/// - Cung cấp sự kiện khi nhấn vào để sử dụng gợi ý hoặc xem quảng cáo nhận mạng/gợi ý.
class TopBar extends StatelessWidget {
  final PlayerManager playerManager;
  final VoidCallback onTapHint;
  final VoidCallback? onTapLives;

  const TopBar({
    super.key,
    required this.playerManager,
    required this.onTapHint,
    this.onTapLives,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerManager,
      builder: (context, _) {
        final int lives = playerManager.lives;
        final int hints = playerManager.hints;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF334155).withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ─── Cụm Mạng sống (Lives) ──────────────────────────────────
              _buildClickableBadge(
                onTap: onTapLives,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'MẠNG',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '$lives',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: lives > 1
                                    ? Colors.white
                                    : const Color(0xFFF87171),
                              ),
                            ),
                            Text(
                              '/${PlayerManager.maxLives}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (lives < PlayerManager.maxLives) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 13,
                                color: Color(0xFF38BDF8),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Phần ngăn cách nhẹ ──────────────────────────────────────
              Container(
                height: 24,
                width: 1,
                color: const Color(0xFF334155),
              ),

              // ─── Cụm Gợi ý (Hints) ───────────────────────────────────────
              _buildClickableBadge(
                onTap: onTapHint,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'GỢI Ý',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '$hints',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: hints > 0
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: hints > 0
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF7F1D1D),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hints > 0 ? 'DÙNG' : '+ XEM QC',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: hints > 0
                                      ? const Color(0xFF6EE7B7)
                                      : const Color(0xFFFCA5A5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClickableBadge({
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white10,
        highlightColor: Colors.white12,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: child,
        ),
      ),
    );
  }
}
