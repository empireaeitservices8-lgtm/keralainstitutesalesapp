import '../utils/helpers.dart';

class PerformanceTask {
  final int id;
  final String title;
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
    return PerformanceTask(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      metricType: json['metric_type'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      periodStart: json['period_start'] as String? ?? '',
      periodEnd: json['period_end'] as String? ?? '',
      baseTarget: json['base_target'] as int? ?? 0,
      carriedOver: json['carried_over'] as int? ?? 0,
      totalTarget: json['total_target'] as int? ?? 0,
      achieved: json['achieved'] as int? ?? 0,
      isCompleted: UiHelpers.parseBool(json['is_completed']),
      completionPercentage: (json['completion_percentage'] as num? ?? 0)
          .toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'metric_type': metricType,
      'frequency': frequency,
      'period_start': periodStart,
      'period_end': periodEnd,
      'base_target': baseTarget,
      'carried_over': carriedOver,
      'total_target': totalTarget,
      'achieved': achieved,
      'is_completed': isCompleted ? 1 : 0,
      'completion_percentage': completionPercentage,
    };
  }
}
