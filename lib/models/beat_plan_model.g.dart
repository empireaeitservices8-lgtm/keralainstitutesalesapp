// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beat_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BeatPlanModel _$BeatPlanModelFromJson(Map<String, dynamic> json) =>
    BeatPlanModel(
      id: json['id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      sequence: (json['sequence'] as num? ?? 0).toInt(),
      scheduleTime: json['schedule_time'] as String? ?? '',
      distanceKm: (json['distance_km'] as num? ?? 0.0).toDouble(),
      latitude: (json['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0.0).toDouble(),
      isVisited: json['is_visited'] as bool? ?? false,
      checkInTime: json['check_in_time'] == null
          ? null
          : DateTime.parse(json['check_in_time'] as String),
      selfiePath: json['selfie_path'] as String?,
      visitNotes: json['visit_notes'] as String?,
      orderValue: (json['order_value'] as num?)?.toDouble(),
      followUpDate: json['follow_up_date'] as String?,
      attachmentPath: json['attachment_path'] as String?,
      status: json['status'] as String? ?? 'Pending',
      assignedBdeEmail: json['assigned_bde_email'] as String? ?? '',
      team: json['team'] as String? ?? '',
      district: json['district'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
    );

Map<String, dynamic> _$BeatPlanModelToJson(BeatPlanModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customer_name': instance.customerName,
      'address': instance.address,
      'sequence': instance.sequence,
      'schedule_time': instance.scheduleTime,
      'distance_km': instance.distanceKm,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'is_visited': instance.isVisited,
      'check_in_time': instance.checkInTime?.toIso8601String(),
      'selfie_path': instance.selfiePath,
      'visit_notes': instance.visitNotes,
      'order_value': instance.orderValue,
      'follow_up_date': instance.followUpDate,
      'attachment_path': instance.attachmentPath,
      'status': instance.status,
      'assigned_bde_email': instance.assignedBdeEmail,
      'team': instance.team,
      'district': instance.district,
      'zone': instance.zone,
    };
