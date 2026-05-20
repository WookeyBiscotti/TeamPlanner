import 'task_item.dart';

/// Task parsed from an import file, with optional source employee label for mapping.
class ParsedTaskImport {
  const ParsedTaskImport({
    required this.task,
    this.employeeName,
  });

  final TaskItem task;
  /// Name from [employeeName]/[assignee] or resolved via file [employees] list.
  final String? employeeName;
}
