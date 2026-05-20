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
}
