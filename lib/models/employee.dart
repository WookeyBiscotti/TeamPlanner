import '../utils/calendar_ranges.dart';
import 'calendar_range.dart';

class Employee {
  const Employee({
    required this.id,
    required this.name,
    this.timeOff = const [],
  });

  final String id;
  final String name;
  /// Vacations and other time off (inclusive date ranges).
  final List<CalendarRange> timeOff;

  Employee copyWith({
    String? id,
    String? name,
    List<CalendarRange>? timeOff,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      timeOff: timeOff ?? this.timeOff,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (timeOff.isNotEmpty)
          'timeOff': timeOff.map((r) => r.toJson()).toList(),
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
    final ranges = <CalendarRange>[];
    final timeOffJson = json['timeOff'] as List<dynamic>?;
    if (timeOffJson != null) {
      for (final item in timeOffJson) {
        ranges.add(CalendarRange.fromJson(item as Map<String, dynamic>));
      }
    }
    final legacyDays = json['offDays'] as List<dynamic>?;
    if (legacyDays != null) {
      for (final d in legacyDays) {
        final key = d as String;
        ranges.add(CalendarRange(start: key, end: key));
      }
    }
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      timeOff: mergeRanges(ranges),
    );
  }
}
