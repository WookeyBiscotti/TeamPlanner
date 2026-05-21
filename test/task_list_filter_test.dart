import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/task_item.dart';
import 'package:planner/models/task_list_filter.dart';

void main() {
  final now = DateTime(2026, 5, 18, 9);

  final estimated = TaskItem(
    id: '1',
    title: 'A',
    estimateWorkingDays: 2,
  );
  final notEstimated = TaskItem(id: '2', title: 'B');
  final scheduled = TaskItem(
    id: '3',
    title: 'C',
    start: now,
    estimateWorkingDays: 1,
  );
  final all = [estimated, notEstimated, scheduled];

  test('no filters returns all tasks', () {
    expect(filterTasksForList(all, TaskListFilters.empty), all);
  });

  test('estimate filter', () {
    final filters = TaskListFilters(
      estimate: {TaskEstimateFilter.estimated},
    );
    expect(filterTasksForList(all, filters).map((t) => t.id), ['1', '3']);
  });

  test('schedule filter', () {
    final filters = TaskListFilters(
      schedule: {TaskScheduleFilter.notScheduled},
    );
    expect(filterTasksForList(all, filters).map((t) => t.id), ['1', '2']);
  });

  test('combined filters use AND across axes', () {
    final filters = TaskListFilters(
      estimate: {TaskEstimateFilter.estimated},
      schedule: {TaskScheduleFilter.scheduled},
    );
    expect(filterTasksForList(all, filters).map((t) => t.id), ['3']);
  });
}
