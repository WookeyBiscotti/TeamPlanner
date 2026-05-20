/// Calendar date keys in `yyyy-MM-dd` form (local date, no time).
String dateKey(DateTime dt) {
  final d = DateTime(dt.year, dt.month, dt.day);
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

DateTime? parseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

String formatDateKeyRu(String key) {
  final dt = parseDateKey(key);
  if (dt == null) return key;
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  return '$day.$month.${dt.year}';
}
