// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_video_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrainingVideoModel _$TrainingVideoModelFromJson(Map<String, dynamic> json) =>
    TrainingVideoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      duration: json['duration'] as String,
      difficulty: json['difficulty'] as String? ?? 'Beginner',
      videoUrl:
          json['video_url'] as String? ??
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      isCompleted: json['is_completed'] as bool? ?? false,
    );

Map<String, dynamic> _$TrainingVideoModelToJson(TrainingVideoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'duration': instance.duration,
      'difficulty': instance.difficulty,
      'video_url': instance.videoUrl,
      'is_completed': instance.isCompleted,
    };
