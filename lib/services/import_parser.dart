import '../models/planner_state.dart';
import '../models/task_item.dart';

enum ImportKind { fullProject, mergeTasks }

class ImportParseResult {
  const ImportParseResult._({
    required this.kind,
    this.project,
    this.tasks,
  });

  final ImportKind kind;
  final PlannerState? project;
  final List<TaskItem>? tasks;

  factory ImportParseResult.fullProject(PlannerState state) =>
      ImportParseResult._(kind: ImportKind.fullProject, project: state);

  factory ImportParseResult.mergeTasks(List<TaskItem> tasks) =>
      ImportParseResult._(kind: ImportKind.mergeTasks, tasks: tasks);
}

ImportParseResult parseImportJson(dynamic decoded) {
  if (decoded is List) {
    return ImportParseResult.mergeTasks(parseTasksJsonList(decoded));
  }
  if (decoded is Map) {
    final map = Map<String, dynamic>.from(decoded);
    if (map.containsKey('timelineStart') || map.containsKey('employees')) {
      return ImportParseResult.fullProject(PlannerState.fromJson(map));
    }
    final tasksJson = map['tasks'];
    if (tasksJson is List) {
      return ImportParseResult.mergeTasks(parseTasksJsonList(tasksJson));
    }
  }
  throw const FormatException(
    'Ожидается JSON-массив задач или файл экспорта проекта',
  );
}

List<TaskItem> parseTasksJsonList(List<dynamic> list) {
  if (list.isEmpty) {
    throw const FormatException('Список задач пуст');
  }
  final tasks = <TaskItem>[];
  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    if (item is! Map) {
      throw FormatException('Элемент $i: ожидается объект задачи');
    }
    final map = Map<String, dynamic>.from(item);
    if (map['title'] == null || '$map[title]'.trim().isEmpty) {
      throw FormatException('Элемент $i: поле title обязательно');
    }
    if (map['id'] == null) {
      map['id'] = 'import-temp-$i';
    }
    tasks.add(TaskItem.fromJson(map));
  }
  return tasks;
}

/// Assigns new ids and rewires parent/blocker links within [imported].
List<TaskItem> prepareImportedTasks(
  List<TaskItem> imported,
  Set<String> validEmployeeIds,
  String Function() newId,
) {
  final idMap = <String, String>{
    for (final t in imported) t.id: newId(),
  };

  return [
    for (final task in imported)
      _normalizeEmployee(
        task.copyWith(
          id: idMap[task.id]!,
          parentId: task.parentId != null && idMap.containsKey(task.parentId)
              ? idMap[task.parentId]
              : null,
          clearParentId:
              task.parentId != null && !idMap.containsKey(task.parentId),
          blockedByIds: [
            for (final blockerId in task.blockedByIds)
              if (idMap.containsKey(blockerId)) idMap[blockerId]!,
          ],
        ),
        validEmployeeIds,
      ),
  ];
}

TaskItem _normalizeEmployee(TaskItem task, Set<String> validEmployeeIds) {
  if (task.employeeId != null &&
      !validEmployeeIds.contains(task.employeeId)) {
    return task.copyWith(clearEmployeeId: true, clearStart: true);
  }
  return task;
}
