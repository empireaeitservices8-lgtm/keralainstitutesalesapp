// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeDashboardModel _$HomeDashboardModelFromJson(Map<String, dynamic> json) =>
    HomeDashboardModel(
      user: HomeUser.fromJson(json['user'] as Map<String, dynamic>),
      designationId: (json['designation_id'] as num? ?? 0).toInt(),
      designationName: json['designation_name'] as String? ?? '',
      attendance: HomeAttendance.fromJson(json['attendance'] as Map<String, dynamic>),
      eodSync: HomeEodSync.fromJson(json['eod_sync'] as Map<String, dynamic>),
      operationalOverview: HomeOperationalOverview.fromJson(
          json['operational_overview'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HomeDashboardModelToJson(HomeDashboardModel instance) =>
    <String, dynamic>{
      'user': instance.user,
      'designation_id': instance.designationId,
      'designation_name': instance.designationName,
      'attendance': instance.attendance,
      'eod_sync': instance.eodSync,
      'operational_overview': instance.operationalOverview,
    };

HomeUser _$HomeUserFromJson(Map<String, dynamic> json) => HomeUser(
      id: (json['id'] as num? ?? 0).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );

Map<String, dynamic> _$HomeUserToJson(HomeUser instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };

HomeAttendance _$HomeAttendanceFromJson(Map<String, dynamic> json) =>
    HomeAttendance(
      checkInTime: json['check_in_time'] as String? ?? '--:--',
      checkOutTime: json['check_out_time'] as String? ?? '--:--',
      shiftStatus: json['shift_status'] as String? ?? 'OFFLINE',
      isCheckedIn: json['is_checked_in'] as bool? ?? false,
    );

Map<String, dynamic> _$HomeAttendanceToJson(HomeAttendance instance) =>
    <String, dynamic>{
      'check_in_time': instance.checkInTime,
      'check_out_time': instance.checkOutTime,
      'shift_status': instance.shiftStatus,
      'is_checked_in': instance.isCheckedIn,
    };

HomeEodSync _$HomeEodSyncFromJson(Map<String, dynamic> json) => HomeEodSync(
      tasksCompleted: (json['tasks_completed'] as num? ?? 0).toInt(),
      totalTasks: (json['total_tasks'] as num? ?? 0).toInt(),
      completionPercentage: json['completion_percentage'] as num? ?? 0,
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
      assignedLeads: (json['assigned_leads'] as num? ?? 0).toInt(),
      followUpLeads: (json['follow_up_leads'] as num? ?? 0).toInt(),
      closedLeads: (json['closed_leads'] as num? ?? 0).toInt(),
      incentivesEarned: json['incentives_earned'] as num? ?? 0,
    );

Map<String, dynamic> _$HomeOperationalOverviewToJson(
        HomeOperationalOverview instance) =>
    <String, dynamic>{
      'assigned_leads': instance.assignedLeads,
      'follow_up_leads': instance.followUpLeads,
      'closed_leads': instance.closedLeads,
      'incentives_earned': instance.incentivesEarned,
    };
