import 'package:json_annotation/json_annotation.dart';

part 'user_session.g.dart';

@JsonSerializable()
class UserSession {
  final String email;
  @JsonKey(name: 'auth_type')
  final String authType;
  @JsonKey(name: 'device_token')
  final String deviceToken;
  final String name;
  final String role;
  final String? zone;
  final String? district;
  final String? team;

  UserSession({
    required this.email,
    required this.authType,
    required this.deviceToken,
    this.name = 'Unknown User',
    this.role = 'BDE',
    this.zone,
    this.district,
    this.team,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => _$UserSessionFromJson(json);
  Map<String, dynamic> toJson() => _$UserSessionToJson(this);

  factory UserSession.fromMap(Map<String, String> map) {
    return UserSession(
      email: map['email'] ?? 'Unknown User',
      authType: map['authType'] ?? map['auth_type'] ?? 'Unknown',
      deviceToken: map['deviceToken'] ?? map['device_token'] ?? 'N/A',
      name: map['name'] ?? 'Unknown User',
      role: map['role'] ?? 'BDE',
      zone: map['zone'] != null && map['zone']!.isNotEmpty ? map['zone'] : null,
      district: map['district'] != null && map['district']!.isNotEmpty ? map['district'] : null,
      team: map['team'] != null && map['team']!.isNotEmpty ? map['team'] : null,
    );
  }

  Map<String, String> toMap() {
    return {
      'email': email,
      'authType': authType,
      'deviceToken': deviceToken,
      'name': name,
      'role': role,
      'zone': zone ?? '',
      'district': district ?? '',
      'team': team ?? '',
    };
  }

  factory UserSession.empty() {
    return UserSession(
      email: '',
      authType: '',
      deviceToken: '',
      name: '',
      role: '',
      zone: null,
      district: null,
      team: null,
    );
  }

  bool get isEmpty => email.isEmpty && deviceToken.isEmpty;
}
