import '../models/employee.dart';
import '../models/task_item.dart';
import 'duration_parse.dart';

String formatTaskSchedule(TaskItem task, List<Employee> employees) {
  if (!task.isOnTimeline) {
    final duration = formatTaskDurationLabel(task);
    if (task.isAssigned) {
      final matches = employees.where((e) => e.id == task.employeeId);
      final who = matches.isEmpty ? 'Сотрудник' : matches.first.name;
      if (duration.isNotEmpty && task.duration.inMinutes > 0) {
        return '$who · без даты · $duration';
      }
      return '$who · без даты на таймлайне';
    }
    if (duration.isNotEmpty && task.duration.inMinutes > 0) {
      return 'Не на таймлайне · $duration';
    }
    return 'Не на таймлайне';
  }

  final matches = employees.where((e) => e.id == task.employeeId);
  final who = matches.isEmpty ? 'Сотрудник' : matches.first.name;
  final start = task.start!;
  final date =
      '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}';
  final time =
      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

  if (task.usesWorkingDays) {
    return '$who · $date $time · ${task.workingDays} раб. дн.';
  }
  if (task.duration.inHours >= 24 && task.duration.inHours % 24 == 0) {
    return '$who · $date $time · ${task.duration.inHours ~/ 24} дн.';
  }
  if (task.duration.inHours > 0) {
    return '$who · $date $time · ${task.duration.inHours} ч';
  }
  return '$who · $date $time';
}

String formatTaskDurationLabel(TaskItem task) {
  if (task.usesWorkingDays) return '${task.workingDays} раб. дн.';
  if (task.duration.inHours >= 24 && task.duration.inHours % 24 == 0) {
    return '${task.duration.inHours ~/ 24} дн.';
  }
  return '${task.duration.inHours} ч';
}

String formatTaskTimeSummary(TaskItem task) {
  final parts = <String>[];
  if (task.estimateWorkingDays != null) {
    parts.add('оценка ${formatWorkingDays(task.estimateWorkingDays)}');
  }
  if (task.actualWorkingDays != null) {
    parts.add('факт ${formatWorkingDays(task.actualWorkingDays)}');
  }
  if (parts.isEmpty) return '';
  return parts.join(' · ');
}
