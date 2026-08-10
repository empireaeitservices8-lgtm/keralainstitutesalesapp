// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eod_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EodModel _$EodModelFromJson(Map<String, dynamic> json) => EodModel(
  id: json['id'] as String,
  totalVisits: (json['total_visits'] as num).toInt(),
  leadsCreated: (json['leads_created'] as num).toInt(),
  followUpsScheduled: (json['follow_ups_scheduled'] as num).toInt(),
  pendingVisits: (json['pending_visits'] as num).toInt(),
  remarks: json['remarks'] as String,
  dailySummary: json['daily_summary'] as String,
  submissionTime: DateTime.parse(json['submission_time'] as String),
  isSubmitted: json['is_submitted'] as bool? ?? false,
);

Map<String, dynamic> _$EodModelToJson(EodModel instance) => <String, dynamic>{
  'id': instance.id,
  'total_visits': instance.totalVisits,
  'leads_created': instance.leadsCreated,
  'follow_ups_scheduled': instance.followUpsScheduled,
  'pending_visits': instance.pendingVisits,
  'remarks': instance.remarks,
  'daily_summary': instance.dailySummary,
  'submission_time': instance.submissionTime.toIso8601String(),
  'is_submitted': instance.isSubmitted,
};
