class LeadImportData {
  final int importId;
  final int totalRows;

  LeadImportData({
    required this.importId,
    required this.totalRows,
  });

  factory LeadImportData.fromJson(Map<String, dynamic> json) {
    return LeadImportData(
      importId: json['import_id'] is num ? (json['import_id'] as num).toInt() : (int.tryParse(json['import_id']?.toString() ?? '') ?? 0),
      totalRows: json['total_rows'] is num ? (json['total_rows'] as num).toInt() : (int.tryParse(json['total_rows']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'import_id': importId,
      'total_rows': totalRows,
    };
  }
}

class LeadImportResult {
  final bool success;
  final String message;
  final LeadImportData? data;

  LeadImportResult({
    required this.success,
    required this.message,
    this.data,
  });

  factory LeadImportResult.fromJson(Map<String, dynamic> json) {
    return LeadImportResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && json['data'] is Map
          ? LeadImportData.fromJson(Map<String, dynamic>.from(json['data'] as Map))
          : null,
    );
  }
}
