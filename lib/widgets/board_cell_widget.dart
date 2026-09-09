import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/game_level.dart';
import '../models/position.dart';

/// BoardCellWidget: Hiển thị một ô bàn cờ với hiệu ứng 3D theo [elevation].
///
/// **Hệ thống màu theo elevation:**
/// - elevation 0 (mặt đất): nền xám xanh tối #1E293B
/// - elevation 1 (bục cao): nền tím xanh sáng hơn, viền tím, đổ bóng bên dưới
///   tạo cảm giác khối nổi lên khỏi mặt đất.
class BoardCellWidget extends StatelessWidget {
  final Position position;
  final Cell cell;
  final Cell originalCell;

  const BoardCellWidget({
    super.key,
    required this.position,
    required this.cell,
    required this.originalCell,
  });

  bool get _isDestination => originalCell.type == CellType.destination;
  bool get _isStart => originalCell.type == CellType.start;
  int get _elevation => cell.elevation;
  bool get _isHighPlatform => _elevation > 0;

  @override
  Widget build(BuildContext context) {
    // Ô tường không cần stack, render đơn giản hơn
    if (cell.type == CellType.wall) {
      return _buildWallCell();
    }

    return _buildNormalCell();
  }

  // ─── Ô tường ────────────────────────────────────────────────────────────
  Widget _buildWallCell() {
    return Container(
      decoration: BoxDecoration(
        // Gradient tường: từ slate đậm → slate rất đậm
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF374151), Color(0xFF1F2937)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF4B5563), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(1, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 18),
      ),
    );
  }

  // ─── Ô thường (empty / start / dest / energy) ────────────────────────────
  Widget _buildNormalCell() {
    return Stack(
      children: [
        // ── Lớp nền chính với hiệu ứng 3D ──────────────────────────────
        Positioned.fill(
          child: _isHighPlatform ? _buildPlatformCell() : _buildGroundCell(),
        ),

        // ── Icon nội dung ─────────────────────────────────────────────
        Center(child: _buildCellContent()),

        // ── Badge elevation ở góc trên phải ───────────────────────────
        if (_isHighPlatform && cell.type != CellType.wall)
          Positioned(
            top: 2,
            right: 2,
            child: _buildElevationBadge(),
          ),
      ],
    );
  }

  // ─── Ô mặt đất (elevation = 0) ──────────────────────────────────────────
  Widget _buildGroundCell() {
    Color bg = _getGroundColor();
    Color border = _getGroundBorderColor();

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1.5),
      ),
    );
  }

  // ─── Ô bục cao (elevation > 0) — hiệu ứng 3D nổi ───────────────────────
  Widget _buildPlatformCell() {
    return Container(
      decoration: BoxDecoration(
        // Gradient sáng từ trên xuống → giả lập ánh sáng chiếu vào mặt bục
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _getPlatformGradientColors(),
        ),
        borderRadius: BorderRadius.circular(6),
        // Viền trên & bên tím sáng (mặt trên của khối)
        border: Border(
          top: BorderSide(color: _getPlatformTopEdgeColor(), width: 2),
          left: BorderSide(color: _getPlatformTopEdgeColor(), width: 2),
          right: BorderSide(color: _getPlatformSideColor(), width: 1),
          bottom: BorderSide(color: _getPlatformSideColor(), width: 1),
        ),
        // Shadow bên dưới bục để tạo chiều sâu 3D
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3730A3).withValues(alpha: 0.5),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.8),
            offset: const Offset(2, 4),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }

  // ─── Màu nền mặt đất ────────────────────────────────────────────────────
  Color _getGroundColor() {
    switch (cell.type) {
      case CellType.destination:
        return const Color(0xFF431407).withValues(alpha: 0.85);
      case CellType.start:
        return const Color(0xFF064E3B).withValues(alpha: 0.85);
      case CellType.energy:
        return const Color(0xFF1C1917).withValues(alpha: 0.8);
      case CellType.empty:
        if (_isDestination) return const Color(0xFF431407).withValues(alpha: 0.85);
        if (_isStart) return const Color(0xFF064E3B).withValues(alpha: 0.85);
        return const Color(0xFF0F172A).withValues(alpha: 0.7);
      case CellType.wall:
        return const Color(0xFF334155);
    }
  }

  Color _getGroundBorderColor() {
    switch (cell.type) {
      case CellType.destination:
        return const Color(0xFFD97706);
      case CellType.start:
        return const Color(0xFF059669);
      case CellType.energy:
        return const Color(0xFFF59E0B).withValues(alpha: 0.5);
      case CellType.empty:
        if (_isDestination) return const Color(0xFFD97706);
        if (_isStart) return const Color(0xFF059669);
        return const Color(0xFF1E3A5F).withValues(alpha: 0.6);
      case CellType.wall:
        return const Color(0xFF475569);
    }
  }

  // ─── Màu gradient cho bục cao ───────────────────────────────────────────
  List<Color> _getPlatformGradientColors() {
    switch (cell.type) {
      case CellType.destination:
        return [const Color(0xFF7C2D12), const Color(0xFF431407)];
      case CellType.start:
        return [const Color(0xFF065F46), const Color(0xFF064E3B)];
      case CellType.energy:
        return [const Color(0xFF3B2800), const Color(0xFF1C1100)];
      default:
        // Bục trống: xanh dương-tím theo độ cao
        final base = 0.3 + (_elevation * 0.15).clamp(0.0, 0.5);
        return [
          Color.fromRGBO(99, 102, 241, base + 0.15),  // tím sáng phía trên
          Color.fromRGBO(67, 56, 202, base),           // tím tối phía dưới
        ];
    }
  }

  Color _getPlatformTopEdgeColor() {
    switch (cell.type) {
      case CellType.destination:
        return const Color(0xFFFB923C);
      case CellType.start:
        return const Color(0xFF34D399);
      case CellType.energy:
        return const Color(0xFFFBBF24).withValues(alpha: 0.8);
      default:
        return const Color(0xFF818CF8);
    }
  }

  Color _getPlatformSideColor() {
    switch (cell.type) {
      case CellType.destination:
        return const Color(0xFF92400E);
      case CellType.start:
        return const Color(0xFF065F46);
      case CellType.energy:
        return const Color(0xFF78350F);
      default:
        return const Color(0xFF3730A3);
    }
  }

  // ─── Badge +N ────────────────────────────────────────────────────────────
  Widget _buildElevationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFA5B4FC).withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Text(
        '+$_elevation',
        style: const TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }

  // ─── Nội dung icon ───────────────────────────────────────────────────────
  Widget? _buildCellContent() {
    if (cell.type == CellType.energy) {
      return Icon(
        Icons.bolt_rounded,
        color: _isHighPlatform
            ? const Color(0xFFFDE68A)
            : const Color(0xFFFACC15),
        size: _isHighPlatform ? 22 : 24,
      );
    }

    if (cell.type == CellType.destination || _isDestination) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.door_sliding_outlined,
            color: const Color(0xFFFB923C),
            size: _isHighPlatform ? 18 : 20,
          ),
          if (_isHighPlatform)
            const Text(
              'EXIT',
              style: TextStyle(
                color: Color(0xFFFB923C),
                fontSize: 6,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
        ],
      );
    }

    if (cell.type == CellType.start || _isStart) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF34D399),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Text(
            'S',
            style: TextStyle(
              color: Color(0xFF34D399),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              height: 1,
            ),
          ),
        ),
      );
    }

    // Ô bục cao trống: icon bậc thang mờ
    if (_isHighPlatform) {
      return Icon(
        Icons.layers_rounded,
        color: const Color(0xFFA5B4FC).withValues(alpha: 0.35),
        size: 14,
      );
    }

    return null;
  }
}
