// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'designation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesignationModel _$DesignationModelFromJson(Map<String, dynamic> json) =>
    DesignationModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$DesignationModelToJson(DesignationModel instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
