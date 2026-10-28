class UserProfileModel {
  final String name;
  final String designation;
  final String email;
  final String contactNumber;
  final String employeeId;
  final LeaveBalances leaveBalances;

  UserProfileModel({
    required this.name,
    required this.designation,
    required this.email,
    required this.contactNumber,
    required this.employeeId,
    required this.leaveBalances,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      name: json['name'] as String? ?? 'User',
      designation: json['designation'] as String? ?? json['designation_name'] as String? ?? 'BDE',
      email: json['email'] as String? ?? '',
      contactNumber: json['contact_number'] as String? ?? json['phone'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      leaveBalances: json['leave_balances'] != null && json['leave_balances'] is Map
          ? LeaveBalances.fromJson(Map<String, dynamic>.from(json['leave_balances'] as Map))
          : LeaveBalances(casual: 0, medical: 0, earned: 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'designation': designation,
        'email': email,
        'contact_number': contactNumber,
        'employee_id': employeeId,
        'leave_balances': leaveBalances.toJson(),
      };
}

class LeaveBalances {
  final int casual;
  final int medical;
  final int earned;

  LeaveBalances({
    required this.casual,
    required this.medical,
    required this.earned,
  });

  factory LeaveBalances.fromJson(Map<String, dynamic> json) {
    return LeaveBalances(
      casual: (json['casual'] as num? ?? 0).toInt(),
      medical: (json['medical'] as num? ?? 0).toInt(),
      earned: (json['earned'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'casual': casual,
        'medical': medical,
        'earned': earned,
      };
}
