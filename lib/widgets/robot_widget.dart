import 'package:flutter/material.dart';
import '../models/enums.dart';

/// Widget hiển thị Robot với xoay hướng mượt mà và badge elevation.
class RobotWidget extends StatelessWidget {
  final Direction direction;
  final bool isWon;
  final bool isLost;
  final double size;

  /// Độ cao ô hiện tại của robot (dùng để hiển thị badge)
  final int elevation;

  const RobotWidget({
    super.key,
    required this.direction,
    this.isWon = false,
    this.isLost = false,
    this.size = 36.0,
    this.elevation = 0,
  });

  double _getTurns(Direction dir) {
    switch (dir) {
      case Direction.up:
        return 0.0;
      case Direction.right:
        return 0.25;
      case Direction.down:
        return 0.50;
      case Direction.left:
        return 0.75;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = const Color(0xFF6366F1);
    Color shadowColor = const Color(0xFF818CF8);

    if (isWon) {
      bgColor = const Color(0xFF059669);
      shadowColor = const Color(0xFF34D399);
    } else if (isLost) {
      bgColor = const Color(0xFFDC2626);
      shadowColor = const Color(0xFFF87171);
    } else if (elevation > 0) {
      // Robot đang trên bục cao → viền tím đậm hơn
      bgColor = const Color(0xFF4338CA);
      shadowColor = const Color(0xFF6366F1);
    }

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedRotation(
            turns: _getTurns(direction),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.6),
                    blurRadius: elevation > 0 ? 14 : 10,
                    spreadRadius: elevation > 0 ? 3 : 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: size * 0.65,
              ),
            ),
          ),
          // Badge elevation ở góc trên phải robot
          if (elevation > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFA5B4FC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  '+$elevation',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
