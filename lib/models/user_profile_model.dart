import 'package:json_annotation/json_annotation.dart';

part 'user_profile_model.g.dart';

@JsonSerializable()
class UserProfileModel {
  final String name;
  final String designation;
  final String email;
  @JsonKey(name: 'contact_number')
  final String contactNumber;
  @JsonKey(name: 'employee_id')
  final String employeeId;
  @JsonKey(name: 'leave_balances')
  final LeaveBalances leaveBalances;

  UserProfileModel({
    required this.name,
    required this.designation,
    required this.email,
    required this.contactNumber,
    required this.employeeId,
    required this.leaveBalances,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => _$UserProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);
}

@JsonSerializable()
class LeaveBalances {
  final int casual;
  final int medical;
  final int earned;

  LeaveBalances({
    required this.casual,
    required this.medical,
    required this.earned,
  });

  factory LeaveBalances.fromJson(Map<String, dynamic> json) => _$LeaveBalancesFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveBalancesToJson(this);
}
