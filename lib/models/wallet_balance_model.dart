import 'package:json_annotation/json_annotation.dart';

part 'wallet_balance_model.g.dart';

double _doubleFromString(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

@JsonSerializable()
class WalletBalanceModel {
  @JsonKey(fromJson: _doubleFromString)
  final double balance;
  @JsonKey(name: 'total_paid', fromJson: _doubleFromString)
  final double totalPaid;
  @JsonKey(name: 'total_earned', fromJson: _doubleFromString)
  final double totalEarned;
  @JsonKey(name: 'withdraw_requests')
  final WithdrawRequestsWrapper withdrawRequestsWrapper;

  WalletBalanceModel({
    required this.balance,
    required this.totalPaid,
    required this.totalEarned,
    required this.withdrawRequestsWrapper,
  });

  // Getter to preserve compatibility with UI lists
  List<WithdrawRequest> get withdrawRequests => withdrawRequestsWrapper.data;

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    final rawRequests = json['withdraw_requests'];
    final List<WithdrawRequest> requestsList;
    if (rawRequests is List) {
      requestsList = rawRequests
          .whereType<Map>()
          .map((e) => WithdrawRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (rawRequests is Map && rawRequests['data'] is List) {
      requestsList = (rawRequests['data'] as List)
          .whereType<Map>()
          .map((e) => WithdrawRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      requestsList = [];
    }

    return WalletBalanceModel(
      balance: _doubleFromString(json['balance']),
      totalPaid: _doubleFromString(json['total_paid']),
      totalEarned: _doubleFromString(json['total_earned']),
      withdrawRequestsWrapper: WithdrawRequestsWrapper(data: requestsList),
    );
  }
  Map<String, dynamic> toJson() => {
    'balance': balance,
    'total_paid': totalPaid,
    'total_earned': totalEarned,
    'withdraw_requests': withdrawRequestsWrapper.toJson(),
  };
}

@JsonSerializable()
class WithdrawRequestsWrapper {
  final List<WithdrawRequest> data;

  WithdrawRequestsWrapper({required this.data});

  factory WithdrawRequestsWrapper.fromJson(dynamic json) {
    if (json is List) {
      return WithdrawRequestsWrapper(
        data: json
            .whereType<Map>()
            .map((e) => WithdrawRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
    if (json is Map && json['data'] is List) {
      return WithdrawRequestsWrapper(
        data: (json['data'] as List)
            .whereType<Map>()
            .map((e) => WithdrawRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
    return WithdrawRequestsWrapper(data: []);
  }
  Map<String, dynamic> toJson() => {
    'data': data.map((e) => e.toJson()).toList(),
  };
}

@JsonSerializable()
class WithdrawRequest {
  final int id;
  @JsonKey(name: 'reference_id')
  final String referenceId;
  @JsonKey(fromJson: _doubleFromString)
  final double amount;
  final int status;
  @JsonKey(name: 'transaction_id')
  final String? transactionId;
  final String? remarks;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  WithdrawRequest({
    required this.id,
    required this.referenceId,
    required this.amount,
    required this.status,
    this.transactionId,
    this.remarks,
    required this.createdAt,
  });

  factory WithdrawRequest.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is num ? rawId.toInt() : (int.tryParse(rawId?.toString() ?? '') ?? 0);
    final rawStatus = json['status'];
    final status = rawStatus is num ? rawStatus.toInt() : (int.tryParse(rawStatus?.toString() ?? '') ?? 1);
    
    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return WithdrawRequest(
      id: id,
      referenceId: json['reference_id']?.toString() ?? '',
      amount: _doubleFromString(json['amount']),
      status: status,
      transactionId: json['transaction_id']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: parsedDate,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'reference_id': referenceId,
    'amount': amount,
    'status': status,
    'transaction_id': transactionId,
    'remarks': remarks,
    'created_at': createdAt.toIso8601String(),
  };

  String get statusString {
    switch (status) {
      case 2:
        return 'Approved';
      case 3:
        return 'Rejected';
      case 4:
        return 'Paid';
      case 1:
      default:
        return 'Pending';
    }
  }
}
