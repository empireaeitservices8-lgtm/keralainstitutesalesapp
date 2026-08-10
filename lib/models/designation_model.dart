import 'package:json_annotation/json_annotation.dart';

part 'designation_model.g.dart';

@JsonSerializable()
class DesignationModel {
  final int id;
  final String name;

  DesignationModel({
    required this.id,
    required this.name,
  });

  factory DesignationModel.fromJson(Map<String, dynamic> json) => _$DesignationModelFromJson(json);
  Map<String, dynamic> toJson() => _$DesignationModelToJson(this);
}
