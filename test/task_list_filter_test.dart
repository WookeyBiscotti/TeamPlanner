import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/task_item.dart';
import 'package:planner/models/task_list_filter.dart';
import 'package:planner/utils/task_schedule_fields.dart';

void main() {
  final now = DateTime(2026, 5, 18, 9);

  final estimated = TaskItem(
    id: '1',
    title: 'A',
    estimateWorkingDays: 2,
  );
  final notEstimated = TaskItem(id: '2', title: 'B');
  final actualOnly = TaskItem(
    id: '4',
    title: 'D',
    actualWorkingDays: 1,
  );
  final timelineDaysOnly = TaskItem(
    id: '5',
    title: 'E',
    start: now,
    workingDays: 3,
    duration: const Duration(hours: 24),
  );
  final scheduled = TaskItem(
    id: '3',
    title: 'C',
    start: now,
    estimateWorkingDays: 1,
  );
  final all = [
    estimated,
    notEstimated,
    scheduled,
    actualOnly,
    timelineDaysOnly,
  ];

  test('no filters returns all tasks', () {
    expect(filterTasksForList(all, TaskListFilters.empty), all);
  });

  test('estimate filter uses planned estimate only', () {
    final filters = TaskListFilters(
      estimate: {TaskEstimateFilter.estimated},
    );
    expect(
      filterTasksForList(all, filters).map((t) => t.id),
      ['1', '3'],
    );
  });

  test('timeline workingDays without estimate is not in estimate filter', () {
    expect(taskHasPlannedEstimate(timelineDaysOnly), isFalse);
    expect(taskHasLaborData(timelineDaysOnly), isTrue);
    final filters = TaskListFilters(
      estimate: {TaskEstimateFilter.estimated},
    );
    expect(filterTasksForList([timelineDaysOnly], filters), isEmpty);
  });

  test('not estimated filter excludes planned estimate', () {
    final filters = TaskListFilters(
      estimate: {TaskEstimateFilter.notEstimated},
    );
    expect(filterTasksForList(all, filters).map((t) => t.id), ['2', '4', '5']);
  });

  test('schedule filter', () {
    final filters = TaskListFilters(
      schedule: {TaskScheduleFilter.notScheduled},
    );
    expect(filterTasksForList(all, filters).map((t) => t.id), ['1', '2', '4']);
  });

  test('scheduled filter requires timeline start', () {
    final filters = TaskListFilters(
      schedule: {TaskScheduleFilter.scheduled},
    );
    expect(filterTasksForList(all, filters).map((t) => t.id), ['3', '5']);
  });

  test('combined filters use AND across axes', () {
    final filters = TaskListFilters(
      estimate: {TaskEstimateFilter.estimated},
      schedule: {TaskScheduleFilter.scheduled},
    );
    expect(filterTasksForList(all, filters).map((t) => t.id), ['3']);
  });
}
