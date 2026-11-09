import '../utils/helpers.dart';

class AsmBdeTargetMetrics {
  final int totalLeads;
  final int completedLeads;
  final int pendingLeads;
  final int completionPercentage;

  const AsmBdeTargetMetrics({
    required this.totalLeads,
    required this.completedLeads,
    required this.pendingLeads,
    required this.completionPercentage,
  });

  factory AsmBdeTargetMetrics.fromJson(Map<String, dynamic> json) => AsmBdeTargetMetrics(
    totalLeads: UiHelpers.parseInt(json['total_leads'] ?? json['target_leads']),
    completedLeads: UiHelpers.parseInt(json['completed_leads'] ?? json['achieved_leads']),
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

class AsmBdeModel {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String contactNumber;
  final String designation;
  final String team;
  final String district;
  final String zone;
  final String reportsTo;
  final int salary;
  final int incentive;
  final int leadsAssigned;
  final int admissionsClosed;
  final String conversionRate;
  final String status;

  final int dailyTarget;
  final int dailyAchieved;
  final int dailyPending;
  final int dailyCompletionPercentage;

  final int monthlyTarget;
  final int monthlyAchieved;
  final int monthlyPending;
  final int monthlyCompletionPercentage;

  final int totalLeadsCount;
  final int completedLeadsCount;
  final int pendingLeadsCount;
  final int overallCompletionPercentage;

  final AsmBdeTargetMetrics? dailyTargets;
  final AsmBdeTargetMetrics? monthlyTargets;
  final AsmBdeTargetMetrics? overallTargets;

  const AsmBdeModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.designation,
    required this.team,
    required this.district,
    this.zone = '',
    required this.reportsTo,
    this.salary = 0,
    this.incentive = 0,
    required this.leadsAssigned,
    required this.admissionsClosed,
    required this.conversionRate,
    required this.status,
    this.dailyTarget = 0,
    this.dailyAchieved = 0,
    this.dailyPending = 0,
    this.dailyCompletionPercentage = 0,
    this.monthlyTarget = 0,
    this.monthlyAchieved = 0,
    this.monthlyPending = 0,
    this.monthlyCompletionPercentage = 0,
    this.totalLeadsCount = 0,
    this.completedLeadsCount = 0,
    this.pendingLeadsCount = 0,
    this.overallCompletionPercentage = 0,
    this.dailyTargets,
    this.monthlyTargets,
    this.overallTargets,
  });

  int get totalLeads => totalLeadsCount > 0 ? totalLeadsCount : leadsAssigned;
  int get admissions => admissionsClosed;
  int get completedLeads => completedLeadsCount > 0 ? completedLeadsCount : admissionsClosed;

  String get formattedSalary =>
      '\u20B9${salary.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

  String get formattedIncentive =>
      '\u20B9${incentive.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

  String get displayConversionRate {
    if (conversionRate.isEmpty) return '0%';
    final trimmed = conversionRate.trim();
    return trimmed.endsWith('%') ? trimmed : '$trimmed%';
  }

  factory AsmBdeModel.fromJson(Map<String, dynamic> json) {
    final rawConversion = json['conversion_rate'] ?? json['conversion_percentage'];
    String convRate = '0%';
    if (rawConversion != null) {
      final str = rawConversion.toString().trim();
      convRate = str.endsWith('%') ? str : '$str%';
    }

    final targetsMap = json['targets'] is Map ? json['targets'] as Map<String, dynamic> : null;
    final dailyMap = targetsMap?['daily'] is Map ? targetsMap!['daily'] as Map : null;
    final monthlyMap = targetsMap?['monthly'] is Map ? targetsMap!['monthly'] as Map : null;
    final overallMap = targetsMap?['overall'] is Map ? targetsMap!['overall'] as Map : null;

    final dTarget = UiHelpers.parseInt(json['daily_target'] ?? dailyMap?['total_leads']);
    final dAchieved = UiHelpers.parseInt(json['daily_achieved'] ?? dailyMap?['completed_leads']);
    final dPending = UiHelpers.parseInt(json['daily_pending'] ?? dailyMap?['pending_leads'] ?? (dTarget - dAchieved));
    final dPct = UiHelpers.parseInt(json['daily_completion_percentage'] ?? dailyMap?['completion_percentage']);

    final mTarget = UiHelpers.parseInt(json['monthly_target'] ?? monthlyMap?['total_leads']);
    final mAchieved = UiHelpers.parseInt(json['monthly_achieved'] ?? monthlyMap?['completed_leads']);
    final mPending = UiHelpers.parseInt(json['monthly_pending'] ?? monthlyMap?['pending_leads'] ?? (mTarget - mAchieved));
    final mPct = UiHelpers.parseInt(json['monthly_completion_percentage'] ?? monthlyMap?['completion_percentage']);

    final tLeads = UiHelpers.parseInt(
      json['total_leads'] ?? json['leads_assigned'] ?? json['leads_count'] ?? overallMap?['total_leads'],
    );
    final cLeads = UiHelpers.parseInt(
      json['completed_leads'] ?? json['admissions'] ?? json['admissions_closed'] ?? overallMap?['completed_leads'],
    );
    final pLeads = UiHelpers.parseInt(json['pending_leads'] ?? overallMap?['pending_leads'] ?? (tLeads - cLeads));
    final oPct = UiHelpers.parseInt(json['completion_percentage'] ?? overallMap?['completion_percentage']);

    return AsmBdeModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'BDE Executive',
      email: json['email']?.toString() ?? '',
      contactNumber:
          json['contact_number']?.toString() ?? json['phone']?.toString() ?? '',
      designation:
          json['designation']?.toString() ?? 'Business Development Executive',
      team: json['team']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      zone: json['zone']?.toString() ?? '',
      reportsTo: json['reports_to']?.toString() ?? '',
      salary: UiHelpers.parseInt(json['salary'] ?? json['base_salary']),
      incentive: UiHelpers.parseInt(json['incentive'] ?? json['incentives']),
      leadsAssigned: tLeads,
      admissionsClosed: UiHelpers.parseInt(
        json['admissions'] ??
            json['admissions_closed'] ??
            json['admissions_count'] ??
            json['total_admissions'],
      ),
      conversionRate: convRate,
      status: json['status']?.toString() ?? 'active',
      dailyTarget: dTarget,
      dailyAchieved: dAchieved,
      dailyPending: dPending > 0 ? dPending : (dTarget - dAchieved > 0 ? dTarget - dAchieved : 0),
      dailyCompletionPercentage: dPct > 0 ? dPct : (dTarget > 0 ? ((dAchieved / dTarget) * 100).toInt() : 0),
      monthlyTarget: mTarget,
      monthlyAchieved: mAchieved,
      monthlyPending: mPending > 0 ? mPending : (mTarget - mAchieved > 0 ? mTarget - mAchieved : 0),
      monthlyCompletionPercentage: mPct > 0 ? mPct : (mTarget > 0 ? ((mAchieved / mTarget) * 100).toInt() : 0),
      totalLeadsCount: tLeads,
      completedLeadsCount: cLeads,
      pendingLeadsCount: pLeads > 0 ? pLeads : (tLeads - cLeads > 0 ? tLeads - cLeads : 0),
      overallCompletionPercentage: oPct > 0 ? oPct : (tLeads > 0 ? ((cLeads / tLeads) * 100).toInt() : 0),
      dailyTargets: targetsMap?['daily'] is Map
          ? AsmBdeTargetMetrics.fromJson(Map<String, dynamic>.from(targetsMap!['daily'] as Map))
          : null,
      monthlyTargets: targetsMap?['monthly'] is Map
          ? AsmBdeTargetMetrics.fromJson(Map<String, dynamic>.from(targetsMap!['monthly'] as Map))
          : null,
      overallTargets: targetsMap?['overall'] is Map
          ? AsmBdeTargetMetrics.fromJson(Map<String, dynamic>.from(targetsMap!['overall'] as Map))
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
    'district': district,
    'zone': zone,
    'reports_to': reportsTo,
    'salary': salary,
    'incentive': incentive,
    'total_leads': leadsAssigned,
    'leads_assigned': leadsAssigned,
    'admissions': admissionsClosed,
    'admissions_closed': admissionsClosed,
    'conversion_rate': conversionRate,
    'status': status,
    'daily_target': dailyTarget,
    'daily_achieved': dailyAchieved,
    'daily_pending': dailyPending,
    'daily_completion_percentage': dailyCompletionPercentage,
    'monthly_target': monthlyTarget,
    'monthly_achieved': monthlyAchieved,
    'monthly_pending': monthlyPending,
    'monthly_completion_percentage': monthlyCompletionPercentage,
    'total_leads_count': totalLeadsCount,
    'completed_leads_count': completedLeadsCount,
    'pending_leads_count': pendingLeadsCount,
    'overall_completion_percentage': overallCompletionPercentage,
    'targets': {
      if (dailyTargets != null) 'daily': dailyTargets!.toJson(),
      if (monthlyTargets != null) 'monthly': monthlyTargets!.toJson(),
      if (overallTargets != null) 'overall': overallTargets!.toJson(),
    },
  };

  AsmBdeModel copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? email,
    String? contactNumber,
    String? designation,
    String? team,
    String? district,
    String? zone,
    String? reportsTo,
    int? salary,
    int? incentive,
    int? leadsAssigned,
    int? admissionsClosed,
    String? conversionRate,
    String? status,
    int? dailyTarget,
    int? dailyAchieved,
    int? dailyPending,
    int? dailyCompletionPercentage,
    int? monthlyTarget,
    int? monthlyAchieved,
    int? monthlyPending,
    int? monthlyCompletionPercentage,
    int? totalLeadsCount,
    int? completedLeadsCount,
    int? pendingLeadsCount,
    int? overallCompletionPercentage,
    AsmBdeTargetMetrics? dailyTargets,
    AsmBdeTargetMetrics? monthlyTargets,
    AsmBdeTargetMetrics? overallTargets,
  }) {
    final dTarget = dailyTarget ?? this.dailyTarget;
    final dAchieved = dailyAchieved ?? this.dailyAchieved;
    final mTarget = monthlyTarget ?? this.monthlyTarget;
    final mAchieved = monthlyAchieved ?? this.monthlyAchieved;
    final tCount = totalLeadsCount ?? this.totalLeadsCount;
    final cCount = completedLeadsCount ?? this.completedLeadsCount;

    return AsmBdeModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      designation: designation ?? this.designation,
      team: team ?? this.team,
      district: district ?? this.district,
      zone: zone ?? this.zone,
      reportsTo: reportsTo ?? this.reportsTo,
      salary: salary ?? this.salary,
      incentive: incentive ?? this.incentive,
      leadsAssigned: leadsAssigned ?? this.leadsAssigned,
      admissionsClosed: admissionsClosed ?? this.admissionsClosed,
      conversionRate: conversionRate ?? this.conversionRate,
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
      totalLeadsCount: tCount,
      completedLeadsCount: cCount,
      pendingLeadsCount: pendingLeadsCount ?? (tCount - cCount > 0 ? tCount - cCount : 0),
      overallCompletionPercentage: overallCompletionPercentage ??
          (tCount > 0 ? ((cCount / tCount) * 100).toInt() : 0),
      dailyTargets: dailyTargets ?? this.dailyTargets,
      monthlyTargets: monthlyTargets ?? this.monthlyTargets,
      overallTargets: overallTargets ?? this.overallTargets,
    );
  }

  @override
  String toString() {
    return 'AsmBdeModel('
        'id: $id, '
        'employeeId: $employeeId, '
        'name: $name, '
        'email: $email, '
        'contactNumber: $contactNumber, '
        'designation: $designation, '
        'team: $team, '
        'district: $district, '
        'zone: $zone, '
        'reportsTo: $reportsTo, '
        'salary: $salary, '
        'incentive: $incentive, '
        'leadsAssigned: $leadsAssigned, '
        'admissionsClosed: $admissionsClosed, '
        'conversionRate: $conversionRate, '
        'status: $status'
        ')';
  }
}
