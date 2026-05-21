import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_item.dart';
import '../models/task_status.dart';
import '../providers/planner_notifier.dart';
import '../utils/task_field_style.dart';
import '../utils/task_relations.dart';
import 'task_appearance_section.dart';
import 'task_relations_section.dart';
import 'task_time_section.dart';

/// Timeline / backlog schedule badge.
class TaskScheduleChip extends StatelessWidget {
  const TaskScheduleChip({
    super.key,
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

/// Editable task fields: title, status, time, description, relations.
class TaskDetailPane extends StatefulWidget {
  const TaskDetailPane({
    super.key,
    required this.taskId,
    this.onSelectTask,
    required this.onDeleted,
  });

  final String taskId;
  final void Function(String taskId)? onSelectTask;
  final VoidCallback onDeleted;

  @override
  TaskDetailPaneState createState() => TaskDetailPaneState();
}

/// Public state for saving the open task before auto-schedule.
class TaskDetailPaneState extends State<TaskDetailPane> {

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _externalUrlController;
  final _timeSectionKey = GlobalKey<TaskTimeSectionState>();
  late bool _descriptionExpanded;
  String? _loadedTaskId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _externalUrlController = TextEditingController();
    _descriptionExpanded = false;
  }

  void _syncFromTask(TaskItem task) {
    if (_loadedTaskId == task.id) return;
    _loadedTaskId = task.id;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _externalUrlController.text = task.externalDescriptionUrl;
    _descriptionExpanded = task.description.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _externalUrlController.dispose();
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

  /// Persists the form (including Трудозатраты → Оценка).
  Future<void> savePending() => _saveTask(widget.taskId);

  Future<void> _saveTask(String taskId) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final time = _timeSectionKey.currentState?.collectValues();
    if (time == null) return;

    await context.read<PlannerNotifier>().updateTaskFields(
          taskId,
          title: title,
          description: _descriptionController.text,
          externalDescriptionUrl: _externalUrlController.text.trim(),
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
          effortUnit: time.effortUnit,
          clearEffortUnit: time.clearEffortUnit,
        );
    if (_descriptionController.text.trim().isEmpty && mounted) {
      setState(() => _descriptionExpanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = context.watch<PlannerNotifier>();
    final task = taskById(notifier.allTasks, widget.taskId);
    if (task == null) {
      return const SizedBox.shrink();
    }
    _syncFromTask(task);

    final state = notifier.state;
    final employees = state.employees;
    final scheduled = task.isScheduled;
    final defaultStart =
        task.start ?? state.timelineStart.add(const Duration(hours: 9));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Задача',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    task.id,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TaskScheduleChip(scheduled: scheduled),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _saveTask(task.id),
                child: const Text('Сохранить'),
              ),
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
          const SizedBox(height: 12),
          TextField(
            controller: _externalUrlController,
            keyboardType: TextInputType.url,
            decoration: TaskFieldStyle.withPrefix(
              icon: TaskFieldStyle.externalDescription,
              color: TaskFieldStyle.externalDescriptionColor(
                theme.colorScheme,
              ),
              decoration: const InputDecoration(
                labelText: 'Ссылка на описание',
                hintText: 'https://…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
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

/// Modal editor for a task (timeline tap, etc.).
Future<void> showTaskEditorDialog(
  BuildContext context, {
  required String taskId,
  void Function(String taskId)? onSelectTask,
  VoidCallback? onDeleted,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final maxHeight = MediaQuery.sizeOf(dialogContext).height * 0.85;
      return Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: maxHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Закрыть',
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
              Flexible(
                child: TaskDetailPane(
                  key: ValueKey(taskId),
                  taskId: taskId,
                  onSelectTask: onSelectTask == null
                      ? null
                      : (otherId) {
                          Navigator.pop(dialogContext);
                          onSelectTask(otherId);
                          showTaskEditorDialog(
                            context,
                            taskId: otherId,
                            onSelectTask: onSelectTask,
                            onDeleted: onDeleted,
                          );
                        },
                  onDeleted: () {
                    Navigator.pop(dialogContext);
                    onDeleted?.call();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
