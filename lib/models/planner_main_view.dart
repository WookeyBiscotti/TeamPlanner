enum PlannerMainView {
  timeline,
  relations,
  tasks;

  String get label => switch (this) {
        PlannerMainView.timeline => 'Таймлайн',
        PlannerMainView.relations => 'Связи',
        PlannerMainView.tasks => 'Задачи',
      };
}
