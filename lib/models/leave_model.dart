class LeaveModel {
  final String id;
  final String leaveType; // 'Casual Leave' | 'Medical Leave' | 'Earned Leave'
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final String status; // 'Pending' | 'Approved' | 'Rejected'
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
