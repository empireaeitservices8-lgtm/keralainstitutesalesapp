import '../utils/helpers.dart';

class PerformanceTasksSummary {
  final int total;
  final int completed;
  final int pending;
  final List<PerformanceTask> list;

  PerformanceTasksSummary({
    this.total = 0,
    this.completed = 0,
    this.pending = 0,
    this.list = const [],
  });

  factory PerformanceTasksSummary.fromJson(dynamic json) {
    if (json == null) return PerformanceTasksSummary();
    if (json is List) {
      final items = json
          .whereType<Map>()
          .map((e) => PerformanceTask.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final comp = items
          .where((t) =>
              t.isCompleted ||
              (t.totalTarget > 0 && t.achieved >= t.totalTarget))
          .length;
      return PerformanceTasksSummary(
        total: items.length,
        completed: comp,
        pending: items.length - comp,
        list: items,
      );
    }
    if (json is Map) {
      final rawList = json['list'] ?? json['tasks'] ?? json['data'];
      final List<PerformanceTask> items = (rawList is List)
          ? rawList
              .whereType<Map>()
              .map((e) =>
                  PerformanceTask.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [];

      final total = json['total'] != null
          ? UiHelpers.parseInt(json['total'])
          : items.length;
      final completed = json['completed'] != null
          ? UiHelpers.parseInt(json['completed'])
          : items
              .where((t) =>
                  t.isCompleted ||
                  (t.totalTarget > 0 && t.achieved >= t.totalTarget))
              .length;
      final pending = json['pending'] != null
          ? UiHelpers.parseInt(json['pending'])
          : (total >= completed ? total - completed : items.length - completed);

      return PerformanceTasksSummary(
        total: total,
        completed: completed,
        pending: pending,
        list: items,
      );
    }
    return PerformanceTasksSummary();
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'list': list.map((e) => e.toJson()).toList(),
    };
  }
}

class PerformanceTask {
  final String id;
  final String title;
  final String taskTemplate;
  final String employee;
  final String employeeId;
  final String metricType;
  final String frequency;
  final String periodStart;
  final String periodEnd;
  final int baseTarget;
  final int carriedOver;
  final int totalTarget;
  final int achieved;
  final bool isCompleted;
  final double completionPercentage;

  PerformanceTask({
    required this.id,
    required this.title,
    this.taskTemplate = '',
    this.employee = '',
    this.employeeId = '',
    required this.metricType,
    required this.frequency,
    required this.periodStart,
    required this.periodEnd,
    required this.baseTarget,
    required this.carriedOver,
    required this.totalTarget,
    required this.achieved,
    required this.isCompleted,
    required this.completionPercentage,
  });

  factory PerformanceTask.fromJson(Map<String, dynamic> json) {
    final rawTotal = UiHelpers.parseInt(
      json['total_target'] ?? json['target'] ?? json['base_target'],
    );
    final rawAchieved = UiHelpers.parseInt(json['achieved']);

    double percentage = UiHelpers.parseDouble(json['completion_percentage']);
    if (percentage == 0.0 && rawTotal > 0) {
      percentage = ((rawAchieved / rawTotal) * 100);
    }

    final template = json['task_template']?.toString() ?? '';
    final rawTitle = json['title']?.toString() ?? '';
    final finalTitle = rawTitle.isNotEmpty
        ? rawTitle
        : (template.isNotEmpty ? template : 'Task');

    final bool completed = UiHelpers.parseBool(json['is_completed']) ||
        (rawTotal > 0 && rawAchieved >= rawTotal);

    return PerformanceTask(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: finalTitle,
      taskTemplate: template,
      employee: json['employee']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      metricType: json['metric_type']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      periodStart: json['period_start']?.toString() ?? '',
      periodEnd: json['period_end']?.toString() ?? '',
      baseTarget: UiHelpers.parseInt(json['base_target']),
      carriedOver: UiHelpers.parseInt(json['carried_over']),
      totalTarget: rawTotal,
      achieved: rawAchieved,
      isCompleted: completed,
      completionPercentage: percentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'title': title,
      'task_template': taskTemplate,
      'employee': employee,
      'employee_id': employeeId,
      'metric_type': metricType,
      'frequency': frequency,
      'period_start': periodStart,
      'period_end': periodEnd,
      'base_target': baseTarget,
      'carried_over': carriedOver,
      'total_target': totalTarget,
      'achieved': achieved,
      'is_completed': isCompleted,
      'completion_percentage': completionPercentage,
    };
  }
}

