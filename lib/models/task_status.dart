enum TaskStatus {
  open,
  active,
  review,
  closed;

  String get label => switch (this) {
        TaskStatus.open => 'Открыта',
        TaskStatus.active => 'В работе',
        TaskStatus.review => 'На ревью',
        TaskStatus.closed => 'Закрыта',
      };

  static TaskStatus fromJson(String? raw) {
    if (raw == null) return TaskStatus.open;
    return TaskStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => TaskStatus.open,
    );
  }
}
