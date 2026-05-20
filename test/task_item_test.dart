import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/task_item.dart';
import 'package:planner/models/task_status.dart';

void main() {
  test('backlog task has no schedule', () {
    const task = TaskItem(id: '1', title: 'Backlog');
    expect(task.isScheduled, isFalse);
    expect(task.isAssigned, isFalse);
    expect(task.isOnTimeline, isFalse);
  });

  test('assigned without start is not on timeline', () {
    const task = TaskItem(
      id: '1',
      title: 'Docs',
      employeeId: 'emp-1',
      workingDays: 2,
    );
    expect(task.isAssigned, isTrue);
    expect(task.isOnTimeline, isFalse);
    expect(task.isScheduled, isFalse);
  });

  test('timeline task needs start', () {
    final task = TaskItem(
      id: '1',
      title: 'Work',
      employeeId: 'emp-1',
      start: DateTime(2025, 5, 12, 9),
    );
    expect(task.isOnTimeline, isTrue);
    expect(task.isScheduled, isTrue);
  });

  test('relations round-trip json', () {
    const task = TaskItem(
      id: '1',
      title: 'T',
      parentId: 'p',
      blockedByIds: ['b1'],
      status: TaskStatus.closed,
    );
    final restored = TaskItem.fromJson(task.toJson());
    expect(restored.parentId, 'p');
    expect(restored.blockedByIds, ['b1']);
    expect(restored.status, TaskStatus.closed);
    expect(restored.isCompleted, isTrue);
  });

  test('legacy isCompleted migrates to closed status', () {
    final restored = TaskItem.fromJson({
      'id': '1',
      'title': 'T',
      'durationMinutes': 240,
      'isCompleted': true,
    });
    expect(restored.status, TaskStatus.closed);
  });

  test('color and fill pattern round-trip json', () {
    const task = TaskItem(
      id: '1',
      title: 'T',
      color: Color(0xFFEF5350),
      fillPattern: 'dots',
    );
    final restored = TaskItem.fromJson(task.toJson());
    expect(restored.color, const Color(0xFFEF5350));
    expect(restored.fillPattern, 'dots');
  });

  test('status round-trip json', () {
    const task = TaskItem(
      id: '1',
      title: 'T',
      status: TaskStatus.review,
    );
    final restored = TaskItem.fromJson(task.toJson());
    expect(restored.status, TaskStatus.review);
  });

  test('estimate and actual working days round-trip json', () {
    const task = TaskItem(
      id: '1',
      title: 'T',
      estimateWorkingDays: 3,
      actualWorkingDays: 2,
    );
    final restored = TaskItem.fromJson(task.toJson());
    expect(restored.estimateWorkingDays, 3);
    expect(restored.actualWorkingDays, 2);
  });

  test('legacy estimate minutes migrate to working days', () {
    final restored = TaskItem.fromJson({
      'id': '1',
      'title': 'T',
      'durationMinutes': 240,
      'estimateMinutes': 960,
      'actualMinutes': 480,
    });
    expect(restored.estimateWorkingDays, 2);
    expect(restored.actualWorkingDays, 1);
  });

  test('backlog task round-trips json', () {
    const task = TaskItem(
      id: '1',
      title: 'Research',
      description: 'Notes here',
    );
    final restored = TaskItem.fromJson(task.toJson());
    expect(restored.isScheduled, isFalse);
    expect(restored.description, 'Notes here');
    expect(restored.employeeId, isNull);
    expect(restored.start, isNull);
  });

  test('assigned without start round-trips json', () {
    const task = TaskItem(
      id: '1',
      title: 'Docs',
      employeeId: 'emp-1',
      workingDays: 2,
    );
    final restored = TaskItem.fromJson(task.toJson());
    expect(restored.employeeId, 'emp-1');
    expect(restored.start, isNull);
    expect(restored.isOnTimeline, isFalse);
  });
}
