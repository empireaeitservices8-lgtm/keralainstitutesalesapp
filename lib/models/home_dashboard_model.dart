import 'package:json_annotation/json_annotation.dart';

part 'home_dashboard_model.g.dart';

@JsonSerializable()
class HomeDashboardModel {
  final HomeUser user;
  @JsonKey(name: 'designation_id')
  final int designationId;
  @JsonKey(name: 'designation_name')
  final String designationName;
  final HomeAttendance attendance;
  @JsonKey(name: 'eod_sync')
  final HomeEodSync eodSync;
  @JsonKey(name: 'operational_overview')
  final HomeOperationalOverview operationalOverview;

  HomeDashboardModel({
    required this.user,
    required this.designationId,
    required this.designationName,
    required this.attendance,
    required this.eodSync,
    required this.operationalOverview,
  });

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) => _$HomeDashboardModelFromJson(json);
  Map<String, dynamic> toJson() => _$HomeDashboardModelToJson(this);
}

@JsonSerializable()
class HomeUser {
  final int id;
  final String name;
  final String email;

  HomeUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory HomeUser.fromJson(Map<String, dynamic> json) => _$HomeUserFromJson(json);
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
  @JsonKey(name: 'is_checked_in')
  final bool isCheckedIn;

  HomeAttendance({
    required this.checkInTime,
    required this.checkOutTime,
    required this.shiftStatus,
    required this.isCheckedIn,
  });

  factory HomeAttendance.fromJson(Map<String, dynamic> json) => _$HomeAttendanceFromJson(json);
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

  factory HomeEodSync.fromJson(Map<String, dynamic> json) => _$HomeEodSyncFromJson(json);
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

  factory HomeOperationalOverview.fromJson(Map<String, dynamic> json) => _$HomeOperationalOverviewFromJson(json);
  Map<String, dynamic> toJson() => _$HomeOperationalOverviewToJson(this);
}
