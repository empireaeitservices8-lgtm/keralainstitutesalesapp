// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadDistrict _$LeadDistrictFromJson(Map<String, dynamic> json) =>
    LeadDistrict(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$LeadDistrictToJson(LeadDistrict instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

LeadCourse _$LeadCourseFromJson(Map<String, dynamic> json) =>
    LeadCourse(id: (json['id'] as num).toInt(), name: json['name'] as String);

Map<String, dynamic> _$LeadCourseToJson(LeadCourse instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

LeadFollowUp _$LeadFollowUpFromJson(Map<String, dynamic> json) => LeadFollowUp(
  id: (json['id'] as num).toInt(),
  leadId: (json['lead_id'] as num).toInt(),
  employeeId: (json['employee_id'] as num).toInt(),
  followupDate: json['followup_date'] as String,
  type: json['type'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$LeadFollowUpToJson(LeadFollowUp instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lead_id': instance.leadId,
      'employee_id': instance.employeeId,
      'followup_date': instance.followupDate,
      'type': instance.type,
      'notes': instance.notes,
    };

LeadModel _$LeadModelFromJson(Map<String, dynamic> json) => LeadModel(
  id: (json['id'] as num).toInt(),
  name: LeadModel._parseString(json['name']),
  phone: LeadModel._parseString(json['phone']),
  email: LeadModel._parseString(json['email']),
  address: LeadModel._parseString(json['address']),
  districtId: LeadModel._parseInt(json['district_id']),
  courseId: LeadModel._parseInt(json['course_id']),
  source: LeadModel._parseInt(json['source']),
  status: LeadModel._parseInt(json['status']),
  notes: LeadModel._parseString(json['notes']),
  createdAt: LeadModel._parseDateTime(json['created_at']),
  updatedAt: LeadModel._parseDateTime(json['updated_at']),
  district: json['district'] == null
      ? null
      : LeadDistrict.fromJson(json['district'] as Map<String, dynamic>),
  course: json['course'] == null
      ? null
      : LeadCourse.fromJson(json['course'] as Map<String, dynamic>),
  followups: (json['followups'] as List<dynamic>?)
      ?.map((e) => LeadFollowUp.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LeadModelToJson(LeadModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'email': instance.email,
  'address': instance.address,
  'district_id': instance.districtId,
  'course_id': instance.courseId,
  'source': instance.source,
  'status': instance.status,
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
