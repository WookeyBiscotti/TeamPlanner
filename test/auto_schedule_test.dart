import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/employee.dart';
import 'package:planner/models/planner_state.dart';
import 'package:planner/models/task_item.dart';
import 'package:planner/models/task_status.dart';
import 'package:planner/models/timeline_scale.dart';
import 'package:planner/utils/auto_schedule.dart';
import 'package:planner/utils/task_relations.dart';

void main() {
  final timelineStart = DateTime(2025, 5, 12);
  final emp1 = Employee(id: 'e1', name: 'A');
  final emp2 = Employee(id: 'e2', name: 'B');

  PlannerState baseState(List<TaskItem> tasks) => PlannerState(
        timelineStart: timelineStart,
        timelineScale: TimelineScale.hours,
        pixelsPerHour: 24,
        pixelsPerDay: 64,
        employees: [emp1, emp2],
        tasks: tasks,
      );

  test('schedules estimated backlog tasks on assigned employee', () {
    final state = baseState([
      const TaskItem(
        id: 't1',
        title: 'Task',
        employeeId: 'e1',
        estimateWorkingDays: 2,
      ),
    ]);

    final result = computeAutoSchedule(state);
    expect(result.ok, isTrue);
    expect(result.scheduledCount, 1);

    final scheduled = result.tasks.first;
    expect(scheduled.isOnTimeline, isTrue);
    expect(scheduled.employeeId, 'e1');
    expect(scheduled.workingDays, 2);
    expect(scheduled.start, timelineStart.add(const Duration(hours: 9)));
  });

  test('dependent starts after blocker ends', () {
    final state = baseState([
      const TaskItem(
        id: 'a',
        title: 'Blocker',
        employeeId: 'e1',
        estimateWorkingDays: 1,
      ),
      const TaskItem(
        id: 'b',
        title: 'Dependent',
        employeeId: 'e1',
        estimateWorkingDays: 1,
        blockedByIds: ['a'],
      ),
    ]);

    final result = computeAutoSchedule(state);
    expect(result.ok, isTrue);

    final a = result.tasks.firstWhere((t) => t.id == 'a');
    final b = result.tasks.firstWhere((t) => t.id == 'b');
    final aEnd = taskScheduledEnd(a, state: state)!;
    expect(b.start!.isBefore(aEnd), isFalse);
  });

  test('assigns unassigned task to earliest-free employee', () {
    final state = baseState([
      TaskItem(
        id: 'busy',
        title: 'Busy',
        employeeId: 'e1',
        start: timelineStart.add(const Duration(hours: 9)),
        duration: const Duration(days: 5),
        workingDays: 3,
        estimateWorkingDays: 3,
      ),
      const TaskItem(
        id: 'free',
        title: 'Free',
        estimateWorkingDays: 1,
      ),
    ]);

    final result = computeAutoSchedule(state);
    final free = result.tasks.firstWhere((t) => t.id == 'free');
    expect(free.employeeId, 'e2');
    expect(free.isOnTimeline, isTrue);
  });

  test('detects blocker cycles', () {
    final state = baseState([
      const TaskItem(
        id: 'a',
        title: 'A',
        estimateWorkingDays: 1,
        blockedByIds: ['b'],
      ),
      const TaskItem(
        id: 'b',
        title: 'B',
        estimateWorkingDays: 1,
        blockedByIds: ['a'],
      ),
    ]);

    final result = computeAutoSchedule(state);
    expect(result.ok, isFalse);
    expect(result.error, isNotNull);
  });

  test('schedules parent when children have no estimate', () {
    final state = baseState([
      const TaskItem(
        id: 'parent',
        title: 'Epic',
        employeeId: 'e1',
        estimateWorkingDays: 3,
      ),
      const TaskItem(id: 'child', title: 'Child', parentId: 'parent'),
    ]);

    final result = computeAutoSchedule(state);
    expect(result.ok, isTrue);
    expect(result.scheduledCount, 1);
    expect(
      result.tasks.firstWhere((t) => t.id == 'parent').isOnTimeline,
      isTrue,
    );
  });

  test('schedules children not parent when children have estimates', () {
    final state = baseState([
      const TaskItem(
        id: 'parent',
        title: 'Epic',
        employeeId: 'e1',
        estimateWorkingDays: 5,
      ),
      const TaskItem(
        id: 'child',
        title: 'Child',
        parentId: 'parent',
        employeeId: 'e1',
        estimateWorkingDays: 2,
      ),
    ]);

    final result = computeAutoSchedule(state);
    expect(result.scheduledCount, 1);
    expect(
      result.tasks.firstWhere((t) => t.id == 'parent').isOnTimeline,
      isFalse,
    );
    expect(
      result.tasks.firstWhere((t) => t.id == 'child').isOnTimeline,
      isTrue,
    );
  });

  test('skips when all estimated work is effectively done', () {
    final state = baseState([
      const TaskItem(
        id: 'parent',
        title: 'Epic',
        employeeId: 'e1',
        estimateWorkingDays: 3,
        status: TaskStatus.closed,
      ),
      const TaskItem(
        id: 'child',
        title: 'Child',
        parentId: 'parent',
        status: TaskStatus.closed,
      ),
    ]);

    final result = computeAutoSchedule(state);
    expect(result.scheduledCount, 0);
    expect(result.error, isNotNull);
  });

  test('skips completed estimated tasks', () {
    final state = baseState([
      const TaskItem(
        id: 'done',
        title: 'Done',
        estimateWorkingDays: 2,
        status: TaskStatus.closed,
      ),
      const TaskItem(
        id: 'open',
        title: 'Open',
        employeeId: 'e1',
        estimateWorkingDays: 1,
      ),
    ]);

    final result = computeAutoSchedule(state);
    expect(result.scheduledCount, 1);
    expect(result.tasks.firstWhere((t) => t.id == 'done').isOnTimeline, isFalse);
  });

  test('rejects when estimated task depends on unestimated blocker', () {
    final state = baseState([
      const TaskItem(id: 'blocker', title: 'Блокер без оценки'),
      const TaskItem(
        id: 'dep',
        title: 'Зависимая',
        employeeId: 'e1',
        estimateWorkingDays: 1,
        blockedByIds: ['blocker'],
      ),
    ]);

    final result = computeAutoSchedule(state);
    expect(result.ok, isFalse);
    expect(result.error, contains('Блокер без оценки'));
    expect(result.error, contains('Зависимая'));
    expect(result.scheduledCount, 0);
  });

  test('plans when blocker has estimate', () {
    final state = baseState([
      const TaskItem(
        id: 'blocker',
        title: 'Blocker',
        employeeId: 'e1',
        estimateWorkingDays: 1,
      ),
      const TaskItem(
        id: 'dep',
        title: 'Dep',
        employeeId: 'e1',
        estimateWorkingDays: 1,
        blockedByIds: ['blocker'],
      ),
    ]);

    final result = computeAutoSchedule(state);
    expect(result.ok, isTrue);
    expect(result.scheduledCount, 2);

    final blocker = result.tasks.firstWhere((t) => t.id == 'blocker');
    final dep = result.tasks.firstWhere((t) => t.id == 'dep');
    expect(dep.start!.isBefore(taskScheduledEnd(blocker, state: state)!), isFalse);
  });
}
