import 'package:json_annotation/json_annotation.dart';
import '../utils/helpers.dart';

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
  final String? attachment;

  const LeadFollowUp({
    required this.id,
    required this.leadId,
    required this.employeeId,
    required this.followupDate,
    this.type,
    this.notes,
    this.attachment,
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

  static String? _parseStringNullable(dynamic val) => val?.toString();
  static int? _parseIntNullable(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  final int id;
  @JsonKey(name: 'lead_id')
  final String? leadId;
  @JsonKey(name: 'student_id', fromJson: _parseStringNullable)
  final String? studentId;
  @JsonKey(fromJson: _parseString)
  final String name;
  @JsonKey(fromJson: _parseString)
  final String phone;
  @JsonKey(name: 'whatsapp_number', fromJson: _parseStringNullable)
  final String? whatsappNumber;
  @JsonKey(fromJson: _parseString)
  final String email;
  @JsonKey(fromJson: _parseString)
  final String address;
  @JsonKey(fromJson: _parseStringNullable)
  final String? place;

  @JsonKey(name: 'district_id', fromJson: _parseInt)
  final int districtId;
  @JsonKey(name: 'district_name', fromJson: _parseStringNullable)
  final String? districtName;

  @JsonKey(fromJson: _parseIntNullable)
  final int? age;
  @JsonKey(fromJson: _parseStringNullable)
  final String? qualification;
  @JsonKey(name: 'college_name', fromJson: _parseStringNullable)
  final String? collegeName;
  @JsonKey(name: 'current_year', fromJson: _parseStringNullable)
  final String? currentYear;
  @JsonKey(name: 'interested_topic', fromJson: _parseStringNullable)
  final String? interestedTopic;
  @JsonKey(name: 'interested_course', fromJson: _parseStringNullable)
  final String? interestedCourse;

  @JsonKey(name: 'course_id', fromJson: _parseInt)
  final int courseId;

  /// 1 = New, 4 = Admitted (Won), 5 = Closed (Lost)
  @JsonKey(fromJson: _parseInt)
  final int source;
  @JsonKey(name: 'lead_source', fromJson: _parseStringNullable)
  final String? leadSource;
  @JsonKey(fromJson: _parseInt)
  final int status;
  @JsonKey(name: 'admission_status', fromJson: _parseStringNullable)
  final String? admissionStatus;
  @JsonKey(fromJson: _parseStringNullable)
  final String? employee;
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
    this.leadId,
    this.studentId,
    required this.name,
    required this.phone,
    this.whatsappNumber,
    required this.email,
    required this.address,
    this.place,
    required this.districtId,
    this.districtName,
    this.age,
    this.qualification,
    this.collegeName,
    this.currentYear,
    this.interestedTopic,
    this.interestedCourse,
    required this.courseId,
    required this.source,
    this.leadSource,
    required this.status,
    this.admissionStatus,
    this.employee,
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

  String get actualLeadId {
    if (leadId != null && leadId!.trim().isNotEmpty) {
      final val = leadId!.trim();
      if (val.startsWith('LD-')) return val;
      if (val.startsWith('LD_')) return 'LD-${val.substring(3)}';
      if (val.toUpperCase().startsWith('LD') && val.length > 2 && RegExp(r'^\d+$').hasMatch(val.substring(2))) {
        return 'LD-${val.substring(2)}';
      }
      if (RegExp(r'^\d+$').hasMatch(val)) return 'LD-$val';
      return val;
    }
    return (id > 0) ? 'LD-$id' : '';
  }

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

  factory LeadsPage.fromJson(dynamic json) {
    if (json is List) {
      return LeadsPage(
        currentPage: 1,
        data: json
            .whereType<Map>()
            .map((e) => LeadModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        lastPage: 1,
        perPage: json.length,
        total: json.length,
      );
    }
    if (json is Map) {
      final rawData = json['data'] is List
          ? json['data'] as List
          : (json['leads'] is List ? json['leads'] as List : []);
      return LeadsPage(
        currentPage: UiHelpers.parseInt(json['current_page'], 1),
        data: rawData
            .whereType<Map>()
            .map((e) => LeadModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        lastPage: UiHelpers.parseInt(json['last_page'], 1),
        perPage: UiHelpers.parseInt(json['per_page'], rawData.length),
        total: UiHelpers.parseInt(json['total'], rawData.length),
        nextPageUrl: json['next_page_url']?.toString(),
        prevPageUrl: json['prev_page_url']?.toString(),
      );
    }
    return const LeadsPage(
      currentPage: 1,
      data: [],
      lastPage: 1,
      perPage: 0,
      total: 0,
    );
  }
  Map<String, dynamic> toJson() => _$LeadsPageToJson(this);

  bool get hasNextPage => nextPageUrl != null;
}
