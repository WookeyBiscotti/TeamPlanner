import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/employee.dart';
import '../models/planner_state.dart';
import '../models/timeline_scale.dart';
import '../models/task_fill_pattern.dart';
import '../models/task_item.dart';
import '../models/task_status.dart';
import '../services/export_service.dart';
import '../services/import_parser.dart';
import '../services/storage_service.dart';
import '../models/calendar_range.dart';
import '../utils/calendar_dates.dart';
import '../utils/calendar_ranges.dart';
import '../utils/task_colors.dart';
import '../utils/task_relations.dart';
import '../utils/timeline_layout.dart';
import '../utils/working_days.dart';

class PlannerNotifier extends ChangeNotifier {
  PlannerNotifier({
    StorageService? storageService,
    ExportService? exportService,
  })  : _storage = storageService ?? StorageService(),
        _export = exportService ?? ExportService();

  final StorageService _storage;
  final ExportService _export;
  final _uuid = const Uuid();

  PlannerState _state = PlannerState.initial();
  bool _isLoading = true;

  PlannerState get state => _state;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final saved = await _storage.load();
    if (saved != null) {
      _state = saved;
    } else {
      await _storage.save(_state);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.save(_state);
    notifyListeners();
  }

  Future<void> addEmployee(String name) async {
    final employee = Employee(id: _uuid.v4(), name: name.trim());
    if (employee.name.isEmpty) return;
    _state = _state.copyWith(employees: [..._state.employees, employee]);
    await _persist();
  }

  Future<void> updateEmployee(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _state = _state.copyWith(
      employees: _state.employees
          .map((e) => e.id == id ? e.copyWith(name: trimmed) : e)
          .toList(),
    );
    await _persist();
  }

  Future<void> removeEmployee(String id) async {
    _state = _state.copyWith(
      employees: _state.employees.where((e) => e.id != id).toList(),
      tasks: _state.tasks.where((t) => t.employeeId != id).toList(),
    );
    await _persist();
  }

  DateTime clampScheduledStart(TaskItem task, DateTime proposed) {
    return clampTaskStart(_state, task, proposed, _state.tasks);
  }

  Future<String?> addTask({
    required String employeeId,
    required String title,
    required DateTime start,
    required Duration duration,
    int? workingDays,
    String description = '',
    List<String> blockedByIds = const [],
  }) async {
    final id = _uuid.v4();
    var task = TaskItem(
      id: id,
      employeeId: employeeId,
      title: title.trim(),
      description: description,
      start: start,
      duration: duration,
      workingDays: workingDays,
      blockedByIds: blockedByIds,
      color: colorForEmployee(employeeId),
    );
    if (task.title.isEmpty) return null;
    _state = _state.copyWith(tasks: [..._state.tasks, task]);
    await _persist();
    return id;
  }

  Future<void> addBacklogTask({String title = 'Новая задача'}) async {
    final task = TaskItem(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Новая задача' : title.trim(),
    );
    _state = _state.copyWith(tasks: [..._state.tasks, task]);
    await _persist();
  }

  Future<void> updateTaskFields(
    String id, {
    String? title,
    String? description,
    int? estimateWorkingDays,
    bool clearEstimateWorkingDays = false,
    int? actualWorkingDays,
    bool clearActualWorkingDays = false,
    String? employeeId,
    bool clearEmployeeId = false,
    DateTime? start,
    bool clearStart = false,
    Duration? duration,
    int? workingDays,
    bool clearWorkingDays = false,
  }) async {
    final index = _state.tasks.indexWhere((t) => t.id == id);
    if (index < 0) return;
    final current = _state.tasks[index];
    var updated = current.copyWith(
      title: title ?? current.title,
      description: description ?? current.description,
      estimateWorkingDays: estimateWorkingDays,
      clearEstimateWorkingDays: clearEstimateWorkingDays,
      actualWorkingDays: actualWorkingDays,
      clearActualWorkingDays: clearActualWorkingDays,
      employeeId: employeeId,
      clearEmployeeId: clearEmployeeId,
      start: start,
      clearStart: clearStart,
      duration: duration,
      workingDays: workingDays,
      clearWorkingDays: clearWorkingDays,
    );
    if (updated.isOnTimeline) {
      updated = updated.copyWith(
        start: clampScheduledStart(updated, updated.start!),
        color: updated.isAssigned
            ? (updated.color ?? colorForEmployee(updated.employeeId!))
            : updated.color,
      );
    }
    if (updated.title.trim().isEmpty) return;
    await updateTask(updated);
  }

  Future<void> updateTask(TaskItem task, {bool cascadeBlockedDependents = true}) async {
    if (task.title.trim().isEmpty) return;

    final previous = taskById(_state.tasks, task.id);
    var normalized = task;
    if (normalized.isOnTimeline) {
      normalized = normalized.copyWith(
        start: clampScheduledStart(normalized, normalized.start!),
      );
    }

    var tasks = _state.tasks
        .map((t) => t.id == task.id ? normalized : t)
        .toList();

    if (cascadeBlockedDependents &&
        previous != null &&
        previous.isOnTimeline &&
        normalized.isOnTimeline &&
        previous.start != null &&
        normalized.start != null) {
      final delta = normalized.start!.difference(previous.start!);
      if (delta != Duration.zero) {
        tasks = cascadeShiftBlockedTasks(
          state: _state,
          tasks: tasks,
          movedTaskId: normalized.id,
          delta: delta,
        );
      }
    }

    _state = _state.copyWith(tasks: tasks);
    await _persist();
  }

  Future<void> scheduleTask({
    required String taskId,
    required String employeeId,
    required DateTime start,
    required Duration duration,
    int? workingDays,
    String? title,
    String? description,
  }) async {
    final index = _state.tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    final current = _state.tasks[index];
    await updateTask(
      current.copyWith(
        title: title ?? current.title,
        description: description ?? current.description,
        employeeId: employeeId,
        start: start,
        duration: duration,
        workingDays: workingDays,
        color: colorForEmployee(employeeId),
      ),
    );
  }

  Future<void> moveTaskTo(
    TaskItem task, {
    required String newEmployeeId,
    required DateTime newStart,
  }) async {
    if (!task.isOnTimeline) return;
    final clamped = clampScheduledStart(task, newStart);
    if (task.employeeId == newEmployeeId &&
        (task.start!.difference(clamped).inMinutes).abs() < 1) {
      return;
    }
    await updateTask(
      task.copyWith(
        employeeId: newEmployeeId,
        start: clamped,
        color: colorForEmployee(newEmployeeId),
      ),
    );
  }

  Future<void> removeTask(String id) async {
    _state = _state.copyWith(
      tasks: _state.tasks
          .where((t) => t.id != id)
          .map((t) {
            var updated = t;
            if (t.parentId == id) {
              updated = updated.copyWith(clearParentId: true);
            }
            if (t.blockedByIds.contains(id)) {
              updated = updated.copyWith(
                blockedByIds:
                    t.blockedByIds.where((bid) => bid != id).toList(),
              );
            }
            return updated;
          })
          .toList(),
    );
    await _persist();
  }

  Future<void> setTaskStatus(String id, TaskStatus status) async {
    final index = _state.tasks.indexWhere((t) => t.id == id);
    if (index < 0) return;
    await updateTask(_state.tasks[index].copyWith(status: status));
  }

  Future<void> setTaskAppearance(
    String id, {
    Color? color,
    bool clearColor = false,
    TaskFillPattern? fillPattern,
    bool clearFillPattern = false,
  }) async {
    final index = _state.tasks.indexWhere((t) => t.id == id);
    if (index < 0) return;
    await updateTask(
      _state.tasks[index].copyWith(
        color: color,
        clearColor: clearColor,
        fillPattern: fillPattern?.storageKey,
        clearFillPattern: clearFillPattern,
      ),
    );
  }

  Future<void> setTaskCompleted(String id, bool completed) async {
    await setTaskStatus(
      id,
      completed ? TaskStatus.closed : TaskStatus.open,
    );
  }

  Future<String?> setTaskParent(String taskId, String? parentId) async {
    if (parentId != null &&
        wouldCreateParentCycle(
          taskId: taskId,
          newParentId: parentId,
          tasks: _state.tasks,
        )) {
      return 'Нельзя сделать подзадачу своим потомком';
    }
    final index = _state.tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return 'Задача не найдена';
    await updateTask(
      _state.tasks[index].copyWith(
        parentId: parentId,
        clearParentId: parentId == null,
      ),
    );
    return null;
  }

  Future<String?> addBlocker(String taskId, String blockerId) async {
    if (wouldCreateBlockerCycle(
      taskId: taskId,
      blockerId: blockerId,
      tasks: _state.tasks,
    )) {
      return 'Циклическая зависимость блокеров';
    }
    final index = _state.tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return 'Задача не найдена';
    final task = _state.tasks[index];
    if (task.blockedByIds.contains(blockerId)) return null;
    await updateTask(
      task.copyWith(blockedByIds: [...task.blockedByIds, blockerId]),
    );
    return null;
  }

  Future<void> removeBlocker(String taskId, String blockerId) async {
    final index = _state.tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;
    final task = _state.tasks[index];
    await updateTask(
      task.copyWith(
        blockedByIds:
            task.blockedByIds.where((id) => id != blockerId).toList(),
      ),
    );
  }

  Future<void> setTimelineStart(DateTime start) async {
    _state = _state.copyWith(
      timelineStart: DateTime(start.year, start.month, start.day),
    );
    await _persist();
  }

  Future<void> goToToday() async {
    await setTimelineStart(PlannerState.mondayOfWeek(DateTime.now()));
  }

  Future<void> setTimelineScale(TimelineScale scale) async {
    _state = _state.copyWith(timelineScale: scale);
    await _persist();
  }

  /// Toggles a single company holiday on [date].
  Future<bool> toggleHoliday(DateTime date) async {
    final day = dateOnly(date);
    final wasOff = isGlobalHoliday(day, _state.holidayRanges);
    final ranges = wasOff
        ? removeDayFromRanges(_state.holidayRanges, day)
        : addRange(_state.holidayRanges, CalendarRange.single(day));
    _state = _state.copyWith(holidayRanges: ranges);
    await _persist();
    await _recalculateAllWorkingDayTasks();
    return !wasOff;
  }

  Future<void> addHolidayRange(CalendarRange range) async {
    _state = _state.copyWith(
      holidayRanges: addRange(_state.holidayRanges, range),
    );
    await _persist();
    await _recalculateAllWorkingDayTasks();
  }

  Future<void> removeHolidayRange(CalendarRange range) async {
    _state = _state.copyWith(
      holidayRanges: _state.holidayRanges
          .where((r) => r.start != range.start || r.end != range.end)
          .toList(),
    );
    await _persist();
    await _recalculateAllWorkingDayTasks();
  }

  /// Toggles a single day off for [employeeId].
  Future<bool> toggleEmployeeOffDay(String employeeId, DateTime date) async {
    final day = dateOnly(date);
    var added = false;
    final employees = _state.employees.map((e) {
      if (e.id != employeeId) return e;
      if (isDateInRanges(day, e.timeOff)) {
        added = false;
        return e.copyWith(timeOff: removeDayFromRanges(e.timeOff, day));
      }
      added = true;
      return e.copyWith(
        timeOff: addRange(e.timeOff, CalendarRange.single(day)),
      );
    }).toList();
    _state = _state.copyWith(employees: employees);
    await _persist();
    await _recalculateTasksForEmployee(employeeId);
    return added;
  }

  Future<void> addEmployeeTimeOffRange(
    String employeeId,
    CalendarRange range,
  ) async {
    final employees = _state.employees.map((e) {
      if (e.id != employeeId) return e;
      return e.copyWith(timeOff: addRange(e.timeOff, range));
    }).toList();
    _state = _state.copyWith(employees: employees);
    await _persist();
    await _recalculateTasksForEmployee(employeeId);
  }

  Future<void> removeEmployeeTimeOffRange(
    String employeeId,
    CalendarRange range,
  ) async {
    final employees = _state.employees.map((e) {
      if (e.id != employeeId) return e;
      return e.copyWith(
        timeOff: e.timeOff
            .where((r) => r.start != range.start || r.end != range.end)
            .toList(),
      );
    }).toList();
    _state = _state.copyWith(employees: employees);
    await _persist();
    await _recalculateTasksForEmployee(employeeId);
  }

  Future<void> _recalculateAllWorkingDayTasks() async {
    for (final employee in _state.employees) {
      await _recalculateTasksForEmployee(employee.id);
    }
  }

  Future<void> _recalculateTasksForEmployee(String employeeId) async {
    var tasks = List<TaskItem>.from(_state.tasks);
    var changed = false;
    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      if (!task.isOnTimeline ||
          task.employeeId != employeeId ||
          task.workingDays == null ||
          task.workingDays! <= 0) {
        continue;
      }
      final newDuration = calendarDurationForTask(
        start: task.start!,
        duration: task.duration,
        workingDays: task.workingDays,
        holidayRanges: _state.holidayRanges,
        employeeId: employeeId,
        state: _state,
      );
      if (newDuration != task.duration) {
        tasks[i] = task.copyWith(duration: newDuration);
        changed = true;
      }
    }
    if (changed) {
      _state = _state.copyWith(tasks: tasks);
      await _storage.save(_state);
      notifyListeners();
    }
  }

  Future<String?> exportState() => _export.saveProjectJson(_state);

  Future<String?> importState() async {
    try {
      final parsed = await _export.pickAndParseImport();
      if (parsed == null) return null;

      switch (parsed.kind) {
        case ImportKind.fullProject:
          _state = parsed.project!;
          await _persist();
          return 'Проект импортирован';
        case ImportKind.mergeTasks:
          final tasks = parsed.tasks!;
          if (tasks.isEmpty) return 'Файл не содержит задач';
          final employeeIds = _state.employees.map((e) => e.id).toSet();
          final prepared = prepareImportedTasks(
            tasks,
            employeeIds,
            () => _uuid.v4(),
          );
          _state = _state.copyWith(
            tasks: [..._state.tasks, ...prepared],
          );
          await _persist();
          return 'Добавлено задач: ${prepared.length}';
      }
    } on FormatException catch (e) {
      return e.message;
    } catch (e) {
      return 'Ошибка импорта: $e';
    }
  }

  List<TaskItem> scheduledTasksForEmployee(String employeeId) {
    return _state.tasks
        .where((t) => t.isOnTimeline && t.employeeId == employeeId)
        .toList();
  }

  List<TaskItem> get allTasks => List.unmodifiable(_state.tasks);

  List<TaskItem> get scheduledTasks =>
      _state.tasks.where((t) => t.isOnTimeline).toList();

  List<TaskItem> get backlogTasks =>
      _state.tasks.where((t) => !t.isOnTimeline).toList();
}
