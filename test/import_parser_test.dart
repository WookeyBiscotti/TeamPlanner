import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/employee.dart';
import 'package:planner/models/parsed_task_import.dart';
import 'package:planner/models/planner_state.dart';
import 'package:planner/models/task_item.dart';
import 'package:planner/services/import_parser.dart';

void main() {
  test('parses JSON array of tasks', () {
    final result = parseImportJson([
      {'id': 'a', 'title': 'Задача A'},
      {
        'title': 'Задача B',
        'description': 'описание',
        'externalDescriptionUrl': 'https://tracker/issue/2',
      },
    ]);

    expect(result.kind, ImportKind.mergeTasks);
    expect(result.parsedTasks, hasLength(2));
    expect(result.parsedTasks![0].task.title, 'Задача A');
    expect(result.parsedTasks![1].task.title, 'Задача B');
    expect(
      result.parsedTasks![1].task.externalDescriptionUrl,
      'https://tracker/issue/2',
    );
  });

  test('parses employeeName from task', () {
    final result = parseImportJson([
      {
        'id': 'a',
        'title': 'T',
        'employeeName': 'Иван',
      },
    ]);

    expect(result.parsedTasks!.single.employeeName, 'Иван');
  });

  test('resolves employee name from file employees list', () {
    final result = parseImportJson({
      'employees': [
        {'id': 'e1', 'name': 'Мария'},
      ],
      'tasks': [
        {'id': 't1', 'title': 'Task', 'employeeId': 'e1'},
      ],
    });

    expect(result.parsedTasks!.single.employeeName, 'Мария');
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
    expect(result.parsedTasks, hasLength(1));
  });

  test('collectImportEmployeeNames skips valid project ids', () {
    const imports = [
      ParsedTaskImport(
        task: TaskItem(id: '1', title: 'T', employeeId: 'emp-1'),
      ),
    ];
    expect(collectImportEmployeeNames(imports, {'emp-1'}), isEmpty);
  });

  test('collectImportEmployeeNames includes unknown names', () {
    const imports = [
      ParsedTaskImport(
        task: TaskItem(id: '1', title: 'T'),
        employeeName: 'Внешний',
      ),
    ];
    expect(collectImportEmployeeNames(imports, {'emp-1'}), ['Внешний']);
  });

  test('resolveEmployeeMappingForImport prefers saved mapping', () {
    const employees = [
      Employee(id: 'e1', name: 'Алексей'),
      Employee(id: 'e2', name: 'Мария'),
    ];
    final mapping = resolveEmployeeMappingForImport(
      importNames: ['Внешний', 'Мария'],
      savedMapping: {'Внешний': 'e1'},
      projectEmployees: employees,
    );
    expect(mapping['Внешний'], 'e1');
    expect(mapping['Мария'], 'e2');
  });

  test('resolveEmployeeMappingForImport keeps explicit null assign', () {
    const employees = [Employee(id: 'e1', name: 'Алексей')];
    final mapping = resolveEmployeeMappingForImport(
      importNames: ['Игнор'],
      savedMapping: {'Игнор': null},
      projectEmployees: employees,
    );
    expect(mapping['Игнор'], isNull);
  });

  test('suggestEmployeeMapping matches by name', () {
    const employees = [
      Employee(id: 'e1', name: 'Алексей'),
      Employee(id: 'e2', name: 'Мария'),
    ];
    final mapping = suggestEmployeeMapping(['алексей', 'Пётр'], employees);
    expect(mapping['алексей'], 'e1');
    expect(mapping['Пётр'], isNull);
  });

  test('applyEmployeeNameMapping assigns project employee', () {
    final imports = [
      ParsedTaskImport(
        task: TaskItem(
          id: '1',
          title: 'T',
          start: DateTime(2025, 6, 2),
        ),
        employeeName: 'Иван',
      ),
    ];
    final tasks = applyEmployeeNameMapping(
      imports,
      {'Иван': 'emp-1'},
      {'emp-1'},
    );
    expect(tasks.single.employeeId, 'emp-1');
    expect(tasks.single.start, isNotNull);
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
