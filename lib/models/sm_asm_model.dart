import '../utils/helpers.dart';

class SmAsmTargetMetrics {
  final int totalLeads;
  final int completedLeads;
  final int pendingLeads;
  final int completionPercentage;

  const SmAsmTargetMetrics({
    required this.totalLeads,
    required this.completedLeads,
    required this.pendingLeads,
    required this.completionPercentage,
  });

  factory SmAsmTargetMetrics.fromJson(Map<String, dynamic> json) => SmAsmTargetMetrics(
    totalLeads: UiHelpers.parseInt(json['total_leads']),
    completedLeads: UiHelpers.parseInt(json['completed_leads']),
    pendingLeads: UiHelpers.parseInt(json['pending_leads']),
    completionPercentage: UiHelpers.parseInt(json['completion_percentage']),
  );

  Map<String, dynamic> toJson() => {
    'total_leads': totalLeads,
    'completed_leads': completedLeads,
    'pending_leads': pendingLeads,
    'completion_percentage': completionPercentage,
  };
}

class SmAsmModel {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String contactNumber;
  final String designation;
  final String team;
  final List<String> districts;
  final String zone;
  final String reportsTo;
  final int bdesCount;
  final String status;

  final int dailyTarget;
  final int dailyAchieved;
  final int dailyPending;
  final int dailyCompletionPercentage;

  final int monthlyTarget;
  final int monthlyAchieved;
  final int monthlyPending;
  final int monthlyCompletionPercentage;

  final int totalLeads;
  final int completedLeads;
  final int pendingLeads;
  final int completionPercentage;

  final int salary;
  final int incentive;

  final SmAsmTargetMetrics? dailyTargets;
  final SmAsmTargetMetrics? monthlyTargets;
  final SmAsmTargetMetrics? overallTargets;

  const SmAsmModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.designation,
    required this.team,
    required this.districts,
    required this.zone,
    required this.reportsTo,
    required this.bdesCount,
    required this.status,
    required this.dailyTarget,
    required this.dailyAchieved,
    required this.dailyPending,
    required this.dailyCompletionPercentage,
    required this.monthlyTarget,
    required this.monthlyAchieved,
    required this.monthlyPending,
    required this.monthlyCompletionPercentage,
    required this.totalLeads,
    required this.completedLeads,
    required this.pendingLeads,
    required this.completionPercentage,
    this.salary = 0,
    this.incentive = 0,
    this.dailyTargets,
    this.monthlyTargets,
    this.overallTargets,
  });

  String get formattedSalary => salary > 0 ? '\u20B9$salary' : 'Not set';
  String get formattedIncentive => incentive > 0 ? '\u20B9$incentive' : 'Not set';

  String get code {
    final clean = team.replaceAll('Team', '').trim();
    if (clean.isNotEmpty) {
      if (clean.length <= 4) return clean.toUpperCase();
      return clean.substring(0, 3).toUpperCase();
    }
    if (districts.isNotEmpty) {
      return districts.first.substring(0, 3).toUpperCase();
    }
    return employeeId.isNotEmpty ? employeeId : 'ASM';
  }

  String get districtsDisplay {
    if (districts.isEmpty) return 'General Territory';
    return districts.join(' \u2022 ');
  }

  int getTarget(String period) {
    if (period == 'Today' || period == 'Daily') return dailyTarget;
    if (period == 'Overall') return totalLeads;
    return monthlyTarget;
  }

  int getAchieved(String period) {
    if (period == 'Today' || period == 'Daily') return dailyAchieved;
    if (period == 'Overall') return completedLeads;
    return monthlyAchieved;
  }

  int getPercentage(String period) {
    if (period == 'Today' || period == 'Daily') return dailyCompletionPercentage;
    if (period == 'Overall') return completionPercentage;
    return monthlyCompletionPercentage;
  }

  int getPending(String period) {
    if (period == 'Today' || period == 'Daily') return dailyPending;
    if (period == 'Overall') return pendingLeads;
    return monthlyPending;
  }

  SmAsmModel copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? email,
    String? contactNumber,
    String? designation,
    String? team,
    List<String>? districts,
    String? zone,
    String? reportsTo,
    int? bdesCount,
    String? status,
    int? dailyTarget,
    int? dailyAchieved,
    int? dailyPending,
    int? dailyCompletionPercentage,
    int? monthlyTarget,
    int? monthlyAchieved,
    int? monthlyPending,
    int? monthlyCompletionPercentage,
    int? totalLeads,
    int? completedLeads,
    int? pendingLeads,
    int? completionPercentage,
    int? salary,
    int? incentive,
    SmAsmTargetMetrics? dailyTargets,
    SmAsmTargetMetrics? monthlyTargets,
    SmAsmTargetMetrics? overallTargets,
  }) {
    final dTarget = dailyTarget ?? this.dailyTarget;
    final dAchieved = dailyAchieved ?? this.dailyAchieved;
    final mTarget = monthlyTarget ?? this.monthlyTarget;
    final mAchieved = monthlyAchieved ?? this.monthlyAchieved;

    return SmAsmModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      designation: designation ?? this.designation,
      team: team ?? this.team,
      districts: districts ?? this.districts,
      zone: zone ?? this.zone,
      reportsTo: reportsTo ?? this.reportsTo,
      bdesCount: bdesCount ?? this.bdesCount,
      status: status ?? this.status,
      dailyTarget: dTarget,
      dailyAchieved: dAchieved,
      dailyPending: dailyPending ?? (dTarget - dAchieved > 0 ? dTarget - dAchieved : 0),
      dailyCompletionPercentage: dailyCompletionPercentage ??
          (dTarget > 0 ? ((dAchieved / dTarget) * 100).toInt() : 0),
      monthlyTarget: mTarget,
      monthlyAchieved: mAchieved,
      monthlyPending: monthlyPending ?? (mTarget - mAchieved > 0 ? mTarget - mAchieved : 0),
      monthlyCompletionPercentage: monthlyCompletionPercentage ??
          (mTarget > 0 ? ((mAchieved / mTarget) * 100).toInt() : 0),
      totalLeads: totalLeads ?? this.totalLeads,
      completedLeads: completedLeads ?? this.completedLeads,
      pendingLeads: pendingLeads ?? this.pendingLeads,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      salary: salary ?? this.salary,
      incentive: incentive ?? this.incentive,
      dailyTargets: dailyTargets ?? this.dailyTargets,
      monthlyTargets: monthlyTargets ?? this.monthlyTargets,
      overallTargets: overallTargets ?? this.overallTargets,
    );
  }

  factory SmAsmModel.fromJson(Map<String, dynamic> json) {
    List<String> distList = [];
    if (json['districts'] is List) {
      distList = (json['districts'] as List).map((e) => e.toString()).toList();
    } else if (json['district'] != null) {
      distList = [json['district'].toString()];
    }

    final targetsMap = json['targets'] is Map ? json['targets'] as Map<String, dynamic> : null;
    final dailyMap = targetsMap?['daily'] is Map ? targetsMap!['daily'] as Map : null;
    final monthlyMap = targetsMap?['monthly'] is Map ? targetsMap!['monthly'] as Map : null;
    final overallMap = targetsMap?['overall'] is Map ? targetsMap!['overall'] as Map : null;

    final mTarget = UiHelpers.parseInt(json['monthly_target'] ?? monthlyMap?['total_leads']);
    final mAchieved = UiHelpers.parseInt(json['monthly_achieved'] ?? monthlyMap?['completed_leads']);
    final mPending = UiHelpers.parseInt(json['monthly_pending'] ?? monthlyMap?['pending_leads'] ?? (mTarget - mAchieved));
    final mPct = UiHelpers.parseInt(json['monthly_completion_percentage'] ?? monthlyMap?['completion_percentage']);

    final dTarget = UiHelpers.parseInt(json['daily_target'] ?? dailyMap?['total_leads']);
    final dAchieved = UiHelpers.parseInt(json['daily_achieved'] ?? dailyMap?['completed_leads']);
    final dPending = UiHelpers.parseInt(json['daily_pending'] ?? dailyMap?['pending_leads'] ?? (dTarget - dAchieved));
    final dPct = UiHelpers.parseInt(json['daily_completion_percentage'] ?? dailyMap?['completion_percentage']);

    final tLeads = UiHelpers.parseInt(json['total_leads'] ?? overallMap?['total_leads']);
    final cLeads = UiHelpers.parseInt(json['completed_leads'] ?? overallMap?['completed_leads']);
    final pLeads = UiHelpers.parseInt(json['pending_leads'] ?? overallMap?['pending_leads'] ?? (tLeads - cLeads));
    final oPct = UiHelpers.parseInt(json['completion_percentage'] ?? overallMap?['completion_percentage']);

    return SmAsmModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      employeeId: (json['employee_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      contactNumber: (json['contact_number'] ?? json['phone'] ?? '').toString(),
      designation: (json['designation'] ?? 'Area Sales Manager').toString(),
      team: (json['team'] ?? '').toString(),
      districts: distList,
      zone: (json['zone'] ?? '').toString(),
      reportsTo: (json['reports_to'] ?? '').toString(),
      bdesCount: UiHelpers.parseInt(json['bdes_count']),
      status: (json['status'] ?? 'active').toString(),
      dailyTarget: dTarget,
      dailyAchieved: dAchieved,
      dailyPending: UiHelpers.parseInt(json['daily_pending'] ?? (dTarget - dAchieved)),
      dailyCompletionPercentage: dPct > 0 ? dPct : (dTarget > 0 ? ((dAchieved / dTarget) * 100).toInt() : 0),
      monthlyTarget: mTarget,
      monthlyAchieved: mAchieved,
      monthlyPending: UiHelpers.parseInt(json['monthly_pending'] ?? (mTarget - mAchieved)),
      monthlyCompletionPercentage: mPct > 0 ? mPct : (mTarget > 0 ? ((mAchieved / mTarget) * 100).toInt() : 0),
      totalLeads: tLeads,
      completedLeads: cLeads,
      pendingLeads: UiHelpers.parseInt(json['pending_leads'] ?? (tLeads - cLeads)),
      completionPercentage: oPct > 0 ? oPct : (tLeads > 0 ? ((cLeads / tLeads) * 100).toInt() : 0),
      salary: UiHelpers.parseInt(json['salary'] ?? json['base_salary']),
      incentive: UiHelpers.parseInt(json['incentive'] ?? json['incentives']),
      dailyTargets: targetsMap?['daily'] is Map
          ? SmAsmTargetMetrics.fromJson(Map<String, dynamic>.from(targetsMap!['daily'] as Map))
          : null,
      monthlyTargets: targetsMap?['monthly'] is Map
          ? SmAsmTargetMetrics.fromJson(Map<String, dynamic>.from(targetsMap!['monthly'] as Map))
          : null,
      overallTargets: targetsMap?['overall'] is Map
          ? SmAsmTargetMetrics.fromJson(Map<String, dynamic>.from(targetsMap!['overall'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'name': name,
    'email': email,
    'contact_number': contactNumber,
    'designation': designation,
    'team': team,
    'districts': districts,
    'zone': zone,
    'reports_to': reportsTo,
    'bdes_count': bdesCount,
    'status': status,
    'daily_target': dailyTarget,
    'daily_achieved': dailyAchieved,
    'daily_pending': dailyPending,
    'daily_completion_percentage': dailyCompletionPercentage,
    'monthly_target': monthlyTarget,
    'monthly_achieved': monthlyAchieved,
    'monthly_pending': monthlyPending,
    'monthly_completion_percentage': monthlyCompletionPercentage,
    'total_leads': totalLeads,
    'completed_leads': completedLeads,
    'pending_leads': pendingLeads,
    'completion_percentage': completionPercentage,
    'salary': salary,
    'incentive': incentive,
    'targets': {
      if (dailyTargets != null) 'daily': dailyTargets!.toJson(),
      if (monthlyTargets != null) 'monthly': monthlyTargets!.toJson(),
      if (overallTargets != null) 'overall': overallTargets!.toJson(),
    },
  };
}
