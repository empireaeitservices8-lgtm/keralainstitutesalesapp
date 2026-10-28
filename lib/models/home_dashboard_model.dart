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
                ?.whereType<Map>()
                .map((e) => HomeBdeStatus.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        return MapEntry(key.toString(), list);
      });
    }
    return null;
  }

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) {
    return HomeDashboardModel(
      user: json['user'] is Map<String, dynamic>
          ? HomeUser.fromJson(json['user'] as Map<String, dynamic>)
          : (json['user'] is Map
              ? HomeUser.fromJson(Map<String, dynamic>.from(json['user'] as Map))
              : HomeUser(id: 0, name: '', email: '')),
      designationId: UiHelpers.parseInt(json['designation_id']),
      designationName:
          (json['designation_name'] ?? json['designation'] ?? '').toString(),
      attendance: json['attendance'] is Map
          ? HomeAttendance.fromJson(
              Map<String, dynamic>.from(json['attendance'] as Map),
            )
          : null,
      eodSync: json['eod_sync'] is Map
          ? HomeEodSync.fromJson(
              Map<String, dynamic>.from(json['eod_sync'] as Map),
            )
          : null,
      operationalOverview: json['operational_overview'] is Map
          ? HomeOperationalOverview.fromJson(
              Map<String, dynamic>.from(json['operational_overview'] as Map),
            )
          : null,
      dashboardType: json['dashboard_type']?.toString(),
      teamName: json['team_name']?.toString(),
      teamMetrics: json['team_metrics'] is Map
          ? HomeTeamMetrics.fromJson(
              Map<String, dynamic>.from(json['team_metrics'] as Map),
            )
          : null,
      teamSubordinateStatus:
          _parseSubordinateStatus(json['team_subordinate_status']),
      territoryReport: (json['territory_report'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((e) =>
              HomeTerritoryReport.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => _$HomeDashboardModelToJson(this);
}

@JsonSerializable()
class HomeUser {
  final int id;
  final String name;
  final String email;

  HomeUser({required this.id, required this.name, required this.email});

  factory HomeUser.fromJson(Map<String, dynamic> json) => HomeUser(
        id: UiHelpers.parseInt(json['id']),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
      );
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

  factory HomeAttendance.fromJson(Map<String, dynamic> json) => HomeAttendance(
        checkInTime: (json['check_in_time'] ?? '').toString(),
        checkOutTime: (json['check_out_time'] ?? '').toString(),
        shiftStatus: (json['shift_status'] ?? '').toString(),
        isCheckedIn: UiHelpers.parseBool(json['is_checked_in']),
        locationLat: _parseLocation(json['location_lat']),
        locationLng: _parseLocation(json['location_lng']),
      );
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

  factory HomeEodSync.fromJson(Map<String, dynamic> json) => HomeEodSync(
        tasksCompleted: UiHelpers.parseInt(json['tasks_completed']),
        totalTasks: UiHelpers.parseInt(json['total_tasks']),
        completionPercentage:
            UiHelpers.parseDouble(json['completion_percentage']),
      );
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
      HomeOperationalOverview(
        assignedLeads: UiHelpers.parseInt(json['assigned_leads']),
        followUpLeads: UiHelpers.parseInt(json['follow_up_leads']),
        closedLeads: UiHelpers.parseInt(json['closed_leads']),
        incentivesEarned:
            UiHelpers.parseDouble(json['incentives_earned']),
      );
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
      HomeTeamMetrics(
        teamLeads: UiHelpers.parseInt(json['team_leads']),
        teamAdmissions: UiHelpers.parseInt(json['team_admissions']),
        teamConversion: (json['team_conversion'] ?? '0%').toString(),
        visitsPending: UiHelpers.parseInt(json['visits_pending']),
      );
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

  factory HomeBdeStatus.fromJson(Map<String, dynamic> json) => HomeBdeStatus(
        id: UiHelpers.parseInt(json['id']),
        name: (json['name'] ?? '').toString(),
        designation: (json['designation'] ?? '').toString(),
        conversionPercentage:
            (json['conversion_percentage'] ?? '0%').toString(),
        leadsAssigned: (json['leads_assigned'] ?? '0').toString(),
        onlineStatus: (json['online_status'] ?? 'offline').toString(),
        onlineTime: json['online_time']?.toString(),
        locationLat: _parseLocation(json['location_lat']),
        locationLng: _parseLocation(json['location_lng']),
      );
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
      HomeTerritoryReport(
        territoryName: (json['territory_name'] ?? '').toString(),
        managerName: (json['manager_name'] ?? '').toString(),
        managerDesignation: (json['manager_designation'] ?? '').toString(),
        leadsCount: UiHelpers.parseInt(json['leads_count']),
        bdesCount: UiHelpers.parseInt(json['bdes_count']),
        conversionPercentage:
            (json['conversion_percentage'] ?? '0%').toString(),
      );
  Map<String, dynamic> toJson() => _$HomeTerritoryReportToJson(this);
}

num? _parseLocation(dynamic val) {
  if (val == null) return null;
  if (val is num) return val;
  if (val is String) {
    return num.tryParse(val.trim());
  }
  return null;
}
