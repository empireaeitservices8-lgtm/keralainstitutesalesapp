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

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) => _$WalletBalanceModelFromJson(json);
  Map<String, dynamic> toJson() => _$WalletBalanceModelToJson(this);
}

@JsonSerializable()
class WithdrawRequestsWrapper {
  final List<WithdrawRequest> data;

  WithdrawRequestsWrapper({required this.data});

  factory WithdrawRequestsWrapper.fromJson(Map<String, dynamic> json) => _$WithdrawRequestsWrapperFromJson(json);
  Map<String, dynamic> toJson() => _$WithdrawRequestsWrapperToJson(this);
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

  factory WithdrawRequest.fromJson(Map<String, dynamic> json) => _$WithdrawRequestFromJson(json);
  Map<String, dynamic> toJson() => _$WithdrawRequestToJson(this);

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
