import '../models/employee.dart';
import '../models/parsed_task_import.dart';
import '../models/planner_state.dart';
import '../models/task_item.dart';
import '../utils/task_colors.dart';

enum ImportKind { fullProject, mergeTasks }

class ImportParseResult {
  const ImportParseResult._({
    required this.kind,
    this.project,
    this.parsedTasks,
  });

  final ImportKind kind;
  final PlannerState? project;
  final List<ParsedTaskImport>? parsedTasks;

  factory ImportParseResult.fullProject(PlannerState state) =>
      ImportParseResult._(kind: ImportKind.fullProject, project: state);

  factory ImportParseResult.mergeTasks(List<ParsedTaskImport> tasks) =>
      ImportParseResult._(kind: ImportKind.mergeTasks, parsedTasks: tasks);
}

ImportParseResult parseImportJson(dynamic decoded) {
  if (decoded is List) {
    return ImportParseResult.mergeTasks(parseTasksJsonList(decoded));
  }
  if (decoded is Map) {
    final map = Map<String, dynamic>.from(decoded);
    if (map.containsKey('timelineStart')) {
      return ImportParseResult.fullProject(PlannerState.fromJson(map));
    }
    final tasksJson = map['tasks'];
    if (tasksJson is List) {
      return ImportParseResult.mergeTasks(
        parseTasksJsonList(
          tasksJson,
          fileEmployeeNames: _parseFileEmployees(map['employees']),
        ),
      );
    }
    if (map.containsKey('employees')) {
      return ImportParseResult.fullProject(PlannerState.fromJson(map));
    }
  }
  throw const FormatException(
    'Ожидается JSON-массив задач или файл экспорта проекта',
  );
}

Map<String, String>? _parseFileEmployees(dynamic employeesJson) {
  if (employeesJson is! List) return null;
  final map = <String, String>{};
  for (final item in employeesJson) {
    if (item is! Map) continue;
    final id = item['id'] as String?;
    final name = item['name'] as String?;
    if (id != null && name != null && name.trim().isNotEmpty) {
      map[id] = name.trim();
    }
  }
  return map.isEmpty ? null : map;
}

List<ParsedTaskImport> parseTasksJsonList(
  List<dynamic> list, {
  Map<String, String>? fileEmployeeNames,
}) {
  if (list.isEmpty) {
    throw const FormatException('Список задач пуст');
  }
  final tasks = <ParsedTaskImport>[];
  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    if (item is! Map) {
      throw FormatException('Элемент $i: ожидается объект задачи');
    }
    final map = Map<String, dynamic>.from(item);
    if (map['title'] == null || '${map['title']}'.trim().isEmpty) {
      throw FormatException('Элемент $i: поле title обязательно');
    }
    if (map['id'] == null) {
      map['id'] = 'import-temp-$i';
    }
    final employeeId = map['employeeId'] as String?;
    var sourceName = _readEmployeeName(map);
    if ((sourceName == null || sourceName.isEmpty) &&
        employeeId != null &&
        fileEmployeeNames != null) {
      sourceName = fileEmployeeNames[employeeId];
    }
    if ((sourceName == null || sourceName.isEmpty) &&
        employeeId != null &&
        (fileEmployeeNames == null ||
            !fileEmployeeNames.containsKey(employeeId))) {
      sourceName = employeeId;
    }
    tasks.add(
      ParsedTaskImport(
        task: TaskItem.fromJson(map),
        employeeName: sourceName?.trim().isEmpty ?? true
            ? null
            : sourceName?.trim(),
      ),
    );
  }
  return tasks;
}

String? _readEmployeeName(Map<String, dynamic> map) {
  for (final key in ['employeeName', 'employee', 'assignee', 'исполнитель']) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

/// Unique labels from the file that should be mapped to project employees.
List<String> collectImportEmployeeNames(
  List<ParsedTaskImport> imports,
  Set<String> projectEmployeeIds,
) {
  final names = <String>{};
  for (final entry in imports) {
    final key = mappingKeyFor(entry, projectEmployeeIds);
    if (key != null) names.add(key);
  }
  return names.toList()..sort();
}

String? mappingKeyFor(
  ParsedTaskImport entry,
  Set<String> projectEmployeeIds,
) {
  final task = entry.task;
  if (task.employeeId != null &&
      projectEmployeeIds.contains(task.employeeId) &&
      (entry.employeeName == null || entry.employeeName!.isEmpty)) {
    return null;
  }
  final name = entry.employeeName?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (task.employeeId != null && !projectEmployeeIds.contains(task.employeeId)) {
    return task.employeeId;
  }
  return null;
}

Map<String, String?> suggestEmployeeMapping(
  List<String> importNames,
  List<Employee> projectEmployees,
) {
  final result = <String, String?>{};
  for (final name in importNames) {
    final normalized = name.trim().toLowerCase();
    final matches = projectEmployees
        .where((e) => e.name.trim().toLowerCase() == normalized)
        .toList();
    result[name] = matches.length == 1 ? matches.first.id : null;
  }
  return result;
}

/// Uses [savedMapping] from the project, then falls back to name matching.
Map<String, String?> resolveEmployeeMappingForImport({
  required List<String> importNames,
  required Map<String, String?> savedMapping,
  required List<Employee> projectEmployees,
}) {
  final projectIds = projectEmployees.map((e) => e.id).toSet();
  final byName = suggestEmployeeMapping(importNames, projectEmployees);
  final result = <String, String?>{};
  for (final name in importNames) {
    if (savedMapping.containsKey(name)) {
      final saved = savedMapping[name];
      if (saved == null || projectIds.contains(saved)) {
        result[name] = saved;
        continue;
      }
    }
    result[name] = byName[name];
  }
  return result;
}

List<TaskItem> applyEmployeeNameMapping(
  List<ParsedTaskImport> imports,
  Map<String, String?> nameToEmployeeId,
  Set<String> projectEmployeeIds,
) {
  return [
    for (final entry in imports)
      _applyMapping(entry, nameToEmployeeId, projectEmployeeIds),
  ];
}

TaskItem _applyMapping(
  ParsedTaskImport entry,
  Map<String, String?> nameToEmployeeId,
  Set<String> projectEmployeeIds,
) {
  final key = mappingKeyFor(entry, projectEmployeeIds);
  if (key == null) {
    final id = entry.task.employeeId;
    if (id != null && projectEmployeeIds.contains(id)) {
      return entry.task.copyWith(color: colorForEmployee(id));
    }
    return entry.task;
  }
  final employeeId = nameToEmployeeId[key];
  if (employeeId == null) {
    return entry.task.copyWith(clearEmployeeId: true, clearStart: true);
  }
  return entry.task.copyWith(
    employeeId: employeeId,
    color: colorForEmployee(employeeId),
  );
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
