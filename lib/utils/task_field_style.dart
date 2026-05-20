import 'package:flutter/material.dart';

import '../models/task_status.dart';

/// Colored icons for task form fields and statuses.
abstract final class TaskFieldStyle {
  static const title = Icons.title;
  static const description = Icons.notes;
  static const status = Icons.flag_outlined;
  static const employee = Icons.person_outline;
  static const schedule = Icons.event;
  static const duration = Icons.timelapse;
  static const estimate = Icons.analytics_outlined;
  static const actual = Icons.timer_outlined;
  static const parent = Icons.folder_outlined;
  static const blockers = Icons.lock_outline;
  static const relations = Icons.account_tree_outlined;
  static const timeline = Icons.view_timeline;
  static const backlog = Icons.inbox_outlined;

  static Color titleColor(ColorScheme s) => s.primary;
  static Color descriptionColor(ColorScheme s) => s.onSurfaceVariant;
  static Color employeeColor(ColorScheme s) => s.secondary;
  static Color scheduleColor(ColorScheme s) => s.primary;
  static Color durationColor(ColorScheme s) => const Color(0xFFEF6C00);
  static Color estimateColor(ColorScheme s) => const Color(0xFF1565C0);
  static Color actualColor(ColorScheme s) => const Color(0xFF2E7D32);
  static Color parentColor(ColorScheme s) => const Color(0xFF6A1B9A);
  static Color blockersColor(ColorScheme s) => s.error;
  static Color relationsColor(ColorScheme s) => s.tertiary;
  static Color timelineColor(ColorScheme s) => s.primary;
  static Color backlogColor(ColorScheme s) => s.onSurfaceVariant;

  static Icon prefixIcon(
    IconData icon,
    Color color, {
    double size = 22,
  }) =>
      Icon(icon, color: color, size: size);

  static InputDecoration withPrefix({
    required InputDecoration decoration,
    required IconData icon,
    required Color color,
  }) =>
      decoration.copyWith(
        prefixIcon: prefixIcon(icon, color),
      );

  static Widget statusMenuItem(BuildContext context, TaskStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        prefixIcon(status.icon, status.color(scheme)),
        const SizedBox(width: 10),
        Text(status.label),
      ],
    );
  }

  static Widget sectionHeader(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        prefixIcon(icon, color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

extension TaskStatusStyle on TaskStatus {
  IconData get icon => switch (this) {
        TaskStatus.open => Icons.radio_button_unchecked,
        TaskStatus.active => Icons.play_circle_outline,
        TaskStatus.review => Icons.rate_review_outlined,
        TaskStatus.closed => Icons.check_circle,
      };

  Color color(ColorScheme scheme) => switch (this) {
        TaskStatus.open => scheme.onSurfaceVariant,
        TaskStatus.active => scheme.primary,
        TaskStatus.review => scheme.tertiary,
        TaskStatus.closed => scheme.secondary,
      };
}
