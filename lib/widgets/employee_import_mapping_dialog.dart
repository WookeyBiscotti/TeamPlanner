import 'package:flutter/material.dart';

import '../models/employee.dart';

/// Shows employees from the import file and lets the user map each to a project employee.
/// Returns [importName] -> project [employeeId], or null if cancelled.
Future<Map<String, String?>?> showEmployeeImportMappingDialog(
  BuildContext context, {
  required List<String> importNames,
  required List<Employee> projectEmployees,
  required Map<String, String?> initialMapping,
}) async {
  return showDialog<Map<String, String?>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _EmployeeImportMappingDialog(
      importNames: importNames,
      projectEmployees: projectEmployees,
      initialMapping: initialMapping,
    ),
  );
}

class _EmployeeImportMappingDialog extends StatefulWidget {
  const _EmployeeImportMappingDialog({
    required this.importNames,
    required this.projectEmployees,
    required this.initialMapping,
  });

  final List<String> importNames;
  final List<Employee> projectEmployees;
  final Map<String, String?> initialMapping;

  @override
  State<_EmployeeImportMappingDialog> createState() =>
      _EmployeeImportMappingDialogState();
}

class _EmployeeImportMappingDialogState
    extends State<_EmployeeImportMappingDialog> {
  late final Map<String, String?> _mapping;

  @override
  void initState() {
    super.initState();
    _mapping = Map<String, String?>.from(widget.initialMapping);
    for (final name in widget.importNames) {
      _mapping.putIfAbsent(name, () => null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сопоставление сотрудников'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'В файле указаны исполнители, которых нужно сопоставить '
                'с сотрудниками проекта:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...widget.importNames.map(_buildRow),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _mapping),
          child: const Text('Импортировать'),
        ),
      ],
    );
  }

  Widget _buildRow(String importName) {
    final selectedId = _mapping[importName];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                importName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String?>(
              value: selectedId != null &&
                      widget.projectEmployees.any((e) => e.id == selectedId)
                  ? selectedId
                  : null,
              decoration: const InputDecoration(
                labelText: 'В проекте',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('— не назначать —'),
                ),
                ...widget.projectEmployees.map(
                  (e) => DropdownMenuItem<String?>(
                    value: e.id,
                    child: Text(e.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _mapping[importName] = value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
