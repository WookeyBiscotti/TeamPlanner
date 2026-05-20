import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/task_item.dart';
import 'package:planner/utils/task_lanes.dart';

void main() {
  test('non-overlapping tasks share one lane', () {
    final a = TaskItem(
      id: 'a',
      employeeId: 'e',
      title: 'A',
      start: DateTime(2025, 5, 12, 9),
      duration: const Duration(hours: 1),
    );
    final b = TaskItem(
      id: 'b',
      employeeId: 'e',
      title: 'B',
      start: DateTime(2025, 5, 12, 10, 30),
      duration: const Duration(hours: 1),
    );
    final layout = TaskLaneLayout.compute([a, b]);
    expect(layout.laneCount, 1);
    expect(layout.laneFor('a'), 0);
    expect(layout.laneFor('b'), 0);
  });

  test('overlapping tasks get stacked lanes', () {
    final a = TaskItem(
      id: 'a',
      employeeId: 'e',
      title: 'A',
      start: DateTime(2025, 5, 12, 9),
      duration: const Duration(hours: 4),
    );
    final b = TaskItem(
      id: 'b',
      employeeId: 'e',
      title: 'B',
      start: DateTime(2025, 5, 12, 10),
      duration: const Duration(hours: 4),
    );
    final layout = TaskLaneLayout.compute([a, b]);
    expect(layout.laneCount, 2);
    expect({layout.laneFor('a'), layout.laneFor('b')}, {0, 1});
  });
}
