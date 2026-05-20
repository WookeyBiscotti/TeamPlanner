import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/planner_main_view.dart';
import '../models/timeline_scale.dart';
import '../providers/planner_notifier.dart';
import '../providers/theme_notifier.dart';
import '../widgets/calendar_settings_dialog.dart';
import '../widgets/employee_sidebar.dart';
import '../widgets/gantt_chart.dart';
import '../widgets/relations_view.dart';
import '../widgets/tasks_panel.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _verticalScrollController = ScrollController();
  final _horizontalScrollController = ScrollController();
  PlannerMainView _mainView = PlannerMainView.timeline;
  String? _selectedTaskId;

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _export(BuildContext context) async {
    final notifier = context.read<PlannerNotifier>();
    try {
      final path = await notifier.exportState();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path != null
                ? 'Проект экспортирован: $path'
                : 'Экспорт отменён',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка экспорта: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _import(BuildContext context) async {
    final notifier = context.read<PlannerNotifier>();
    final message = await notifier.importState();
    if (!context.mounted) return;
    final isError = message != null &&
        !message.startsWith('Проект') &&
        !message.startsWith('Добавлено');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Импорт отменён'),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerNotifier>(
      builder: (context, notifier, _) {
        if (notifier.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isTimeline = _mainView == PlannerMainView.timeline;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Team Planner'),
            actions: [
              if (isTimeline) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SegmentedButton<TimelineScale>(
                    segments: TimelineScale.values
                        .map(
                          (s) => ButtonSegment(
                            value: s,
                            label: Text(s.label),
                            icon: Icon(
                              s == TimelineScale.hours
                                  ? Icons.schedule
                                  : Icons.calendar_view_day,
                            ),
                          ),
                        )
                        .toList(),
                    selected: {notifier.state.timelineScale},
                    onSelectionChanged: (selected) {
                      notifier.setTimelineScale(selected.first);
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: () => notifier.goToToday(),
                  icon: const Icon(Icons.today),
                  label: const Text('Сегодня'),
                ),
                IconButton(
                  icon: const Icon(Icons.event),
                  tooltip: 'Праздники и выходные',
                  onPressed: () => showCalendarSettingsDialog(context),
                ),
              ],
              Consumer<ThemeNotifier>(
                builder: (context, themeNotifier, _) {
                  return IconButton(
                    icon: Icon(themeNotifier.icon),
                    tooltip: themeNotifier.tooltip,
                    onPressed: themeNotifier.cycleThemeMode,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.save_alt),
                tooltip: 'Экспорт в JSON',
                onPressed: () => _export(context),
              ),
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: 'Импорт: проект или массив задач JSON',
                onPressed: () => _import(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<PlannerMainView>(
                    segments: [
                      ButtonSegment(
                        value: PlannerMainView.timeline,
                        label: Text(PlannerMainView.timeline.label),
                        icon: const Icon(Icons.view_timeline),
                      ),
                      ButtonSegment(
                        value: PlannerMainView.relations,
                        label: Text(PlannerMainView.relations.label),
                        icon: const Icon(Icons.account_tree),
                      ),
                    ],
                    selected: {_mainView},
                    onSelectionChanged: (selected) {
                      setState(() => _mainView = selected.first);
                    },
                  ),
                ),
              ),
              Expanded(
                child: isTimeline
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          EmployeeSidebar(
                            verticalScrollController: _verticalScrollController,
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: GanttChart(
                              verticalScrollController: _verticalScrollController,
                              horizontalScrollController:
                                  _horizontalScrollController,
                              onTaskSelected: (id) =>
                                  setState(() => _selectedTaskId = id),
                            ),
                          ),
                        ],
                      )
                    : RelationsView(
                        selectedTaskId: _selectedTaskId,
                        onTaskSelected: (id) =>
                            setState(() => _selectedTaskId = id),
                      ),
              ),
              ResizableTasksSection(
                selectedTaskId: _selectedTaskId,
                onSelectedTaskIdChanged: (id) =>
                    setState(() => _selectedTaskId = id),
              ),
            ],
          ),
        );
      },
    );
  }
}
