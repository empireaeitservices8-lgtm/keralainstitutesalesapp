import '../utils/helpers.dart';

num _parseNum(dynamic val, [num defaultValue = 0]) {
  if (val == null) return defaultValue;
  if (val is num) return val;
  if (val is String) {
    return num.tryParse(val.trim()) ?? defaultValue;
  }
  return defaultValue;
}

class WalletApprovalResponse {
  final bool success;
  final int count;
  final WalletApprovalSummary summary;
  final List<WalletApprovalRequestItem> data;

  const WalletApprovalResponse({
    required this.success,
    required this.count,
    required this.summary,
    required this.data,
  });

  factory WalletApprovalResponse.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['summary'];
    final summaryObj = rawSummary is Map<String, dynamic>
        ? WalletApprovalSummary.fromJson(rawSummary)
        : (rawSummary is Map ? WalletApprovalSummary.fromJson(Map<String, dynamic>.from(rawSummary)) : WalletApprovalSummary.empty());

    final rawData = json['data'];
    final List<WalletApprovalRequestItem> items = [];
    if (rawData is List) {
      for (final el in rawData) {
        if (el is Map<String, dynamic>) {
          items.add(WalletApprovalRequestItem.fromJson(el));
        } else if (el is Map) {
          items.add(WalletApprovalRequestItem.fromJson(Map<String, dynamic>.from(el)));
        }
      }
    }

    return WalletApprovalResponse(
      success: json['success'] == true,
      count: UiHelpers.parseInt(json['count']),
      summary: summaryObj,
      data: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'count': count,
    'summary': summary.toJson(),
    'data': data.map((e) => e.toJson()).toList(),
  };
}

class WalletApprovalSummary {
  final int total;
  final int pending;
  final int approved;
  final int paid;
  final int rejected;
  final num pendingAmount;

  const WalletApprovalSummary({
    required this.total,
    required this.pending,
    required this.approved,
    required this.paid,
    required this.rejected,
    required this.pendingAmount,
  });

  factory WalletApprovalSummary.empty() => const WalletApprovalSummary(
    total: 0,
    pending: 0,
    approved: 0,
    paid: 0,
    rejected: 0,
    pendingAmount: 0,
  );

  factory WalletApprovalSummary.fromJson(Map<String, dynamic> json) {
    return WalletApprovalSummary(
      total: UiHelpers.parseInt(json['total']),
      pending: UiHelpers.parseInt(json['pending']),
      approved: UiHelpers.parseInt(json['approved']),
      paid: UiHelpers.parseInt(json['paid']),
      rejected: UiHelpers.parseInt(json['rejected']),
      pendingAmount: _parseNum(json['pending_amount']),
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'pending': pending,
    'approved': approved,
    'paid': paid,
    'rejected': rejected,
    'pending_amount': pendingAmount,
  };

  String get formattedPendingAmount => '\u20B9${pendingAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

class WalletApprovalStage {
  final String stage;
  final String actionBy;
  final String? role;
  final String? action;
  final String? actionAt;
  final String? remarks;

  const WalletApprovalStage({
    required this.stage,
    required this.actionBy,
    this.role,
    this.action,
    this.actionAt,
    this.remarks,
  });

  factory WalletApprovalStage.fromJson(Map<String, dynamic> json) {
    return WalletApprovalStage(
      stage: json['step']?.toString() ?? json['stage']?.toString() ?? '',
      actionBy: json['actor']?.toString() ?? json['action_by']?.toString() ?? '',
      role: json['role']?.toString(),
      action: json['action']?.toString(),
      actionAt: json['timestamp']?.toString() ?? json['action_at']?.toString(),
      remarks: json['remarks']?.toString() ?? json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'stage': stage,
    'action_by': actionBy,
    if (role != null) 'role': role,
    if (action != null) 'action': action,
    'action_at': actionAt,
    'remarks': remarks,
  };
}

class WalletApprovalRequestItem {
  final String id;
  final String requestId;
  final String employee;
  final String employeeId;
  final String designation;
  final String team;
  final String? asmId;
  final String? asmName;
  final String? smId;
  final String? smName;
  final num amount;
  final num availableBalance;
  String status;
  String statusLabel;
  String? remarks;
  List<WalletApprovalStage> approvalHistory;
  final String? createdAt;

  WalletApprovalRequestItem({
    required this.id,
    required this.requestId,
    required this.employee,
    required this.employeeId,
    required this.designation,
    required this.team,
    this.asmId,
    this.asmName,
    this.smId,
    this.smName,
    required this.amount,
    required this.availableBalance,
    required this.status,
    required this.statusLabel,
    this.remarks,
    required this.approvalHistory,
    this.createdAt,
  });

  factory WalletApprovalRequestItem.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['approval_history'];
    final List<WalletApprovalStage> history = [];
    if (rawHistory is List) {
      for (final h in rawHistory) {
        if (h is Map<String, dynamic>) {
          history.add(WalletApprovalStage.fromJson(h));
        } else if (h is Map) {
          history.add(WalletApprovalStage.fromJson(Map<String, dynamic>.from(h)));
        }
      }
    }

    return WalletApprovalRequestItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['request_id']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? json['id']?.toString() ?? 'REQ',
      employee: json['employee']?.toString() ?? json['employee_name']?.toString() ?? json['name']?.toString() ?? 'Employee',
      employeeId: json['employee_id']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'Business Development Executive',
      team: json['team']?.toString() ?? 'Kerala Team',
      asmId: json['asm_id']?.toString(),
      asmName: json['asm_name']?.toString(),
      smId: json['sm_id']?.toString(),
      smName: json['sm_name']?.toString(),
      amount: _parseNum(json['amount']),
      availableBalance: _parseNum(json['available_balance']),
      status: json['status']?.toString() ?? 'Pending',
      statusLabel: json['status_label']?.toString() ?? 'Pending',
      remarks: json['remarks']?.toString(),
      approvalHistory: history,
      createdAt: json['created_at']?.toString() ?? json['date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'request_id': requestId,
    'employee': employee,
    'employee_id': employeeId,
    'designation': designation,
    'team': team,
    'asm_id': asmId,
    'asm_name': asmName,
    'sm_id': smId,
    'sm_name': smName,
    'amount': amount,
    'available_balance': availableBalance,
    'status': status,
    'status_label': statusLabel,
    'remarks': remarks,
    'approval_history': approvalHistory.map((e) => e.toJson()).toList(),
    'created_at': createdAt,
  };

  String get formattedAmount => '\u20B9${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  String get formattedBalance => '\u20B9${availableBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  bool get isPending {
    final s = status.toLowerCase();
    final l = statusLabel.toLowerCase();
    return l == 'pending' || s.contains('pending') || s.contains('forwarded');
  }

  bool get isForwardedToSm => status.toLowerCase().contains('forwarded to sm') || status == 'Pending_SM';
  bool get isPendingAsm => status.toLowerCase().contains('submitted to asm') || status == 'Pending_ASM' || (isPending && !isForwardedToSm);
  bool get isApproved => status.toLowerCase().contains('approved') || status.toLowerCase().contains('sanctioned');
  bool get isPaid => status.toLowerCase().contains('paid') || status.toLowerCase().contains('disbursed');
  bool get isRejected => status.toLowerCase().contains('rejected');
}

