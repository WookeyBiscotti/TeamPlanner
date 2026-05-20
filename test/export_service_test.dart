import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/planner_state.dart';
import 'package:planner/services/export_service.dart';

void main() {
  test('export JSON round-trips through import', () {
    final service = ExportService();
    final state = PlannerState.initial();
    final decoded =
        jsonDecode(service.exportToJson(state)) as Map<String, dynamic>;

    expect(decoded['formatVersion'], ExportService.formatVersion);
    expect(decoded['exportedAt'], isNotNull);

    final restored = PlannerState.fromJson(decoded);
    expect(restored.employees.length, state.employees.length);
    expect(restored.tasks.length, state.tasks.length);
    expect(restored.timelineStart, state.timelineStart);
  });

  test('default filename ends with .json', () {
    final name = ExportService().defaultFilename();
    expect(name, endsWith('.json'));
    expect(name, startsWith('planner_export_'));
  });
}
