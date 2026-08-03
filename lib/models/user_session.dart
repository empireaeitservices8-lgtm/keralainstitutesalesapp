class UserSession {
  final String email;
  final String authType;
  final String deviceToken;
  final String name;
  final String role; // 'MD' | 'ZM' | 'ASM' | 'BDM' | 'BDE'
  final String? zone; // 'South Zone' | 'Central Zone' | 'North Zone'
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

  factory UserSession.fromMap(Map<String, String> map) {
    return UserSession(
      email: map['email'] ?? 'Unknown User',
      authType: map['authType'] ?? 'Unknown',
      deviceToken: map['deviceToken'] ?? 'N/A',
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
