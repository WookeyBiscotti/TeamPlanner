import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/planner_state.dart';
import 'package:planner/models/task_item.dart';
import 'package:planner/models/task_status.dart';
import 'package:planner/models/timeline_scale.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:planner/utils/relations_graph.dart';
import 'package:planner/utils/task_relations.dart';
import 'package:planner/utils/timeline_layout.dart';

void main() {
  test('parent cycle detection', () {
    final tasks = [
      const TaskItem(id: 'a', title: 'A'),
      const TaskItem(id: 'b', title: 'B', parentId: 'a'),
      const TaskItem(id: 'c', title: 'C', parentId: 'b'),
    ];
    expect(
      wouldCreateParentCycle(taskId: 'a', newParentId: 'c', tasks: tasks),
      isTrue,
    );
    expect(
      wouldCreateParentCycle(taskId: 'c', newParentId: 'a', tasks: tasks),
      isFalse,
    );
  });

  test('blocker incomplete blocks task', () {
    final tasks = [
      const TaskItem(id: 'a', title: 'A'),
      const TaskItem(id: 'b', title: 'B', blockedByIds: ['a']),
    ];
    expect(isBlockedByIncomplete(tasks[1], tasks), isTrue);
    final done = [
      const TaskItem(id: 'a', title: 'A', status: TaskStatus.closed),
      const TaskItem(id: 'b', title: 'B', blockedByIds: ['a']),
    ];
    expect(isBlockedByIncomplete(done[1], done), isFalse);
  });

  test('earliestStartAfterBlockers uses latest blocker end', () {
    final blockerStart = DateTime(2025, 5, 12, 9);
    final tasks = [
      TaskItem(
        id: 'a',
        title: 'A',
        employeeId: 'e',
        start: blockerStart,
        duration: const Duration(hours: 6),
      ),
      const TaskItem(
        id: 'b',
        title: 'B',
        blockedByIds: ['a'],
      ),
    ];
    final min = earliestStartAfterBlockers(tasks[1], tasks)!;
    expect(min, blockerStart.add(const Duration(hours: 6)));
  });

  test('cascadeShiftBlockedTasks shifts direct dependent', () {
    final timelineStart = DateTime(2025, 5, 12);
    final state = PlannerState(
      timelineStart: timelineStart,
      timelineScale: TimelineScale.hours,
      pixelsPerHour: 24,
      pixelsPerDay: 64,
      employees: [],
      tasks: [],
    );
    final tasks = [
      TaskItem(
        id: 'a',
        title: 'A',
        employeeId: 'e',
        start: timelineStart.add(const Duration(hours: 9)),
        duration: const Duration(hours: 4),
      ),
      TaskItem(
        id: 'b',
        title: 'B',
        employeeId: 'e',
        start: timelineStart.add(const Duration(hours: 14)),
        duration: const Duration(hours: 2),
        blockedByIds: ['a'],
      ),
    ];
    final shifted = cascadeShiftBlockedTasks(
      state: state,
      tasks: tasks,
      movedTaskId: 'a',
      delta: const Duration(hours: 2),
    );
    final b = shifted.firstWhere((t) => t.id == 'b');
    expect(b.start, timelineStart.add(const Duration(hours: 16)));
  });

  test('cascadeShiftBlockedTasks propagates through chain', () {
    final timelineStart = DateTime(2025, 5, 12);
    final state = PlannerState(
      timelineStart: timelineStart,
      timelineScale: TimelineScale.hours,
      pixelsPerHour: 24,
      pixelsPerDay: 64,
      employees: [],
      tasks: [],
    );
    final tasks = [
      TaskItem(
        id: 'a',
        title: 'A',
        employeeId: 'e',
        start: timelineStart.add(const Duration(hours: 9)),
        duration: const Duration(hours: 2),
      ),
      TaskItem(
        id: 'b',
        title: 'B',
        employeeId: 'e',
        start: timelineStart.add(const Duration(hours: 12)),
        duration: const Duration(hours: 2),
        blockedByIds: ['a'],
      ),
      TaskItem(
        id: 'c',
        title: 'C',
        employeeId: 'e',
        start: timelineStart.add(const Duration(hours: 15)),
        duration: const Duration(hours: 1),
        blockedByIds: ['b'],
      ),
    ];
    final shifted = cascadeShiftBlockedTasks(
      state: state,
      tasks: tasks,
      movedTaskId: 'a',
      delta: const Duration(hours: 3),
    );
    expect(
      shifted.firstWhere((t) => t.id == 'b').start,
      timelineStart.add(const Duration(hours: 15)),
    );
    expect(
      shifted.firstWhere((t) => t.id == 'c').start,
      timelineStart.add(const Duration(hours: 18)),
    );
  });

  test('clampTaskStart moves start after blocker', () {
    final timelineStart = DateTime(2025, 5, 12);
    final state = PlannerState(
      timelineStart: timelineStart,
      timelineScale: TimelineScale.hours,
      pixelsPerHour: 24,
      pixelsPerDay: 64,
      employees: [],
      tasks: [],
    );
    final tasks = [
      TaskItem(
        id: 'a',
        title: 'A',
        employeeId: 'e',
        start: timelineStart.add(const Duration(hours: 9)),
        duration: const Duration(hours: 4),
      ),
      TaskItem(
        id: 'b',
        title: 'B',
        employeeId: 'e',
        start: timelineStart,
        duration: const Duration(hours: 2),
        blockedByIds: ['a'],
      ),
    ];
    final clamped = clampTaskStart(
      state,
      tasks[1],
      timelineStart.add(const Duration(hours: 10)),
      tasks,
    );
    expect(
      clamped.isBefore(tasks[0].start!.add(const Duration(hours: 4))),
      isFalse,
    );
  });

  test('buildTaskTree nests children', () {
    final tasks = [
      const TaskItem(id: 'p', title: 'Parent'),
      const TaskItem(id: 'c', title: 'Child', parentId: 'p'),
    ];
    final tree = buildTaskTree(tasks);
    expect(tree.length, 2);
    expect(tree[0].task.id, 'p');
    expect(tree[1].depth, 1);
  });

  test('buildParentGroupDisplays groups children in container', () {
    final tasks = [
      const TaskItem(id: 'p', title: 'Parent'),
      const TaskItem(id: 'c', title: 'Child', parentId: 'p'),
      const TaskItem(id: 'solo', title: 'Solo'),
    ];
    final groups = buildParentGroupDisplays(tasks);
    expect(groups.length, 2);
    final parentGroup = groups.firstWhere((g) => g.root.id == 'p');
    expect(parentGroup.isContainer, isTrue);
    expect(parentGroup.children.map((t) => t.id), ['c']);
    final solo = groups.firstWhere((g) => g.root.id == 'solo');
    expect(solo.isContainer, isFalse);
  });

  test('buildBlockerEdges lists blocker to dependent', () {
    final tasks = [
      const TaskItem(id: 'a', title: 'A'),
      const TaskItem(id: 'b', title: 'B', blockedByIds: ['a']),
    ];
    final edges = buildBlockerEdges(tasks);
    expect(edges.length, 1);
    expect(edges.first.fromId, 'a');
    expect(edges.first.toId, 'b');
  });

  test('buildRelationsGraph adds parent, blocker, and orphan nodes', () {
    final tasks = [
      const TaskItem(id: 'p', title: 'Parent'),
      const TaskItem(id: 'c', title: 'Child', parentId: 'p'),
      const TaskItem(id: 'solo', title: 'Solo'),
      const TaskItem(id: 'b', title: 'Blocked', blockedByIds: ['solo']),
    ];
    final data = buildRelationsGraph(
      tasks: tasks,
      parentEdgeColor: Colors.grey,
      blockerEdgeColor: Colors.red,
    );
    expect(data.graph.nodeCount(), 5); // 4 tasks + hub
    expect(data.graph.getEdgeBetween(Node.Id('p'), Node.Id('c')), isNotNull);
    expect(data.graph.getEdgeBetween(Node.Id('solo'), Node.Id('b')), isNotNull);
    expect(data.tasksById['solo']?.title, 'Solo');
    expect(
      data.graph.getEdgeBetween(Node.Id(relationsGraphHubId), Node.Id('solo')),
      isNotNull,
    );
  });

  test('buildRelationsGraph links unrelated tasks via hub', () {
    final tasks = [
      const TaskItem(id: 'a', title: 'A'),
      const TaskItem(id: 'b', title: 'B'),
      const TaskItem(id: 'c', title: 'C'),
    ];
    final data = buildRelationsGraph(
      tasks: tasks,
      parentEdgeColor: Colors.grey,
      blockerEdgeColor: Colors.red,
    );
    expect(data.graph.nodeCount(), 4);
    for (final id in ['a', 'b', 'c']) {
      expect(
        data.graph.getEdgeBetween(Node.Id(relationsGraphHubId), Node.Id(id)),
        isNotNull,
        reason: 'orphan $id must connect to hub',
      );
    }
  });
}
