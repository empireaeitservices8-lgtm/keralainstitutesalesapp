import '../utils/helpers.dart';

class OfficeTelecallerModel {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String contactNumber;
  final int leadsAssigned;
  final int admissionsClosed;
  final String conversionRate;
  final String status;
  final String? district;
  final String shift;
  final int callsToday;
  final int baseSalary;
  final int incentivePerAdmission;
  final int monthlyTarget;

  const OfficeTelecallerModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.contactNumber,
    this.leadsAssigned = 0,
    this.admissionsClosed = 0,
    this.conversionRate = '0%',
    this.status = 'active',
    this.district,
    this.shift = 'General Shift (10 AM - 6 PM)',
    this.callsToday = 0,
    this.baseSalary = 18000,
    this.incentivePerAdmission = 500,
    this.monthlyTarget = 30,
  });

  factory OfficeTelecallerModel.fromJson(Map<String, dynamic> json) {
    return OfficeTelecallerModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Telecaller',
      email: json['email']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? json['phone']?.toString() ?? '',
      leadsAssigned: UiHelpers.parseInt(json['leads_assigned'] ?? json['leads_generated']),
      admissionsClosed: UiHelpers.parseInt(json['admissions_closed'] ?? json['admissions']),
      conversionRate: json['conversion_rate']?.toString() ?? '0%',
      status: json['status']?.toString() ?? 'active',
      district: json['district']?.toString(),
      shift: json['shift']?.toString() ?? 'General Shift (10 AM - 6 PM)',
      callsToday: UiHelpers.parseInt(json['calls_today']),
      baseSalary: UiHelpers.parseInt(json['base_salary'] ?? 18000),
      incentivePerAdmission: UiHelpers.parseInt(json['incentive_per_admission'] ?? 500),
      monthlyTarget: UiHelpers.parseInt(json['monthly_target'] ?? 30),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'name': name,
    'email': email,
    'contact_number': contactNumber,
    'leads_assigned': leadsAssigned,
    'admissions_closed': admissionsClosed,
    'conversion_rate': conversionRate,
    'status': status,
    'district': district,
    'shift': shift,
    'calls_today': callsToday,
    'base_salary': baseSalary,
    'incentive_per_admission': incentivePerAdmission,
    'monthly_target': monthlyTarget,
  };

  OfficeTelecallerModel copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? email,
    String? contactNumber,
    int? leadsAssigned,
    int? admissionsClosed,
    String? conversionRate,
    String? status,
    String? district,
    String? shift,
    int? callsToday,
    int? baseSalary,
    int? incentivePerAdmission,
    int? monthlyTarget,
  }) {
    return OfficeTelecallerModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      leadsAssigned: leadsAssigned ?? this.leadsAssigned,
      admissionsClosed: admissionsClosed ?? this.admissionsClosed,
      conversionRate: conversionRate ?? this.conversionRate,
      status: status ?? this.status,
      district: district ?? this.district,
      shift: shift ?? this.shift,
      callsToday: callsToday ?? this.callsToday,
      baseSalary: baseSalary ?? this.baseSalary,
      incentivePerAdmission: incentivePerAdmission ?? this.incentivePerAdmission,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
    );
  }
}

