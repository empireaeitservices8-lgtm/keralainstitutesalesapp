// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) =>
    UserProfileModel(
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      email: json['email'] as String? ?? '',
      contactNumber: json['contact_number'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      leaveBalances: LeaveBalances.fromJson(
          json['leave_balances'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserProfileModelToJson(UserProfileModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'designation': instance.designation,
      'email': instance.email,
      'contact_number': instance.contactNumber,
      'employee_id': instance.employeeId,
      'leave_balances': instance.leaveBalances,
    };

LeaveBalances _$LeaveBalancesFromJson(Map<String, dynamic> json) =>
    LeaveBalances(
      casual: (json['casual'] as num? ?? 0).toInt(),
      medical: (json['medical'] as num? ?? 0).toInt(),
      earned: (json['earned'] as num? ?? 0).toInt(),
    );

Map<String, dynamic> _$LeaveBalancesToJson(LeaveBalances instance) =>
    <String, dynamic>{
      'casual': instance.casual,
      'medical': instance.medical,
      'earned': instance.earned,
    };
