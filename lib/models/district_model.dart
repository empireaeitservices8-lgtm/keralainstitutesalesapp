class DistrictModel {
  final String id;
  final String name;
  final String zone;
  final String description;
  final String? createdAt;
  final String? updatedAt;

  const DistrictModel({
    required this.id,
    required this.name,
    required this.zone,
    this.description = '',
    this.createdAt,
    this.updatedAt,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      zone: (json['zone'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'zone': zone,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

