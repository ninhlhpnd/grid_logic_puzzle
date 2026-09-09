import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../models/enums.dart';

// ─── Định nghĩa nút lệnh ────────────────────────────────────────────────────
class _CmdDef {
  final CommandType cmd;
  final String label;
  final IconData icon;
  final Color color;
  const _CmdDef(this.cmd, this.label, this.icon, this.color);
}

/// Toàn bộ danh sách lệnh có thể dùng
const _allCommands = [
  _CmdDef(CommandType.moveForward, 'Tiến', Icons.arrow_upward_rounded,
      Color(0xFF4ADE80)),
  _CmdDef(CommandType.turnLeft, 'Trái', Icons.rotate_left_rounded,
      Color(0xFF38BDF8)),
  _CmdDef(CommandType.turnRight, 'Phải', Icons.rotate_right_rounded,
      Color(0xFFA78BFA)),
  _CmdDef(CommandType.jump, 'Nhảy', Icons.upload_rounded,
      Color(0xFFF472B6)),
  _CmdDef(CommandType.collectEnergy, 'Nhặt', Icons.bolt_rounded,
      Color(0xFFFBBF24)),
  _CmdDef(CommandType.callFunction1, 'F1', Icons.functions_rounded,
      Color(0xFFFB923C)),
];

/// Lệnh dùng trong F1 (không có callFunction1 để tránh đệ quy vô hạn)
const _f1Commands = [
  _CmdDef(CommandType.moveForward, 'Tiến', Icons.arrow_upward_rounded,
      Color(0xFF4ADE80)),
  _CmdDef(CommandType.turnLeft, 'Trái', Icons.rotate_left_rounded,
      Color(0xFF38BDF8)),
  _CmdDef(CommandType.turnRight, 'Phải', Icons.rotate_right_rounded,
      Color(0xFFA78BFA)),
  _CmdDef(CommandType.jump, 'Nhảy', Icons.upload_rounded,
      Color(0xFFF472B6)),
  _CmdDef(CommandType.collectEnergy, 'Nhặt', Icons.bolt_rounded,
      Color(0xFFFBBF24)),
];

/// CommandPalette: Bảng chọn lệnh hai vùng Main Routine / Function 1.
///
/// Thiết kế:
/// - Hai tab: [▶ Main Routine] và [⟳ Function F1]
/// - Tab Main: 6 nút (gồm cả nút "F1" để gọi hàm)
/// - Tab F1:   5 nút (không có "Gọi F1" để tránh đệ quy)
/// - Header mỗi tab hiển thị màu accent riêng (indigo cho Main, cam cho F1)
class CommandPalette extends StatefulWidget {
  final GameEngine engine;

  const CommandPalette({super.key, required this.engine});

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  bool _isF1Tab = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        final bool locked = widget.engine.isExecuting;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isF1Tab
                  ? const Color(0xFF78350F).withValues(alpha: 0.8)
                  : const Color(0xFF1E3A5F).withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header tab ─────────────────────────────────────────────
              _buildHeader(locked),

              // ── Divider ────────────────────────────────────────────────
              Divider(
                height: 1,
                color: _isF1Tab
                    ? const Color(0xFF78350F).withValues(alpha: 0.5)
                    : const Color(0xFF1E3A5F).withValues(alpha: 0.5),
              ),

              // ── Nút lệnh ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: _buildCommandButtons(locked),
              ),

              // ── Footer hint ────────────────────────────────────────────
              _buildFooterHint(),
            ],
          ),
        );
      },
    );
  }

  // ─── Header với 2 tab toggle ─────────────────────────────────────────────
  Widget _buildHeader(bool locked) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Tab Main Routine
          Expanded(
            child: _TabButton(
              label: '▶  Main Routine',
              isActive: !_isF1Tab,
              activeColor: const Color(0xFF6366F1),
              activeBg: const Color(0xFF1E1B4B),
              onTap: locked ? null : () => setState(() => _isF1Tab = false),
              icon: Icons.code_rounded,
              commandCount: widget.engine.commandList.length,
              maxCommands: widget.engine.currentLevel.maxCommandsAllowed,
            ),
          ),
          const SizedBox(width: 6),
          // Tab Function F1
          Expanded(
            child: _TabButton(
              label: '⟳  Function F1',
              isActive: _isF1Tab,
              activeColor: const Color(0xFFFB923C),
              activeBg: const Color(0xFF431407),
              onTap: locked ? null : () => setState(() => _isF1Tab = true),
              icon: Icons.functions_rounded,
              commandCount: widget.engine.function1List.length,
              maxCommands: widget.engine.currentLevel.maxFunction1Commands,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lưới nút lệnh ───────────────────────────────────────────────────────
  Widget _buildCommandButtons(bool locked) {
    final cmds = _isF1Tab ? _f1Commands : _allCommands;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cmds.map((def) {
        final bool isDisabled = locked ||
            (_isF1Tab && def.cmd == CommandType.callFunction1);

        return _CommandButton(
          def: def,
          isDisabled: isDisabled,
          isF1Tab: _isF1Tab,
          onTap: () {
            if (_isF1Tab) {
              widget.engine.addToFunction1(def.cmd);
            } else {
              widget.engine.addCommand(def.cmd);
            }
          },
        );
      }).toList(),
    );
  }

  // ─── Footer gợi ý nhỏ ───────────────────────────────────────────────────
  Widget _buildFooterHint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 3,
        children: [
          _hint(Icons.upload_rounded, const Color(0xFFF472B6),
              'Nhảy: lên 1 bậc / xuống bất kỳ'),
          _hint(Icons.functions_rounded, const Color(0xFFFB923C),
              'F1: mở rộng hàm con'),
          _hint(Icons.layers_rounded, const Color(0xFF818CF8),
              'Bục tím = cần lệnh Nhảy'),
        ],
      ),
    );
  }

  Widget _hint(IconData icon, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }
}

// ─── Tab Button ──────────────────────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color activeBg;
  final VoidCallback? onTap;
  final IconData icon;
  final int commandCount;
  final int maxCommands;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.activeBg,
    required this.onTap,
    required this.icon,
    required this.commandCount,
    required this.maxCommands,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? activeColor : Colors.white30),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? activeColor : Colors.white30,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Badge đếm lệnh
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.25)
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$commandCount/$maxCommands',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? activeColor : Colors.white30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nút lệnh đơn ──────────────────────────────────────────────────────────
class _CommandButton extends StatelessWidget {
  final _CmdDef def;
  final bool isDisabled;
  final bool isF1Tab;
  final VoidCallback onTap;

  const _CommandButton({
    required this.def,
    required this.isDisabled,
    required this.isF1Tab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 56) / 3;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width.clamp(80.0, 140.0),
        height: 44,
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    def.color.withValues(alpha: 0.12),
                    def.color.withValues(alpha: 0.04),
                  ],
                ),
          color: isDisabled ? const Color(0xFF1E293B) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? const Color(0xFF334155)
                : def.color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              def.icon,
              size: 18,
              color: isDisabled
                  ? const Color(0xFF334155)
                  : def.color,
            ),
            const SizedBox(width: 6),
            Text(
              def.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDisabled
                    ? const Color(0xFF475569)
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
