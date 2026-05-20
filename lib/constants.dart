const double kRowHeight = 48;
const double kLaneBarHeight = 28;
const double kLaneGap = 3;
const double kGanttRowPaddingV = 5;
const double kSidebarWidth = 220;
const double kTimeHeaderHeight = 56;
const int kVisibleHours = 336; // 2 weeks in hour scale
const int kVisibleDays = 56; // 8 weeks in day scale
/// Scrollable history before [PlannerState.timelineStart].
const int kTimelinePastHours = 336; // 2 weeks in hour scale
const int kTimelinePastDays = 56; // 8 weeks in day scale
const int kDefaultPixelsPerHour = 24;
const int kDefaultPixelsPerDay = 64;
const double kTasksPanelDefaultHeight = 280;
const double kTasksPanelMinHeight = 140;
const double kTasksPanelMaxHeight = 640;
const double kTasksListWidth = 280;

/// Minimum row height; grows when stacked task lanes are needed.
double employeeGanttRowHeight(int laneCount) {
  if (laneCount <= 0) return kRowHeight;
  final tracks =
      laneCount * kLaneBarHeight + (laneCount - 1) * kLaneGap;
  final h = kGanttRowPaddingV * 2 + tracks;
  return h > kRowHeight ? h : kRowHeight;
}

double laneTopOffset(int laneIndex) {
  return kGanttRowPaddingV + laneIndex * (kLaneBarHeight + kLaneGap);
}

