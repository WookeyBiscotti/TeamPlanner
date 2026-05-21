import 'task_item.dart';
import '../utils/task_schedule_fields.dart';

enum TaskEstimateFilter { estimated, notEstimated }

enum TaskScheduleFilter { scheduled, notScheduled }

/// Active filter chips for the task list (empty set = no constraint on that axis).
class TaskListFilters {
  const TaskListFilters({
    this.estimate = const {},
    this.schedule = const {},
  });

  final Set<TaskEstimateFilter> estimate;
  final Set<TaskScheduleFilter> schedule;

  static const empty = TaskListFilters();

  bool get isActive => estimate.isNotEmpty || schedule.isNotEmpty;

  TaskListFilters copyWith({
    Set<TaskEstimateFilter>? estimate,
    Set<TaskScheduleFilter>? schedule,
  }) {
    return TaskListFilters(
      estimate: estimate ?? this.estimate,
      schedule: schedule ?? this.schedule,
    );
  }

  TaskListFilters toggleEstimate(TaskEstimateFilter value) {
    final next = Set<TaskEstimateFilter>.from(estimate);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return copyWith(estimate: next);
  }

  TaskListFilters toggleSchedule(TaskScheduleFilter value) {
    final next = Set<TaskScheduleFilter>.from(schedule);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return copyWith(schedule: next);
  }
}

List<TaskItem> filterTasksForList(
  List<TaskItem> tasks,
  TaskListFilters filters,
) {
  if (!filters.isActive) return tasks;

  return tasks.where((task) {
    if (filters.estimate.isNotEmpty) {
      final estimated = taskHasPlannedEstimate(task);
      final matches = (estimated &&
              filters.estimate.contains(TaskEstimateFilter.estimated)) ||
          (!estimated &&
              filters.estimate.contains(TaskEstimateFilter.notEstimated));
      if (!matches) return false;
    }
    if (filters.schedule.isNotEmpty) {
      final matches = (task.isScheduled &&
              filters.schedule.contains(TaskScheduleFilter.scheduled)) ||
          (!task.isScheduled &&
              filters.schedule.contains(TaskScheduleFilter.notScheduled));
      if (!matches) return false;
    }
    return true;
  }).toList();
}
