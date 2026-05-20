import 'package:flutter/material.dart';
import 'package:patterns_canvas/patterns_canvas.dart';

import '../models/task_fill_pattern.dart';
import '../models/task_item.dart';
import 'task_colors.dart';

Color resolveTaskColor(TaskItem task, ColorScheme scheme) {
  if (task.color != null) return task.color!;
  final empId = task.employeeId;
  if (empId != null) return colorForEmployee(empId);
  return scheme.secondary;
}

Color patternForegroundFor(Color base) {
  return base.computeLuminance() > 0.5
      ? Color.lerp(base, Colors.black, 0.45)!
      : Color.lerp(base, Colors.white, 0.38)!;
}

Pattern? patternForTask(TaskItem task, Color background) {
  final fill = TaskFillPattern.fromKey(task.fillPattern);
  if (fill == null) return null;
  return Pattern.fromValues(
    patternType: fill.patternType,
    bgColor: background,
    fgColor: patternForegroundFor(background),
  );
}

Color faceColorForTask({
  required TaskItem task,
  required Color base,
  required bool isBlocked,
}) {
  if (task.isCompleted) return base.withValues(alpha: 0.45);
  if (isBlocked) return base.withValues(alpha: 0.55);
  return base;
}

Color onTaskBarText(Color base) => Color.lerp(base, Colors.white, 0.92)!;
