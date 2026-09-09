import 'dart:math';
import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/enums.dart';
import '../models/position.dart';
import 'board_cell_widget.dart';
import 'robot_widget.dart';

/// GameBoardWidget: Widget hiển thị bàn cờ lưới (Grid Logic Puzzle)
/// - Lắng nghe thay đổi trạng thái từ [GameEngine] qua [ListenableBuilder].
/// - Tự động co giãn theo tỷ lệ vuông 1:1 trên màn hình điện thoại hoặc web.
/// - Hiển thị elevation (bục cao) qua BoardCellWidget được nâng cấp.
class GameBoardWidget extends StatelessWidget {
  final GameEngine engine;
  final double cellSpacing;
  final double boardPadding;
  final double? maxBoardSize;

  const GameBoardWidget({
    super.key,
    required this.engine,
    this.cellSpacing = 4.0,
    this.boardPadding = 8.0,
    this.maxBoardSize = 420.0,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final level = engine.currentLevel;
        final int gridWidth = level.gridWidth;
        final int gridHeight = level.gridHeight;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double limit = maxBoardSize ?? 420.0;
            final double availableWidth = constraints.maxWidth;
            final double availableHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : limit;
            final double boardSize =
                min(min(availableWidth, availableHeight), limit);

            final double innerWidth = boardSize - (2 * boardPadding);
            final double innerHeight = boardSize - (2 * boardPadding);
            final double cellWidth =
                (innerWidth - (gridWidth - 1) * cellSpacing) / gridWidth;
            final double cellHeight =
                (innerHeight - (gridHeight - 1) * cellSpacing) / gridHeight;
            final double cellSize = min(cellWidth, cellHeight);

            final double actualBoardWidth =
                (gridWidth * cellSize) + ((gridWidth - 1) * cellSpacing);
            final double actualBoardHeight =
                (gridHeight * cellSize) + ((gridHeight - 1) * cellSpacing);

            final double offsetX = (boardSize - actualBoardWidth) / 2;
            final double offsetY = (boardSize - actualBoardHeight) / 2;

            return Center(
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF334155),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Lớp 1: Các ô cờ (hỗ trợ Cell với elevation)
                        Positioned(
                          left: offsetX,
                          top: offsetY,
                          width: actualBoardWidth,
                          height: actualBoardHeight,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridWidth,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: cellSpacing,
                              mainAxisSpacing: cellSpacing,
                            ),
                            itemCount: gridWidth * gridHeight,
                            itemBuilder: (context, index) {
                              final int x = index % gridWidth;
                              final int y = index ~/ gridWidth;
                              final Position pos = Position(x, y);

                              // Cell runtime: phản ánh vật phẩm đã nhặt
                              final runtimeCell = engine.getRuntimeCellAt(pos);
                              if (runtimeCell == null) {
                                return const SizedBox.shrink();
                              }

                              // Cell gốc (dùng để biết đây là start/destination)
                              final originalCell = level.mapData[y][x];

                              // Nếu runtime đã empty nhưng gốc là destination/start
                              // → vẫn truyền originalCell để hiện icon đúng
                              final displayCell =
                                  runtimeCell.type == CellType.empty &&
                                          (originalCell.type ==
                                                  CellType.destination ||
                                              originalCell.type ==
                                                  CellType.start)
                                      ? originalCell
                                      : runtimeCell;

                              return BoardCellWidget(
                                position: pos,
                                cell: displayCell,
                                originalCell: originalCell,
                              );
                            },
                          ),
                        ),

                        // Lớp 2: Robot (AnimatedPositioned mượt mà)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: offsetX +
                              engine.botPosition.x * (cellSize + cellSpacing),
                          top: offsetY +
                              engine.botPosition.y * (cellSize + cellSpacing),
                          width: cellSize,
                          height: cellSize,
                          child: RobotWidget(
                            direction: engine.botDirection,
                            isWon: engine.isWon,
                            isLost: engine.isLost,
                            size: cellSize * 0.75,
                            elevation: engine.botElevation,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
