import 'package:json_annotation/json_annotation.dart';

part 'attendance_model.g.dart';

@JsonSerializable()
class AttendanceModel {
  @JsonKey(name: 'employee_id')
  final String employeeId;
  @JsonKey(name: 'employee_name')
  final String employeeName;
  @JsonKey(name: 'check_in_selfie')
  final String checkInSelfie;
  @JsonKey(name: 'check_in_time')
  final DateTime checkInTime;
  @JsonKey(name: 'check_in_latitude')
  final double checkInLatitude;
  @JsonKey(name: 'check_in_longitude')
  final double checkInLongitude;
  
  @JsonKey(name: 'check_out_selfie')
  final String? checkOutSelfie;
  @JsonKey(name: 'check_out_time')
  final DateTime? checkOutTime;
  @JsonKey(name: 'working_hours')
  final double? workingHours;
  final String status;

  AttendanceModel({
    required this.employeeId,
    required this.employeeName,
    required this.checkInSelfie,
    required this.checkInTime,
    required this.checkInLatitude,
    required this.checkInLongitude,
    this.checkOutSelfie,
    this.checkOutTime,
    this.workingHours,
    required this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => _$AttendanceModelFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceModelToJson(this);

  AttendanceModel copyWith({
    String? checkOutSelfie,
    DateTime? checkOutTime,
    double? workingHours,
    String? status,
  }) {
    return AttendanceModel(
      employeeId: employeeId,
      employeeName: employeeName,
      checkInSelfie: checkInSelfie,
      checkInTime: checkInTime,
      checkInLatitude: checkInLatitude,
      checkInLongitude: checkInLongitude,
      checkOutSelfie: checkOutSelfie ?? this.checkOutSelfie,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      workingHours: workingHours ?? this.workingHours,
      status: status ?? this.status,
    );
  }

  factory AttendanceModel.empty() {
    return AttendanceModel(
      employeeId: '',
      employeeName: '',
      checkInSelfie: '',
      checkInTime: DateTime.now(),
      checkInLatitude: 0.0,
      checkInLongitude: 0.0,
      status: 'Absent',
    );
  }

  bool get isAbsent => status == 'Absent';
  bool get isPresent => status == 'Present';
  bool get isCompleted => status == 'Completed';
}
