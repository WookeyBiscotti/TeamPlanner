import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../utils/task_appearance.dart';
import 'task_bar_fill_painter.dart';
import 'task_drag_data.dart';

/// Blocks opening the edit dialog briefly after drag-related gestures complete.
class _TapAfterDragGuard {
  DateTime allowTapAfter = DateTime.fromMillisecondsSinceEpoch(0);

  void suppressTapFor(Duration duration) {
    allowTapAfter = DateTime.now().add(duration);
  }

  bool get mayTap => !DateTime.now().isBefore(allowTapAfter);
}

class TaskBar extends StatefulWidget {
  const TaskBar({
    super.key,
    required this.task,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.onTap,
    this.isBlocked = false,
    this.isEffectivelyCompleted = false,
  });

  final TaskItem task;
  final double left;
  final double top;
  final double width;
  final double height;
  final VoidCallback onTap;
  final bool isBlocked;
  final bool isEffectivelyCompleted;

  @override
  State<TaskBar> createState() => _TaskBarState();
}

class _TaskBarState extends State<TaskBar> {
  double _grabOffsetX = 0;

  /// Single guard instance reused across gesture callbacks (no setState needed).
  final _tapGuard = _TapAfterDragGuard();

  static const _suppressAfterDrag = Duration(milliseconds: 450);
  /// Slightly shorter than Material default so drag wins before stray taps on web.
  static const _longPressDelay = Duration(milliseconds: 340);

  void _scheduleSuppressTap([Duration duration = _suppressAfterDrag]) {
    _tapGuard.suppressTapFor(duration);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = resolveTaskColor(widget.task, theme.colorScheme);
    final onBar = onTaskBarText(base);
    final displayWidth = widget.width < 4 ? 4.0 : widget.width;

    Widget barFace({required bool draggingGhost}) {
      final faceColor = faceColorForTask(
        isEffectivelyCompleted: widget.isEffectivelyCompleted,
        base: base,
        isBlocked: widget.isBlocked,
      );
      final pattern = patternForTask(widget.task, faceColor);
      final content = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: widget.isBlocked && !widget.isEffectivelyCompleted
              ? Border.all(color: onBar.withValues(alpha: 0.85), width: 1.5)
              : null,
          boxShadow: draggingGhost
              ? []
              : [
                  BoxShadow(
                    color: base.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CustomPaint(
            painter: TaskBarFillPainter(
              color: faceColor,
              pattern: pattern,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (widget.isBlocked && !widget.isEffectivelyCompleted) ...[
                    Icon(Icons.lock_outline, size: 12, color: onBar),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      widget.task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onBar,
                        fontSize: widget.height >= 26 ? 12 : 10,
                        fontWeight: FontWeight.w500,
                        decoration: widget.isEffectivelyCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          /// Single tap — only quick taps; never fire right after drag / long press.
          onTap: () {
            if (!_tapGuard.mayTap) return;
            widget.onTap();
          },
          child: content,
        ),
      );
    }

    final barChild = barFace(draggingGhost: false);

    return Positioned(
      left: widget.left,
      top: widget.top,
      width: displayWidth,
      height: widget.height,
      child: Listener(
        onPointerDown: (e) {
          final x = e.localPosition.dx.clamp(0.0, displayWidth);
          if (x != _grabOffsetX) {
            setState(() => _grabOffsetX = x);
          }
        },
        child: LongPressDraggable<TaskDragData>(
          delay: _longPressDelay,
          data: TaskDragData(
            task: widget.task,
            grabOffsetX: _grabOffsetX,
          ),
          dragAnchorStrategy: pointerDragAnchorStrategy,
          maxSimultaneousDrags: 1,
          onDragStarted: () => _scheduleSuppressTap(_suppressAfterDrag),
          onDragEnd: (_) => _scheduleSuppressTap(_suppressAfterDrag),
          onDraggableCanceled: (_, _) =>
              _scheduleSuppressTap(_suppressAfterDrag),
          feedback: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(6),
            child: Opacity(
              opacity: 0.92,
              child: SizedBox(
                width: displayWidth,
                height: widget.height,
                child: barFace(draggingGhost: true),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.22,
            child: barChild,
          ),
          child: barChild,
        ),
      ),
    );
  }
}
