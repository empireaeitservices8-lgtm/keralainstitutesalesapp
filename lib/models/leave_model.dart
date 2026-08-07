import 'package:json_annotation/json_annotation.dart';

part 'leave_model.g.dart';

@JsonSerializable()
class LeaveModel {
  final String id;
  @JsonKey(name: 'leave_type')
  final String leaveType;
  @JsonKey(name: 'from_date')
  final DateTime fromDate;
  @JsonKey(name: 'to_date')
  final DateTime toDate;
  final String reason;
  final String status;
  @JsonKey(name: 'applied_date')
  final DateTime appliedDate;

  LeaveModel({
    required this.id,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    this.status = 'Pending',
    required this.appliedDate,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) => _$LeaveModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeaveModelToJson(this);

  LeaveModel copyWith({
    String? status,
  }) {
    return LeaveModel(
      id: id,
      leaveType: leaveType,
      fromDate: fromDate,
      toDate: toDate,
      reason: reason,
      status: status ?? this.status,
      appliedDate: appliedDate,
    );
  }
}
