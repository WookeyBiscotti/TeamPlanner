import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/calendar_range.dart';
import 'package:planner/models/employee.dart';
import 'package:planner/models/planner_state.dart';
import 'package:planner/models/timeline_scale.dart';
import 'package:planner/utils/calendar_dates.dart';
import 'package:planner/utils/calendar_ranges.dart';
import 'package:planner/utils/working_days.dart';

PlannerState _stateWith({
  List<CalendarRange> holidayRanges = const [],
  List<CalendarRange> timeOff = const [],
}) {
  return PlannerState(
    timelineStart: DateTime(2025, 5, 12),
    timelineScale: TimelineScale.days,
    pixelsPerHour: 24,
    pixelsPerDay: 64,
    employees: [
      Employee(id: 'e1', name: 'Test', timeOff: timeOff),
    ],
    tasks: const [],
    holidayRanges: holidayRanges,
  );
}

void main() {
  test('5 working days from Friday skips weekend', () {
    final friday = DateTime(2025, 5, 16, 9); // Fri
    final end = endAfterWorkingDays(friday, 5);
    expect(end, DateTime(2025, 5, 23, 9));
  });

  test('isWeekend detects Sat and Sun', () {
    expect(isWeekend(DateTime(2025, 5, 17)), isTrue);
    expect(isWeekend(DateTime(2025, 5, 18)), isTrue);
    expect(isWeekend(DateTime(2025, 5, 16)), isFalse);
  });

  test('calendarDurationForTask uses working days', () {
    final start = DateTime(2025, 5, 16, 9);
    final duration = calendarDurationForTask(
      start: start,
      duration: Duration.zero,
      workingDays: 5,
    );
    expect(duration.inHours, 24 * 7);
  });

  test('holiday range is skipped in working day count', () {
    final state = _stateWith(
      holidayRanges: [
        CalendarRange(
          start: dateKey(DateTime(2025, 5, 19)),
          end: dateKey(DateTime(2025, 5, 19)),
        ),
      ],
    );
    final friday = DateTime(2025, 5, 16, 9);
    final end = endAfterWorkingDays(
      friday,
      5,
      holidayRanges: state.holidayRanges,
      employeeId: 'e1',
      state: state,
    );
    expect(end, DateTime(2025, 5, 24, 9));
  });

  test('vacation range is skipped for employee', () {
    final state = _stateWith(
      timeOff: [
        CalendarRange(
          start: dateKey(DateTime(2025, 5, 19)),
          end: dateKey(DateTime(2025, 5, 21)),
        ),
      ],
    );
    final friday = DateTime(2025, 5, 16, 9);
    final end = endAfterWorkingDays(
      friday,
      3,
      holidayRanges: state.holidayRanges,
      employeeId: 'e1',
      state: state,
    );
    // Fri, weekend, skip Mon–Wed vacation, Thu + Fri
    expect(end, DateTime(2025, 5, 24, 9));
  });

  test('mergeRanges merges adjacent ranges', () {
    final merged = mergeRanges([
      CalendarRange(start: '2025-01-01', end: '2025-01-03'),
      CalendarRange(start: '2025-01-04', end: '2025-01-05'),
    ]);
    expect(merged.length, 1);
    expect(merged.first.start, '2025-01-01');
    expect(merged.first.end, '2025-01-05');
  });

  test('removeDayFromRanges splits multi-day range', () {
    final result = removeDayFromRanges(
      [CalendarRange(start: '2025-07-01', end: '2025-07-05')],
      DateTime(2025, 7, 3),
    );
    expect(result.length, 2);
    expect(result[0].end, '2025-07-02');
    expect(result[1].start, '2025-07-04');
  });

  test('expandRange returns inclusive days', () {
    final keys = expandRange(
      CalendarRange(start: '2025-05-01', end: '2025-05-03'),
    );
    expect(keys, ['2025-05-01', '2025-05-02', '2025-05-03']);
  });
}
