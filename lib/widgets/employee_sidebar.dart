import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/employee.dart';
import '../providers/planner_notifier.dart';
import '../utils/task_lanes.dart';
import 'employee_dialog.dart';

class EmployeeSidebar extends StatelessWidget {
  const EmployeeSidebar({
    super.key,
    required this.verticalScrollController,
  });

  final ScrollController verticalScrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: kSidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: kTimeHeaderHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    'Команда',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    tooltip: 'Добавить сотрудника',
                    onPressed: () => _addEmployee(context),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<PlannerNotifier>(
              builder: (context, notifier, _) {
                final employees = notifier.state.employees;
                return ListView.builder(
                  controller: verticalScrollController,
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    final lanes = TaskLaneLayout.compute(
                      notifier.scheduledTasksForEmployee(employee.id),
                      state: notifier.state,
                    );
                    final h = employeeGanttRowHeight(lanes.laneCount);
                    return SizedBox(
                      height: h,
                      child: _EmployeeRow(
                        name: employee.name,
                        onEdit: () => _editEmployee(context, notifier, employee),
                        onDelete: () => _deleteEmployee(
                          context,
                          notifier,
                          employee.id,
                          employee.name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addEmployee(BuildContext context) async {
    final name = await showEmployeeDialog(
      context,
      title: 'Новый сотрудник',
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    await context.read<PlannerNotifier>().addEmployee(name);
  }

  Future<void> _editEmployee(
    BuildContext context,
    PlannerNotifier notifier,
    Employee employee,
  ) async {
    final name = await showEmployeeDialog(
      context,
      initialName: employee.name,
      title: 'Редактировать',
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    await notifier.updateEmployee(employee.id, name);
  }

  Future<void> _deleteEmployee(
    BuildContext context,
    PlannerNotifier notifier,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сотрудника?'),
        content: Text('«$name» и все его задачи будут удалены.'),
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
    if (confirmed == true && context.mounted) {
      await notifier.removeEmployee(id);
    }
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.name,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon:
                    Icon(Icons.close, size: 18, color: theme.colorScheme.error),
                tooltip: 'Удалить',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
