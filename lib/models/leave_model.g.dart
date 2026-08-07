// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveModel _$LeaveModelFromJson(Map<String, dynamic> json) => LeaveModel(
      id: json['id'] as String? ?? '',
      leaveType: json['leave_type'] as String? ?? '',
      fromDate: json['from_date'] != null
          ? DateTime.parse(json['from_date'] as String)
          : DateTime.now(),
      toDate: json['to_date'] != null
          ? DateTime.parse(json['to_date'] as String)
          : DateTime.now(),
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      appliedDate: json['applied_date'] != null
          ? DateTime.parse(json['applied_date'] as String)
          : DateTime.now(),
    );

Map<String, dynamic> _$LeaveModelToJson(LeaveModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'leave_type': instance.leaveType,
      'from_date': instance.fromDate.toIso8601String(),
      'to_date': instance.toDate.toIso8601String(),
      'reason': instance.reason,
      'status': instance.status,
      'applied_date': instance.appliedDate.toIso8601String(),
    };
