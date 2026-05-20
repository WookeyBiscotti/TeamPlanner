enum TimelineScale {
  hours,
  days;

  String get label => switch (this) {
        TimelineScale.hours => 'Часы',
        TimelineScale.days => 'Дни',
      };

  static TimelineScale fromJson(String? value) {
    return value == 'days' ? TimelineScale.days : TimelineScale.hours;
  }

  String toJson() => name;
}
