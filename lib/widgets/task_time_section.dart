import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../models/task_item.dart';
import '../providers/planner_notifier.dart';
import '../utils/duration_parse.dart';
import '../utils/task_field_style.dart';
import '../utils/task_relations.dart';
import '../utils/task_schedule_fields.dart';

/// Collected time fields for a single task save.
class TaskTimeFormValues {
  const TaskTimeFormValues({
    required this.estimateWorkingDays,
    required this.clearEstimateWorkingDays,
    required this.actualWorkingDays,
    required this.clearActualWorkingDays,
    required this.employeeId,
    required this.clearEmployeeId,
    required this.start,
    required this.clearStart,
    required this.duration,
    required this.workingDays,
    required this.clearWorkingDays,
  });

  final int? estimateWorkingDays;
  final bool clearEstimateWorkingDays;
  final int? actualWorkingDays;
  final bool clearActualWorkingDays;
  final String? employeeId;
  final bool clearEmployeeId;
  final DateTime? start;
  final bool clearStart;
  final Duration? duration;
  final int? workingDays;
  final bool clearWorkingDays;
}

/// Timeline placement and effort — saved together with the rest of the task.
class TaskTimeSection extends StatefulWidget {
  const TaskTimeSection({
    super.key,
    required this.task,
    required this.employees,
    required this.defaultStart,
  });

  final TaskItem task;
  final List<Employee> employees;
  final DateTime defaultStart;

  @override
  TaskTimeSectionState createState() => TaskTimeSectionState();
}

class TaskTimeSectionState extends State<TaskTimeSection> {
  late final TextEditingController _estimateController;
  late final TextEditingController _actualController;
  late final TextEditingController _durationController;
  DateTime? _start;
  late DurationUnit _unit;
  String? _employeeId;

  @override
  void initState() {
    super.initState();
    _estimateController = TextEditingController();
    _actualController = TextEditingController();
    _durationController = TextEditingController();
    _syncFromTask(widget.task);
  }

  @override
  void didUpdateWidget(TaskTimeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id ||
        oldWidget.task.estimateWorkingDays != widget.task.estimateWorkingDays ||
        oldWidget.task.actualWorkingDays != widget.task.actualWorkingDays ||
        oldWidget.task.isOnTimeline != widget.task.isOnTimeline ||
        oldWidget.task.start != widget.task.start ||
        oldWidget.task.duration != widget.task.duration ||
        oldWidget.task.workingDays != widget.task.workingDays ||
        oldWidget.task.employeeId != widget.task.employeeId) {
      _syncFromTask(widget.task);
    }
  }

  void _syncFromTask(TaskItem task) {
    _estimateController.text = workingDaysToField(task.estimateWorkingDays);
    _actualController.text = workingDaysToField(task.actualWorkingDays);
    _start = task.start;
    _unit = durationUnitForTask(task);
    _durationController.text = '${durationAmountForTask(task, _unit)}';
    _employeeId = task.employeeId;
  }

  DateTime? _blockerMinStart(BuildContext context) {
    if (widget.task.blockedByIds.isEmpty) return null;
    final notifier = context.read<PlannerNotifier>();
    return earliestStartAfterBlockers(
      widget.task,
      notifier.allTasks,
      state: notifier.state,
    );
  }

  void _applyBlockerMinStart(BuildContext context) {
    final start = _start;
    if (start == null) return;
    final min = _blockerMinStart(context);
    if (min != null && start.isBefore(min)) {
      setState(() => _start = min);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_employeeId != null) _applyBlockerMinStart(context);
  }

  @override
  void dispose() {
    _estimateController.dispose();
    _actualController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  ({Duration? duration, int? workingDays, bool clearWorkingDays})
      _durationFieldsFromForm() {
    final amount = int.tryParse(_durationController.text) ?? 1;
    if (_unit == DurationUnit.days) {
      return (
        duration: Duration(hours: 8 * amount),
        workingDays: amount,
        clearWorkingDays: false,
      );
    }
    return (
      duration: Duration(hours: amount),
      workingDays: null,
      clearWorkingDays: true,
    );
  }

  TaskTimeFormValues collectValues() {
    final estimateText = _estimateController.text.trim();
    final actualText = _actualController.text.trim();
    final estimateWorkingDays = parseWorkingDaysField(estimateText);
    final actualWorkingDays = parseWorkingDaysField(actualText);
    final amount = int.tryParse(_durationController.text) ?? 1;
    final onTimeline = _start != null;

    Duration? duration;
    int? workingDays;
    var clearWorkingDays = false;
    DateTime? start;

    if (onTimeline) {
      final notifier = context.read<PlannerNotifier>();
      final schedule = buildScheduleFields(
        task: widget.task,
        onTimeline: true,
        employeeId: _employeeId,
        start: _start!,
        unit: _unit,
        amount: amount,
        state: notifier.state,
      );
      start = schedule.start;
      if (start != null) {
        final draft = widget.task.copyWith(
          start: start,
          duration: schedule.duration!,
          workingDays: schedule.workingDays,
          clearWorkingDays: schedule.clearWorkingDays,
          employeeId: _employeeId,
        );
        start = notifier.clampScheduledStart(draft, start);
      }
      duration = schedule.duration;
      workingDays = schedule.workingDays;
      clearWorkingDays = schedule.clearWorkingDays;
    } else if (_employeeId != null) {
      final fields = _durationFieldsFromForm();
      duration = fields.duration;
      workingDays = fields.workingDays;
      clearWorkingDays = fields.clearWorkingDays;
    }

    return TaskTimeFormValues(
      estimateWorkingDays: estimateWorkingDays,
      clearEstimateWorkingDays:
          estimateWorkingDays == null && estimateText.isEmpty,
      actualWorkingDays: actualWorkingDays,
      clearActualWorkingDays:
          actualWorkingDays == null && actualText.isEmpty,
      employeeId: _employeeId,
      clearEmployeeId: _employeeId == null,
      start: start,
      clearStart: !onTimeline,
      duration: duration,
      workingDays: workingDays,
      clearWorkingDays: clearWorkingDays,
    );
  }

  void _planOnTimeline() {
    setState(() => _start = widget.defaultStart);
    _applyBlockerMinStart(context);
  }

  void _removeFromTimeline() {
    setState(() => _start = null);
  }

  Future<void> _pickStart() async {
    final initial = _start ?? widget.defaultStart;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _start = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _applyBlockerMinStart(context);
    });
  }

  DateTime? _timelineEndPreview() {
    if (_employeeId == null || _start == null) return null;
    final amount = int.tryParse(_durationController.text) ?? 1;
    final schedule = buildScheduleFields(
      task: widget.task,
      onTimeline: true,
      employeeId: _employeeId,
      start: _start!,
      unit: _unit,
      amount: amount,
      state: context.read<PlannerNotifier>().state,
    );
    final start = schedule.start;
    final duration = schedule.duration;
    if (start == null || duration == null) return null;
    return start.add(duration);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockerMin = _blockerMinStart(context);
    final assigned = _employeeId != null;
    final onTimeline = _start != null;
    final endPreview = _timelineEndPreview();

    final estimatePreview = parseWorkingDaysField(_estimateController.text);
    final actualPreview = parseWorkingDaysField(_actualController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.employees.isEmpty)
          Text(
            'Добавьте сотрудника, чтобы привязать задачу.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          DropdownButtonFormField<String?>(
            value: _employeeId,
            decoration: TaskFieldStyle.withPrefix(
              icon: TaskFieldStyle.employee,
              color: TaskFieldStyle.employeeColor(theme.colorScheme),
              decoration: const InputDecoration(
                labelText: 'Сотрудник',
                border: OutlineInputBorder(),
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Не привязана'),
              ),
              ...widget.employees.map(
                (e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(e.name),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _employeeId = v),
          ),
        if (assigned) ...[
          const SizedBox(height: 12),
          if (onTimeline) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: TaskFieldStyle.prefixIcon(
                    TaskFieldStyle.schedule,
                    TaskFieldStyle.scheduleColor(theme.colorScheme),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        endPreview != null
                            ? 'Начало ${formatDateTime(_start!)} · Окончание ${formatDateTime(endPreview)}'
                            : 'Начало ${formatDateTime(_start!)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (blockerMin != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Не раньше ${formatDateTime(blockerMin)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    TaskFieldStyle.schedule,
                    color: TaskFieldStyle.scheduleColor(theme.colorScheme),
                  ),
                  onPressed: _pickStart,
                  tooltip: 'Изменить дату начала',
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _removeFromTimeline,
                child: const Text('Убрать с таймлайна'),
              ),
            ),
          ] else ...[
            Text(
              'Задача привязана к сотруднику, но без даты начала не показывается на таймлайне.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _planOnTimeline,
              icon: Icon(
                TaskFieldStyle.timeline,
                color: TaskFieldStyle.timelineColor(theme.colorScheme),
              ),
              label: const Text('Запланировать на таймлайне'),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: TaskFieldStyle.withPrefix(
                    icon: TaskFieldStyle.duration,
                    color: TaskFieldStyle.durationColor(theme.colorScheme),
                    decoration: InputDecoration(
                      labelText: 'Длительность',
                      helperText: _unit == DurationUnit.days
                          ? 'Рабочие дни (без выходных)'
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DropdownButton<DurationUnit>(
                  value: _unit,
                  items: const [
                    DropdownMenuItem(
                      value: DurationUnit.hours,
                      child: Text('часов'),
                    ),
                    DropdownMenuItem(
                      value: DurationUnit.days,
                      child: Text('раб. дней'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _unit = v);
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        TaskFieldStyle.sectionHeader(
          context,
          icon: TaskFieldStyle.estimate,
          color: TaskFieldStyle.estimateColor(theme.colorScheme),
          title: 'Трудозатраты',
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _WorkingDaysField(
                controller: _estimateController,
                label: 'Оценка',
                icon: TaskFieldStyle.estimate,
                iconColor: TaskFieldStyle.estimateColor(theme.colorScheme),
                helperText: 'Плановые трудозатраты (раб. дни)',
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WorkingDaysField(
                controller: _actualController,
                label: 'Фактическое время',
                icon: TaskFieldStyle.actual,
                iconColor: TaskFieldStyle.actualColor(theme.colorScheme),
                helperText: 'Сколько потрачено по факту (раб. дни)',
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
        if (estimatePreview != null && actualPreview != null) ...[
          const SizedBox(height: 8),
          _VarianceChip(
            estimate: estimatePreview,
            actual: actualPreview,
          ),
        ],
      ],
    );
  }
}

class _WorkingDaysField extends StatelessWidget {
  const _WorkingDaysField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.helperText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;
  final String? helperText;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => onChanged?.call(),
      decoration: TaskFieldStyle.withPrefix(
        icon: icon,
        color: iconColor,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
          suffixText: 'раб. дн.',
        ),
      ),
    );
  }
}

class _VarianceChip extends StatelessWidget {
  const _VarianceChip({required this.estimate, required this.actual});

  final int estimate;
  final int actual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = actual - estimate;
    final over = delta > 0;
    final label = over
        ? 'Перерасход: $delta раб. дн.'
        : delta < 0
            ? 'Экономия: ${-delta} раб. дн.'
            : 'В срок по оценке';

    return Chip(
      avatar: Icon(
        over
            ? Icons.trending_up
            : delta < 0
                ? Icons.trending_down
                : Icons.check,
        size: 18,
        color: over ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      label: Text(label, style: theme.textTheme.labelMedium),
      backgroundColor: over
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
    );
  }
}
