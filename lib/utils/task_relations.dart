import '../models/planner_state.dart';
import '../models/task_item.dart';
import 'timeline_layout.dart';
import 'working_days.dart';

class TaskTreeEntry {
  const TaskTreeEntry({required this.task, required this.depth});

  final TaskItem task;
  final int depth;
}

/// Parent row for the relations graph: [root] plus [children] inside a container.
class ParentGroupDisplay {
  const ParentGroupDisplay({required this.root, required this.children});

  final TaskItem root;
  final List<TaskItem> children;

  bool get isContainer => children.isNotEmpty;
}

class BlockerEdge {
  const BlockerEdge({required this.fromId, required this.toId});

  final String fromId;
  final String toId;
}

/// Roots (no parent in list) with their direct children for grouped UI.
List<ParentGroupDisplay> buildParentGroupDisplays(List<TaskItem> tasks) {
  if (tasks.isEmpty) return [];

  final ids = tasks.map((t) => t.id).toSet();
  final roots = tasks
      .where((t) => t.parentId == null || !ids.contains(t.parentId))
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));

  return roots.map((root) {
    final children = childrenOf(root.id, tasks)
      ..sort((a, b) => a.title.compareTo(b.title));
    return ParentGroupDisplay(root: root, children: children);
  }).toList();
}

List<BlockerEdge> buildBlockerEdges(List<TaskItem> tasks) {
  final edges = <BlockerEdge>[];
  for (final task in tasks) {
    for (final blockerId in task.blockedByIds) {
      if (tasks.any((t) => t.id == blockerId)) {
        edges.add(BlockerEdge(fromId: blockerId, toId: task.id));
      }
    }
  }
  return edges;
}

/// Hierarchical list: roots first, children indented by [depth].
List<TaskTreeEntry> buildTaskTree(List<TaskItem> tasks) {
  if (tasks.isEmpty) return [];

  final ids = tasks.map((t) => t.id).toSet();
  final byParent = <String?, List<TaskItem>>{};

  for (final task in tasks) {
    final key =
        task.parentId != null && ids.contains(task.parentId) ? task.parentId : null;
    byParent.putIfAbsent(key, () => []).add(task);
  }

  for (final group in byParent.values) {
    group.sort((a, b) => a.title.compareTo(b.title));
  }

  final result = <TaskTreeEntry>[];
  void visit(String? parentId, int depth) {
    for (final task in byParent[parentId] ?? const []) {
      result.add(TaskTreeEntry(task: task, depth: depth));
      visit(task.id, depth + 1);
    }
  }

  visit(null, 0);
  return result;
}

TaskItem? taskById(List<TaskItem> tasks, String id) {
  for (final t in tasks) {
    if (t.id == id) return t;
  }
  return null;
}

List<TaskItem> childrenOf(String parentId, List<TaskItem> tasks) {
  return tasks.where((t) => t.parentId == parentId).toList();
}

Set<String> descendantIds(String taskId, List<TaskItem> tasks) {
  final result = <String>{};
  void collect(String id) {
    for (final child in childrenOf(id, tasks)) {
      if (result.add(child.id)) collect(child.id);
    }
  }

  collect(taskId);
  return result;
}

bool wouldCreateParentCycle({
  required String taskId,
  required String newParentId,
  required List<TaskItem> tasks,
}) {
  if (taskId == newParentId) return true;
  if (descendantIds(taskId, tasks).contains(newParentId)) return true;
  return false;
}

bool wouldCreateBlockerCycle({
  required String taskId,
  required String blockerId,
  required List<TaskItem> tasks,
}) {
  if (taskId == blockerId) return true;
  // task cannot block itself; also no cycle: if blocker depends on task
  final blockersOfBlocker = _allBlockersTransitively(blockerId, tasks);
  return blockersOfBlocker.contains(taskId);
}

Set<String> _allBlockersTransitively(String taskId, List<TaskItem> tasks) {
  final seen = <String>{};
  final queue = <String>[taskId];
  while (queue.isNotEmpty) {
    final id = queue.removeAt(0);
    final task = taskById(tasks, id);
    if (task == null) continue;
    for (final bid in task.blockedByIds) {
      if (seen.add(bid)) queue.add(bid);
    }
  }
  seen.remove(taskId);
  return seen;
}

List<TaskItem> incompleteBlockers(TaskItem task, List<TaskItem> tasks) {
  return task.blockedByIds
      .map((id) => taskById(tasks, id))
      .whereType<TaskItem>()
      .where((t) => !t.isCompleted)
      .toList();
}

bool isBlockedByIncomplete(TaskItem task, List<TaskItem> tasks) {
  return incompleteBlockers(task, tasks).isNotEmpty;
}

List<TaskItem> tasksBlockedBy(String blockerId, List<TaskItem> tasks) {
  return tasks.where((t) => t.blockedByIds.contains(blockerId)).toList();
}

/// After [movedTaskId] shifts by [delta], shift all scheduled dependents (and their chains).
List<TaskItem> cascadeShiftBlockedTasks({
  required PlannerState state,
  required List<TaskItem> tasks,
  required String movedTaskId,
  required Duration delta,
}) {
  if (delta == Duration.zero) return tasks;

  var list = List<TaskItem>.from(tasks);
  var frontier = <String, Duration>{movedTaskId: delta};

  while (frontier.isNotEmpty) {
    final nextFrontier = <String, Duration>{};
    for (final entry in frontier.entries) {
      final blockerId = entry.key;
      final shift = entry.value;
      if (shift == Duration.zero) continue;

      for (final dependent in tasksBlockedBy(blockerId, list)) {
        if (!dependent.isOnTimeline) continue;

        final oldStart = dependent.start!;
        final proposed = oldStart.add(shift);
        final newStart = clampTaskStart(state, dependent, proposed, list);
        final applied = newStart.difference(oldStart);
        if (applied == Duration.zero) continue;

        list = list
            .map((t) => t.id == dependent.id ? t.copyWith(start: newStart) : t)
            .toList();
        nextFrontier[dependent.id] = applied;
      }
    }
    frontier = nextFrontier;
  }

  return list;
}

/// End of task on the timeline (start + calendar duration).
DateTime? taskScheduledEnd(TaskItem task, {PlannerState? state}) {
  if (!task.isOnTimeline) return null;
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

/// Earliest allowed [start] for [task]: not before the end of any scheduled blocker.
DateTime? earliestStartAfterBlockers(
  TaskItem task,
  List<TaskItem> allTasks, {
  PlannerState? state,
}) {
  DateTime? latestEnd;
  for (final blockerId in task.blockedByIds) {
    final blocker = taskById(allTasks, blockerId);
    if (blocker == null || !blocker.isOnTimeline) continue;
    final end = taskScheduledEnd(blocker, state: state);
    if (end == null) continue;
    if (latestEnd == null || end.isAfter(latestEnd)) {
      latestEnd = end;
    }
  }
  return latestEnd;
}

/// Scheduled blockers whose end is after [proposedStart].
List<TaskItem> blockersViolatingStart(
  TaskItem task,
  DateTime proposedStart,
  List<TaskItem> allTasks, {
  PlannerState? state,
}) {
  final min = earliestStartAfterBlockers(task, allTasks, state: state);
  if (min == null || !proposedStart.isBefore(min)) return [];
  return task.blockedByIds
      .map((id) => taskById(allTasks, id))
      .whereType<TaskItem>()
      .where((b) {
        final end = taskScheduledEnd(b, state: state);
        return end != null && end.isAfter(proposedStart);
      })
      .toList();
}
