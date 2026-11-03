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
  @JsonKey(name: 'status_text')
  final String? statusText;

  AttendanceModel({
    required this.employeeId,
    required this.employeeName,
    required this.checkInSelfie,
    required DateTime checkInTime,
    required this.checkInLatitude,
    required this.checkInLongitude,
    this.checkOutSelfie,
    DateTime? checkOutTime,
    this.workingHours,
    required this.status,
    this.statusText,
  }) : checkInTime = checkInTime.toLocal(),
       checkOutTime = checkOutTime?.toLocal();

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    if (json['check_in_time'] is String) {
      json['check_in_time'] = _normalizeUtcString(json['check_in_time'] as String);
    }
    if (json['check_out_time'] is String) {
      json['check_out_time'] = _normalizeUtcString(json['check_out_time'] as String);
    }
    return _$AttendanceModelFromJson(json);
  }

  static String _normalizeUtcString(String str) {
    if (str.isEmpty) return str;
    if (str.contains('Z') || str.contains('+')) return str;
    return str.replaceFirst(' ', 'T');
  }
  Map<String, dynamic> toJson() => _$AttendanceModelToJson(this);

  AttendanceModel copyWith({
    DateTime? checkInTime,
    String? checkOutSelfie,
    DateTime? checkOutTime,
    double? workingHours,
    String? status,
    String? statusText,
  }) {
    return AttendanceModel(
      employeeId: employeeId,
      employeeName: employeeName,
      checkInSelfie: checkInSelfie,
      checkInTime: checkInTime ?? this.checkInTime,
      checkInLatitude: checkInLatitude,
      checkInLongitude: checkInLongitude,
      checkOutSelfie: checkOutSelfie ?? this.checkOutSelfie,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      workingHours: workingHours ?? this.workingHours,
      status: status ?? this.status,
      statusText: statusText ?? this.statusText,
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
      statusText: 'absent',
    );
  }

  bool get isAbsent => status == 'Absent';
  bool get isPresent => status == 'Present';
  bool get isCompleted => status == 'Completed';
}
