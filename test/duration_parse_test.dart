import 'package:flutter_test/flutter_test.dart';
import 'package:planner/utils/duration_parse.dart';

void main() {
  test('parseDurationHoursField accepts decimals', () {
    expect(parseDurationHoursField('2.5')?.inMinutes, 150);
    expect(parseDurationHoursField(''), isNull);
    expect(parseDurationHoursField('0'), isNull);
  });

  test('durationToHoursField round-trips integers', () {
    expect(durationToHoursField(const Duration(hours: 4)), '4');
    expect(
      durationToHoursField(const Duration(minutes: 90)),
      '1.5',
    );
  });
}
