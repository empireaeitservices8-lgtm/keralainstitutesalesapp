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
// Nested: followups
// ---------------------------------------------------------------------------
@JsonSerializable()
class LeadFollowUp {
  final int id;
  @JsonKey(name: 'lead_id')
  final int leadId;
  @JsonKey(name: 'employee_id')
  final int employeeId;
  @JsonKey(name: 'followup_date')
  final String followupDate;
  final String? type;
  final String? notes;

  const LeadFollowUp({
    required this.id,
    required this.leadId,
    required this.employeeId,
    required this.followupDate,
    this.type,
    this.notes,
  });

  factory LeadFollowUp.fromJson(Map<String, dynamic> json) =>
      _$LeadFollowUpFromJson(json);
  Map<String, dynamic> toJson() => _$LeadFollowUpToJson(this);
}

// ---------------------------------------------------------------------------
// Lead (single item inside data.leads.data[])
// ---------------------------------------------------------------------------
@JsonSerializable()
class LeadModel {
  static String _parseString(dynamic val) => val?.toString() ?? '';
  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }
  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is String) {
      if (val.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(val);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  final int id;
  @JsonKey(fromJson: _parseString)
  final String name;
  @JsonKey(fromJson: _parseString)
  final String phone;
  @JsonKey(fromJson: _parseString)
  final String email;
  @JsonKey(fromJson: _parseString)
  final String address;

  @JsonKey(name: 'district_id', fromJson: _parseInt)
  final int districtId;

  @JsonKey(name: 'course_id', fromJson: _parseInt)
  final int courseId;

  /// 1 = New, 4 = Admitted (Won), 5 = Closed (Lost)
  @JsonKey(fromJson: _parseInt)
  final int source;
  @JsonKey(fromJson: _parseInt)
  final int status;
  @JsonKey(fromJson: _parseString)
  final String notes;

  @JsonKey(name: 'created_at', fromJson: _parseDateTime)
  final DateTime createdAt;

  @JsonKey(name: 'updated_at', fromJson: _parseDateTime)
  final DateTime updatedAt;

  final LeadDistrict? district;
  final LeadCourse? course;
  final List<LeadFollowUp>? followups;

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
    this.followups,
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
