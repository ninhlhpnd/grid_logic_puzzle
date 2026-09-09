import 'package:flutter/material.dart';
import '../engine/game_engine.dart';

/// Widget ActionButtons: Cung cấp các nút điều khiển thực thi chính:
/// - Nút "▶ CHẠY (RUN)": Gọi engine.runCommands(), hiển thị trạng thái loading khi đang chạy.
/// - Nút "🔄 ĐẶT LẠI (RESET)": Gọi engine.resetLevel() đưa Robot và năng lượng về ban đầu.
class ActionButtons extends StatelessWidget {
  final GameEngine engine;
  final VoidCallback? onRun;

  const ActionButtons({
    super.key,
    required this.engine,
    this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final bool isRunning = engine.isExecuting;
        final bool canRun = !isRunning && engine.commandList.isNotEmpty;
        final bool canReset = !isRunning;

        return Row(
          children: [
            // Nút "▶ CHẠY (RUN)"
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: canRun ? (onRun ?? () => engine.runCommands()) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5), // Indigo rực rỡ
                    disabledBackgroundColor: const Color(0xFF312E81).withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white30,
                    elevation: canRun ? 4 : 0,
                    shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isRunning
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.cyanAccent),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'ĐANG CHẠY...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 24),
                            SizedBox(width: 6),
                            Text(
                              'CHẠY (RUN)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Nút "🔄 ĐẶT LẠI (RESET)"
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: canReset ? () => engine.resetLevel() : null,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'ĐẶT LẠI (RESET)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    disabledForegroundColor: Colors.white24,
                    side: BorderSide(
                      color: canReset
                          ? const Color(0xFF475569)
                          : const Color(0xFF334155),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
