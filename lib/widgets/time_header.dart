import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/planner_state.dart';
import '../utils/timeline_layout.dart';
import '../utils/working_days.dart';
import 'range_select_marker.dart';
import 'weekend_background.dart';

class TimeHeader extends StatelessWidget {
  const TimeHeader({
    super.key,
    required this.state,
    required this.width,
    this.onDayLongPress,
    this.rangeSelectStart,
  });

  final PlannerState state;
  final double width;
  final void Function(DateTime day)? onDayLongPress;
  final DateTime? rangeSelectStart;

  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = state.totalDayCount;
    final dayWidth = state.dayWidth;

    return SizedBox(
      height: kTimeHeaderHeight,
      width: width,
      child: Stack(
        children: [
          NonWorkingDayBackground(
            state: state,
            width: width,
            height: kTimeHeaderHeight,
          ),
          if (rangeSelectStart != null)
            RangeSelectMarker(
              state: state,
              anchor: rangeSelectStart!,
              width: width,
              height: kTimeHeaderHeight,
            ),
          for (var d = 0; d < days; d++)
            _DayLabel(
              left: d * dayWidth,
              width: dayWidth,
              label: _dayLabel(
                state.timelineEpoch.add(Duration(days: d)),
              ),
              day: state.timelineEpoch.add(Duration(days: d)),
              isWeekend: isWeekend(
                state.timelineEpoch.add(Duration(days: d)),
              ),
              isHoliday: isGlobalHoliday(
                state.timelineEpoch.add(Duration(days: d)),
                state.holidayRanges,
              ),
              theme: theme,
              onLongPress: onDayLongPress,
            ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime day) {
    final weekday = _weekdays[day.weekday - 1];
    final date =
        '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}';
    return '$weekday $date';
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({
    required this.left,
    required this.width,
    required this.label,
    required this.day,
    required this.isWeekend,
    required this.isHoliday,
    required this.theme,
    this.onLongPress,
  });

  final double left;
  final double width;
  final String label;
  final DateTime day;
  final bool isWeekend;
  final bool isHoliday;
  final ThemeData theme;
  final void Function(DateTime day)? onLongPress;

  Color? get _labelColor {
    if (isWeekend) return theme.colorScheme.error;
    if (isHoliday) return theme.colorScheme.tertiary;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      width: width,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress:
            onLongPress == null ? null : () => onLongPress!(day),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.dividerColor),
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _labelColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
