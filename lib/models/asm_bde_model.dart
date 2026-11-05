import '../utils/helpers.dart';

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
  });

  int get totalLeads => leadsAssigned;
  int get admissions => admissionsClosed;

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
      leadsAssigned: UiHelpers.parseInt(
        json['total_leads'] ?? json['leads_assigned'] ?? json['leads_count'],
      ),
      admissionsClosed: UiHelpers.parseInt(
        json['admissions'] ??
            json['admissions_closed'] ??
            json['admissions_count'] ??
            json['total_admissions'],
      ),
      conversionRate: convRate,
      status: json['status']?.toString() ?? 'active',
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
  }) {
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
