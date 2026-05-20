import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/employee.dart';
import '../models/task_item.dart';
import '../models/task_status.dart';
import '../providers/planner_notifier.dart';
import '../utils/task_appearance.dart';
import '../utils/task_field_style.dart';
import '../utils/task_format.dart';
import '../utils/task_relations.dart';
import 'task_appearance_section.dart';
import 'task_relations_section.dart';
import 'task_status_chip.dart';
import 'task_time_section.dart';

/// Bottom section: draggable height, task list (left), task detail (right).
class ResizableTasksSection extends StatefulWidget {
  const ResizableTasksSection({
    super.key,
    required this.selectedTaskId,
    required this.onSelectedTaskIdChanged,
  });

  final String? selectedTaskId;
  final ValueChanged<String?> onSelectedTaskIdChanged;

  @override
  State<ResizableTasksSection> createState() => _ResizableTasksSectionState();
}

class _ResizableTasksSectionState extends State<ResizableTasksSection> {
  double _height = kTasksPanelDefaultHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: _height,
      child: Column(
        children: [
          _ResizeHandle(
            onDragDelta: (dy) {
              setState(() {
                _height = (_height - dy).clamp(
                  kTasksPanelMinHeight,
                  kTasksPanelMaxHeight,
                );
              });
            },
          ),
          Expanded(
            child: Material(
              elevation: 8,
              color: theme.colorScheme.surfaceContainerLow,
              child: TasksPanel(
                selectedTaskId: widget.selectedTaskId,
                onSelectedTaskIdChanged: widget.onSelectedTaskIdChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.onDragDelta});

  final void Function(double dy) onDragDelta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) => onDragDelta(d.delta.dy),
        child: Container(
          height: 10,
          alignment: Alignment.center,
          color: theme.colorScheme.surfaceContainerHigh,
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

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
                  final scheduled = notifier.scheduledTasks.length;
                  final backlog = notifier.backlogTasks.length;
                  return Text(
                    '$scheduled на таймлайне · $backlog вне таймлайна',
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
              final tasks = notifier.allTasks;
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
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.tonalIcon(
                              onPressed: () async {
                                await notifier.addBacklogTask();
                                if (!context.mounted) return;
                                final updated = notifier.allTasks;
                                _select(updated.last.id);
                              },
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Новая задача'),
                            ),
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
                        Expanded(
                          child: tasks.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Нет задач. Добавьте задачу.',
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
                    child: tasks.isEmpty
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
                            : _TaskDetailPane(
                                key: ValueKey(selected.id),
                                task: selected,
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
              if (blocked && !task.isCompleted)
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
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TaskStatusChip(status: task.status, compact: true),
                        const SizedBox(width: 4),
                        _ScheduleChip(scheduled: task.isScheduled, compact: true),
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

class _TaskDetailPane extends StatefulWidget {
  const _TaskDetailPane({
    super.key,
    required this.task,
    required this.onSelectTask,
    required this.onDeleted,
  });

  final TaskItem task;
  final void Function(String taskId) onSelectTask;
  final VoidCallback onDeleted;

  @override
  State<_TaskDetailPane> createState() => _TaskDetailPaneState();
}

class _TaskDetailPaneState extends State<_TaskDetailPane> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _timeSectionKey = GlobalKey<TaskTimeSectionState>();
  late bool _descriptionExpanded;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _descriptionExpanded = widget.task.description.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant _TaskDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _titleController.text = widget.task.title;
      _descriptionController.text = widget.task.description;
      _descriptionExpanded = widget.task.description.trim().isNotEmpty;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: Text('«${task.title}» будет удалена.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<PlannerNotifier>().removeTask(task.id);
      widget.onDeleted();
    }
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final time = _timeSectionKey.currentState?.collectValues();
    if (time == null) return;

    await context.read<PlannerNotifier>().updateTaskFields(
          widget.task.id,
          title: title,
          description: _descriptionController.text,
          estimateWorkingDays: time.estimateWorkingDays,
          clearEstimateWorkingDays: time.clearEstimateWorkingDays,
          actualWorkingDays: time.actualWorkingDays,
          clearActualWorkingDays: time.clearActualWorkingDays,
          employeeId: time.employeeId,
          clearEmployeeId: time.clearEmployeeId,
          start: time.start,
          clearStart: time.clearStart,
          duration: time.duration,
          workingDays: time.workingDays,
          clearWorkingDays: time.clearWorkingDays,
        );
    if (_descriptionController.text.trim().isEmpty && mounted) {
      setState(() => _descriptionExpanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = context.watch<PlannerNotifier>();
    final task = taskById(notifier.allTasks, widget.task.id) ?? widget.task;
    final state = notifier.state;
    final employees = state.employees;
    final scheduled = task.isScheduled;
    final defaultStart =
        task.start ?? state.timelineStart.add(const Duration(hours: 9));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Задача',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _ScheduleChip(scheduled: scheduled),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Удалить',
                onPressed: () => _confirmDelete(task),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: TaskFieldStyle.withPrefix(
              icon: TaskFieldStyle.title,
              color: TaskFieldStyle.titleColor(theme.colorScheme),
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskStatus>(
            value: task.status,
            decoration: const InputDecoration(
              labelText: 'Статус',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: TaskStatus.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: TaskFieldStyle.statusMenuItem(context, s),
                  ),
                )
                .toList(),
            onChanged: (status) {
              if (status != null) {
                notifier.setTaskStatus(task.id, status);
              }
            },
          ),
          const SizedBox(height: 16),
          TaskAppearanceSection(task: task),
          const SizedBox(height: 16),
          TaskTimeSection(
            key: _timeSectionKey,
            task: task,
            employees: employees,
            defaultStart: defaultStart,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TaskFieldStyle.sectionHeader(
                context,
                icon: TaskFieldStyle.description,
                color: TaskFieldStyle.descriptionColor(theme.colorScheme),
                title: 'Описание',
              ),
              const Spacer(),
              if (!_descriptionExpanded)
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: TaskFieldStyle.descriptionColor(theme.colorScheme),
                  ),
                  tooltip: 'Добавить описание',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      setState(() => _descriptionExpanded = true),
                ),
              FilledButton(
                onPressed: _saveTask,
                child: const Text('Сохранить'),
              ),
            ],
          ),
          if (_descriptionExpanded) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 12,
              decoration: TaskFieldStyle.withPrefix(
                icon: TaskFieldStyle.description,
                color: TaskFieldStyle.descriptionColor(theme.colorScheme),
                decoration: const InputDecoration(
                  hintText: 'Текст описания',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TaskRelationsSection(
            task: task,
            onSelectTask: widget.onSelectTask,
          ),
        ],
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip({
    required this.scheduled,
    this.compact = false,
  });

  final bool scheduled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: scheduled
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            scheduled ? TaskFieldStyle.timeline : TaskFieldStyle.backlog,
            size: compact ? 12 : 14,
            color: scheduled
                ? TaskFieldStyle.timelineColor(theme.colorScheme)
                : TaskFieldStyle.backlogColor(theme.colorScheme),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            scheduled ? 'Таймлайн' : 'Бэклог',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : null,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
