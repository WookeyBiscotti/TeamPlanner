import 'package:flutter/material.dart';

import '../models/planner_state.dart';
import '../utils/timeline_layout.dart';
import '../utils/working_days.dart';

/// Shaded columns for non-working days on the timeline.
class NonWorkingDayBackground extends StatelessWidget {
  const NonWorkingDayBackground({
    super.key,
    required this.state,
    required this.width,
    required this.height,
    this.employeeId,
  });

  final PlannerState state;
  final double width;
  final double height;
  final String? employeeId;

  static Color weekendFillColor(BuildContext context) {
    return Theme.of(context).colorScheme.error.withValues(alpha: 0.14);
  }

  static Color holidayFillColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2);
  }

  static Color employeeOffFillColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.22);
  }

  @override
  Widget build(BuildContext context) {
    final days = state.totalDayCount;
    final dayWidth = state.dayWidth;
    final weekendFill = weekendFillColor(context);
    final holidayFill = holidayFillColor(context);
    final offFill = employeeOffFillColor(context);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          for (var d = 0; d < days; d++) ...[
            if (_isWeekend(state, d))
              _column(d, dayWidth, weekendFill),
            if (_isHoliday(state, d)) _column(d, dayWidth, holidayFill),
            if (employeeId != null && _isEmployeeOff(state, employeeId!, d))
              _column(d, dayWidth, offFill),
          ],
        ],
      ),
    );
  }

  Positioned _column(int dayIndex, double dayWidth, Color color) {
    return Positioned(
      left: dayIndex * dayWidth,
      width: dayWidth,
      top: 0,
      bottom: 0,
      child: ColoredBox(color: color),
    );
  }

  DateTime _dayAt(int index) =>
      state.timelineEpoch.add(Duration(days: index));

  bool _isWeekend(PlannerState state, int d) => isWeekend(_dayAt(d));

  bool _isHoliday(PlannerState state, int d) =>
      isGlobalHoliday(_dayAt(d), state.holidayRanges);

  bool _isEmployeeOff(PlannerState state, String employeeId, int d) =>
      isEmployeeDayOff(_dayAt(d), employeeId, state);
}

/// @deprecated Use [NonWorkingDayBackground].
typedef WeekendBackground = NonWorkingDayBackground;
