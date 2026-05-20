import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/employee.dart';
import '../models/planner_state.dart';
import '../models/task_item.dart';
import '../models/timeline_scale.dart';
import '../providers/planner_notifier.dart';
import '../utils/calendar_ranges.dart';
import '../utils/timeline_math.dart';
import '../utils/working_days.dart';
import 'gantt_row.dart';
import 'time_header.dart';

class GanttChart extends StatefulWidget {
  const GanttChart({
    super.key,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    required this.onTaskSelected,
  });

  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final ValueChanged<String> onTaskSelected;

  @override
  State<GanttChart> createState() => _GanttChartState();
}

class _RangeSelectMode {
  const _RangeSelectMode._(this.start, {this.employeeId});

  const _RangeSelectMode.holiday(DateTime start) : this._(start);

  const _RangeSelectMode.timeOff(String employeeId, DateTime start)
      : this._(start, employeeId: employeeId);

  final DateTime start;
  final String? employeeId;

  bool get isHoliday => employeeId == null;
}

class _GanttChartState extends State<GanttChart> {
  late final ScrollController _headerHorizontalController;
  bool _syncingScroll = false;
  DateTime? _anchoredTimelineStart;
  TimelineScale? _anchoredScale;
  _RangeSelectMode? _rangeSelect;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController = ScrollController();
    widget.horizontalScrollController.addListener(_syncHeaderScroll);
  }

  @override
  void dispose() {
    widget.horizontalScrollController.removeListener(_syncHeaderScroll);
    _headerHorizontalController.dispose();
    super.dispose();
  }

  void _clearRangeSelect() {
    if (_rangeSelect == null) return;
    setState(() => _rangeSelect = null);
  }

  void _syncHeaderScroll() {
    if (_syncingScroll || !_headerHorizontalController.hasClients) return;
    _syncingScroll = true;
    _headerHorizontalController.jumpTo(widget.horizontalScrollController.offset);
    _syncingScroll = false;
  }

  void _scrollToTimelineStart(PlannerState state) {
    final inset = state.timelineContentInset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final controller in [
        widget.horizontalScrollController,
        _headerHorizontalController,
      ]) {
        if (!controller.hasClients) continue;
        final max = controller.position.maxScrollExtent;
        controller.jumpTo(inset.clamp(0.0, max));
      }
    });
  }

  void _maybeAnchorScroll(PlannerState state) {
    final anchorChanged = _anchoredTimelineStart != state.timelineStart ||
        _anchoredScale != state.timelineScale;
    if (_anchoredTimelineStart == null || anchorChanged) {
      _anchoredTimelineStart = state.timelineStart;
      _anchoredScale = state.timelineScale;
      _scrollToTimelineStart(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerNotifier>(
      builder: (context, notifier, _) {
        final state = notifier.state;
        final width = state.timelineWidth;
        _maybeAnchorScroll(state);

        return Column(
          children: [
            SizedBox(
              height: kTimeHeaderHeight,
              child: SingleChildScrollView(
                controller: _headerHorizontalController,
                scrollDirection: Axis.horizontal,
                child: TimeHeader(
                  state: state,
                  width: width,
                  rangeSelectStart: _rangeSelect?.isHoliday == true
                      ? _rangeSelect!.start
                      : null,
                  onDayLongPress: (day) => _onHeaderDayLongPress(
                    context,
                    notifier,
                    day,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.verticalScrollController,
                child: SingleChildScrollView(
                  controller: widget.horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      children: state.employees.map((employee) {
                        final tasks =
                            notifier.scheduledTasksForEmployee(employee.id);
                        final selectingThis = _rangeSelect != null &&
                            !_rangeSelect!.isHoliday &&
                            _rangeSelect!.employeeId == employee.id;
                        return GanttRow(
                          employee: employee,
                          state: state,
                          tasks: tasks,
                          allTasks: notifier.allTasks,
                          rangeSelectStart:
                              selectingThis ? _rangeSelect!.start : null,
                          onBackgroundTap: (localX) => _onRowTap(
                            context,
                            notifier,
                            state,
                            employee.id,
                            localX,
                          ),
                          onBackgroundLongPress: (localX) =>
                              _onRowLongPress(
                            context,
                            notifier,
                            employee,
                            localX,
                          ),
                          onTaskTap: _onTaskTap,
                          onTaskDropped: (task, newEmpId, newStart) =>
                              notifier.moveTaskTo(
                            task,
                            newEmployeeId: newEmpId,
                            newStart: newStart,
                          ),
                        );
                      }).toList(),
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

  Future<void> _onRowTap(
    BuildContext context,
    PlannerNotifier notifier,
    PlannerState state,
    String employeeId,
    double localX,
  ) async {
    if (_rangeSelect != null) {
      _clearRangeSelect();
      _showCalendarSnack(context, 'Выбор диапазона отменён');
      return;
    }
    final start = timeAtOffset(state, localX);
    final duration = calendarDurationForTask(
      start: start,
      duration: Duration.zero,
      workingDays: 1,
      holidayRanges: state.holidayRanges,
      employeeId: employeeId,
      state: state,
    );
    final id = await notifier.addTask(
      employeeId: employeeId,
      title: 'Новая задача',
      start: start,
      duration: duration,
      workingDays: 1,
    );
    if (id != null && context.mounted) {
      widget.onTaskSelected(id);
    }
  }

  void _onTaskTap(TaskItem task) {
    widget.onTaskSelected(task.id);
  }

  Future<void> _onHeaderDayLongPress(
    BuildContext context,
    PlannerNotifier notifier,
    DateTime day,
  ) async {
    final calendarDay = dateOnly(day);
    if (isWeekend(calendarDay)) {
      _showCalendarSnack(
        context,
        'Суббота и воскресенье уже выходные',
      );
      return;
    }

    final pending = _rangeSelect;
    if (pending != null && pending.isHoliday) {
      final range = normalizeRange(pending.start, calendarDay);
      await notifier.addHolidayRange(range);
      _clearRangeSelect();
      if (!context.mounted) return;
      _showCalendarSnack(
        context,
        'Праздник: ${formatRangeRu(range)}',
      );
      return;
    }

    setState(() => _rangeSelect = _RangeSelectMode.holiday(calendarDay));
    _showRangeSelectSnack(
      context,
      'Удерживайте конечную дату праздника в шапке',
    );
  }

  Future<void> _onRowLongPress(
    BuildContext context,
    PlannerNotifier notifier,
    Employee employee,
    double localX,
  ) async {
    final state = notifier.state;
    final day = dateOnly(timeAtOffset(state, localX));
    if (isWeekend(day)) {
      _showCalendarSnack(context, 'Выходные дни задаются выходными');
      return;
    }
    if (isGlobalHoliday(day, state.holidayRanges)) {
      _showCalendarSnack(
        context,
        'Это праздник для всех — измените в шапке таймлайна',
      );
      return;
    }

    final pending = _rangeSelect;
    if (pending != null &&
        !pending.isHoliday &&
        pending.employeeId == employee.id) {
      final range = normalizeRange(pending.start, day);
      await notifier.addEmployeeTimeOffRange(employee.id, range);
      _clearRangeSelect();
      if (!context.mounted) return;
      _showCalendarSnack(
        context,
        'Отпуск ${employee.name}: ${formatRangeRu(range)}',
      );
      return;
    }

    setState(
      () => _rangeSelect = _RangeSelectMode.timeOff(employee.id, day),
    );
    _showRangeSelectSnack(
      context,
      'Удерживайте конечную дату отпуска для ${employee.name}',
    );
  }

  void _showRangeSelectSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Отмена',
          onPressed: _clearRangeSelect,
        ),
      ),
    );
  }

  void _showCalendarSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
