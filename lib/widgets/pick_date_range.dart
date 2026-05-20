import 'package:flutter/material.dart';

import '../models/calendar_range.dart';
import '../utils/calendar_ranges.dart';

/// Opens Material date range picker and returns normalized [CalendarRange].
Future<CalendarRange?> pickDateRange(
  BuildContext context, {
  String helpText = 'Выберите период',
  DateTime? initialStart,
  DateTime? initialEnd,
}) async {
  final now = DateTime.now();
  final picked = await showDateRangePicker(
    context: context,
    helpText: helpText,
    initialDateRange: initialStart != null && initialEnd != null
        ? DateTimeRange(start: initialStart, end: initialEnd)
        : null,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
  if (picked == null) return null;
  return normalizeRange(picked.start, picked.end);
}
