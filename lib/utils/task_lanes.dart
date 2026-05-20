import '../models/planner_state.dart';
import '../models/task_item.dart';
import 'working_days.dart';

/// Tracks which vertical lane each task sits in when intervals overlap on the timeline.
class TaskLaneLayout {
  TaskLaneLayout._({
    required this.laneCount,
    required this.taskIdToLane,
  });

  final int laneCount;
  final Map<String, int> taskIdToLane;

  int laneFor(String taskId) => taskIdToLane[taskId] ?? 0;

  static TaskLaneLayout compute(List<TaskItem> tasks, {PlannerState? state}) {
    if (tasks.isEmpty) {
      return TaskLaneLayout._(laneCount: 0, taskIdToLane: {});
    }

    final sorted = List<TaskItem>.from(tasks)
      ..sort((a, b) {
        final c = a.start!.compareTo(b.start!);
        if (c != 0) return c;
        return _taskEnd(b).compareTo(_taskEnd(a));
      });

    final laneEnds = <DateTime>[];
    final idToLane = <String, int>{};

    for (final task in sorted) {
      final end = _taskEnd(task, state: state);
      var placed = false;
      for (var i = 0; i < laneEnds.length; i++) {
        if (!task.start!.isBefore(laneEnds[i])) {
          laneEnds[i] = end;
          idToLane[task.id] = i;
          placed = true;
          break;
        }
      }
      if (!placed) {
        idToLane[task.id] = laneEnds.length;
        laneEnds.add(end);
      }
    }

    return TaskLaneLayout._(
      laneCount: laneEnds.length,
      taskIdToLane: idToLane,
    );
  }

  static DateTime _taskEnd(TaskItem task, {PlannerState? state}) {
    final start = task.start!;
    return start.add(
      calendarDurationForTask(
        start: start,
        duration: task.duration,
        workingDays: task.workingDays,
        holidayRanges: state?.holidayRanges ?? const [],
        employeeId: task.employeeId,
        state: state,
      ),
    );
  }
}
