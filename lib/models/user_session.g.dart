// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSession _$UserSessionFromJson(Map<String, dynamic> json) => UserSession(
  email: json['email'] as String,
  authType: json['auth_type'] as String,
  deviceToken: json['device_token'] as String,
  name: json['name'] as String? ?? 'Unknown User',
  role: json['role'] as String? ?? 'BDE',
  zone: json['zone'] as String?,
  district: json['district'] as String?,
  team: json['team'] as String?,
);

Map<String, dynamic> _$UserSessionToJson(UserSession instance) =>
    <String, dynamic>{
      'email': instance.email,
      'auth_type': instance.authType,
      'device_token': instance.deviceToken,
      'name': instance.name,
      'role': instance.role,
      'zone': instance.zone,
      'district': instance.district,
      'team': instance.team,
    };
