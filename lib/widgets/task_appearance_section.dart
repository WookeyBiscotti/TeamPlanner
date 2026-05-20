import 'package:flutter/material.dart';
import 'package:patterns_canvas/patterns_canvas.dart';
import 'package:provider/provider.dart';

import '../models/task_fill_pattern.dart';
import '../models/task_item.dart';
import '../providers/planner_notifier.dart';
import '../utils/task_appearance.dart';
import '../utils/task_colors.dart';
import '../utils/task_field_style.dart';
import '../utils/task_relations.dart';
import 'task_bar_fill_painter.dart';

/// Color and pattern fill for the timeline bar.
class TaskAppearanceSection extends StatefulWidget {
  const TaskAppearanceSection({super.key, required this.task});

  final TaskItem task;

  @override
  State<TaskAppearanceSection> createState() => _TaskAppearanceSectionState();
}

class _TaskAppearanceSectionState extends State<TaskAppearanceSection> {
  late bool _expanded;

  static bool _hasCustomAppearance(TaskItem task) =>
      task.color != null || task.fillPattern != null;

  @override
  void initState() {
    super.initState();
    _expanded = _hasCustomAppearance(widget.task);
  }

  @override
  void didUpdateWidget(covariant TaskAppearanceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _expanded = _hasCustomAppearance(widget.task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final notifier = context.watch<PlannerNotifier>();
    final current = taskById(notifier.allTasks, widget.task.id) ?? widget.task;
    final base = resolveTaskColor(current, scheme);
    final selectedPattern = TaskFillPattern.fromKey(current.fillPattern);
    final usesCustomColor = current.color != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TaskFieldStyle.sectionHeader(
                    context,
                    icon: Icons.palette_outlined,
                    color: scheme.primary,
                    title: 'Оформление на таймлайне',
                  ),
                ),
                if (!_expanded && _hasCustomAppearance(current))
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _CollapsedSummary(
                      baseColor: base,
                      fillPattern: selectedPattern,
                    ),
                  ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Text('Цвет', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ColorSwatch(
                color: current.employeeId != null
                    ? colorForEmployee(current.employeeId!)
                    : scheme.secondary,
                selected: !usesCustomColor,
                tooltip: 'По умолчанию',
                onTap: () => notifier.setTaskAppearance(
                  current.id,
                  clearColor: true,
                ),
              ),
              ...taskColorPalette.map(
                (c) => _ColorSwatch(
                  color: c,
                  selected: current.color?.toARGB32() == c.toARGB32(),
                  onTap: () => notifier.setTaskAppearance(
                    current.id,
                    color: c,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Узор', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PatternSwatch(
                label: 'Без узора',
                selected: selectedPattern == null,
                baseColor: base,
                onTap: () => notifier.setTaskAppearance(
                  current.id,
                  clearFillPattern: true,
                ),
              ),
              ...TaskFillPattern.values.map(
                (p) => _PatternSwatch(
                  label: p.label,
                  selected: selectedPattern == p,
                  baseColor: base,
                  fillPattern: p,
                  onTap: () => notifier.setTaskAppearance(
                    current.id,
                    fillPattern: p,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TimelinePreview(
            baseColor: base,
            fillPattern: selectedPattern,
          ),
        ],
      ],
    );
  }
}

class _CollapsedSummary extends StatelessWidget {
  const _CollapsedSummary({
    required this.baseColor,
    required this.fillPattern,
  });

  final Color baseColor;
  final TaskFillPattern? fillPattern;

  @override
  Widget build(BuildContext context) {
    final pattern = fillPattern == null
        ? null
        : Pattern.fromValues(
            patternType: fillPattern!.patternType,
            bgColor: baseColor,
            fgColor: patternForegroundFor(baseColor),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 48,
        height: 20,
        child: CustomPaint(
          painter: TaskBarFillPainter(
            color: baseColor,
            pattern: pattern,
            borderRadius: 4,
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.tooltip,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check,
                    size: 18,
                    color: color.computeLuminance() > 0.55
                        ? Colors.black87
                        : Colors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _PatternSwatch extends StatelessWidget {
  const _PatternSwatch({
    required this.label,
    required this.selected,
    required this.baseColor,
    required this.onTap,
    this.fillPattern,
  });

  final String label;
  final bool selected;
  final Color baseColor;
  final TaskFillPattern? fillPattern;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pattern = fillPattern == null
        ? null
        : Pattern.fromValues(
            patternType: fillPattern!.patternType,
            bgColor: baseColor,
            fgColor: patternForegroundFor(baseColor),
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 32,
                width: double.infinity,
                child: CustomPaint(
                  painter: TaskBarFillPainter(
                    color: baseColor,
                    pattern: pattern,
                    borderRadius: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelinePreview extends StatelessWidget {
  const _TimelinePreview({
    required this.baseColor,
    required this.fillPattern,
  });

  final Color baseColor;
  final TaskFillPattern? fillPattern;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pattern = fillPattern == null
        ? null
        : Pattern.fromValues(
            patternType: fillPattern!.patternType,
            bgColor: baseColor,
            fgColor: patternForegroundFor(baseColor),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Превью',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 36,
            width: double.infinity,
            child: CustomPaint(
              painter: TaskBarFillPainter(
                color: baseColor,
                pattern: pattern,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Пример задачи',
                    style: TextStyle(
                      color: onTaskBarText(baseColor),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
