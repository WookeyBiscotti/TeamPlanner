import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/planner_state.dart';
import 'package:planner/models/task_item.dart';
import 'package:planner/services/import_parser.dart';

void main() {
  test('parses JSON array of tasks', () {
    final result = parseImportJson([
      {'id': 'a', 'title': 'Задача A'},
      {'title': 'Задача B', 'description': 'описание'},
    ]);

    expect(result.kind, ImportKind.mergeTasks);
    expect(result.tasks, hasLength(2));
    expect(result.tasks![0].title, 'Задача A');
    expect(result.tasks![1].title, 'Задача B');
    expect(result.tasks![1].id, isNotEmpty);
  });

  test('parses full project export', () {
    final state = PlannerState.initial();
    final result = parseImportJson(state.toJson());

    expect(result.kind, ImportKind.fullProject);
    expect(result.project!.tasks.length, state.tasks.length);
  });

  test('parses object with tasks key only', () {
    final result = parseImportJson({
      'tasks': [
        {'id': 'x', 'title': 'Only tasks'},
      ],
    });

    expect(result.kind, ImportKind.mergeTasks);
    expect(result.tasks, hasLength(1));
  });

  test('prepareImportedTasks remaps ids and relations', () {
    const imported = [
      TaskItem(id: 'old-parent', title: 'Parent'),
      TaskItem(
        id: 'old-child',
        title: 'Child',
        parentId: 'old-parent',
        blockedByIds: ['old-parent'],
      ),
    ];

    var counter = 0;
    final prepared = prepareImportedTasks(
      imported,
      const {},
      () => 'new-${++counter}',
    );

    expect(prepared, hasLength(2));
    expect(prepared[0].id, 'new-1');
    expect(prepared[1].id, 'new-2');
    expect(prepared[1].parentId, 'new-1');
    expect(prepared[1].blockedByIds, ['new-1']);
  });

  test('prepareImportedTasks clears unknown employee', () {
    final prepared = prepareImportedTasks(
      [
        TaskItem(
          id: 't1',
          title: 'Scheduled',
          employeeId: 'unknown-emp',
          start: DateTime(2025, 6, 2, 9),
        ),
      ],
      {'emp-1'},
      () => 'new-id',
    );

    expect(prepared.single.employeeId, isNull);
    expect(prepared.single.start, isNull);
  });

  test('rejects unsupported JSON', () {
    expect(
      () => parseImportJson({'foo': 'bar'}),
      throwsFormatException,
    );
  });

  test('rejects task without title', () {
    expect(
      () => parseTasksJsonList([{'id': '1'}]),
      throwsFormatException,
    );
  });
}
