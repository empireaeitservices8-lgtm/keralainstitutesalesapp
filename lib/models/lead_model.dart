import 'package:json_annotation/json_annotation.dart';

part 'lead_model.g.dart';

// ---------------------------------------------------------------------------
// Nested: district
// ---------------------------------------------------------------------------
@JsonSerializable()
class LeadDistrict {
  final int id;
  final String name;

  const LeadDistrict({required this.id, required this.name});

  factory LeadDistrict.fromJson(Map<String, dynamic> json) =>
      _$LeadDistrictFromJson(json);
  Map<String, dynamic> toJson() => _$LeadDistrictToJson(this);
}

// ---------------------------------------------------------------------------
// Nested: course
// ---------------------------------------------------------------------------
@JsonSerializable()
class LeadCourse {
  final int id;
  final String name;

  const LeadCourse({required this.id, required this.name});

  factory LeadCourse.fromJson(Map<String, dynamic> json) =>
      _$LeadCourseFromJson(json);
  Map<String, dynamic> toJson() => _$LeadCourseToJson(this);
}

// ---------------------------------------------------------------------------
// Lead (single item inside data.leads.data[])
// ---------------------------------------------------------------------------
@JsonSerializable()
class LeadModel {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;

  @JsonKey(name: 'district_id')
  final int districtId;

  @JsonKey(name: 'course_id')
  final int courseId;

  /// 1 = New, 4 = Admitted (Won), 5 = Closed (Lost)
  final int source;
  final int status;
  final String notes;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  final LeadDistrict? district;
  final LeadCourse? course;

  const LeadModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.districtId,
    required this.courseId,
    required this.source,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.district,
    this.course,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) =>
      _$LeadModelFromJson(json);
  Map<String, dynamic> toJson() => _$LeadModelToJson(this);

  /// Convenience: human-readable status string
  String get statusLabel {
    switch (status) {
      case 4:
        return 'Admitted';
      case 5:
        return 'Closed';
      default:
        return 'Pending';
    }
  }

  bool get isCompleted => status == 4 || status == 5;
}

// ---------------------------------------------------------------------------
// Paginated wrapper: data.leads
// ---------------------------------------------------------------------------
@JsonSerializable()
class LeadsPage {
  @JsonKey(name: 'current_page')
  final int currentPage;

  final List<LeadModel> data;

  @JsonKey(name: 'last_page')
  final int lastPage;

  @JsonKey(name: 'per_page')
  final int perPage;

  final int total;

  @JsonKey(name: 'next_page_url')
  final String? nextPageUrl;

  @JsonKey(name: 'prev_page_url')
  final String? prevPageUrl;

  const LeadsPage({
    required this.currentPage,
    required this.data,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory LeadsPage.fromJson(Map<String, dynamic> json) =>
      _$LeadsPageFromJson(json);
  Map<String, dynamic> toJson() => _$LeadsPageToJson(this);

  bool get hasNextPage => nextPageUrl != null;
}
