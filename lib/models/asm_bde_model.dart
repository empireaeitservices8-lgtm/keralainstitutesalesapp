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
  final String reportsTo;
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
    required this.reportsTo,
    required this.leadsAssigned,
    required this.admissionsClosed,
    required this.conversionRate,
    required this.status,
  });

  factory AsmBdeModel.fromJson(Map<String, dynamic> json) {
    return AsmBdeModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'BDE Executive',
      email: json['email']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? json['phone']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'Business Development Executive',
      team: json['team']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      reportsTo: json['reports_to']?.toString() ?? '',
      leadsAssigned: UiHelpers.parseInt(json['leads_assigned'] ?? json['leads_count'] ?? json['total_leads']),
      admissionsClosed: UiHelpers.parseInt(json['admissions_closed'] ?? json['admissions_count'] ?? json['total_admissions']),
      conversionRate: json['conversion_rate']?.toString() ?? json['conversion_percentage']?.toString() ?? '0%',
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
    'reports_to': reportsTo,
    'leads_assigned': leadsAssigned,
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
    String? reportsTo,
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
      reportsTo: reportsTo ?? this.reportsTo,
      leadsAssigned: leadsAssigned ?? this.leadsAssigned,
      admissionsClosed: admissionsClosed ?? this.admissionsClosed,
      conversionRate: conversionRate ?? this.conversionRate,
      status: status ?? this.status,
    );
  }
}

