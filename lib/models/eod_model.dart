import 'package:json_annotation/json_annotation.dart';

part 'eod_model.g.dart';

@JsonSerializable()
class EodModel {
  final String id;
  @JsonKey(name: 'total_visits')
  final int totalVisits;
  @JsonKey(name: 'leads_created')
  final int leadsCreated;
  @JsonKey(name: 'follow_ups_scheduled')
  final int followUpsScheduled;
  @JsonKey(name: 'pending_visits')
  final int pendingVisits;
  final String remarks;
  @JsonKey(name: 'daily_summary')
  final String dailySummary;
  @JsonKey(name: 'submission_time')
  final DateTime submissionTime;
  @JsonKey(name: 'is_submitted')
  final bool isSubmitted;

  EodModel({
    required this.id,
    required this.totalVisits,
    required this.leadsCreated,
    required this.followUpsScheduled,
    required this.pendingVisits,
    required this.remarks,
    required this.dailySummary,
    required this.submissionTime,
    this.isSubmitted = false,
  });

  factory EodModel.fromJson(Map<String, dynamic> json) => _$EodModelFromJson(json);
  Map<String, dynamic> toJson() => _$EodModelToJson(this);

  factory EodModel.empty() {
    return EodModel(
      id: '',
      totalVisits: 0,
      leadsCreated: 0,
      followUpsScheduled: 0,
      pendingVisits: 0,
      remarks: '',
      dailySummary: '',
      submissionTime: DateTime.now(),
    );
  }
}
