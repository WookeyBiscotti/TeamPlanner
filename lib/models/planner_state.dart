import 'calendar_range.dart';
import 'employee.dart';
import 'task_item.dart';
import 'task_status.dart';
import 'timeline_scale.dart';
import '../constants.dart';
import '../utils/calendar_ranges.dart';
import '../utils/working_days.dart';

class PlannerState {
  const PlannerState({
    required this.timelineStart,
    required this.timelineScale,
    required this.pixelsPerHour,
    required this.pixelsPerDay,
    required this.employees,
    required this.tasks,
    this.holidayRanges = const [],
  });

  final DateTime timelineStart;
  final TimelineScale timelineScale;
  final int pixelsPerHour;
  final int pixelsPerDay;
  final List<Employee> employees;
  final List<TaskItem> tasks;
  /// Company-wide non-working periods (in addition to weekends).
  final List<CalendarRange> holidayRanges;

  PlannerState copyWith({
    DateTime? timelineStart,
    TimelineScale? timelineScale,
    int? pixelsPerHour,
    int? pixelsPerDay,
    List<Employee>? employees,
    List<TaskItem>? tasks,
    List<CalendarRange>? holidayRanges,
  }) {
    return PlannerState(
      timelineStart: timelineStart ?? this.timelineStart,
      timelineScale: timelineScale ?? this.timelineScale,
      pixelsPerHour: pixelsPerHour ?? this.pixelsPerHour,
      pixelsPerDay: pixelsPerDay ?? this.pixelsPerDay,
      employees: employees ?? this.employees,
      tasks: tasks ?? this.tasks,
      holidayRanges: holidayRanges ?? this.holidayRanges,
    );
  }

  static DateTime mondayOfWeek(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  static PlannerState initial() {
    final timelineStart = mondayOfWeek(DateTime.now());
    final emp1 = Employee(id: 'demo-emp-1', name: 'Алексей');
    final emp2 = Employee(id: 'demo-emp-2', name: 'Мария');
    final day1 = timelineStart.add(const Duration(hours: 9));
    final day2 = timelineStart.add(const Duration(days: 1, hours: 10));

    return PlannerState(
      timelineStart: timelineStart,
      timelineScale: TimelineScale.hours,
      pixelsPerHour: kDefaultPixelsPerHour,
      pixelsPerDay: kDefaultPixelsPerDay,
      employees: [emp1, emp2],
      tasks: [
        TaskItem(
          id: 'demo-task-1',
          employeeId: emp1.id,
          title: 'Дизайн макета',
          start: day1,
          duration: calendarDurationForTask(
            start: day1,
            duration: Duration.zero,
            workingDays: 1,
          ),
          workingDays: 1,
          estimateWorkingDays: 1,
          actualWorkingDays: 1,
          status: TaskStatus.closed,
        ),
        TaskItem(
          id: 'demo-task-2',
          employeeId: emp1.id,
          title: 'Ревью',
          start: timelineStart.add(const Duration(days: 2, hours: 14)),
          duration: calendarDurationForTask(
            start: timelineStart.add(const Duration(days: 2, hours: 14)),
            duration: Duration.zero,
            workingDays: 1,
          ),
          workingDays: 1,
          parentId: 'demo-task-1',
          blockedByIds: ['demo-task-1'],
          status: TaskStatus.review,
        ),
        TaskItem(
          id: 'demo-task-3',
          employeeId: emp2.id,
          title: 'Backend API',
          start: day2,
          duration: const Duration(days: 3),
          workingDays: 2,
          status: TaskStatus.active,
          fillPattern: 'diagonalLight',
        ),
        TaskItem(
          id: 'demo-assigned-1',
          employeeId: emp2.id,
          title: 'Документация API',
          description: 'Без даты — только в списке задач.',
          estimateWorkingDays: 2,
          workingDays: 2,
        ),
        TaskItem(
          id: 'demo-backlog-1',
          title: 'Исследование конкурентов',
          description: 'Собрать список аналогов и сравнить функции.',
          estimateWorkingDays: 1,
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'timelineStart': timelineStart.toIso8601String(),
        'timelineScale': timelineScale.toJson(),
        'pixelsPerHour': pixelsPerHour,
        'pixelsPerDay': pixelsPerDay,
        'employees': employees.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        if (holidayRanges.isNotEmpty)
          'holidayRanges': holidayRanges.map((r) => r.toJson()).toList(),
      };

  factory PlannerState.fromJson(Map<String, dynamic> json) {
    final holidayRanges = <CalendarRange>[];
    final rangesJson = json['holidayRanges'] as List<dynamic>?;
    if (rangesJson != null) {
      for (final item in rangesJson) {
        holidayRanges.add(
          CalendarRange.fromJson(item as Map<String, dynamic>),
        );
      }
    }
    final legacyHolidays = json['holidays'] as List<dynamic>?;
    if (legacyHolidays != null) {
      for (final d in legacyHolidays) {
        final key = d as String;
        holidayRanges.add(CalendarRange(start: key, end: key));
      }
    }

    return PlannerState(
      timelineStart: DateTime.parse(json['timelineStart'] as String),
      timelineScale: TimelineScale.fromJson(json['timelineScale'] as String?),
      pixelsPerHour: json['pixelsPerHour'] as int? ?? kDefaultPixelsPerHour,
      pixelsPerDay: json['pixelsPerDay'] as int? ?? kDefaultPixelsPerDay,
      employees: (json['employees'] as List<dynamic>)
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList(),
      tasks: (json['tasks'] as List<dynamic>)
          .map((t) => TaskItem.fromJson(t as Map<String, dynamic>))
          .toList(),
      holidayRanges: mergeRanges(holidayRanges),
    );
  }
}
