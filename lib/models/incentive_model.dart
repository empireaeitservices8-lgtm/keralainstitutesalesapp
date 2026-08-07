import 'package:json_annotation/json_annotation.dart';

part 'incentive_model.g.dart';

@JsonSerializable()
class IncentiveModel {
  final String id;
  final String category;
  final double amount;
  final String remarks;
  final DateTime date;
  @JsonKey(name: 'achievement_proof_path')
  final String? achievementProofPath;
  final String status;

  IncentiveModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.remarks,
    required this.date,
    this.achievementProofPath,
    this.status = 'Pending',
  });

  factory IncentiveModel.fromJson(Map<String, dynamic> json) => _$IncentiveModelFromJson(json);
  Map<String, dynamic> toJson() => _$IncentiveModelToJson(this);

  IncentiveModel copyWith({
    String? status,
  }) {
    return IncentiveModel(
      id: id,
      category: category,
      amount: amount,
      remarks: remarks,
      date: date,
      achievementProofPath: achievementProofPath,
      status: status ?? this.status,
    );
  }
}
