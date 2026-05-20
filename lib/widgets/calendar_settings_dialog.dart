import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/calendar_range.dart';
import '../models/employee.dart';
import '../providers/planner_notifier.dart';
import '../utils/calendar_ranges.dart';
import 'pick_date_range.dart';

Future<void> showCalendarSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _CalendarSettingsDialog(),
  );
}

class _CalendarSettingsDialog extends StatelessWidget {
  const _CalendarSettingsDialog();

  Future<void> _addHolidayRange(BuildContext context) async {
    final range = await pickDateRange(
      context,
      helpText: 'Период праздника',
    );
    if (range == null || !context.mounted) return;
    await context.read<PlannerNotifier>().addHolidayRange(range);
  }

  Future<void> _addVacation(
    BuildContext context,
    Employee employee,
  ) async {
    final range = await pickDateRange(
      context,
      helpText: 'Период отпуска — ${employee.name}',
    );
    if (range == null || !context.mounted) return;
    await context.read<PlannerNotifier>().addEmployeeTimeOffRange(
          employee.id,
          range,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerNotifier>(
      builder: (context, notifier, _) {
        final state = notifier.state;
        final holidays = List<CalendarRange>.from(state.holidayRanges);

        return AlertDialog(
          title: const Text('Календарь'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Праздники для всех',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'На таймлайне: удерживайте начало и конец периода в шапке.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (holidays.isEmpty)
                    Text(
                      'Нет праздников',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    )
                  else
                    ...holidays.map(
                      (range) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.celebration,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 20,
                        ),
                        title: Text(formatRangeRu(range)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () =>
                              notifier.removeHolidayRange(range),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addHolidayRange(context),
                      icon: const Icon(Icons.date_range),
                      label: const Text('Добавить период'),
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Отпуска и выходные',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'На таймлайне: удерживайте начало и конец на строке сотрудника.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ...state.employees.map((employee) {
                    final timeOff = List<CalendarRange>.from(employee.timeOff);
                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(employee.name),
                      subtitle: timeOff.isEmpty
                          ? const Text('Нет отпусков')
                          : Text('${timeOff.length} период(ов)'),
                      children: [
                        ...timeOff.map(
                          (range) => ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(left: 16),
                            leading: Icon(
                              Icons.beach_access,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                            title: Text(formatRangeRu(range)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => notifier
                                  .removeEmployeeTimeOffRange(
                                employee.id,
                                range,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _addVacation(context, employee),
                            icon: const Icon(Icons.date_range),
                            label: const Text('Добавить отпуск'),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}
