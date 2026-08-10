// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceModel _$AttendanceModelFromJson(Map<String, dynamic> json) =>
    AttendanceModel(
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      checkInSelfie: json['check_in_selfie'] as String,
      checkInTime: DateTime.parse(json['check_in_time'] as String),
      checkInLatitude: (json['check_in_latitude'] as num).toDouble(),
      checkInLongitude: (json['check_in_longitude'] as num).toDouble(),
      checkOutSelfie: json['check_out_selfie'] as String?,
      checkOutTime: json['check_out_time'] == null
          ? null
          : DateTime.parse(json['check_out_time'] as String),
      workingHours: (json['working_hours'] as num?)?.toDouble(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$AttendanceModelToJson(AttendanceModel instance) =>
    <String, dynamic>{
      'employee_id': instance.employeeId,
      'employee_name': instance.employeeName,
      'check_in_selfie': instance.checkInSelfie,
      'check_in_time': instance.checkInTime.toIso8601String(),
      'check_in_latitude': instance.checkInLatitude,
      'check_in_longitude': instance.checkInLongitude,
      'check_out_selfie': instance.checkOutSelfie,
      'check_out_time': instance.checkOutTime?.toIso8601String(),
      'working_hours': instance.workingHours,
      'status': instance.status,
    };
