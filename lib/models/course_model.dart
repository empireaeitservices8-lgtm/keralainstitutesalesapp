class CourseModel {
  final String id;
  final String name;
  final int fee;
  final String duration;
  final String status;
  final String createdAt;
  final String updatedAt;

  const CourseModel({
    required this.id,
    required this.name,
    this.fee = 0,
    this.duration = '',
    this.status = 'active',
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isActive => status.toLowerCase() == 'active';

  String get formattedFee => '₹$fee';

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fee: json['fee'] is num
          ? (json['fee'] as num).toInt()
          : (int.tryParse(json['fee']?.toString() ?? '') ??
              int.tryParse(json['fees']?.toString() ?? '') ??
              0),
      duration: json['duration']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'fee': fee,
      'duration': duration,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
