import '../models/planner_state.dart';
import '../models/task_item.dart';
import '../models/task_list_filter.dart';
import 'task_colors.dart';
import 'task_relations.dart';
import 'timeline_layout.dart';
import 'working_days.dart';

class AutoScheduleResult {
  const AutoScheduleResult({
    required this.tasks,
    this.error,
    this.scheduledCount = 0,
    this.skippedCount = 0,
  });

  final List<TaskItem> tasks;
  final String? error;
  final int scheduledCount;
  final int skippedCount;

  bool get ok => error == null;
}

/// Places all non-completed estimated leaf tasks on the timeline, respecting
/// [blockedByIds] and each employee's calendar. Blockers must have an estimate.
AutoScheduleResult computeAutoSchedule(PlannerState state) {
  if (state.employees.isEmpty) {
    return AutoScheduleResult(
      tasks: state.tasks,
      error: 'Добавьте хотя бы одного сотрудника',
    );
  }

  final estimatedIds = state.tasks
      .where(
        (t) =>
            taskHasEstimate(t) &&
            !isEffectivelyCompleted(t, state.tasks) &&
            !hasTaskChildren(t.id, state.tasks),
      )
      .map((t) => t.id)
      .toSet();

  if (estimatedIds.isEmpty) {
    return AutoScheduleResult(
      tasks: state.tasks,
      skippedCount: state.tasks.length,
    );
  }

  final blockerError = _missingBlockerEstimateError(estimatedIds, state.tasks);
  if (blockerError != null) {
    return AutoScheduleResult(tasks: state.tasks, error: blockerError);
  }

  final order = _topologicalOrder(estimatedIds, state.tasks);
  if (order == null) {
    return AutoScheduleResult(
      tasks: state.tasks,
      error: 'Циклические зависимости блокеров — автопланирование невозможно',
    );
  }

  final employeeIds = state.employees.map((e) => e.id).toList();
  final planningStart = _planningEpochStart(state, employeeIds.first);
  final cursors = {for (final id in employeeIds) id: planningStart};

  var list = List<TaskItem>.from(state.tasks);
  var scheduledCount = 0;

  for (final id in order) {
    final index = list.indexWhere((t) => t.id == id);
    if (index < 0) continue;
    final task = list[index];

    final workingDays = task.estimateWorkingDays!;

    final employeeId = _resolveEmployeeId(
      task: task,
      employeeIds: employeeIds,
      cursors: cursors,
    );

    var proposed = cursors[employeeId]!;
    final blockerMin = earliestStartAfterBlockers(task, list, state: state);
    if (blockerMin != null && proposed.isBefore(blockerMin)) {
      proposed = blockerMin;
    }
    if (proposed.isBefore(planningStart)) {
      proposed = planningStart;
    }
    proposed = _alignToWorkCalendar(proposed, employeeId, state);

    var draft = task.copyWith(
      employeeId: employeeId,
      start: proposed,
      workingDays: workingDays,
      color: colorForEmployee(employeeId),
    );
    draft = draft.copyWith(
      duration: calendarDurationForTask(
        start: proposed,
        duration: draft.duration,
        workingDays: workingDays,
        holidayRanges: state.holidayRanges,
        employeeId: employeeId,
        state: state,
      ),
    );

    final clampedStart = clampTaskStart(state, draft, proposed, list);
    final duration = calendarDurationForTask(
      start: clampedStart,
      duration: draft.duration,
      workingDays: workingDays,
      holidayRanges: state.holidayRanges,
      employeeId: employeeId,
      state: state,
    );

    final scheduled = draft.copyWith(start: clampedStart, duration: duration);
    list[index] = scheduled;
    scheduledCount++;

    final end = taskScheduledEnd(scheduled, state: state);
    if (end != null) {
      cursors[employeeId] = _alignToWorkCalendar(end, employeeId, state);
    }
  }

  final skippedCount = state.tasks.length - scheduledCount;

  return AutoScheduleResult(
    tasks: list,
    scheduledCount: scheduledCount,
    skippedCount: skippedCount,
  );
}

/// Error text when an estimated task waits on an incomplete blocker without estimate.
String? _missingBlockerEstimateError(Set<String> estimatedIds, List<TaskItem> tasks) {
  final lines = <String>[];

  for (final id in estimatedIds) {
    final task = taskById(tasks, id);
    if (task == null) continue;
    for (final blockerId in task.blockedByIds) {
      final blocker = taskById(tasks, blockerId);
      if (blocker == null || isEffectivelyCompleted(blocker, tasks)) continue;
      if (!taskHasEstimate(blocker)) {
        lines.add('«${task.title}» — блокер «${blocker.title}» без оценки');
      }
    }
  }

  if (lines.isEmpty) return null;
  lines.sort();
  if (lines.length == 1) {
    return 'Нельзя спланировать: ${lines.single}';
  }
  return 'Нельзя спланировать:\n${lines.map((l) => '• $l').join('\n')}';
}

/// Returns task ids in blocker-before-dependent order, or null if a cycle exists.
List<String>? _topologicalOrder(Set<String> ids, List<TaskItem> tasks) {
  final inDegree = {for (final id in ids) id: 0};
  final dependents = {for (final id in ids) id: <String>[]};

  for (final task in tasks) {
    if (!ids.contains(task.id)) continue;
    for (final blockerId in task.blockedByIds) {
      if (!ids.contains(blockerId)) continue;
      dependents[blockerId]!.add(task.id);
      inDegree[task.id] = inDegree[task.id]! + 1;
    }
  }

  final queue = inDegree.entries
      .where((e) => e.value == 0)
      .map((e) => e.key)
      .toList()
    ..sort();
  final order = <String>[];

  while (queue.isNotEmpty) {
    final id = queue.removeAt(0);
    order.add(id);
    for (final dependentId in dependents[id]!) {
      final next = inDegree[dependentId]! - 1;
      inDegree[dependentId] = next;
      if (next == 0) {
        queue.add(dependentId);
        queue.sort();
      }
    }
  }

  if (order.length != ids.length) return null;
  return order;
}

DateTime _planningEpochStart(PlannerState state, String employeeId) {
  return _alignToWorkCalendar(
    state.timelineStart.add(const Duration(hours: 9)),
    employeeId,
    state,
  );
}

DateTime _alignToWorkCalendar(
  DateTime moment,
  String employeeId,
  PlannerState state,
) {
  var m = moment;
  while (isNonWorkingDay(
    dateOnly(m),
    holidayRanges: state.holidayRanges,
    employeeId: employeeId,
    state: state,
  )) {
    m = dateOnly(m).add(const Duration(days: 1)).add(const Duration(hours: 9));
  }
  final dayStart = dateOnly(m).add(const Duration(hours: 9));
  if (m.isBefore(dayStart)) return dayStart;
  return m;
}

String _resolveEmployeeId({
  required TaskItem task,
  required List<String> employeeIds,
  required Map<String, DateTime> cursors,
}) {
  final assigned = task.employeeId;
  if (assigned != null && employeeIds.contains(assigned)) {
    return assigned;
  }
  return cursors.entries
      .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
      .key;
}
