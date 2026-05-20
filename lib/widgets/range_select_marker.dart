import 'package:flutter/material.dart';

import '../models/planner_state.dart';
import '../utils/timeline_layout.dart';
import '../utils/working_days.dart';

/// Highlights the anchor day while the user picks a range end.
class RangeSelectMarker extends StatelessWidget {
  const RangeSelectMarker({
    super.key,
    required this.state,
    required this.anchor,
    required this.width,
    required this.height,
  });

  final PlannerState state;
  final DateTime anchor;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dayWidth = state.dayWidth;
    final anchorDay = dateOnly(anchor);
    final epochDay = dateOnly(state.timelineEpoch);
    final index = anchorDay.difference(epochDay).inDays;
    if (index < 0 || index >= state.totalDayCount) {
      return const SizedBox.shrink();
    }

    final color = Theme.of(context).colorScheme.primary;
    return Positioned(
      left: index * dayWidth,
      width: dayWidth,
      top: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}
