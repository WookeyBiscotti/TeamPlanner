import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/employee.dart';
import '../models/planner_state.dart';
import '../models/task_item.dart';
import '../utils/task_lanes.dart';
import '../utils/task_relations.dart';
import '../utils/timeline_layout.dart';
import 'task_bar.dart';
import 'task_drag_data.dart';
import 'range_select_marker.dart';
import 'weekend_background.dart';

class GanttRow extends StatefulWidget {
  const GanttRow({
    super.key,
    required this.employee,
    required this.state,
    required this.tasks,
    required this.allTasks,
    required this.onBackgroundTap,
    this.onBackgroundLongPress,
    this.rangeSelectStart,
    required this.onTaskTap,
    required this.onTaskDropped,
  });

  final Employee employee;
  final PlannerState state;
  final List<TaskItem> tasks;
  final List<TaskItem> allTasks;
  final void Function(double localX) onBackgroundTap;
  final void Function(double localX)? onBackgroundLongPress;
  final DateTime? rangeSelectStart;
  final void Function(TaskItem task) onTaskTap;
  final void Function(TaskItem task, String newEmployeeId, DateTime newStart)
      onTaskDropped;

  @override
  State<GanttRow> createState() => _GanttRowState();
}

class _GanttRowState extends State<GanttRow> {
  final GlobalKey _rowContentKey = GlobalKey();

  void _handleAccept(DragTargetDetails<TaskDragData> details) {
    final box =
        _rowContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final local = box.globalToLocal(details.offset);
    final barLeftX = local.dx - details.data.grabOffsetX;
    final rawStart = timeAtOffset(widget.state, barLeftX);
    final newStart = clampTaskStart(
      widget.state,
      details.data.task,
      rawStart,
      widget.allTasks,
    );
    widget.onTaskDropped(
      details.data.task,
      widget.employee.id,
      newStart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = widget.state.timelineWidth;
    final lanes = TaskLaneLayout.compute(widget.tasks, state: widget.state);
    final rowHeight = employeeGanttRowHeight(lanes.laneCount);

    return SizedBox(
      height: rowHeight,
      width: width,
      child: DragTarget<TaskDragData>(
        hitTestBehavior: HitTestBehavior.opaque,
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: _handleAccept,
        builder: (context, candidateData, rejectedData) {
          final highlighted = candidateData.isNotEmpty;

          return DecoratedBox(
            decoration: BoxDecoration(
              color: highlighted
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                  : null,
            ),
            child: SizedBox(
              key: _rowContentKey,
              height: rowHeight,
              width: width,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Not onTapDown: it fires immediately on pointer down while long-press
                // drag is still ambiguous, opening "new task" over task bars on hold.
                onTapUp: (details) =>
                    widget.onBackgroundTap(details.localPosition.dx),
                onLongPressStart: widget.onBackgroundLongPress == null
                    ? null
                    : (details) => widget.onBackgroundLongPress!(
                          details.localPosition.dx,
                        ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NonWorkingDayBackground(
                      state: widget.state,
                      width: width,
                      height: rowHeight,
                      employeeId: widget.employee.id,
                    ),
                    if (widget.rangeSelectStart != null)
                      RangeSelectMarker(
                        state: widget.state,
                        anchor: widget.rangeSelectStart!,
                        width: width,
                        height: rowHeight,
                      ),
                    CustomPaint(
                      size: Size(width, rowHeight),
                      painter: _GridPainter(
                        state: widget.state,
                        lineColor:
                            theme.dividerColor.withValues(alpha: 0.6),
                        dayLineColor: theme.dividerColor,
                      ),
                    ),
                    ...widget.tasks.map((task) {
                      final lane = lanes.laneFor(task.id);
                      return TaskBar(
                        task: task,
                        left: taskLeft(widget.state, task.start!),
                        top: laneTopOffset(lane),
                        width: taskWidthFor(widget.state, task),
                        height: kLaneBarHeight,
                        isBlocked: isBlockedByIncomplete(task, widget.allTasks),
                        isEffectivelyCompleted: isEffectivelyCompleted(
                          task,
                          widget.allTasks,
                        ),
                        onTap: () => widget.onTaskTap(task),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.state,
    required this.lineColor,
    required this.dayLineColor,
  });

  final PlannerState state;
  final Color lineColor;
  final Color dayLineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final hourPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final dayPaint = Paint()
      ..color = dayLineColor
      ..strokeWidth = 1;

    final pph = state.effectivePixelsPerHour;
    final days = state.totalDayCount;
    final totalHours = state.timelinePastHours + kVisibleHours;

    if (state.showHourGridLines) {
      for (var h = 0; h <= totalHours; h++) {
        final x = h * pph;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), hourPaint);
      }
    }

    for (var d = 0; d <= days; d++) {
      final x = d * state.dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), dayPaint);
    }

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      dayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.state.timelineScale != state.timelineScale ||
        oldDelegate.state.pixelsPerHour != state.pixelsPerHour ||
        oldDelegate.state.pixelsPerDay != state.pixelsPerDay;
  }
}
