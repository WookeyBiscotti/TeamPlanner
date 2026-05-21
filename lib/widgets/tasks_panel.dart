import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/employee.dart';
import '../models/task_item.dart';
import '../models/task_list_filter.dart';
import '../providers/planner_notifier.dart';
import '../utils/task_appearance.dart';
import '../utils/task_field_style.dart';
import '../utils/task_format.dart';
import '../utils/task_relations.dart';
import 'task_detail_pane.dart';
import 'task_status_chip.dart';

/// Task list (left) and task detail (right).
class TasksPanel extends StatefulWidget {
  const TasksPanel({
    super.key,
    required this.selectedTaskId,
    required this.onSelectedTaskIdChanged,
  });

  final String? selectedTaskId;
  final ValueChanged<String?> onSelectedTaskIdChanged;

  @override
  State<TasksPanel> createState() => _TasksPanelState();
}

class _TasksPanelState extends State<TasksPanel> {
  TaskListFilters _filters = TaskListFilters.empty;
  final _detailPaneKey = GlobalKey<TaskDetailPaneState>();

  void _ensureSelection(List<TaskItem> tasks) {
    String? next;
    if (tasks.isEmpty) {
      next = null;
    } else if (widget.selectedTaskId == null ||
        !tasks.any((t) => t.id == widget.selectedTaskId)) {
      next = tasks.first.id;
    } else {
      return;
    }
    if (next != widget.selectedTaskId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSelectedTaskIdChanged(next);
      });
    }
  }

  void _select(String? id) => widget.onSelectedTaskIdChanged(id);

  Future<void> _autoSchedule(
    BuildContext context,
    PlannerNotifier notifier,
  ) async {
    final tasks = notifier.allTasks;
    final toReplan = tasks
        .where(
          (t) => isAutoSchedulable(t, tasks) && t.isOnTimeline,
        )
        .length;
    await _detailPaneKey.currentState?.savePending();

    if (toReplan > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Автопланирование'),
          content: Text(
            'Перепланировать $toReplan задач на таймлайне? '
            'Будут учтены оценки, исполнители и блокеры. '
            'Учитывается только «Трудозатраты → Оценка» (нужно сохранить задачу). '
            'У блокеров тоже должна быть оценка.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Спланировать'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final message = await notifier.scheduleAllEstimatedTasks();
    if (!context.mounted) return;
    final isError = message.contains('Циклическ') ||
        message.contains('Добавьте хотя бы') ||
        message.contains('Нельзя спланировать');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Text(
                'Задачи',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Consumer<PlannerNotifier>(
                builder: (context, notifier, _) {
                  final all = notifier.allTasks;
                  final visible = filterTasksForList(all, _filters);
                  final scheduled = visible.where((t) => t.isScheduled).length;
                  final backlog = visible.length - scheduled;
                  final suffix = _filters.isActive && visible.length != all.length
                      ? ' · ${visible.length} из ${all.length}'
                      : '';
                  return Text(
                    '$scheduled на таймлайне · $backlog вне таймлайна$suffix',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Consumer<PlannerNotifier>(
            builder: (context, notifier, _) {
              final allTasks = notifier.allTasks;
              final tasks = filterTasksForList(allTasks, _filters);
              final tree = buildTaskTree(tasks);
              _ensureSelection(tasks);

              final selected = taskById(tasks, widget.selectedTaskId ?? '');

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: kTasksListWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () async {
                                  await notifier.addBacklogTask();
                                  if (!context.mounted) return;
                                  final updated = notifier.allTasks;
                                  _select(updated.last.id);
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Новая задача'),
                              ),
                              OutlinedButton.icon(
                                onPressed: notifier.state.employees.isEmpty
                                    ? null
                                    : () => _autoSchedule(context, notifier),
                                icon: const Icon(Icons.auto_fix_high, size: 20),
                                label: const Text('Спланировать'),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                          child: Text(
                            'Список',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                          child: _TaskListFiltersBar(
                            filters: _filters,
                            onChanged: (next) => setState(() => _filters = next),
                          ),
                        ),
                        Expanded(
                          child: tasks.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      allTasks.isEmpty
                                          ? 'Нет задач. Добавьте задачу.'
                                          : 'Нет задач по выбранным фильтрам.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  itemCount: tree.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final entry = tree[index];
                                    return _TaskListTile(
                                      task: entry.task,
                                      depth: entry.depth,
                                      allTasks: tasks,
                                      selected: entry.task.id ==
                                          widget.selectedTaskId,
                                      employees: notifier.state.employees,
                                      onTap: () => _select(entry.task.id),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: allTasks.isEmpty
                        ? Center(
                            child: Text(
                              'Добавьте задачу кнопкой «Новая задача»',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : selected == null
                            ? Center(
                                child: Text(
                                  'Выберите задачу',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : TaskDetailPane(
                                key: _detailPaneKey,
                                taskId: selected.id,
                                onSelectTask: _select,
                                onDeleted: () {
                                  final remaining = notifier.allTasks
                                      .where((t) => t.id != selected.id)
                                      .toList();
                                  _select(
                                    remaining.isEmpty
                                        ? null
                                        : remaining.first.id,
                                  );
                                },
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TaskListFiltersBar extends StatelessWidget {
  const _TaskListFiltersBar({
    required this.filters,
    required this.onChanged,
  });

  final TaskListFilters filters;
  final ValueChanged<TaskListFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    FilterChip chip({
      required String label,
      required bool selected,
      required VoidCallback onSelected,
    }) {
      return FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        labelStyle: theme.textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onSelected: (_) => onSelected(),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        chip(
          label: 'Оцененные',
          selected: filters.estimate.contains(TaskEstimateFilter.estimated),
          onSelected: () => onChanged(
            filters.toggleEstimate(TaskEstimateFilter.estimated),
          ),
        ),
        chip(
          label: 'Не оцененные',
          selected:
              filters.estimate.contains(TaskEstimateFilter.notEstimated),
          onSelected: () => onChanged(
            filters.toggleEstimate(TaskEstimateFilter.notEstimated),
          ),
        ),
        chip(
          label: 'Запланированные',
          selected: filters.schedule.contains(TaskScheduleFilter.scheduled),
          onSelected: () => onChanged(
            filters.toggleSchedule(TaskScheduleFilter.scheduled),
          ),
        ),
        chip(
          label: 'Не запланированные',
          selected:
              filters.schedule.contains(TaskScheduleFilter.notScheduled),
          onSelected: () => onChanged(
            filters.toggleSchedule(TaskScheduleFilter.notScheduled),
          ),
        ),
      ],
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({
    required this.task,
    required this.depth,
    required this.allTasks,
    required this.selected,
    required this.employees,
    required this.onTap,
  });

  final TaskItem task;
  final int depth;
  final List<TaskItem> allTasks;
  final bool selected;
  final List<Employee> employees;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = resolveTaskColor(task, theme.colorScheme);
    final blocked = isBlockedByIncomplete(task, allTasks);
    final done = isEffectivelyCompleted(task, allTasks);

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(10 + depth * 14.0, 8, 10, 8),
          child: Row(
            children: [
              if (blocked && !done)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    TaskFieldStyle.blockers,
                    size: 16,
                    color: TaskFieldStyle.blockersColor(theme.colorScheme),
                  ),
                ),
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: done
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TaskStatusChip(status: task.status, compact: true),
                        const SizedBox(width: 4),
                        TaskScheduleChip(scheduled: task.isScheduled, compact: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTaskSchedule(task, employees),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    if (formatTaskTimeSummary(task).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        formatTaskTimeSummary(task),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
