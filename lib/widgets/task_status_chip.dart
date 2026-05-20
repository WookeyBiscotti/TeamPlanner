import 'package:flutter/material.dart';

import '../models/task_status.dart';
import '../utils/task_field_style.dart';

class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final TaskStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = status.color(scheme);
    final bg = _background(scheme, status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 12 : 14, color: fg),
          SizedBox(width: compact ? 4 : 6),
          Text(
            status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : null,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

Color _background(ColorScheme scheme, TaskStatus status) {
  return switch (status) {
    TaskStatus.open => scheme.surfaceContainerHighest,
    TaskStatus.active => scheme.primaryContainer,
    TaskStatus.review => scheme.tertiaryContainer,
    TaskStatus.closed => scheme.secondaryContainer,
  };
}
