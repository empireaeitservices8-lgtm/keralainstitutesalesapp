class TrainingVideoModel {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final String videoUrl;
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
}
