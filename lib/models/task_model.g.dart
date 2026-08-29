// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => TaskModel(
  id: json['id'] as String,
  studentName: json['student_name'] as String,
  location: json['location'] as String,
  course: json['course'] as String,
  description: json['description'] as String,
  status: json['status'] as String? ?? 'Pending',
  leadStatus: json['lead_status'] as String? ?? 'Pending',
  assignedDate: DateTime.parse(json['assigned_date'] as String),
  completedDate: json['completed_date'] == null
      ? null
      : DateTime.parse(json['completed_date'] as String),
  completionProofPath: json['completion_proof_path'] as String?,
  remarks: json['remarks'] as String?,
  followUps: (json['follow_ups'] as List<dynamic>?)
      ?.map((e) => FollowUpItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  assignedBdeEmail: json['assigned_bde_email'] as String,
  team: json['team'] as String,
  district: json['district'] as String,
  zone: json['zone'] as String,
  creatorEmail: json['creator_email'] as String? ?? 'md@keralainstitute.org',
);

Map<String, dynamic> _$TaskModelToJson(TaskModel instance) => <String, dynamic>{
  'id': instance.id,
  'student_name': instance.studentName,
  'location': instance.location,
  'course': instance.course,
  'description': instance.description,
  'status': instance.status,
  'lead_status': instance.leadStatus,
  'assigned_date': instance.assignedDate.toIso8601String(),
  'completed_date': instance.completedDate?.toIso8601String(),
  'completion_proof_path': instance.completionProofPath,
  'remarks': instance.remarks,
  'follow_ups': instance.followUps,
  'phone': instance.phone,
  'email': instance.email,
  'assigned_bde_email': instance.assignedBdeEmail,
  'team': instance.team,
  'district': instance.district,
  'zone': instance.zone,
  'creator_email': instance.creatorEmail,
};
