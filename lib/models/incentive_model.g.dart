// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incentive_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncentiveModel _$IncentiveModelFromJson(Map<String, dynamic> json) =>
    IncentiveModel(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0.0).toDouble(),
      remarks: json['remarks'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      achievementProofPath: json['achievement_proof_path'] as String?,
      status: json['status'] as String? ?? 'Pending',
    );

Map<String, dynamic> _$IncentiveModelToJson(IncentiveModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'amount': instance.amount,
      'remarks': instance.remarks,
      'date': instance.date.toIso8601String(),
      'achievement_proof_path': instance.achievementProofPath,
      'status': instance.status,
    };
