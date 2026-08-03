class AttendanceModel {
  final String employeeId;
  final String employeeName;
  final String checkInSelfie; // Mock Selfie Path or Indicator
  final DateTime checkInTime;
  final double checkInLatitude;
  final double checkInLongitude;
  
  final String? checkOutSelfie;
  final DateTime? checkOutTime;
  final double? workingHours;
  final String status; // 'Absent' | 'Present' (Checked In) | 'Completed' (Checked Out)

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
