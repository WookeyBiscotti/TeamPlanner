import '../models/task_item.dart';

/// Payload while dragging a task between rows or along the timeline.
class TaskDragData {
  TaskDragData({required this.task, required this.grabOffsetX});

  final TaskItem task;
  /// X offset within the bar from the pointer (local coords at drag start).
  final double grabOffsetX;
}
