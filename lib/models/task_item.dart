import 'package:flutter/material.dart';

import 'task_status.dart';

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.externalDescriptionUrl = '',
    this.employeeId,
    this.start,
    this.duration = const Duration(hours: 4),
    this.workingDays,
    this.color,
    this.fillPattern,
    this.parentId,
    this.blockedByIds = const [],
    this.status = TaskStatus.open,
    this.estimateWorkingDays,
    this.actualWorkingDays,
    this.effortUnit,
  });

  final String id;
  final String title;
  final String description;
  /// Link to task description in an external system (issue tracker, wiki, etc.).
  final String externalDescriptionUrl;
  final String? employeeId;
  final DateTime? start;
  final Duration duration;
  /// When set, [duration] on the timeline spans this many Mon–Fri days (weekends skipped).
  final int? workingDays;
  final Color? color;
  /// [TaskFillPattern.storageKey] for patterns_canvas fill; null = solid color.
  final String? fillPattern;
  /// Parent task for grouping (one level; children belong to this group).
  final String? parentId;
  /// This task cannot start until all listed tasks are completed.
  final List<String> blockedByIds;
  final TaskStatus status;
  /// Трудозатраты → Оценка (раб. дни или часы — см. [effortUnit]).
  final int? estimateWorkingDays;
  /// Трудозатраты → Фактическое время.
  final int? actualWorkingDays;
  /// `hours` or `days` — unit for [estimateWorkingDays] / [actualWorkingDays].
  final String? effortUnit;

  bool get isAssigned => employeeId != null;

  /// Task bar is shown on the Gantt chart only when [start] is set.
  bool get isOnTimeline => start != null;

  /// Alias for [isOnTimeline] (scheduled in time).
  bool get isScheduled => isOnTimeline;
  bool get usesWorkingDays => workingDays != null && workingDays! > 0;
  bool get isCompleted => status == TaskStatus.closed;

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    String? externalDescriptionUrl,
    String? employeeId,
    bool clearEmployeeId = false,
    DateTime? start,
    bool clearStart = false,
    Duration? duration,
    int? workingDays,
    bool clearWorkingDays = false,
    Color? color,
    bool clearColor = false,
    String? fillPattern,
    bool clearFillPattern = false,
    String? parentId,
    bool clearParentId = false,
    List<String>? blockedByIds,
    TaskStatus? status,
    int? estimateWorkingDays,
    bool clearEstimateWorkingDays = false,
    int? actualWorkingDays,
    bool clearActualWorkingDays = false,
    String? effortUnit,
    bool clearEffortUnit = false,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      externalDescriptionUrl:
          externalDescriptionUrl ?? this.externalDescriptionUrl,
      employeeId: clearEmployeeId ? null : (employeeId ?? this.employeeId),
      start: clearStart ? null : (start ?? this.start),
      duration: duration ?? this.duration,
      workingDays:
          clearWorkingDays ? null : (workingDays ?? this.workingDays),
      color: clearColor ? null : (color ?? this.color),
      fillPattern:
          clearFillPattern ? null : (fillPattern ?? this.fillPattern),
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      blockedByIds: blockedByIds ?? this.blockedByIds,
      status: status ?? this.status,
      estimateWorkingDays: clearEstimateWorkingDays
          ? null
          : (estimateWorkingDays ?? this.estimateWorkingDays),
      actualWorkingDays: clearActualWorkingDays
          ? null
          : (actualWorkingDays ?? this.actualWorkingDays),
      effortUnit: clearEffortUnit ? null : (effortUnit ?? this.effortUnit),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        if (externalDescriptionUrl.isNotEmpty)
          'externalDescriptionUrl': externalDescriptionUrl,
        if (employeeId != null) 'employeeId': employeeId,
        if (start != null) 'start': start!.toIso8601String(),
        'durationMinutes': duration.inMinutes,
        if (workingDays != null) 'workingDays': workingDays,
        if (color != null) 'color': color!.toARGB32(),
        if (fillPattern != null) 'fillPattern': fillPattern,
        if (parentId != null) 'parentId': parentId,
        if (blockedByIds.isNotEmpty) 'blockedByIds': blockedByIds,
        if (status != TaskStatus.open) 'status': status.name,
        if (estimateWorkingDays != null)
          'estimateWorkingDays': estimateWorkingDays,
        if (actualWorkingDays != null) 'actualWorkingDays': actualWorkingDays,
        if (effortUnit != null) 'effortUnit': effortUnit,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final duration = Duration(minutes: json['durationMinutes'] as int? ?? 240);
    final employeeId = json['employeeId'] as String?;
    final startRaw = json['start'] as String?;
    final blockedRaw = json['blockedByIds'] as List<dynamic>?;

    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      externalDescriptionUrl: _externalDescriptionUrlFromJson(json),
      employeeId: employeeId,
      start: startRaw != null ? DateTime.parse(startRaw) : null,
      duration: duration,
      workingDays: json['workingDays'] as int?,
      color: json['color'] != null
          ? Color(json['color'] as int)
          : null,
      fillPattern: json['fillPattern'] as String?,
      parentId: json['parentId'] as String?,
      blockedByIds: blockedRaw?.map((e) => e as String).toList() ?? const [],
      status: json['status'] != null
          ? TaskStatus.fromJson(json['status'] as String?)
          : ((json['isCompleted'] as bool? ?? false)
              ? TaskStatus.closed
              : TaskStatus.open),
      estimateWorkingDays: _workingDaysFromJson(
        json['estimateWorkingDays'],
        json['estimateMinutes'],
      ),
      actualWorkingDays: _workingDaysFromJson(
        json['actualWorkingDays'],
        json['actualMinutes'],
      ),
      effortUnit: json['effortUnit'] as String?,
    );
  }
}

String _externalDescriptionUrlFromJson(Map<String, dynamic> json) {
  for (final key in [
    'externalDescriptionUrl',
    'externalUrl',
    'descriptionUrl',
    'externalLink',
  ]) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}

int? _workingDaysFromJson(Object? daysRaw, Object? legacyMinutesRaw) {
  final days = daysRaw is int ? daysRaw : int.tryParse('$daysRaw');
  if (days != null && days > 0) return days;
  final minutes =
      legacyMinutesRaw is int ? legacyMinutesRaw : int.tryParse('$legacyMinutesRaw');
  if (minutes == null || minutes <= 0) return null;
  return (minutes / (8 * 60)).ceil();
}
