import 'package:json_annotation/json_annotation.dart';
import '../utils/helpers.dart';

part 'home_dashboard_model.g.dart';

@JsonSerializable()
class HomeDashboardModel {
  final HomeUser user;
  @JsonKey(name: 'designation_id')
  final int designationId;
  @JsonKey(name: 'designation_name')
  final String designationName;
  final HomeAttendance? attendance;
  @JsonKey(name: 'eod_sync')
  final HomeEodSync? eodSync;
  @JsonKey(name: 'operational_overview')
  final HomeOperationalOverview? operationalOverview;
  @JsonKey(name: 'dashboard_type')
  final String? dashboardType;
  @JsonKey(name: 'team_name')
  final String? teamName;
  @JsonKey(name: 'team_metrics')
  final HomeTeamMetrics? teamMetrics;
  @JsonKey(name: 'team_subordinate_status', fromJson: _parseSubordinateStatus)
  final Map<String, List<HomeBdeStatus>>? teamSubordinateStatus;
  @JsonKey(name: 'territory_report')
  final List<HomeTerritoryReport>? territoryReport;

  HomeDashboardModel({
    required this.user,
    required this.designationId,
    required this.designationName,
    this.attendance,
    this.eodSync,
    this.operationalOverview,
    this.dashboardType,
    this.teamName,
    this.teamMetrics,
    this.teamSubordinateStatus,
    this.territoryReport,
  });

  static Map<String, List<HomeBdeStatus>>? _parseSubordinateStatus(
    dynamic json,
  ) {
    if (json == null) return null;
    if (json is Map) {
      return json.map((key, value) {
        final list =
            (value as List?)
                ?.map((e) => HomeBdeStatus.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return MapEntry(key.toString(), list);
      });
    }
    return null;
  }

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) =>
      _$HomeDashboardModelFromJson(json);
  Map<String, dynamic> toJson() => _$HomeDashboardModelToJson(this);
}

@JsonSerializable()
class HomeUser {
  final int id;
  final String name;
  final String email;

  HomeUser({required this.id, required this.name, required this.email});

  factory HomeUser.fromJson(Map<String, dynamic> json) =>
      _$HomeUserFromJson(json);
  Map<String, dynamic> toJson() => _$HomeUserToJson(this);
}

@JsonSerializable()
class HomeAttendance {
  @JsonKey(name: 'check_in_time')
  final String checkInTime;
  @JsonKey(name: 'check_out_time')
  final String checkOutTime;
  @JsonKey(name: 'shift_status')
  final String shiftStatus;
  @JsonKey(name: 'is_checked_in', fromJson: UiHelpers.parseBool)
  final bool isCheckedIn;
  @JsonKey(name: 'location_lat')
  final num? locationLat;
  @JsonKey(name: 'location_lng')
  final num? locationLng;

  HomeAttendance({
    required this.checkInTime,
    required this.checkOutTime,
    required this.shiftStatus,
    required this.isCheckedIn,
    this.locationLat,
    this.locationLng,
  });

  factory HomeAttendance.fromJson(Map<String, dynamic> json) =>
      _$HomeAttendanceFromJson(json);
  Map<String, dynamic> toJson() => _$HomeAttendanceToJson(this);
}

@JsonSerializable()
class HomeEodSync {
  @JsonKey(name: 'tasks_completed')
  final int tasksCompleted;
  @JsonKey(name: 'total_tasks')
  final int totalTasks;
  @JsonKey(name: 'completion_percentage')
  final num completionPercentage;

  HomeEodSync({
    required this.tasksCompleted,
    required this.totalTasks,
    required this.completionPercentage,
  });

  factory HomeEodSync.fromJson(Map<String, dynamic> json) =>
      _$HomeEodSyncFromJson(json);
  Map<String, dynamic> toJson() => _$HomeEodSyncToJson(this);
}

@JsonSerializable()
class HomeOperationalOverview {
  @JsonKey(name: 'assigned_leads')
  final int assignedLeads;
  @JsonKey(name: 'follow_up_leads')
  final int followUpLeads;
  @JsonKey(name: 'closed_leads')
  final int closedLeads;
  @JsonKey(name: 'incentives_earned')
  final num incentivesEarned;

  HomeOperationalOverview({
    required this.assignedLeads,
    required this.followUpLeads,
    required this.closedLeads,
    required this.incentivesEarned,
  });

  factory HomeOperationalOverview.fromJson(Map<String, dynamic> json) =>
      _$HomeOperationalOverviewFromJson(json);
  Map<String, dynamic> toJson() => _$HomeOperationalOverviewToJson(this);
}

@JsonSerializable()
class HomeTeamMetrics {
  @JsonKey(name: 'team_leads')
  final int teamLeads;
  @JsonKey(name: 'team_admissions')
  final int teamAdmissions;
  @JsonKey(name: 'team_conversion')
  final String teamConversion;
  @JsonKey(name: 'visits_pending')
  final int visitsPending;

  HomeTeamMetrics({
    required this.teamLeads,
    required this.teamAdmissions,
    required this.teamConversion,
    required this.visitsPending,
  });

  factory HomeTeamMetrics.fromJson(Map<String, dynamic> json) =>
      _$HomeTeamMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$HomeTeamMetricsToJson(this);
}

@JsonSerializable()
class HomeBdeStatus {
  final int id;
  final String name;
  final String designation;
  @JsonKey(name: 'conversion_percentage')
  final String conversionPercentage;
  @JsonKey(name: 'leads_assigned')
  final String leadsAssigned;
  @JsonKey(name: 'online_status')
  final String onlineStatus;
  @JsonKey(name: 'online_time')
  final String? onlineTime;
  @JsonKey(name: 'location_lat')
  final num? locationLat;
  @JsonKey(name: 'location_lng')
  final num? locationLng;

  HomeBdeStatus({
    required this.id,
    required this.name,
    required this.designation,
    required this.conversionPercentage,
    required this.leadsAssigned,
    required this.onlineStatus,
    this.onlineTime,
    this.locationLat,
    this.locationLng,
  });

  factory HomeBdeStatus.fromJson(Map<String, dynamic> json) =>
      _$HomeBdeStatusFromJson(json);
  Map<String, dynamic> toJson() => _$HomeBdeStatusToJson(this);
}

@JsonSerializable()
class HomeTerritoryReport {
  @JsonKey(name: 'territory_name')
  final String territoryName;
  @JsonKey(name: 'manager_name')
  final String managerName;
  @JsonKey(name: 'manager_designation')
  final String managerDesignation;
  @JsonKey(name: 'leads_count')
  final int leadsCount;
  @JsonKey(name: 'bdes_count')
  final int bdesCount;
  @JsonKey(name: 'conversion_percentage')
  final String conversionPercentage;

  const HomeTerritoryReport({
    required this.territoryName,
    required this.managerName,
    required this.managerDesignation,
    required this.leadsCount,
    required this.bdesCount,
    required this.conversionPercentage,
  });

  factory HomeTerritoryReport.fromJson(Map<String, dynamic> json) =>
      _$HomeTerritoryReportFromJson(json);
  Map<String, dynamic> toJson() => _$HomeTerritoryReportToJson(this);
}

num? _parseLocation(dynamic val) {
  if (val == null) return null;
  if (val is num) return val;
  if (val is String) {
    return num.tryParse(val);
  }
  return null;
}
