import 'package:flutter_test/flutter_test.dart';
import 'package:planner/models/calendar_range.dart';
import 'package:planner/models/employee.dart';
import 'package:planner/utils/calendar_ranges.dart';

void main() {
  test('Employee migrates legacy offDays to timeOff ranges', () {
    final employee = Employee.fromJson({
      'id': 'e1',
      'name': 'Ann',
      'offDays': ['2025-08-01', '2025-08-05'],
    });
    expect(employee.timeOff.length, 2);
    expect(employee.timeOff[0].start, '2025-08-01');
    expect(employee.timeOff[1].start, '2025-08-05');
  });

  test('normalizeRange swaps inverted dates', () {
    final range = normalizeRange(
      DateTime(2025, 8, 10),
      DateTime(2025, 8, 5),
    );
    expect(range.start, '2025-08-05');
    expect(range.end, '2025-08-10');
  });
}
