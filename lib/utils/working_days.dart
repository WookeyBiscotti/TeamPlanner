import '../models/calendar_range.dart';
import '../models/planner_state.dart';
import 'calendar_dates.dart';
import 'calendar_ranges.dart';

/// Saturday and Sunday are non-working days.
bool isWeekend(DateTime date) {
  return date.weekday == DateTime.saturday ||
      date.weekday == DateTime.sunday;
}

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

bool isGlobalHoliday(DateTime date, List<CalendarRange> holidayRanges) {
  return isDateInRanges(date, holidayRanges);
}

bool isEmployeeDayOff(
  DateTime date,
  String employeeId,
  PlannerState state,
) {
  for (final employee in state.employees) {
    if (employee.id == employeeId) {
      return isDateInRanges(date, employee.timeOff);
    }
  }
  return false;
}

/// Non-working for scheduling: weekends, company holidays, and employee time off.
bool isNonWorkingDay(
  DateTime date, {
  List<CalendarRange> holidayRanges = const [],
  String? employeeId,
  PlannerState? state,
}) {
  final day = dateOnly(date);
  if (isWeekend(day)) return true;
  if (isGlobalHoliday(day, holidayRanges)) return true;
  if (employeeId != null &&
      state != null &&
      isEmployeeDayOff(day, employeeId, state)) {
    return true;
  }
  return false;
}

/// Inclusive count of working days from [start] through [end] (by calendar date).
int countWorkingDaysBetween(
  DateTime start,
  DateTime end, {
  List<CalendarRange> holidayRanges = const [],
  String? employeeId,
  PlannerState? state,
}) {
  var from = dateOnly(start);
  final to = dateOnly(end);
  if (to.isBefore(from)) return 0;

  var count = 0;
  while (!from.isAfter(to)) {
    if (!isNonWorkingDay(
      from,
      holidayRanges: holidayRanges,
      employeeId: employeeId,
      state: state,
    )) {
      count++;
    }
    from = from.add(const Duration(days: 1));
  }
  return count;
}

/// Adds [workingDays] working days starting from [start]'s calendar date (inclusive).
/// Returns the instant at the start of the calendar day after the last working day.
DateTime endAfterWorkingDays(
  DateTime start,
  int workingDays, {
  List<CalendarRange> holidayRanges = const [],
  String? employeeId,
  PlannerState? state,
}) {
  if (workingDays <= 0) return start;

  var day = dateOnly(start);
  var counted = isNonWorkingDay(
        day,
        holidayRanges: holidayRanges,
        employeeId: employeeId,
        state: state,
      )
      ? 0
      : 1;

  while (counted < workingDays) {
    day = day.add(const Duration(days: 1));
    if (!isNonWorkingDay(
      day,
      holidayRanges: holidayRanges,
      employeeId: employeeId,
      state: state,
    )) {
      counted++;
    }
  }

  final startTime = start.difference(dateOnly(start));
  return day.add(const Duration(days: 1)).add(startTime);
}

Duration calendarDurationForTask({
  required DateTime start,
  required Duration duration,
  int? workingDays,
  List<CalendarRange> holidayRanges = const [],
  String? employeeId,
  PlannerState? state,
}) {
  if (workingDays != null && workingDays > 0) {
    return endAfterWorkingDays(
      start,
      workingDays,
      holidayRanges: holidayRanges,
      employeeId: employeeId,
      state: state,
    ).difference(start);
  }
  return duration;
}
