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
      withdrawRequestsWrapper: WithdrawRequestsWrapper.fromJson(
          json['withdraw_requests'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WalletBalanceModelToJson(WalletBalanceModel instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'total_paid': instance.totalPaid,
      'total_earned': instance.totalEarned,
      'withdraw_requests': instance.withdrawRequestsWrapper,
    };

WithdrawRequestsWrapper _$WithdrawRequestsWrapperFromJson(
        Map<String, dynamic> json) =>
    WithdrawRequestsWrapper(
      data: (json['data'] as List<dynamic>)
          .map((e) => WithdrawRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WithdrawRequestsWrapperToJson(
        WithdrawRequestsWrapper instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

WithdrawRequest _$WithdrawRequestFromJson(Map<String, dynamic> json) =>
    WithdrawRequest(
      id: (json['id'] as num).toInt(),
      referenceId: json['reference_id'] as String? ?? '',
      amount: _doubleFromString(json['amount']),
      status: (json['status'] as num? ?? 1).toInt(),
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );

Map<String, dynamic> _$WithdrawRequestToJson(WithdrawRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference_id': instance.referenceId,
      'amount': instance.amount,
      'status': instance.status,
      'remarks': instance.remarks,
      'created_at': instance.createdAt.toIso8601String(),
    };
