// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletBalanceModel _$WalletBalanceModelFromJson(Map<String, dynamic> json) =>
    WalletBalanceModel(
      balance: _doubleFromString(json['balance']),
      totalPaid: _doubleFromString(json['total_paid']),
      totalEarned: _doubleFromString(json['total_earned']),
      withdrawRequestsWrapper: json['withdraw_requests'] != null
          ? WithdrawRequestsWrapper.fromJson(json['withdraw_requests'])
          : WithdrawRequestsWrapper(data: []),
    );

Map<String, dynamic> _$WalletBalanceModelToJson(WalletBalanceModel instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'total_paid': instance.totalPaid,
      'total_earned': instance.totalEarned,
      'withdraw_requests': instance.withdrawRequestsWrapper,
    };

WithdrawRequestsWrapper _$WithdrawRequestsWrapperFromJson(
  Map<String, dynamic> json,
) => WithdrawRequestsWrapper(
  data: (json['data'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((e) => WithdrawRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
      [],
);

Map<String, dynamic> _$WithdrawRequestsWrapperToJson(
  WithdrawRequestsWrapper instance,
) => <String, dynamic>{'data': instance.data};

WithdrawRequest _$WithdrawRequestFromJson(Map<String, dynamic> json) =>
    WithdrawRequest(
      id: (json['id'] as num).toInt(),
      referenceId: json['reference_id'] as String,
      amount: _doubleFromString(json['amount']),
      status: (json['status'] as num).toInt(),
      transactionId: json['transaction_id'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$WithdrawRequestToJson(WithdrawRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference_id': instance.referenceId,
      'amount': instance.amount,
      'status': instance.status,
      'transaction_id': instance.transactionId,
      'remarks': instance.remarks,
      'created_at': instance.createdAt.toIso8601String(),
    };
