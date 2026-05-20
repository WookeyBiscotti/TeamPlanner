import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../models/task_item.dart';
import '../providers/planner_notifier.dart';
import '../utils/relations_graph.dart';
import '../utils/task_appearance.dart';
import '../utils/task_field_style.dart';
import '../utils/task_format.dart';
import '../utils/task_relations.dart';

class RelationsView extends StatefulWidget {
  const RelationsView({
    super.key,
    required this.selectedTaskId,
    required this.onTaskSelected,
  });

  final String? selectedTaskId;
  final ValueChanged<String> onTaskSelected;

  @override
  State<RelationsView> createState() => _RelationsViewState();
}

class _RelationsViewState extends State<RelationsView> {
  final _controller = GraphViewController();
  late final SugiyamaConfiguration _layoutConfig;
  Graph? _graph;
  Map<String, TaskItem> _tasksById = {};
  String _graphSignature = '';

  @override
  void initState() {
    super.initState();
    _layoutConfig = SugiyamaConfiguration()
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM
      ..levelSeparation = 72
      ..nodeSeparation = 36
      ..addTriangleToEdge = true;
  }

  @override
  void didUpdateWidget(RelationsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.selectedTaskId;
    if (id != null && id != oldWidget.selectedTaskId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.jumpToNode(ValueKey(id));
      });
    }
  }

  void _syncGraph(List<TaskItem> tasks, ColorScheme colors) {
    final signature = relationsGraphSignature(tasks);
    if (signature == _graphSignature) return;

    final data = buildRelationsGraph(
      tasks: tasks,
      parentEdgeColor: colors.outline,
      blockerEdgeColor: colors.error,
    );
    _graphSignature = signature;
    _graph = data.graph;
    _tasksById = data.tasksById;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.zoomToFit();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerNotifier>(
      builder: (context, notifier, _) {
        final tasks = notifier.allTasks;
        final employees = notifier.state.employees;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        if (tasks.isEmpty) {
          return Center(
            child: Text(
              'Нет задач для отображения связей',
              style: theme.textTheme.bodyLarge,
            ),
          );
        }

        _syncGraph(tasks, colors);
        final graph = _graph!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Связи между задачами',
                    style: theme.textTheme.titleSmall,
                  ),
                  _LegendChip(
                    color: colors.outline,
                    label: 'родитель → ребёнок',
                  ),
                  _LegendChip(
                    color: colors.error,
                    label: 'блокер → задача',
                  ),
                  IconButton(
                    tooltip: 'Подогнать масштаб',
                    icon: const Icon(Icons.fit_screen),
                    onPressed: _controller.zoomToFit,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GraphView.builder(
                key: ValueKey(_graphSignature),
                graph: graph,
                algorithm: SugiyamaAlgorithm(_layoutConfig),
                controller: _controller,
                animated: true,
                autoZoomToFit: true,
                paint: Paint()
                  ..color = colors.outline
                  ..strokeWidth = 2
                  ..style = PaintingStyle.stroke,
                builder: (node) {
                  final taskId = node.key!.value as String;
                  if (taskId == relationsGraphHubId) {
                    return const SizedBox(width: 1, height: 1);
                  }
                  final task = _tasksById[taskId];
                  if (task == null) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    width: 220,
                    child: _RelationsTaskCard(
                      task: task,
                      allTasks: tasks,
                      employees: employees,
                      selected: taskId == widget.selectedTaskId,
                      onTap: () => widget.onTaskSelected(taskId),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RelationsTaskCard extends StatelessWidget {
  const _RelationsTaskCard({
    required this.task,
    required this.allTasks,
    required this.employees,
    required this.selected,
    required this.onTap,
  });

  final TaskItem task;
  final List<TaskItem> allTasks;
  final List<Employee> employees;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = resolveTaskColor(task, theme.colorScheme);
    final blocked = isBlockedByIncomplete(task, allTasks);

    return Material(
      elevation: selected ? 4 : 1,
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.85)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTaskSchedule(task, employees),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                task.status.icon,
                size: 16,
                color: task.status.color(theme.colorScheme),
              ),
              if (blocked && !task.isCompleted) ...[
                const SizedBox(width: 4),
                Icon(
                  TaskFieldStyle.blockers,
                  size: 16,
                  color: TaskFieldStyle.blockersColor(theme.colorScheme),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
