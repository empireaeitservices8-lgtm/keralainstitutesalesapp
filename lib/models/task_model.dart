class TaskModel {
  final String id;
  final String studentName;
  final String location;
  final String course;
  final String description;
  final String status; // 'Pending' | 'Completed'
  final String leadStatus; // 'Pending' | 'Interested' | 'Admitted' | 'Closed'
  final DateTime assignedDate;
  final DateTime? completedDate;
  final String? completionProofPath;
  final String? remarks;
  final String? followUpDate;
  
  // Assignment details
  final String assignedBdeEmail;
  final String team;
  final String district;
  final String zone;
  final String creatorEmail;

  TaskModel({
    required this.id,
    required this.studentName,
    required this.location,
    required this.course,
    required this.description,
    this.status = 'Pending',
    this.leadStatus = 'Pending',
    required this.assignedDate,
    this.completedDate,
    this.completionProofPath,
    this.remarks,
    this.followUpDate,
    required this.assignedBdeEmail,
    required this.team,
    required this.district,
    required this.zone,
    this.creatorEmail = 'md@keralainstitute.org',
  });

  TaskModel copyWith({
    String? status,
    String? leadStatus,
    DateTime? completedDate,
    String? completionProofPath,
    String? remarks,
    String? followUpDate,
    String? assignedBdeEmail,
    String? team,
    String? district,
    String? zone,
    String? creatorEmail,
  }) {
    return TaskModel(
      id: id,
      studentName: studentName,
      location: location,
      course: course,
      description: description,
      status: status ?? this.status,
      leadStatus: leadStatus ?? this.leadStatus,
      assignedDate: assignedDate,
      completedDate: completedDate ?? this.completedDate,
      completionProofPath: completionProofPath ?? this.completionProofPath,
      remarks: remarks ?? this.remarks,
      followUpDate: followUpDate ?? this.followUpDate,
      assignedBdeEmail: assignedBdeEmail ?? this.assignedBdeEmail,
      team: team ?? this.team,
      district: district ?? this.district,
      zone: zone ?? this.zone,
      creatorEmail: creatorEmail ?? this.creatorEmail,
    );
  }
}
