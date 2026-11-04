import 'package:json_annotation/json_annotation.dart';

part 'task_model.g.dart';

@JsonSerializable()
class TaskModel {
  final String id;
  @JsonKey(name: 'lead_id')
  final String? leadId;
  @JsonKey(name: 'student_id')
  final String? studentId;
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
  
  @JsonKey(name: 'follow_ups')
  final List<FollowUpItem>? followUps;

  String? get followUpDate => (followUps != null && followUps!.isNotEmpty) ? followUps!.last.dateTime : null;
  String? get followUpRemark => (followUps != null && followUps!.isNotEmpty) ? followUps!.last.remark : null;

  final String? phone;
  final String? email;
  @JsonKey(name: 'whatsapp_number')
  final String? whatsappNumber;
  final String? place;
  final int? age;
  final String? qualification;
  @JsonKey(name: 'college_name')
  final String? collegeName;
  @JsonKey(name: 'current_year')
  final String? currentYear;
  @JsonKey(name: 'interested_topic')
  final String? interestedTopic;
  @JsonKey(name: 'interested_course')
  final String? interestedCourse;
  @JsonKey(name: 'lead_source')
  final String? leadSource;
  @JsonKey(name: 'admission_status')
  final String? admissionStatus;
  final String? employee;
  
  @JsonKey(name: 'assigned_bde_email')
  final String assignedBdeEmail;
  final String team;
  final String district;
  final String zone;
  @JsonKey(name: 'creator_email')
  final String creatorEmail;

  TaskModel({
    required this.id,
    this.leadId,
    this.studentId,
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
    this.followUps,
    this.phone,
    this.email,
    required this.assignedBdeEmail,
    required this.team,
    required this.district,
    required this.zone,
    this.creatorEmail = 'md@keralainstitute.org',
    this.whatsappNumber,
    this.place,
    this.age,
    this.qualification,
    this.collegeName,
    this.currentYear,
    this.interestedTopic,
    this.interestedCourse,
    this.leadSource,
    this.admissionStatus,
    this.employee,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

  String get leadIdentifier {
    final val = (leadId != null && leadId!.trim().isNotEmpty) ? leadId!.trim() : id.trim();
    if (val.startsWith('LD-')) return val;
    if (val.startsWith('LD_')) return 'LD-${val.substring(3)}';
    if (val.toUpperCase().startsWith('LD') && val.length > 2 && RegExp(r'^\d+$').hasMatch(val.substring(2))) {
      return 'LD-${val.substring(2)}';
    }
    if (RegExp(r'^\d+$').hasMatch(val)) return 'LD-$val';
    return val;
  }

  TaskModel copyWith({
    String? leadId,
    String? studentId,
    String? status,
    String? leadStatus,
    DateTime? completedDate,
    String? completionProofPath,
    String? remarks,
    List<FollowUpItem>? followUps,
    String? phone,
    String? email,
    String? assignedBdeEmail,
    String? team,
    String? district,
    String? zone,
    String? creatorEmail,
    String? whatsappNumber,
    String? place,
    int? age,
    String? qualification,
    String? collegeName,
    String? currentYear,
    String? interestedTopic,
    String? interestedCourse,
    String? leadSource,
    String? admissionStatus,
    String? employee,
  }) {
    return TaskModel(
      id: id,
      leadId: leadId ?? this.leadId,
      studentId: studentId ?? this.studentId,
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
      followUps: followUps ?? this.followUps,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      assignedBdeEmail: assignedBdeEmail ?? this.assignedBdeEmail,
      team: team ?? this.team,
      district: district ?? this.district,
      zone: zone ?? this.zone,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      place: place ?? this.place,
      age: age ?? this.age,
      qualification: qualification ?? this.qualification,
      collegeName: collegeName ?? this.collegeName,
      currentYear: currentYear ?? this.currentYear,
      interestedTopic: interestedTopic ?? this.interestedTopic,
      interestedCourse: interestedCourse ?? this.interestedCourse,
      leadSource: leadSource ?? this.leadSource,
      admissionStatus: admissionStatus ?? this.admissionStatus,
      employee: employee ?? this.employee,
    );
  }
}

class FollowUpItem {
  final String dateTime;
  final String remark;
  final String? attachment;

  FollowUpItem({
    required this.dateTime,
    required this.remark,
    this.attachment,
  });

  factory FollowUpItem.fromJson(Map<String, dynamic> json) {
    return FollowUpItem(
      dateTime: json['dateTime'] as String? ?? json['date_time'] as String? ?? json['followup_date'] as String? ?? '',
      remark: json['remark'] as String? ?? json['notes'] as String? ?? '',
      attachment: json['attachment'] as String? ??
          json['proof'] as String? ??
          json['image'] as String? ??
          json['photo'] as String? ??
          json['file_path'] as String? ??
          json['file'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'dateTime': dateTime,
    'remark': remark,
    if (attachment != null) 'attachment': attachment,
  };
}
