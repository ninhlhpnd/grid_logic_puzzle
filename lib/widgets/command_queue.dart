import 'package:flutter/material.dart';
import '../engine/game_engine.dart';
import '../models/enums.dart';

// ─── Helper lấy icon / màu lệnh (public để reuse) ───────────────────────────
IconData getIconForCommand(CommandType cmd) {
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

Color getColorForCommand(CommandType cmd) {
  switch (cmd) {
    case CommandType.moveForward:
      return const Color(0xFF4ADE80);
    case CommandType.turnLeft:
      return const Color(0xFF38BDF8);
    case CommandType.turnRight:
      return const Color(0xFFA78BFA);
    case CommandType.collectEnergy:
      return const Color(0xFFFBBF24);
    case CommandType.jump:
      return const Color(0xFFF472B6);
    case CommandType.callFunction1:
      return const Color(0xFFFB923C);
  }
}

/// CommandQueue: Hiển thị **hai vùng** lệnh song song:
///   - **Main Routine** (màu indigo): danh sách lệnh chính
///   - **Function F1**  (màu cam):    danh sách hàm con F1
///
/// Mỗi vùng hỗ trợ 2 chế độ hiển thị qua nút toggle:
///   - Expanded (Wrap nhiều dòng) — mặc định
///   - Compact  (cuộn ngang)
class CommandQueue extends StatefulWidget {
  final GameEngine engine;

  const CommandQueue({super.key, required this.engine});

  @override
  State<CommandQueue> createState() => _CommandQueueState();
}

class _CommandQueueState extends State<CommandQueue> {
  bool _mainExpanded = true;
  bool _f1Expanded = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Main Routine ──────────────────────────────────────────────
            _QueueSection(
              title: 'Main Routine',
              icon: Icons.code_rounded,
              accentColor: const Color(0xFF6366F1),
              accentBg: const Color(0xFF1E1B4B),
              borderColor: const Color(0xFF3730A3),
              commands: widget.engine.commandList,
              maxCommands: widget.engine.currentLevel.maxCommandsAllowed,
              activeIndex: widget.engine.currentCommandIndex,
              isExecuting: widget.engine.isExecuting,
              isExpanded: _mainExpanded,
              emptyHint: 'Chương trình chính trống. Thêm lệnh từ bảng bên dưới!',
              onToggleExpand: () =>
                  setState(() => _mainExpanded = !_mainExpanded),
              onRemove: widget.engine.removeCommandAt,
              onClear: widget.engine.clearCommands,
            ),

            const SizedBox(height: 6),

            // ── Function F1 ───────────────────────────────────────────────
            _QueueSection(
              title: 'Function F1',
              icon: Icons.functions_rounded,
              accentColor: const Color(0xFFFB923C),
              accentBg: const Color(0xFF431407),
              borderColor: const Color(0xFF92400E),
              commands: widget.engine.function1List,
              maxCommands: widget.engine.currentLevel.maxFunction1Commands,
              activeIndex: widget.engine.currentF1CommandIndex,
              isExecuting: widget.engine.isExecuting,
              isExpanded: _f1Expanded,
              emptyHint: 'Hàm F1 trống. Chuyển sang tab F1 để thêm lệnh!',
              onToggleExpand: () =>
                  setState(() => _f1Expanded = !_f1Expanded),
              onRemove: widget.engine.removeFunction1At,
              onClear: widget.engine.clearFunction1,
            ),
          ],
        );
      },
    );
  }
}

// ─── Section hiển thị 1 queue ────────────────────────────────────────────────
class _QueueSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Color accentBg;
  final Color borderColor;
  final List<CommandType> commands;
  final int maxCommands;
  final int? activeIndex;
  final bool isExecuting;
  final bool isExpanded;
  final String emptyHint;
  final VoidCallback onToggleExpand;
  final void Function(int) onRemove;
  final VoidCallback onClear;

  const _QueueSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.accentBg,
    required this.borderColor,
    required this.commands,
    required this.maxCommands,
    required this.activeIndex,
    required this.isExecuting,
    required this.isExpanded,
    required this.emptyHint,
    required this.onToggleExpand,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final int count = commands.length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentBg.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Icon + Title
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                // Badge đếm lệnh
                _CountBadge(
                  count: count,
                  max: maxCommands,
                  color: accentColor,
                ),
                const Spacer(),
                // Nút Expand/Compact
                _IconBtn(
                  icon: isExpanded
                      ? Icons.grid_view_rounded
                      : Icons.view_stream_rounded,
                  color: accentColor.withValues(alpha: 0.7),
                  tooltip: isExpanded ? 'Thu gọn' : 'Mở rộng',
                  onTap: onToggleExpand,
                ),
                // Nút Xóa hết (chỉ hiện khi có lệnh và không executing)
                if (count > 0 && !isExecuting) ...[
                  const SizedBox(width: 4),
                  _IconBtn(
                    icon: Icons.delete_sweep_rounded,
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    tooltip: 'Xóa hết',
                    onTap: onClear,
                  ),
                ],
              ],
            ),
          ),

          // ── Nội dung danh sách ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: count == 0
                ? _EmptyHint(hint: emptyHint, color: accentColor)
                : isExpanded
                    ? _ExpandedWrap(
                        commands: commands,
                        activeIndex: activeIndex,
                        canDelete: !isExecuting,
                        onRemove: onRemove,
                        accentColor: accentColor,
                      )
                    : _HorizontalScroll(
                        commands: commands,
                        activeIndex: activeIndex,
                        canDelete: !isExecuting,
                        onRemove: onRemove,
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge đếm ───────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  final int max;
  final Color color;

  const _CountBadge({
    required this.count,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool nearFull = count >= max * 0.8;
    final badgeColor = nearFull ? Colors.redAccent : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        '$count / $max',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }
}

// ─── Icon button nhỏ ─────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ─── Placeholder trống ───────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String hint;
  final Color color;

  const _EmptyHint({required this.hint, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 16,
              color: color.withValues(alpha: 0.3)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chế độ Wrap (nhiều dòng) ────────────────────────────────────────────────
class _ExpandedWrap extends StatelessWidget {
  final List<CommandType> commands;
  final int? activeIndex;
  final bool canDelete;
  final void Function(int) onRemove;
  final Color accentColor;

  const _ExpandedWrap({
    required this.commands,
    required this.activeIndex,
    required this.canDelete,
    required this.onRemove,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 150),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(commands.length, (i) {
            return _CommandChip(
              index: i,
              cmd: commands[i],
              isActive: activeIndex == i,
              canDelete: canDelete,
              onTap: canDelete ? () => onRemove(i) : null,
            );
          }),
        ),
      ),
    );
  }
}

// ─── Chế độ cuộn ngang ───────────────────────────────────────────────────────
class _HorizontalScroll extends StatelessWidget {
  final List<CommandType> commands;
  final int? activeIndex;
  final bool canDelete;
  final void Function(int) onRemove;

  const _HorizontalScroll({
    required this.commands,
    required this.activeIndex,
    required this.canDelete,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: commands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          return _CommandChipVertical(
            index: i,
            cmd: commands[i],
            isActive: activeIndex == i,
            canDelete: canDelete,
            onTap: canDelete ? () => onRemove(i) : null,
          );
        },
      ),
    );
  }
}

// ─── Chip lệnh ngang (Expanded Wrap) ─────────────────────────────────────────
class _CommandChip extends StatelessWidget {
  final int index;
  final CommandType cmd;
  final bool isActive;
  final bool canDelete;
  final VoidCallback? onTap;

  const _CommandChip({
    required this.index,
    required this.cmd,
    required this.isActive,
    required this.canDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = getIconForCommand(cmd);
    final color = getColorForCommand(cmd);

    return Tooltip(
      message: canDelete ? 'Bấm để xóa lệnh #${index + 1}' : cmd.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(colors: [
                    const Color(0xFF4338CA),
                    const Color(0xFF3730A3),
                  ])
                : LinearGradient(colors: [
                    color.withValues(alpha: 0.12),
                    color.withValues(alpha: 0.04),
                  ]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? const Color(0xFF818CF8) : color.withValues(alpha: 0.4),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white70 : Colors.white38,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon,
                  size: 14, color: isActive ? Colors.white : color),
              const SizedBox(width: 4),
              Text(
                cmd.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xDEFFFFFF),
                ),
              ),
              if (canDelete) ...[
                const SizedBox(width: 4),
                Icon(Icons.close_rounded,
                    size: 11,
                    color: isActive
                        ? Colors.white54
                        : Colors.white24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chip lệnh dọc (Horizontal scroll) ───────────────────────────────────────
class _CommandChipVertical extends StatelessWidget {
  final int index;
  final CommandType cmd;
  final bool isActive;
  final bool canDelete;
  final VoidCallback? onTap;

  const _CommandChipVertical({
    required this.index,
    required this.cmd,
    required this.isActive,
    required this.canDelete,
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
        width: 52,
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4338CA), Color(0xFF3730A3)],
                )
              : LinearGradient(colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.04),
                ]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF818CF8) : color.withValues(alpha: 0.4),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.6),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '#${index + 1}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white70 : Colors.white38,
              ),
            ),
            const SizedBox(height: 2),
            Icon(icon,
                size: 18, color: isActive ? Colors.white : color),
            const SizedBox(height: 2),
            Text(
              cmd.label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xDEFFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}
