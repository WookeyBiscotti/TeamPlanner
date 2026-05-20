import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/employee.dart';
import 'package:planner/models/planner_state.dart';
import 'package:planner/models/task_item.dart';
import 'package:planner/models/timeline_scale.dart';
import 'package:planner/utils/timeline_layout.dart';

void main() {
  test('taskLeft and timeAtOffset include scrollable history', () {
    final timelineStart = DateTime(2025, 5, 12);
    final state = PlannerState(
      timelineStart: timelineStart,
      timelineScale: TimelineScale.hours,
      pixelsPerHour: 24,
      pixelsPerDay: 64,
      employees: const [Employee(id: 'e', name: 'A')],
      tasks: const [],
    );

    final inset = state.timelineContentInset;
    expect(inset, greaterThan(0));

    expect(taskLeft(state, timelineStart), inset);
    expect(
      timeAtOffset(state, inset),
      timelineStart,
    );

    final earlier = timelineStart.subtract(const Duration(days: 3));
    expect(taskLeft(state, earlier), lessThan(inset));
    expect(timeAtOffset(state, 0), state.timelineEpoch);
  });

  test('timelinePastHours grows when tasks start before timelineStart', () {
    final timelineStart = DateTime(2025, 5, 12);
    final state = PlannerState(
      timelineStart: timelineStart,
      timelineScale: TimelineScale.hours,
      pixelsPerHour: 24,
      pixelsPerDay: 64,
      employees: const [Employee(id: 'e', name: 'A')],
      tasks: [
        TaskItem(
          id: 'old',
          employeeId: 'e',
          title: 'Old',
          start: timelineStart.subtract(const Duration(days: 20)),
          duration: const Duration(hours: 2),
        ),
      ],
    );

    expect(state.timelinePastHours, greaterThanOrEqualTo(20 * 24));
    expect(
      taskLeft(state, timelineStart.subtract(const Duration(days: 20))),
      0,
    );
  });
}
