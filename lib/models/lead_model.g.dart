// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadDistrict _$LeadDistrictFromJson(Map<String, dynamic> json) =>
    LeadDistrict(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? '',
    );

Map<String, dynamic> _$LeadDistrictToJson(LeadDistrict instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

LeadCourse _$LeadCourseFromJson(Map<String, dynamic> json) =>
    LeadCourse(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? '',
    );

Map<String, dynamic> _$LeadCourseToJson(LeadCourse instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

LeadFollowUp _$LeadFollowUpFromJson(Map<String, dynamic> json) => LeadFollowUp(
  id: json['id'] is num
      ? (json['id'] as num).toInt()
      : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
  leadId: json['lead_id'] is num
      ? (json['lead_id'] as num).toInt()
      : (int.tryParse(json['lead_id']?.toString() ?? '') ?? 0),
  employeeId: json['employee_id'] is num
      ? (json['employee_id'] as num).toInt()
      : (int.tryParse(json['employee_id']?.toString() ?? '') ?? 0),
  followupDate: json['followup_date']?.toString() ?? '',
  type: json['type'] as String?,
  notes: json['notes'] as String?,
  attachment: (json['attachment'] ?? json['proof'] ?? json['image'] ?? json['photo'] ?? json['file_path']) as String?,
);

Map<String, dynamic> _$LeadFollowUpToJson(LeadFollowUp instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lead_id': instance.leadId,
      'employee_id': instance.employeeId,
      'followup_date': instance.followupDate,
      'type': instance.type,
      'notes': instance.notes,
      'attachment': instance.attachment,
    };

LeadModel _$LeadModelFromJson(Map<String, dynamic> json) {
  final rawLeadId = json['lead_id'] ?? json['leadId'];
  final parsedLeadId = rawLeadId?.toString().trim();
  final parsedId = json['id'] is num
      ? (json['id'] as num).toInt()
      : (int.tryParse(json['id']?.toString() ?? '') ?? 0);

  final rawStudentId = json['student_id'] ??
      json['studentId'] ??
      json['student_no'] ??
      json['studentNo'] ??
      json['student_code'] ??
      json['studentCode'] ??
      json['admission_no'] ??
      json['admissionNo'] ??
      (json['student'] is Map
          ? (json['student']['student_id'] ??
              json['student']['student_no'] ??
              json['student']['student_code'] ??
              json['student']['id'] ??
              json['student']['code'])
          : null) ??
      (json['admission'] is Map
          ? (json['admission']['student_id'] ??
              json['admission']['admission_no'] ??
              json['admission']['id'])
          : null);
  final parsedStudentId =
      (rawStudentId != null && rawStudentId.toString().trim().isNotEmpty)
          ? rawStudentId.toString().trim()
          : null;

  return LeadModel(
    id: parsedId,
    leadId: (parsedLeadId != null && parsedLeadId.isNotEmpty) ? parsedLeadId : null,
    studentId: (parsedStudentId != null && parsedStudentId.isNotEmpty) ? parsedStudentId : null,
    name: LeadModel._parseString(json['name']),
  phone: LeadModel._parseString(json['phone']),
  whatsappNumber: LeadModel._parseStringNullable(json['whatsapp_number']),
  email: LeadModel._parseString(json['email']),
  address: LeadModel._parseString(json['address']),
  place: LeadModel._parseStringNullable(json['place']),
  districtId: LeadModel._parseInt(json['district_id']),
  districtName: json['district'] is String
      ? json['district'] as String
      : LeadModel._parseStringNullable(json['district_name']),
  age: LeadModel._parseIntNullable(json['age']),
  qualification: LeadModel._parseStringNullable(json['qualification']),
  collegeName: LeadModel._parseStringNullable(json['college_name']),
  currentYear: LeadModel._parseStringNullable(json['current_year']),
  interestedTopic: LeadModel._parseStringNullable(json['interested_topic']),
  interestedCourse: LeadModel._parseStringNullable(json['interested_course']),
  courseId: LeadModel._parseInt(json['course_id']),
  source: LeadModel._parseInt(json['source']),
  leadSource: LeadModel._parseStringNullable(json['lead_source']),
  status: LeadModel._parseInt(json['status']),
  admissionStatus: LeadModel._parseStringNullable(json['admission_status']),
  employee: LeadModel._parseStringNullable(json['employee']),
  notes: LeadModel._parseString(json['notes']),
  createdAt: LeadModel._parseDateTime(json['created_at']),
  updatedAt: LeadModel._parseDateTime(json['updated_at']),
  district: json['district'] is Map
      ? LeadDistrict.fromJson(Map<String, dynamic>.from(json['district'] as Map))
      : (json['district'] is String
          ? LeadDistrict(id: 0, name: json['district'] as String)
          : null),
  course: json['course'] is Map
      ? LeadCourse.fromJson(Map<String, dynamic>.from(json['course'] as Map))
      : (json['course'] is String
          ? LeadCourse(id: 0, name: json['course'] as String)
          : (json['interested_course'] is String
              ? LeadCourse(id: 0, name: json['interested_course'] as String)
              : null)),
  followups: (json['followups'] as List<dynamic>?)
      ?.whereType<Map>()
      .map((e) => LeadFollowUp.fromJson(Map<String, dynamic>.from(e)))
      .toList(),
  );
}

Map<String, dynamic> _$LeadModelToJson(LeadModel instance) => <String, dynamic>{
  'id': instance.id,
  'lead_id': instance.leadId,
  'student_id': instance.studentId,
  'name': instance.name,
  'phone': instance.phone,
  'whatsapp_number': instance.whatsappNumber,
  'email': instance.email,
  'address': instance.address,
  'place': instance.place,
  'district_id': instance.districtId,
  'district_name': instance.districtName,
  'age': instance.age,
  'qualification': instance.qualification,
  'college_name': instance.collegeName,
  'current_year': instance.currentYear,
  'interested_topic': instance.interestedTopic,
  'interested_course': instance.interestedCourse,
  'course_id': instance.courseId,
  'source': instance.source,
  'lead_source': instance.leadSource,
  'status': instance.status,
  'admission_status': instance.admissionStatus,
  'employee': instance.employee,
  'notes': instance.notes,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'district': instance.district,
  'course': instance.course,
  'followups': instance.followups,
};

LeadsPage _$LeadsPageFromJson(Map<String, dynamic> json) => LeadsPage(
  currentPage: (json['current_page'] as num).toInt(),
  data: (json['data'] as List<dynamic>)
      .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  lastPage: (json['last_page'] as num).toInt(),
  perPage: (json['per_page'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  nextPageUrl: json['next_page_url'] as String?,
  prevPageUrl: json['prev_page_url'] as String?,
);

Map<String, dynamic> _$LeadsPageToJson(LeadsPage instance) => <String, dynamic>{
  'current_page': instance.currentPage,
  'data': instance.data,
  'last_page': instance.lastPage,
  'per_page': instance.perPage,
  'total': instance.total,
  'next_page_url': instance.nextPageUrl,
  'prev_page_url': instance.prevPageUrl,
};
