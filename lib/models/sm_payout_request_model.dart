import '../utils/helpers.dart';

class SmPayoutRequestModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String designation;
  final String? month;
  final int amount;
  String status;
  final String type; // 'Salary' or 'Incentive'
  final String? submittedAt;
  final String? notes;

  SmPayoutRequestModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.designation,
    this.month,
    required this.amount,
    required this.status,
    required this.type,
    this.submittedAt,
    this.notes,
  });

  String get formattedAmount => '\u20B9${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

  bool get isPending => status == 'Pending_SM' || status == 'Pending Review';
  bool get isForwarded => status == 'Forwarded to Accounts' || status == 'Forwarded_Accounts';
  bool get isPaid => status == 'Paid & Verified' || status == 'Disbursed' || status == 'Sanctioned';

  factory SmPayoutRequestModel.fromJson(Map<String, dynamic> json, {String defaultType = 'Salary'}) {
    final rawType = json['type']?.toString();
    final determinedType = rawType != null && rawType.isNotEmpty
        ? (rawType.toLowerCase().contains('wallet') || rawType.toLowerCase().contains('incentive') ? 'Incentive' : 'Salary')
        : (json['month'] != null ? 'Salary' : defaultType);

    return SmPayoutRequestModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['request_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? json['name']?.toString() ?? json['title']?.toString() ?? 'Employee',
      designation: json['designation']?.toString() ?? json['role']?.toString() ?? 'Sales Team',
      month: json['month']?.toString(),
      amount: UiHelpers.parseInt(json['amount'] ?? json['raw_amount']),
      status: json['status']?.toString() ?? 'Pending_SM',
      type: determinedType,
      submittedAt: json['submitted_at']?.toString() ?? json['created_at']?.toString() ?? json['date']?.toString(),
      notes: json['notes']?.toString() ?? json['details']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'employee_name': employeeName,
    'designation': designation,
    'month': month,
    'amount': amount,
    'status': status,
    'type': type,
    'submitted_at': submittedAt,
    'notes': notes,
  };
}

