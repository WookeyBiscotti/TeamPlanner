import '../utils/calendar_dates.dart';

/// Inclusive calendar date range (`yyyy-MM-dd`).
class CalendarRange {
  const CalendarRange({required this.start, required this.end});

  final String start;
  final String end;

  bool get isSingleDay => start == end;

  bool contains(DateTime date) {
    final key = dateKey(date);
    return key.compareTo(start) >= 0 && key.compareTo(end) <= 0;
  }

  bool containsKey(String key) =>
      key.compareTo(start) >= 0 && key.compareTo(end) <= 0;

  CalendarRange copyWith({String? start, String? end}) {
    return CalendarRange(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  factory CalendarRange.fromJson(Map<String, dynamic> json) {
    return CalendarRange(
      start: json['start'] as String,
      end: json['end'] as String,
    );
  }

  factory CalendarRange.single(DateTime date) {
    final key = dateKey(date);
    return CalendarRange(start: key, end: key);
  }
}
