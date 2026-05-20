/// Converts [duration] to hours for text fields (e.g. 90 min → "1.5").
String durationToHoursField(Duration? duration) {
  if (duration == null || duration.inMinutes <= 0) return '';
  final hours = duration.inMinutes / 60;
  if (hours == hours.roundToDouble()) {
    return hours.toInt().toString();
  }
  return hours.toStringAsFixed(1);
}

/// Parses hours from a text field; empty → null.
Duration? parseDurationHoursField(String text) {
  final trimmed = text.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) return null;
  final hours = double.tryParse(trimmed);
  if (hours == null || hours < 0) return null;
  if (hours == 0) return null;
  return Duration(minutes: (hours * 60).round());
}

String workingDaysToField(int? days) {
  if (days == null || days <= 0) return '';
  return '$days';
}

int? parseWorkingDaysField(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final days = int.tryParse(trimmed);
  if (days == null || days <= 0) return null;
  return days;
}

String formatWorkingDays(int? days, {String empty = '—'}) {
  if (days == null || days <= 0) return empty;
  return '$days раб. дн.';
}

String formatDurationHours(Duration? duration, {String empty = '—'}) {
  if (duration == null || duration.inMinutes <= 0) return empty;
  final hours = duration.inMinutes / 60;
  if (hours == hours.roundToDouble()) {
    return '${hours.toInt()} ч';
  }
  return '${hours.toStringAsFixed(1)} ч';
}
