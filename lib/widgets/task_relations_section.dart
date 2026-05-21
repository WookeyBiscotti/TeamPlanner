import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_item.dart';
import '../models/task_status.dart';
import '../providers/planner_notifier.dart';
import '../utils/task_field_style.dart';
import '../utils/task_relations.dart';

/// Parent / blocker links editor for the task detail pane.
class TaskRelationsSection extends StatelessWidget {
  const TaskRelationsSection({
    super.key,
    required this.task,
    this.onSelectTask,
  });

  final TaskItem task;
  final void Function(String taskId)? onSelectTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = context.watch<PlannerNotifier>();
    final all = notifier.allTasks;
    final current = taskById(all, task.id) ?? task;
    final blockers = incompleteBlockers(current, all);
    final children = childrenOf(current.id, all);
    final parent = current.parentId != null
        ? taskById(all, current.parentId!)
        : null;

    final parentCandidates = all
        .where((t) =>
            t.id != current.id &&
            !wouldCreateParentCycle(
              taskId: current.id,
              newParentId: t.id,
              tasks: all,
            ))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    final blockerCandidates = all
        .where((t) =>
            t.id != current.id &&
            !wouldCreateBlockerCycle(
              taskId: current.id,
              blockerId: t.id,
              tasks: all,
            ))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskFieldStyle.sectionHeader(
          context,
          icon: TaskFieldStyle.relations,
          color: TaskFieldStyle.relationsColor(theme.colorScheme),
          title: 'Связи',
        ),
        if (blockers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      TaskFieldStyle.blockers,
                      size: 18,
                      color: TaskFieldStyle.blockersColor(theme.colorScheme),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Заблокирована: ${blockers.map((t) => t.title).join(', ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: current.parentId != null &&
                  all.any((t) => t.id == current.parentId)
              ? current.parentId
              : null,
          decoration: TaskFieldStyle.withPrefix(
            icon: TaskFieldStyle.parent,
            color: TaskFieldStyle.parentColor(theme.colorScheme),
            decoration: const InputDecoration(
              labelText: 'Родительская задача (группа)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('— нет —'),
            ),
            ...parentCandidates.map(
              (t) => DropdownMenuItem(
                value: t.id,
                child: Text(t.title, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (parentId) async {
            final err = await notifier.setTaskParent(current.id, parentId);
            if (err != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(err)),
              );
            }
          },
        ),
        if (parent != null) ...[
          const SizedBox(height: 4),
          _LinkedTaskRow(
            label: 'В группе',
            task: parent,
            onTap: onSelectTask != null ? () => onSelectTask!(parent.id) : null,
          ),
        ],
        if (children.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Подзадачи',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          ...children.map(
            (c) => _LinkedTaskRow(
              task: c,
              onTap: onSelectTask != null ? () => onSelectTask!(c.id) : null,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            TaskFieldStyle.prefixIcon(
              TaskFieldStyle.blockers,
              TaskFieldStyle.blockersColor(theme.colorScheme),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Блокеры (выполнить после)',
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...current.blockedByIds.map((id) {
              final blocker = taskById(all, id);
              if (blocker == null) return const SizedBox.shrink();
              return InputChip(
                label: Text(
                  blocker.title,
                  style: TextStyle(
                    decoration: isEffectivelyCompleted(blocker, all)
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                avatar: Icon(
                  isEffectivelyCompleted(blocker, all)
                      ? blocker.status.icon
                      : TaskFieldStyle.blockers,
                  size: 16,
                  color: isEffectivelyCompleted(blocker, all)
                      ? blocker.status.color(theme.colorScheme)
                      : TaskFieldStyle.blockersColor(theme.colorScheme),
                ),
                onPressed:
                    onSelectTask != null ? () => onSelectTask!(id) : null,
                onDeleted: () => notifier.removeBlocker(current.id, id),
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Добавить блокер'),
              onPressed: blockerCandidates.isEmpty
                  ? null
                  : () => _pickBlocker(context, current, blockerCandidates),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickBlocker(
    BuildContext context,
    TaskItem task,
    List<TaskItem> candidates,
  ) async {
    final available = candidates
        .where((t) => !task.blockedByIds.contains(t.id))
        .toList();
    if (available.isEmpty) return;

    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Выберите блокирующую задачу'),
        children: available
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, t.id),
                child: Text(t.title),
              ),
            )
            .toList(),
      ),
    );
    if (picked == null || !context.mounted) return;
    final err = await context.read<PlannerNotifier>().addBlocker(task.id, picked);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

class _LinkedTaskRow extends StatelessWidget {
  const _LinkedTaskRow({
    required this.task,
    this.label,
    this.onTap,
  });

  final TaskItem task;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        task.status.icon,
        size: 18,
        color: task.status.color(theme.colorScheme),
      ),
      title: Text(label != null ? '$label: ${task.title}' : task.title),
      subtitle: task.status != TaskStatus.open
          ? Text(
              task.status.label,
              style: TextStyle(color: task.status.color(theme.colorScheme)),
            )
          : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right, size: 18) : null,
      onTap: onTap,
    );
  }
}
