// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeDashboardModel _$HomeDashboardModelFromJson(Map<String, dynamic> json) =>
    HomeDashboardModel(
      user: json['user'] == null
          ? HomeUser(id: 0, name: '', email: '')
          : HomeUser.fromJson(json['user'] as Map<String, dynamic>),
      designationId: (json['designation_id'] as num? ?? 0).toInt(),
      designationName: json['designation_name'] as String? ?? '',
      attendance: json['attendance'] == null
          ? null
          : HomeAttendance.fromJson(json['attendance'] as Map<String, dynamic>),
      eodSync: json['eod_sync'] == null
          ? null
          : HomeEodSync.fromJson(json['eod_sync'] as Map<String, dynamic>),
      operationalOverview: json['operational_overview'] == null
          ? null
          : HomeOperationalOverview.fromJson(
              json['operational_overview'] as Map<String, dynamic>,
            ),
      dashboardType: json['dashboard_type'] as String?,
      teamName: json['team_name'] as String?,
      teamMetrics: json['team_metrics'] == null
          ? null
          : HomeTeamMetrics.fromJson(
              json['team_metrics'] as Map<String, dynamic>),
      teamSubordinateStatus: (json['team_subordinate_status'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>)
                  .map((e) => HomeBdeStatus.fromJson(e as Map<String, dynamic>))
                  .toList(),
            ),
          ),
      territoryReport: (json['territory_report'] as List<dynamic>?)
          ?.map((e) => HomeTerritoryReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HomeDashboardModelToJson(HomeDashboardModel instance) =>
    <String, dynamic>{
      'user': instance.user,
      'designation_id': instance.designationId,
      'designation_name': instance.designationName,
      'attendance': instance.attendance,
      'eod_sync': instance.eodSync,
      'operational_overview': instance.operationalOverview,
      'dashboard_type': instance.dashboardType,
      'team_name': instance.teamName,
      'team_metrics': instance.teamMetrics,
      'team_subordinate_status': instance.teamSubordinateStatus,
      'territory_report': instance.territoryReport,
    };

HomeUser _$HomeUserFromJson(Map<String, dynamic> json) => HomeUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$HomeUserToJson(HomeUser instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };

HomeAttendance _$HomeAttendanceFromJson(Map<String, dynamic> json) =>
    HomeAttendance(
      checkInTime: json['check_in_time'] as String? ?? '',
      checkOutTime: json['check_out_time'] as String? ?? '',
      shiftStatus: json['shift_status'] as String? ?? '',
      isCheckedIn: json['is_checked_in'] as bool? ?? false,
      locationLat: _parseLocation(json['location_lat']),
      locationLng: _parseLocation(json['location_lng']),
    );

Map<String, dynamic> _$HomeAttendanceToJson(HomeAttendance instance) =>
    <String, dynamic>{
      'check_in_time': instance.checkInTime,
      'check_out_time': instance.checkOutTime,
      'shift_status': instance.shiftStatus,
      'is_checked_in': instance.isCheckedIn,
      'location_lat': instance.locationLat,
      'location_lng': instance.locationLng,
    };

HomeEodSync _$HomeEodSyncFromJson(Map<String, dynamic> json) => HomeEodSync(
      tasksCompleted: (json['tasks_completed'] as num).toInt(),
      totalTasks: (json['total_tasks'] as num).toInt(),
      completionPercentage: json['completion_percentage'] as num,
    );

Map<String, dynamic> _$HomeEodSyncToJson(HomeEodSync instance) =>
    <String, dynamic>{
      'tasks_completed': instance.tasksCompleted,
      'total_tasks': instance.totalTasks,
      'completion_percentage': instance.completionPercentage,
    };

HomeOperationalOverview _$HomeOperationalOverviewFromJson(
        Map<String, dynamic> json) =>
    HomeOperationalOverview(
      assignedLeads: (json['assigned_leads'] as num).toInt(),
      followUpLeads: (json['follow_up_leads'] as num).toInt(),
      closedLeads: (json['closed_leads'] as num).toInt(),
      incentivesEarned: json['incentives_earned'] as num,
    );

Map<String, dynamic> _$HomeOperationalOverviewToJson(
        HomeOperationalOverview instance) =>
    <String, dynamic>{
      'assigned_leads': instance.assignedLeads,
      'follow_up_leads': instance.followUpLeads,
      'closed_leads': instance.closedLeads,
      'incentives_earned': instance.incentivesEarned,
    };

HomeTeamMetrics _$HomeTeamMetricsFromJson(Map<String, dynamic> json) =>
    HomeTeamMetrics(
      teamLeads: (json['team_leads'] as num).toInt(),
      teamAdmissions: (json['team_admissions'] as num).toInt(),
      teamConversion: json['team_conversion'] as String,
      visitsPending: (json['visits_pending'] as num).toInt(),
    );

Map<String, dynamic> _$HomeTeamMetricsToJson(HomeTeamMetrics instance) =>
    <String, dynamic>{
      'team_leads': instance.teamLeads,
      'team_admissions': instance.teamAdmissions,
      'team_conversion': instance.teamConversion,
      'visits_pending': instance.visitsPending,
    };

HomeBdeStatus _$HomeBdeStatusFromJson(Map<String, dynamic> json) =>
    HomeBdeStatus(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      designation: json['designation'] as String,
      conversionPercentage: json['conversion_percentage'] as String,
      leadsAssigned: json['leads_assigned'] as String,
      onlineStatus: json['online_status'] as String,
      onlineTime: json['online_time'] as String?,
      locationLat: _parseLocation(json['location_lat']),
      locationLng: _parseLocation(json['location_lng']),
    );

Map<String, dynamic> _$HomeBdeStatusToJson(HomeBdeStatus instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'designation': instance.designation,
      'conversion_percentage': instance.conversionPercentage,
      'leads_assigned': instance.leadsAssigned,
      'online_status': instance.onlineStatus,
      'online_time': instance.onlineTime,
      'location_lat': instance.locationLat,
      'location_lng': instance.locationLng,
    };

HomeTerritoryReport _$HomeTerritoryReportFromJson(Map<String, dynamic> json) =>
    HomeTerritoryReport(
      territoryName: json['territory_name'] as String? ?? '',
      managerName: json['manager_name'] as String? ?? '',
      managerDesignation: json['manager_designation'] as String? ?? '',
      leadsCount: (json['leads_count'] as num? ?? 0).toInt(),
      bdesCount: (json['bdes_count'] as num? ?? 0).toInt(),
      conversionPercentage: json['conversion_percentage'] as String? ?? '',
    );

Map<String, dynamic> _$HomeTerritoryReportToJson(HomeTerritoryReport instance) =>
    <String, dynamic>{
      'territory_name': instance.territoryName,
      'manager_name': instance.managerName,
      'manager_designation': instance.managerDesignation,
      'leads_count': instance.leadsCount,
      'bdes_count': instance.bdesCount,
      'conversion_percentage': instance.conversionPercentage,
    };
