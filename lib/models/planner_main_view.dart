enum PlannerMainView {
  timeline,
  relations;

  String get label => switch (this) {
        PlannerMainView.timeline => 'Таймлайн',
        PlannerMainView.relations => 'Связи',
      };
}
