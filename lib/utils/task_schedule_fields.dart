import '../models/planner_state.dart';
import '../models/task_item.dart';
import 'working_days.dart';

enum DurationUnit { hours, days }

/// Parsed schedule fields from the task detail form.
class TaskScheduleFields {
  const TaskScheduleFields({
    required this.onTimeline,
    this.employeeId,
    this.start,
    this.duration,
    this.workingDays,
    this.clearWorkingDays = false,
  });

  final bool onTimeline;
  final String? employeeId;
  final DateTime? start;
  final Duration? duration;
  final int? workingDays;
  final bool clearWorkingDays;
}

DurationUnit durationUnitForTask(TaskItem task) {
  if (task.usesWorkingDays) return DurationUnit.days;
  if (task.duration.inHours >= 24 && task.duration.inHours % 24 == 0) {
    return DurationUnit.days;
  }
  if (task.duration.inHours > 0 && task.duration.inHours < 24) {
    return DurationUnit.hours;
  }
  return DurationUnit.days;
}

bool _hasPositiveDays(int? days) => days != null && days > 0;

/// Recorded estimate/actual effort or timeline working-days bar (list filters).
bool taskHasLaborData(TaskItem task) =>
    _hasPositiveDays(task.estimateWorkingDays) ||
    _hasPositiveDays(task.actualWorkingDays) ||
    _hasPositiveDays(task.workingDays);

/// Effort amount for timeline scheduling: actual, then estimate, then legacy [workingDays].
int effortAmountForTask(TaskItem task, DurationUnit unit) {
  if (unit == DurationUnit.days) {
    return task.actualWorkingDays ??
        task.estimateWorkingDays ??
        (task.usesWorkingDays ? task.workingDays! : null) ??
        1;
  }
  return task.duration.inHours > 0 ? task.duration.inHours : 4;
}

TaskScheduleFields buildScheduleFields({
  required TaskItem task,
  required bool onTimeline,
  required String? employeeId,
  required DateTime start,
  required DurationUnit unit,
  required int amount,
  PlannerState? state,
}) {
  if (!onTimeline) {
    return const TaskScheduleFields(onTimeline: false);
  }

  if (unit == DurationUnit.days) {
    final workingDays = amount;
    final duration = calendarDurationForTask(
      start: start,
      duration: Duration.zero,
      workingDays: workingDays,
      holidayRanges: state?.holidayRanges ?? const [],
      employeeId: employeeId,
      state: state,
    );
    return TaskScheduleFields(
      onTimeline: true,
      employeeId: employeeId,
      start: start,
      duration: duration,
      workingDays: workingDays,
    );
  }

  return TaskScheduleFields(
    onTimeline: true,
    employeeId: employeeId,
    start: start,
    duration: Duration(hours: amount),
    clearWorkingDays: true,
  );
}

String formatDateTime(DateTime dt) {
  final d = '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  final t =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  return '$d $t';
}
