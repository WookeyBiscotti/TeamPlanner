import '../models/calendar_range.dart';
import 'calendar_dates.dart';

/// Normalizes [start] and [end] to inclusive range (start <= end).
CalendarRange normalizeRange(DateTime start, DateTime end) {
  final a = dateKey(start);
  final b = dateKey(end);
  if (a.compareTo(b) <= 0) {
    return CalendarRange(start: a, end: b);
  }
  return CalendarRange(start: b, end: a);
}

bool isDateInRanges(DateTime date, List<CalendarRange> ranges) {
  return ranges.any((r) => r.contains(date));
}

/// Expands range to individual date keys (inclusive).
List<String> expandRange(CalendarRange range) {
  final start = parseDateKey(range.start);
  final end = parseDateKey(range.end);
  if (start == null || end == null) return [];

  final keys = <String>[];
  var day = start;
  final last = end;
  while (!day.isAfter(last)) {
    keys.add(dateKey(day));
    day = day.add(const Duration(days: 1));
  }
  return keys;
}

String formatRangeRu(CalendarRange range) {
  if (range.isSingleDay) return formatDateKeyRu(range.start);
  return '${formatDateKeyRu(range.start)} — ${formatDateKeyRu(range.end)}';
}

/// Merges overlapping and adjacent ranges.
List<CalendarRange> mergeRanges(List<CalendarRange> ranges) {
  if (ranges.isEmpty) return [];

  final sorted = List<CalendarRange>.from(ranges)
    ..sort((a, b) => a.start.compareTo(b.start));

  final merged = <CalendarRange>[sorted.first];
  for (var i = 1; i < sorted.length; i++) {
    final current = sorted[i];
    final last = merged.last;
    final lastEnd = parseDateKey(last.end)!;
    final currentStart = parseDateKey(current.start)!;
    final dayAfterLast = lastEnd.add(const Duration(days: 1));

    if (!currentStart.isAfter(dayAfterLast)) {
      final newEnd = last.end.compareTo(current.end) >= 0
          ? last.end
          : current.end;
      merged[merged.length - 1] =
          CalendarRange(start: last.start, end: newEnd);
    } else {
      merged.add(current);
    }
  }
  return merged;
}

List<CalendarRange> addRange(
  List<CalendarRange> existing,
  CalendarRange added,
) {
  return mergeRanges([...existing, added]);
}

/// Removes [day] from ranges, splitting multi-day ranges when needed.
List<CalendarRange> removeDayFromRanges(
  List<CalendarRange> ranges,
  DateTime day,
) {
  final key = dateKey(day);
  final result = <CalendarRange>[];

  for (final range in ranges) {
    if (!range.containsKey(key)) {
      result.add(range);
      continue;
    }
    if (range.isSingleDay) continue;

    final start = parseDateKey(range.start)!;
    final end = parseDateKey(range.end)!;
    final dayDt = parseDateKey(key)!;

    if (dayDt.isAfter(start)) {
      final beforeEnd = dayDt.subtract(const Duration(days: 1));
      result.add(CalendarRange(start: range.start, end: dateKey(beforeEnd)));
    }
    if (dayDt.isBefore(end)) {
      final afterStart = dayDt.add(const Duration(days: 1));
      result.add(CalendarRange(start: dateKey(afterStart), end: range.end));
    }
  }
  return result;
}

/// Migrates legacy single-day list to ranges.
List<CalendarRange> rangesFromLegacyDays(List<String> days) {
  return days.map((d) => CalendarRange(start: d, end: d)).toList();
}
