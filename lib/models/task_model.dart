import 'package:json_annotation/json_annotation.dart';

part 'task_model.g.dart';

@JsonSerializable()
class TaskModel {
  final String id;
  @JsonKey(name: 'student_name')
  final String studentName;
  final String location;
  final String course;
  final String description;
  final String status;
  @JsonKey(name: 'lead_status')
  final String leadStatus;
  @JsonKey(name: 'assigned_date')
  final DateTime assignedDate;
  @JsonKey(name: 'completed_date')
  final DateTime? completedDate;
  @JsonKey(name: 'completion_proof_path')
  final String? completionProofPath;
  final String? remarks;
  @JsonKey(name: 'follow_up_date')
  final String? followUpDate;
  
  @JsonKey(name: 'assigned_bde_email')
  final String assignedBdeEmail;
  final String team;
  final String district;
  final String zone;
  @JsonKey(name: 'creator_email')
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

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

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
