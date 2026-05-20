import '../constants.dart';
import '../models/planner_state.dart';
import '../models/task_item.dart';
import '../models/timeline_scale.dart';
import 'task_relations.dart';
import 'working_days.dart';

extension TimelineLayout on PlannerState {
  bool get isDaysScale => timelineScale == TimelineScale.days;

  int get visibleDayCount =>
      isDaysScale ? kVisibleDays : kVisibleHours ~/ 24;

  int get timelinePastHours {
    final base = isDaysScale ? kTimelinePastDays * 24 : kTimelinePastHours;
    var hoursBeforeStart = 0;
    for (final t in tasks) {
      if (!t.isOnTimeline) continue;
      if (t.start!.isBefore(timelineStart)) {
        final h = timelineStart.difference(t.start!).inHours;
        if (h > hoursBeforeStart) hoursBeforeStart = h;
      }
    }
    if (hoursBeforeStart == 0) return base;
    // Round up to whole days so day columns stay aligned.
    final needed = ((hoursBeforeStart + 23) ~/ 24) * 24;
    return needed > base ? needed : base;
  }

  int get timelinePastDayCount => timelinePastHours ~/ 24;

  int get totalDayCount => timelinePastDayCount + visibleDayCount;

  /// Left edge of the scrollable canvas (before [timelineStart]).
  DateTime get timelineEpoch =>
      timelineStart.subtract(Duration(hours: timelinePastHours));

  double get effectivePixelsPerHour => isDaysScale
      ? pixelsPerDay / 24.0
      : pixelsPerHour.toDouble();

  /// Horizontal offset where [timelineStart] sits on the canvas.
  double get timelineContentInset =>
      timelinePastHours * effectivePixelsPerHour;

  double get timelineWidth => timelineContentInset +
      (isDaysScale
          ? kVisibleDays * pixelsPerDay.toDouble()
          : kVisibleHours * pixelsPerHour.toDouble());

  double get dayWidth => 24 * effectivePixelsPerHour;

  bool get showHourGridLines => !isDaysScale;
}

double hoursFromTimelineStart(DateTime timelineStart, DateTime moment) {
  return moment.difference(timelineStart).inMinutes / 60.0;
}

double taskLeft(PlannerState state, DateTime taskStart) {
  return hoursFromTimelineStart(state.timelineEpoch, taskStart) *
      state.effectivePixelsPerHour;
}

double taskWidthFor(PlannerState state, TaskItem task) {
  assert(task.isOnTimeline);
  final duration = calendarDurationForTask(
    start: task.start!,
    duration: task.duration,
    workingDays: task.workingDays,
    holidayRanges: state.holidayRanges,
    employeeId: task.employeeId,
    state: state,
  );
  return duration.inMinutes / 60.0 * state.effectivePixelsPerHour;
}

DateTime timeAtOffset(PlannerState state, double offsetX) {
  final hours = offsetX / state.effectivePixelsPerHour;
  final minutes = (hours * 60).round();
  return state.timelineEpoch.add(Duration(minutes: minutes));
}

/// Wall-clock span shown on the chart (hours along the horizontal axis).
int visibleTimelineHours(PlannerState state) {
  return state.isDaysScale ? kVisibleDays * 24 : kVisibleHours;
}

DateTime clampTaskStart(
  PlannerState state,
  TaskItem task,
  DateTime proposed,
  List<TaskItem> allTasks,
) {
  final dur = calendarDurationForTask(
    start: proposed,
    duration: task.duration,
    workingDays: task.workingDays,
    holidayRanges: state.holidayRanges,
    employeeId: task.employeeId,
    state: state,
  );
  final timelineEnd =
      state.timelineStart.add(Duration(hours: visibleTimelineHours(state)));

  var start = proposed;

  final blockerMin = earliestStartAfterBlockers(task, allTasks, state: state);
  if (blockerMin != null && start.isBefore(blockerMin)) {
    start = blockerMin;
  }

  final timelineMin = state.timelineEpoch;
  if (start.isBefore(timelineMin)) {
    start = timelineMin;
  }

  var taskEnd = start.add(dur);
  if (taskEnd.isAfter(timelineEnd)) {
    start = timelineEnd.subtract(dur);
    if (blockerMin != null && start.isBefore(blockerMin)) {
      start = blockerMin;
    }
    if (start.isBefore(timelineMin)) {
      start = timelineMin;
    }
  }
  return start;
}
