// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadDistrict _$LeadDistrictFromJson(Map<String, dynamic> json) => LeadDistrict(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$LeadDistrictToJson(LeadDistrict instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

LeadCourse _$LeadCourseFromJson(Map<String, dynamic> json) => LeadCourse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$LeadCourseToJson(LeadCourse instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

LeadModel _$LeadModelFromJson(Map<String, dynamic> json) => LeadModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
      districtId: (json['district_id'] as num).toInt(),
      courseId: (json['course_id'] as num).toInt(),
      source: (json['source'] as num).toInt(),
      status: (json['status'] as num).toInt(),
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      district: json['district'] == null
          ? null
          : LeadDistrict.fromJson(json['district'] as Map<String, dynamic>),
      course: json['course'] == null
          ? null
          : LeadCourse.fromJson(json['course'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LeadModelToJson(LeadModel instance) =>
    <String, dynamic>{
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
      'district': instance.district?.toJson(),
      'course': instance.course?.toJson(),
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

Map<String, dynamic> _$LeadsPageToJson(LeadsPage instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'data': instance.data.map((e) => e.toJson()).toList(),
      'last_page': instance.lastPage,
      'per_page': instance.perPage,
      'total': instance.total,
      'next_page_url': instance.nextPageUrl,
      'prev_page_url': instance.prevPageUrl,
    };
