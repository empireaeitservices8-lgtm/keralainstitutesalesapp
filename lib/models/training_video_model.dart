import 'package:json_annotation/json_annotation.dart';

part 'training_video_model.g.dart';

@JsonSerializable()
class TrainingVideoModel {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  @JsonKey(name: 'video_url')
  final String videoUrl;
  @JsonKey(name: 'is_completed')
  bool isCompleted;

  TrainingVideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    this.difficulty = 'Beginner',
    this.videoUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    this.isCompleted = false,
  });

  factory TrainingVideoModel.fromJson(Map<String, dynamic> json) => _$TrainingVideoModelFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingVideoModelToJson(this);
}
