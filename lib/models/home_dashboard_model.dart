import '../utils/helpers.dart';
import 'performance_task.dart';

class HomeDashboardModel {
  final HomeUser user;
  final int designationId;
  final String designationName;
  final HomeAttendance? attendance;
  final HomeEodSync? eodSync;
  final HomeOperationalOverview? operationalOverview;
  final String? dashboardType;
  final String? teamName;
  final HomeTeamMetrics? teamMetrics;
  final Map<String, List<HomeBdeStatus>>? teamSubordinateStatus;
  final List<HomeTerritoryReport>? territoryReport;

  // Rich API objects directly from /api/home
  final HomeTasksData? tasks;
  final HomeLeavesData? leaves;
  final HomeWalletData? wallet;
  final HomeLeadsData? leads;
  final HomeTeamData? team;
  final HomeTargetData? target;
  final HomeFollowUpsData? followUps;
  final Map<String, dynamic>? rawJson;

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
    this.tasks,
    this.leaves,
    this.wallet,
    this.leads,
    this.team,
    this.target,
    this.followUps,
    this.rawJson,
  });

  HomeDashboardModel copyWith({
    HomeUser? user,
    int? designationId,
    String? designationName,
    HomeAttendance? attendance,
    HomeEodSync? eodSync,
    HomeOperationalOverview? operationalOverview,
    String? dashboardType,
    String? teamName,
    HomeTeamMetrics? teamMetrics,
    Map<String, List<HomeBdeStatus>>? teamSubordinateStatus,
    List<HomeTerritoryReport>? territoryReport,
    HomeTasksData? tasks,
    HomeLeavesData? leaves,
    HomeWalletData? wallet,
    HomeLeadsData? leads,
    HomeTeamData? team,
    HomeTargetData? target,
    HomeFollowUpsData? followUps,
    Map<String, dynamic>? rawJson,
  }) {
    return HomeDashboardModel(
      user: user ?? this.user,
      designationId: designationId ?? this.designationId,
      designationName: designationName ?? this.designationName,
      attendance: attendance ?? this.attendance,
      eodSync: eodSync ?? this.eodSync,
      operationalOverview: operationalOverview ?? this.operationalOverview,
      dashboardType: dashboardType ?? this.dashboardType,
      teamName: teamName ?? this.teamName,
      teamMetrics: teamMetrics ?? this.teamMetrics,
      teamSubordinateStatus: teamSubordinateStatus ?? this.teamSubordinateStatus,
      territoryReport: territoryReport ?? this.territoryReport,
      tasks: tasks ?? this.tasks,
      leaves: leaves ?? this.leaves,
      wallet: wallet ?? this.wallet,
      leads: leads ?? this.leads,
      team: team ?? this.team,
      target: target ?? this.target,
      followUps: followUps ?? this.followUps,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  // Employee alias for user
  HomeUser get employee => user;

  // Direct check-in / logged-in status getters from Home API
  bool get isUserCheckedIn {
    if (attendance != null && attendance!.isCheckedIn) return true;
    if (rawJson != null) {
      if (rawJson!['is_checked_in'] != null) {
        return UiHelpers.parseBool(rawJson!['is_checked_in']);
      }
      if (rawJson!['checked_in'] != null) {
        return UiHelpers.parseBool(rawJson!['checked_in']);
      }
      if (rawJson!['attendance'] is Map) {
        final att = rawJson!['attendance'] as Map;
        if (att['is_checked_in'] != null) return UiHelpers.parseBool(att['is_checked_in']);
        if (att['checked_in'] != null) return UiHelpers.parseBool(att['checked_in']);
      }
      if (rawJson!['user'] is Map) {
        final u = rawJson!['user'] as Map;
        if (u['is_checked_in'] != null) return UiHelpers.parseBool(u['is_checked_in']);
        if (u['checked_in'] != null) return UiHelpers.parseBool(u['checked_in']);
      }
      final s = (rawJson!['status'] ?? rawJson!['shift_status'])?.toString().toUpperCase();
      if (s == 'ONLINE' || s == 'PRESENT' || s == 'ACTIVE' || s == 'CHECKED_IN') return true;
    }
    return false;
  }

  bool get isUserCheckedOut {
    if (attendance != null && attendance!.isCheckedOut) return true;
    if (rawJson != null) {
      if (rawJson!['is_checked_out'] != null) {
        return UiHelpers.parseBool(rawJson!['is_checked_out']);
      }
      if (rawJson!['checked_out'] != null) {
        return UiHelpers.parseBool(rawJson!['checked_out']);
      }
      if (rawJson!['attendance'] is Map) {
        final att = rawJson!['attendance'] as Map;
        if (att['is_checked_out'] != null) return UiHelpers.parseBool(att['is_checked_out']);
        if (att['checked_out'] != null) return UiHelpers.parseBool(att['checked_out']);
      }
      final s = (rawJson!['status'] ?? rawJson!['shift_status'])?.toString().toUpperCase();
      if (s == 'COMPLETED' || s == 'CHECKED_OUT') return true;
    }
    return false;
  }

  // Direct getters for high-level metrics from Home API
  int get totalLeadsCount => leads?.total ?? operationalOverview?.assignedLeads ?? 0;
  int get todayLeadsCount => leads?.today ?? operationalOverview?.followUpLeads ?? 0;
  int get admittedLeadsCount => leads?.admitted ?? operationalOverview?.closedLeads ?? 0;
  num get walletBalance => wallet?.balance ?? operationalOverview?.incentivesEarned ?? 0;
  int get totalTasksCount => tasks?.total ?? eodSync?.totalTasks ?? 0;
  int get completedTasksCount => tasks?.completed ?? eodSync?.tasksCompleted ?? 0;
  int get pendingTasksCount => tasks?.pending ?? (totalTasksCount - completedTasksCount);

  // Monthly Target & Follow-ups getters for SM & management directly from Home API
  int get monthlyTargetLeads {
    if (target != null && target!.targetLeads > 0) return target!.targetLeads;
    if (target != null && target!.monthlyTarget > 0) return target!.monthlyTarget;
    if (rawJson != null) {
      final val = UiHelpers.parseInt(rawJson!['monthly_target'] ?? rawJson!['target_leads'] ?? rawJson!['target']);
      if (val > 0) return val;
    }
    return 0;
  }

  int get monthlyTargetAdmissions {
    if (target != null && target!.targetAdmissions > 0) return target!.targetAdmissions;
    if (rawJson != null) {
      final val = UiHelpers.parseInt(rawJson!['target_admissions'] ?? rawJson!['monthly_admissions_target']);
      if (val > 0) return val;
    }
    return 0;
  }

  int get totalMonthlyLeadsCount {
    if (leads != null && leads!.total > 0) return leads!.total;
    if (rawJson != null) {
      final val = UiHelpers.parseInt(rawJson!['total_monthly_leads'] ?? rawJson!['total_monthly_lead'] ?? rawJson!['total_leads']);
      if (val > 0) return val;
    }
    if (team != null && team!.totals.leadsTotal > 0) return team!.totals.leadsTotal;
    if (operationalOverview != null && operationalOverview!.assignedLeads > 0) {
      return operationalOverview!.assignedLeads;
    }
    return totalLeadsCount;
  }

  int get teamFollowUpCount {
    if (followUps != null && followUps!.completed > 0) return followUps!.completed;
    if (rawJson != null) {
      final val = UiHelpers.parseInt(rawJson!['follow_up'] ?? rawJson!['team_follow_up'] ?? rawJson!['follow_ups']);
      if (val > 0) return val;
    }
    if (team != null && team!.totals.tasksCompleted > 0) return team!.totals.tasksCompleted;
    if (tasks != null && tasks!.completed > 0) return tasks!.completed;
    if (operationalOverview != null && operationalOverview!.followUpLeads > 0) {
      return operationalOverview!.followUpLeads;
    }
    if (leads != null && leads!.today > 0) return leads!.today;
    return 0;
  }

  int get pendingFollowUpsCount {
    if (followUps != null && followUps!.pending > 0) return followUps!.pending;
    if (rawJson != null) {
      final val = UiHelpers.parseInt(rawJson!['pending_follow_up'] ?? rawJson!['pending_follow_ups'] ?? rawJson!['pending_followup']);
      if (val > 0) return val;
    }
    if (team != null && team!.totals.tasksPending > 0) return team!.totals.tasksPending;
    if (tasks != null && tasks!.pending > 0) return tasks!.pending;
    if (teamMetrics != null && teamMetrics!.visitsPending > 0) return teamMetrics!.visitsPending;
    return 0;
  }

  static Map<String, List<HomeBdeStatus>>? _parseSubordinateStatus(dynamic json) {
    if (json == null) return null;
    if (json is Map) {
      return json.map((key, value) {
        final list = (value as List?)
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
    // 1. Employee / User
    final employeeRaw = json['employee'] ?? json['user'];
    final HomeUser userObj = employeeRaw is Map
        ? HomeUser.fromJson(Map<String, dynamic>.from(employeeRaw))
        : HomeUser(id: 0, name: '', email: '');

    final desId = UiHelpers.parseInt(
      json['designation_id'] ?? json['employee']?['designation_id'],
    );
    final desName = (json['designation_name'] ??
            json['designation'] ??
            json['employee']?['designation_name'] ??
            userObj.designationName)
        .toString();

    // 2. Attendance
    var attendanceObj = json['attendance'] != null
        ? HomeAttendance.fromJsonDynamic(json['attendance'])
        : (json['attendance_list'] != null
            ? HomeAttendance.fromJsonDynamic(json['attendance_list'])
            : null);

    if (attendanceObj == null) {
      final hasRootAttendance = json['is_checked_in'] != null ||
          json['checked_in'] != null ||
          json['check_in_time'] != null ||
          json['check_in'] != null ||
          json['shift_status'] != null;

      final hasUserAttendance = json['user'] is Map &&
          ((json['user'] as Map)['is_checked_in'] != null ||
              (json['user'] as Map)['checked_in'] != null);

      if (hasRootAttendance) {
        attendanceObj = HomeAttendance.fromJson(json);
      } else if (hasUserAttendance) {
        attendanceObj = HomeAttendance.fromJson(Map<String, dynamic>.from(json['user'] as Map));
      }
    }

    // 3. Tasks
    HomeTasksData? tasksData;
    if (json['tasks'] is Map) {
      tasksData = HomeTasksData.fromJson(Map<String, dynamic>.from(json['tasks'] as Map));
    }

    // 4. Leaves
    HomeLeavesData? leavesData;
    if (json['leaves'] is Map) {
      leavesData = HomeLeavesData.fromJson(Map<String, dynamic>.from(json['leaves'] as Map));
    }

    // 5. Wallet
    HomeWalletData? walletData;
    if (json['wallet'] is Map) {
      walletData = HomeWalletData.fromJson(Map<String, dynamic>.from(json['wallet'] as Map));
    }

    // 6. Leads
    HomeLeadsData? leadsData;
    if (json['leads'] is Map) {
      leadsData = HomeLeadsData.fromJson(Map<String, dynamic>.from(json['leads'] as Map));
    }

    // 7. Team
    HomeTeamData? teamData;
    if (json['team'] is Map) {
      teamData = HomeTeamData.fromJson(Map<String, dynamic>.from(json['team'] as Map));
    }

    // 8. Target data (specifically checking monthly_target & target from /api/home)
    dynamic rawTarget = json['monthly_target'] ??
        json['target'] ??
        json['targets'] ??
        json['target_leads'] ??
        json['team_target'] ??
        (json['team'] is Map
            ? (json['team']['monthly_target'] ??
                json['team']['target'] ??
                json['team']['totals']?['monthly_target'] ??
                json['team']['totals']?['target'])
            : null) ??
        (json['leads'] is Map
            ? (json['leads']['monthly_target'] ?? json['leads']['target'])
            : null);

    dynamic rawAdmissions = json['target_admissions'] ??
        json['monthly_admissions_target'] ??
        (json['targets'] is Map
            ? (json['targets']['admissions'] ??
                json['targets']['monthly']?['admissions'])
            : null) ??
        (json['monthly_target'] is Map
            ? json['monthly_target']['admissions']
            : null);

    HomeTargetData? targetData;
    if (rawTarget != null || rawAdmissions != null) {
      targetData = HomeTargetData.fromJson(rawTarget, rawAdmissions);
    } else if (json['target_leads'] != null || json['target_admissions'] != null) {
      targetData = HomeTargetData(
        targetLeads: UiHelpers.parseInt(json['target_leads']),
        targetAdmissions: UiHelpers.parseInt(json['target_admissions']),
        monthlyTarget: UiHelpers.parseInt(json['target_leads']),
      );
    }

    // 9. Follow-up data (specifically checking follow_up & pending_follow_up from /api/home)
    dynamic rawFollowUp = json['follow_up'] ??
        json['follow_ups'] ??
        json['team_follow_up'] ??
        json['followup'] ??
        (json['leads'] is Map
            ? (json['leads']['follow_up'] ?? json['leads']['follow_ups'])
            : null) ??
        (json['tasks'] is Map
            ? (json['tasks']['follow_up'] ?? json['tasks']['follow_ups'])
            : null) ??
        (json['team'] is Map
            ? (json['team']['follow_up'] ??
                json['team']['totals']?['follow_up'])
            : null) ??
        json['operational_overview']?['follow_up_leads'];

    dynamic rawPendingFollowUp = json['pending_follow_up'] ??
        json['pending_follow_ups'] ??
        json['pending_followup'] ??
        (json['leads'] is Map
            ? (json['leads']['pending_follow_up'] ??
                json['leads']['pending_follow_ups'])
            : null) ??
        (json['tasks'] is Map
            ? (json['tasks']['pending_follow_up'] ??
                json['tasks']['pending_follow_ups'])
            : null) ??
        (json['team'] is Map
            ? (json['team']['pending_follow_up'] ??
                json['team']['totals']?['pending_follow_up'])
            : null);

    HomeFollowUpsData? followUpsData;
    if (rawFollowUp != null || rawPendingFollowUp != null) {
      followUpsData = HomeFollowUpsData.fromJson(rawFollowUp, rawPendingFollowUp);
    } else if (teamData != null &&
        (teamData.totals.tasksCompleted > 0 || teamData.totals.tasksPending > 0)) {
      followUpsData = HomeFollowUpsData(
        total: teamData.totals.tasksTotal,
        completed: teamData.totals.tasksCompleted,
        pending: teamData.totals.tasksPending,
      );
    } else if (tasksData != null &&
        (tasksData.completed > 0 || tasksData.pending > 0)) {
      followUpsData = HomeFollowUpsData(
        total: tasksData.total,
        completed: tasksData.completed,
        pending: tasksData.pending,
      );
    }

    // 10. EOD Sync (from json or synthesized from tasks)
    HomeEodSync? eodSyncObj;
    if (json['eod_sync'] is Map) {
      eodSyncObj = HomeEodSync.fromJson(Map<String, dynamic>.from(json['eod_sync'] as Map));
    } else if (tasksData != null) {
      final compPct = tasksData.total > 0
          ? ((tasksData.completed / tasksData.total) * 100)
          : 0.0;
      eodSyncObj = HomeEodSync(
        tasksCompleted: tasksData.completed,
        totalTasks: tasksData.total,
        completionPercentage: compPct,
      );
    }

    // 9. Operational Overview (from json or synthesized from leads + wallet)
    HomeOperationalOverview? opOverviewObj;
    if (json['operational_overview'] is Map) {
      opOverviewObj = HomeOperationalOverview.fromJson(
        Map<String, dynamic>.from(json['operational_overview'] as Map),
      );
    } else if (leadsData != null || walletData != null) {
      opOverviewObj = HomeOperationalOverview(
        assignedLeads: leadsData?.total ?? 0,
        followUpLeads: leadsData?.today ?? 0,
        closedLeads: leadsData?.admitted ?? 0,
        incentivesEarned: walletData?.balance ?? 0,
      );
    }

    // 10. Team Metrics (from json or synthesized from team + leads)
    HomeTeamMetrics? teamMetricsObj;
    if (json['team_metrics'] is Map) {
      teamMetricsObj = HomeTeamMetrics.fromJson(
        Map<String, dynamic>.from(json['team_metrics'] as Map),
      );
    } else if (teamData != null || leadsData != null) {
      final tLeads = teamData != null && teamData.totals.leadsTotal > 0
          ? teamData.totals.leadsTotal
          : (leadsData?.total ?? 0);
      final tAdmissions = leadsData?.admitted ?? 0;
      final tConversion = tLeads > 0
          ? '${((tAdmissions / tLeads) * 100).toInt()}%'
          : '0%';
      final tPending = teamData != null && teamData.totals.tasksPending > 0
          ? teamData.totals.tasksPending
          : (tasksData?.pending ?? 0);

      teamMetricsObj = HomeTeamMetrics(
        teamLeads: tLeads,
        teamAdmissions: tAdmissions,
        teamConversion: tConversion,
        visitsPending: tPending,
      );
    }

    return HomeDashboardModel(
      user: userObj,
      designationId: desId,
      designationName: desName,
      attendance: attendanceObj,
      eodSync: eodSyncObj,
      operationalOverview: opOverviewObj,
      dashboardType: json['dashboard_type']?.toString(),
      teamName: json['team_name']?.toString() ?? teamData?.role ?? userObj.team,
      teamMetrics: teamMetricsObj,
      teamSubordinateStatus: _parseSubordinateStatus(json['team_subordinate_status']),
      territoryReport: (json['territory_report'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((e) => HomeTerritoryReport.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      tasks: tasksData,
      leaves: leavesData,
      wallet: walletData,
      leads: leadsData,
      team: teamData,
      target: targetData,
      followUps: followUpsData,
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'employee': user.toJson(),
    'designation_id': designationId,
    'designation_name': designationName,
    'attendance': attendance?.toJson(),
    'eod_sync': eodSync?.toJson(),
    'operational_overview': operationalOverview?.toJson(),
    'dashboard_type': dashboardType,
    'team_name': teamName,
    'team_metrics': teamMetrics?.toJson(),
    'team_subordinate_status': teamSubordinateStatus?.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    ),
    'territory_report': territoryReport?.map((e) => e.toJson()).toList(),
    if (tasks != null) 'tasks': tasks!.toJson(),
    if (leaves != null) 'leaves': leaves!.toJson(),
    if (wallet != null) 'wallet': wallet!.toJson(),
    if (leads != null) 'leads': leads!.toJson(),
    if (team != null) 'team': team!.toJson(),
    if (target != null) 'target': target!.toJson(),
    if (followUps != null) 'follow_ups': followUps!.toJson(),
    if (rawJson != null) 'raw_data': rawJson,
  };
}

class HomeUser {
  final int id;
  final String name;
  final String email;
  final String employeeId;
  final String designationName;
  final int? designationId;
  final String team;
  final String zone;
  final String district;
  final String reportsTo;
  final List<dynamic> roles;
  final List<dynamic> permissions;
  final String? createdAt;
  final String? updatedAt;

  HomeUser({
    required this.id,
    required this.name,
    required this.email,
    this.employeeId = '',
    this.designationName = '',
    this.designationId,
    this.team = '',
    this.zone = '',
    this.district = '',
    this.reportsTo = '',
    this.roles = const [],
    this.permissions = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory HomeUser.fromJson(Map<String, dynamic> json) => HomeUser(
    id: UiHelpers.parseInt(json['id']),
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    employeeId: (json['employee_id'] ?? '').toString(),
    designationName: (json['designation_name'] ?? json['designation'] ?? '').toString(),
    designationId: json['designation_id'] != null ? UiHelpers.parseInt(json['designation_id']) : null,
    team: (json['team'] ?? '').toString(),
    zone: (json['zone'] ?? '').toString(),
    district: (json['district'] ?? '').toString(),
    reportsTo: (json['reports_to'] ?? '').toString(),
    roles: (json['roles'] as List<dynamic>?) ?? const [],
    permissions: (json['permissions'] as List<dynamic>?) ?? const [],
    createdAt: json['created_at']?.toString(),
    updatedAt: json['updated_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'employee_id': employeeId,
    'designation_name': designationName,
    'designation_id': designationId,
    'team': team,
    'zone': zone,
    'district': district,
    'reports_to': reportsTo,
    'roles': roles,
    'permissions': permissions,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class HomeAttendance {
  final String checkInTime;
  final String checkOutTime;
  final String shiftStatus;
  final bool isCheckedIn;
  final bool isCheckedOut;
  final String date;
  final double hoursWorked;
  final num? locationLat;
  final num? locationLng;

  HomeAttendance({
    required this.checkInTime,
    required this.checkOutTime,
    required this.shiftStatus,
    required this.isCheckedIn,
    this.isCheckedOut = false,
    this.date = '',
    this.hoursWorked = 0.0,
    this.locationLat,
    this.locationLng,
  });

  bool get checkedIn => isCheckedIn;
  bool get checkedOut => isCheckedOut;
  String get checkIn => checkInTime;
  String get checkOut => checkOutTime;
  String get status => shiftStatus;

  static HomeAttendance? fromJsonDynamic(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      if (raw['attendance'] is Map) {
        return HomeAttendance.fromJson(Map<String, dynamic>.from(raw['attendance'] as Map));
      }
      final punchesList =
          (raw['sessions'] is List && (raw['sessions'] as List).isNotEmpty)
          ? (raw['sessions'] as List)
          : ((raw['punches'] is List && (raw['punches'] as List).isNotEmpty)
                ? (raw['punches'] as List)
                : null);
      if (punchesList != null) {
        final last = punchesList.last;
        if (last is Map) {
          final merged = <String, dynamic>{
            ...Map<String, dynamic>.from(raw),
            ...Map<String, dynamic>.from(last),
          };
          final rawHours = UiHelpers.parseWorkingHours(
            raw['hours_worked'] ??
                raw['hours_worked_formatted'] ??
                raw['working_hours'],
          );
          final lastHours = UiHelpers.parseWorkingHours(
            last['hours_worked'] ??
                last['hours_worked_formatted'] ??
                last['working_hours'],
          );
          if (lastHours == 0.0 && rawHours > 0.0) {
            merged['hours_worked'] =
                raw['hours_worked'] ?? raw['hours_worked_formatted'];
            merged['hours_worked_formatted'] =
                raw['hours_worked_formatted'] ?? raw['hours_worked'];
          }
          return HomeAttendance.fromJson(merged);
        }
      }
      if (raw['list'] is List && (raw['list'] as List).isNotEmpty) {
        final last = (raw['list'] as List).last;
        if (last is Map) {
          return HomeAttendance.fromJson(Map<String, dynamic>.from(last));
        }
      }
      return HomeAttendance.fromJson(Map<String, dynamic>.from(raw));
    }
    if (raw is List && raw.isNotEmpty) {
      final last = raw.last;
      if (last is Map) {
        return HomeAttendance.fromJson(Map<String, dynamic>.from(last));
      }
    }
    return null;
  }

  factory HomeAttendance.fromJson(Map<String, dynamic> json) {
    final rawCheckedIn = json['checked_in'] ??
        json['is_checked_in'] ??
        (json['attendance'] is Map ? (json['attendance']['checked_in'] ?? json['attendance']['is_checked_in']) : null) ??
        (json['user'] is Map ? (json['user']['checked_in'] ?? json['user']['is_checked_in']) : null);

    final rawCheckedOut = json['checked_out'] ??
        json['is_checked_out'] ??
        (json['attendance'] is Map ? (json['attendance']['checked_out'] ?? json['attendance']['is_checked_out']) : null) ??
        (json['user'] is Map ? (json['user']['checked_out'] ?? json['user']['is_checked_out']) : null);

    final checkIn = (json['check_in'] ??
        json['check_in_time'] ??
        (json['attendance'] is Map ? (json['attendance']['check_in'] ?? json['attendance']['check_in_time']) : null) ??
        '').toString();

    final checkOut = (json['check_out'] ??
        json['check_out_time'] ??
        (json['attendance'] is Map ? (json['attendance']['check_out'] ?? json['attendance']['check_out_time']) : null) ??
        '').toString();

    final status = (json['status'] ??
        json['shift_status'] ??
        (json['attendance'] is Map ? (json['attendance']['status'] ?? json['attendance']['shift_status']) : null) ??
        '').toString();

    bool isCheckedIn = false;
    if (rawCheckedIn != null) {
      isCheckedIn = UiHelpers.parseBool(rawCheckedIn);
    } else {
      isCheckedIn = status.toUpperCase() == 'ONLINE' ||
          status.toUpperCase() == 'PRESENT' ||
          status.toUpperCase() == 'ACTIVE' ||
          (checkIn.isNotEmpty && checkIn != '--:--' && checkIn != 'null');
    }

    bool isCheckedOut = false;
    if (rawCheckedOut != null) {
      isCheckedOut = UiHelpers.parseBool(rawCheckedOut);
    } else {
      isCheckedOut = status.toUpperCase() == 'COMPLETED' ||
          status.toUpperCase() == 'CHECKED_OUT' ||
          (checkOut.isNotEmpty && checkOut != '--:--' && checkOut != 'null');
    }

    return HomeAttendance(
      checkInTime: checkIn == 'null' ? '' : checkIn,
      checkOutTime: checkOut == 'null' ? '' : checkOut,
      shiftStatus: status.isNotEmpty
          ? status
          : (isCheckedOut
              ? 'COMPLETED'
              : (isCheckedIn ? 'ACTIVE' : 'OFFLINE')),
      isCheckedIn: isCheckedIn,
      isCheckedOut: isCheckedOut,
      date: (json['date'] ?? '').toString(),
      hoursWorked: UiHelpers.parseWorkingHours(
        json['hours_worked'] ??
            json['hours_worked_formatted'] ??
            json['working_hours'],
      ),
      locationLat: _parseLocation(json['location_lat']),
      locationLng: _parseLocation(json['location_lng']),
    );
  }

  Map<String, dynamic> toJson() => {
    'check_in_time': checkInTime,
    'check_out_time': checkOutTime,
    'check_in': checkInTime,
    'check_out': checkOutTime,
    'shift_status': shiftStatus,
    'status': shiftStatus,
    'is_checked_in': isCheckedIn,
    'checked_in': isCheckedIn,
    'is_checked_out': isCheckedOut,
    'checked_out': isCheckedOut,
    'date': date,
    'hours_worked': hoursWorked,
    'location_lat': locationLat,
    'location_lng': locationLng,
  };
}

class HomeTasksData {
  final int total;
  final int completed;
  final int pending;
  final List<PerformanceTask> list;

  const HomeTasksData({
    this.total = 0,
    this.completed = 0,
    this.pending = 0,
    this.list = const [],
  });

  factory HomeTasksData.fromJson(Map<String, dynamic> json) {
    final rawList = json['list'];
    final List<PerformanceTask> items = (rawList is List)
        ? rawList
            .whereType<Map>()
            .map((e) => PerformanceTask.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : [];

    final tot = UiHelpers.parseInt(json['total'] ?? items.length);
    final comp = UiHelpers.parseInt(json['completed']);
    final pend = UiHelpers.parseInt(json['pending'] ?? (tot >= comp ? tot - comp : 0));

    return HomeTasksData(
      total: tot,
      completed: comp,
      pending: pend,
      list: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'completed': completed,
    'pending': pending,
    'list': list.map((e) => e.toJson()).toList(),
  };
}

class HomeLeavesData {
  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final List<dynamic> list;

  const HomeLeavesData({
    this.total = 0,
    this.pending = 0,
    this.approved = 0,
    this.rejected = 0,
    this.list = const [],
  });

  factory HomeLeavesData.fromJson(Map<String, dynamic> json) => HomeLeavesData(
    total: UiHelpers.parseInt(json['total']),
    pending: UiHelpers.parseInt(json['pending']),
    approved: UiHelpers.parseInt(json['approved']),
    rejected: UiHelpers.parseInt(json['rejected']),
    list: (json['list'] as List<dynamic>?) ?? const [],
  );

  Map<String, dynamic> toJson() => {
    'total': total,
    'pending': pending,
    'approved': approved,
    'rejected': rejected,
    'list': list,
  };
}

class HomeWalletData {
  final num balance;
  final String currency;

  const HomeWalletData({
    this.balance = 0,
    this.currency = 'INR',
  });

  factory HomeWalletData.fromJson(Map<String, dynamic> json) => HomeWalletData(
    balance: (json['balance'] as num?) ?? 0,
    currency: (json['currency'] ?? 'INR').toString(),
  );

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'currency': currency,
  };
}

class HomeLeadsData {
  final int total;
  final int today;
  final int admitted;

  const HomeLeadsData({
    this.total = 0,
    this.today = 0,
    this.admitted = 0,
  });

  factory HomeLeadsData.fromJson(Map<String, dynamic> json) => HomeLeadsData(
    total: UiHelpers.parseInt(json['total']),
    today: UiHelpers.parseInt(json['today']),
    admitted: UiHelpers.parseInt(json['admitted']),
  );

  Map<String, dynamic> toJson() => {
    'total': total,
    'today': today,
    'admitted': admitted,
  };
}

class HomeTeamTotals {
  final int members;
  final int tasksTotal;
  final int tasksCompleted;
  final int tasksPending;
  final int leadsTotal;

  const HomeTeamTotals({
    this.members = 0,
    this.tasksTotal = 0,
    this.tasksCompleted = 0,
    this.tasksPending = 0,
    this.leadsTotal = 0,
  });

  factory HomeTeamTotals.fromJson(Map<String, dynamic> json) => HomeTeamTotals(
    members: UiHelpers.parseInt(json['members']),
    tasksTotal: UiHelpers.parseInt(json['tasks_total']),
    tasksCompleted: UiHelpers.parseInt(json['tasks_completed']),
    tasksPending: UiHelpers.parseInt(json['tasks_pending']),
    leadsTotal: UiHelpers.parseInt(json['leads_total']),
  );

  Map<String, dynamic> toJson() => {
    'members': members,
    'tasks_total': tasksTotal,
    'tasks_completed': tasksCompleted,
    'tasks_pending': tasksPending,
    'leads_total': leadsTotal,
  };
}

class HomeTeamData {
  final bool isManager;
  final String role;
  final String scope;
  final Map<String, dynamic>? manager;
  final List<dynamic> members;
  final HomeTeamTotals totals;

  const HomeTeamData({
    this.isManager = false,
    this.role = '',
    this.scope = '',
    this.manager,
    this.members = const [],
    this.totals = const HomeTeamTotals(),
  });

  factory HomeTeamData.fromJson(Map<String, dynamic> json) => HomeTeamData(
    isManager: UiHelpers.parseBool(json['is_manager']),
    role: (json['role'] ?? '').toString(),
    scope: (json['scope'] ?? '').toString(),
    manager: json['manager'] is Map ? Map<String, dynamic>.from(json['manager'] as Map) : null,
    members: (json['members'] as List<dynamic>?) ?? const [],
    totals: json['totals'] is Map
        ? HomeTeamTotals.fromJson(Map<String, dynamic>.from(json['totals'] as Map))
        : const HomeTeamTotals(),
  );

  Map<String, dynamic> toJson() => {
    'is_manager': isManager,
    'role': role,
    'scope': scope,
    'manager': manager,
    'members': members,
    'totals': totals.toJson(),
  };
}

class HomeEodSync {
  final int tasksCompleted;
  final int totalTasks;
  final num completionPercentage;

  const HomeEodSync({
    required this.tasksCompleted,
    required this.totalTasks,
    required this.completionPercentage,
  });

  factory HomeEodSync.fromJson(Map<String, dynamic> json) => HomeEodSync(
    tasksCompleted: UiHelpers.parseInt(json['tasks_completed']),
    totalTasks: UiHelpers.parseInt(json['total_tasks']),
    completionPercentage: UiHelpers.parseDouble(json['completion_percentage']),
  );

  Map<String, dynamic> toJson() => {
    'tasks_completed': tasksCompleted,
    'total_tasks': totalTasks,
    'completion_percentage': completionPercentage,
  };
}

class HomeOperationalOverview {
  final int assignedLeads;
  final int followUpLeads;
  final int closedLeads;
  final num incentivesEarned;

  const HomeOperationalOverview({
    required this.assignedLeads,
    required this.followUpLeads,
    required this.closedLeads,
    required this.incentivesEarned,
  });

  factory HomeOperationalOverview.fromJson(Map<String, dynamic> json) => HomeOperationalOverview(
    assignedLeads: UiHelpers.parseInt(json['assigned_leads']),
    followUpLeads: UiHelpers.parseInt(json['follow_up_leads']),
    closedLeads: UiHelpers.parseInt(json['closed_leads']),
    incentivesEarned: UiHelpers.parseDouble(json['incentives_earned']),
  );

  Map<String, dynamic> toJson() => {
    'assigned_leads': assignedLeads,
    'follow_up_leads': followUpLeads,
    'closed_leads': closedLeads,
    'incentives_earned': incentivesEarned,
  };
}

class HomeTeamMetrics {
  final int teamLeads;
  final int teamAdmissions;
  final String teamConversion;
  final int visitsPending;

  const HomeTeamMetrics({
    required this.teamLeads,
    required this.teamAdmissions,
    required this.teamConversion,
    required this.visitsPending,
  });

  factory HomeTeamMetrics.fromJson(Map<String, dynamic> json) => HomeTeamMetrics(
    teamLeads: UiHelpers.parseInt(json['team_leads']),
    teamAdmissions: UiHelpers.parseInt(json['team_admissions']),
    teamConversion: (json['team_conversion'] ?? '0%').toString(),
    visitsPending: UiHelpers.parseInt(json['visits_pending']),
  );

  Map<String, dynamic> toJson() => {
    'team_leads': teamLeads,
    'team_admissions': teamAdmissions,
    'team_conversion': teamConversion,
    'visits_pending': visitsPending,
  };
}

class HomeBdeStatus {
  final int id;
  final String name;
  final String designation;
  final String conversionPercentage;
  final String leadsAssigned;
  final String onlineStatus;
  final String? onlineTime;
  final num? locationLat;
  final num? locationLng;

  const HomeBdeStatus({
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
    conversionPercentage: (json['conversion_percentage'] ?? '0%').toString(),
    leadsAssigned: (json['leads_assigned'] ?? '0').toString(),
    onlineStatus: (json['online_status'] ?? 'offline').toString(),
    onlineTime: json['online_time']?.toString(),
    locationLat: _parseLocation(json['location_lat']),
    locationLng: _parseLocation(json['location_lng']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'designation': designation,
    'conversion_percentage': conversionPercentage,
    'leads_assigned': leadsAssigned,
    'online_status': onlineStatus,
    'online_time': onlineTime,
    'location_lat': locationLat,
    'location_lng': locationLng,
  };
}

class HomeTerritoryReport {
  final String territoryName;
  final String managerName;
  final String managerDesignation;
  final int leadsCount;
  final int bdesCount;
  final String conversionPercentage;

  const HomeTerritoryReport({
    required this.territoryName,
    required this.managerName,
    required this.managerDesignation,
    required this.leadsCount,
    required this.bdesCount,
    required this.conversionPercentage,
  });

  factory HomeTerritoryReport.fromJson(Map<String, dynamic> json) => HomeTerritoryReport(
    territoryName: (json['territory_name'] ?? '').toString(),
    managerName: (json['manager_name'] ?? '').toString(),
    managerDesignation: (json['manager_designation'] ?? '').toString(),
    leadsCount: UiHelpers.parseInt(json['leads_count']),
    bdesCount: UiHelpers.parseInt(json['bdes_count']),
    conversionPercentage: (json['conversion_percentage'] ?? '0%').toString(),
  );

  Map<String, dynamic> toJson() => {
    'territory_name': territoryName,
    'manager_name': managerName,
    'manager_designation': managerDesignation,
    'leads_count': leadsCount,
    'bdes_count': bdesCount,
    'conversion_percentage': conversionPercentage,
  };
}

num? _parseLocation(dynamic val) {
  if (val == null) return null;
  if (val is num) return val;
  if (val is String) {
    return num.tryParse(val.trim());
  }
  return null;
}

class HomeTargetData {
  final int targetLeads;
  final int targetAdmissions;
  final int monthlyTarget;
  final int dailyTarget;
  final int dailyAchieved;
  final int dailyRemaining;
  final double dailyPercentage;
  final int monthlyAchieved;
  final int monthlyRemaining;
  final double monthlyPercentage;
  final String period;

  const HomeTargetData({
    this.targetLeads = 0,
    this.targetAdmissions = 0,
    this.monthlyTarget = 0,
    this.dailyTarget = 0,
    this.dailyAchieved = 0,
    this.dailyRemaining = 0,
    this.dailyPercentage = 0.0,
    this.monthlyAchieved = 0,
    this.monthlyRemaining = 0,
    this.monthlyPercentage = 0.0,
    this.period = '',
  });

  bool get hasTargets => dailyTarget > 0 || monthlyTarget > 0 || targetLeads > 0;

  factory HomeTargetData.fromJson(dynamic json, [dynamic admissionsJson]) {
    if (json == null) {
      if (admissionsJson != null) {
        return HomeTargetData(targetAdmissions: UiHelpers.parseInt(admissionsJson));
      }
      return const HomeTargetData();
    }
    if (json is num) {
      final val = json.toInt();
      final adm = admissionsJson != null ? UiHelpers.parseInt(admissionsJson) : 0;
      return HomeTargetData(
        targetLeads: val,
        targetAdmissions: adm,
        monthlyTarget: val,
      );
    }
    if (json is String) {
      final val = int.tryParse(json) ?? 0;
      final adm = admissionsJson != null ? UiHelpers.parseInt(admissionsJson) : 0;
      return HomeTargetData(
        targetLeads: val,
        targetAdmissions: adm,
        monthlyTarget: val,
      );
    }
    if (json is Map) {
      final int dailyTarget = UiHelpers.parseInt(json['daily_target'] ?? json['daily']);
      final int dailyAchieved = UiHelpers.parseInt(json['daily_achieved']);
      final int dailyRemaining = json['daily_remaining'] != null
          ? UiHelpers.parseInt(json['daily_remaining'])
          : (dailyTarget - dailyAchieved).clamp(0, 999999);
      final double dailyPercentage = (json['daily_percentage'] as num?)?.toDouble() ??
          (dailyTarget > 0 ? ((dailyAchieved / dailyTarget) * 100).clamp(0.0, 100.0) : 0.0);

      int mTarget = UiHelpers.parseInt(
        json['monthly_target'] ?? json['target'] ?? json['target_leads'],
      );
      final int monthlyAchieved = UiHelpers.parseInt(json['monthly_achieved'] ?? json['achieved']);
      final int monthlyRemaining = json['monthly_remaining'] != null
          ? UiHelpers.parseInt(json['monthly_remaining'])
          : (mTarget - monthlyAchieved).clamp(0, 999999);
      final double monthlyPercentage = (json['monthly_percentage'] as num?)?.toDouble() ??
          (mTarget > 0 ? ((monthlyAchieved / mTarget) * 100).clamp(0.0, 100.0) : 0.0);
      final String period = (json['period'] ?? '').toString();

      int leads = UiHelpers.parseInt(
        json['target_leads'] ??
            json['monthly_target'] ??
            json['leads'] ??
            json['total_leads'] ??
            json['target'],
      );
      int admissions = UiHelpers.parseInt(
        json['target_admissions'] ?? json['admissions'] ?? admissionsJson,
      );

      if (json['monthly'] is Map) {
        final m = json['monthly'] as Map;
        leads = UiHelpers.parseInt(
          m['target_leads'] ??
              m['monthly_target'] ??
              m['leads'] ??
              m['total_leads'] ??
              m['total'] ??
              leads,
        );
        admissions = UiHelpers.parseInt(
          m['target_admissions'] ?? m['admissions'] ?? admissions,
        );
        mTarget = leads;
      } else if (json['monthly'] is num) {
        mTarget = (json['monthly'] as num).toInt();
        if (leads == 0) leads = mTarget;
      }

      return HomeTargetData(
        targetLeads: leads > 0 ? leads : mTarget,
        targetAdmissions: admissions,
        monthlyTarget: mTarget > 0 ? mTarget : leads,
        dailyTarget: dailyTarget,
        dailyAchieved: dailyAchieved,
        dailyRemaining: dailyRemaining,
        dailyPercentage: dailyPercentage,
        monthlyAchieved: monthlyAchieved,
        monthlyRemaining: monthlyRemaining,
        monthlyPercentage: monthlyPercentage,
        period: period,
      );
    }
    return const HomeTargetData();
  }

  Map<String, dynamic> toJson() => {
    'target_leads': targetLeads,
    'target_admissions': targetAdmissions,
    'monthly_target': monthlyTarget,
    'daily_target': dailyTarget,
    'daily_achieved': dailyAchieved,
    'daily_remaining': dailyRemaining,
    'daily_percentage': dailyPercentage,
    'monthly_achieved': monthlyAchieved,
    'monthly_remaining': monthlyRemaining,
    'monthly_percentage': monthlyPercentage,
    'period': period,
  };
}

class HomeFollowUpsData {
  final int total;
  final int completed;
  final int pending;

  const HomeFollowUpsData({
    this.total = 0,
    this.completed = 0,
    this.pending = 0,
  });

  factory HomeFollowUpsData.fromJson(dynamic json, [dynamic pendingJson]) {
    if (json == null) {
      if (pendingJson != null) {
        final p = UiHelpers.parseInt(pendingJson);
        return HomeFollowUpsData(total: p, completed: 0, pending: p);
      }
      return const HomeFollowUpsData();
    }
    if (json is num) {
      final comp = json.toInt();
      final pend = pendingJson != null ? UiHelpers.parseInt(pendingJson) : 0;
      return HomeFollowUpsData(
        total: comp + pend,
        completed: comp,
        pending: pend,
      );
    }
    if (json is String) {
      final comp = int.tryParse(json) ?? 0;
      final pend = pendingJson != null ? UiHelpers.parseInt(pendingJson) : 0;
      return HomeFollowUpsData(
        total: comp + pend,
        completed: comp,
        pending: pend,
      );
    }
    if (json is Map) {
      final tot = UiHelpers.parseInt(
        json['total'] ??
            json['total_follow_ups'] ??
            json['total_followup'] ??
            json['total_follow_up'],
      );
      final comp = UiHelpers.parseInt(
        json['completed'] ??
            json['done'] ??
            json['follow_up'] ??
            json['team_follow_up'] ??
            json['team'] ??
            json['count'],
      );
      final pend = UiHelpers.parseInt(
        json['pending'] ??
            json['pending_follow_ups'] ??
            json['pending_follow_up'] ??
            pendingJson ??
            (tot >= comp ? tot - comp : 0),
      );
      return HomeFollowUpsData(
        total: tot > 0 ? tot : (comp + pend),
        completed: comp,
        pending: pend,
      );
    }
    return const HomeFollowUpsData();
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'completed': completed,
    'pending': pending,
  };
}
