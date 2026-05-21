import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/planner_state.dart';

void main() {
  test('PlannerState serializes and deserializes', () {
    final state = PlannerState.initial();
    final restored = PlannerState.fromJson(state.toJson());

    expect(restored.employees.length, state.employees.length);
    expect(restored.tasks.length, state.tasks.length);
    expect(restored.timelineStart, state.timelineStart);
    expect(restored.pixelsPerHour, state.pixelsPerHour);
    expect(restored.timelineScale, state.timelineScale);
    expect(restored.pixelsPerDay, state.pixelsPerDay);
  });

  test('importEmployeeMapping round-trips json', () {
    final state = PlannerState.initial().copyWith(
      importEmployeeMapping: {
        'Иван': 'demo-emp-1',
        'Неизвестный': null,
      },
    );
    final restored = PlannerState.fromJson(state.toJson());
    expect(restored.importEmployeeMapping['Иван'], 'demo-emp-1');
    expect(restored.importEmployeeMapping['Неизвестный'], isNull);
  });
}
