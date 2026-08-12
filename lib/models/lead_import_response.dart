class LeadImportData {
  final int importId;
  final int totalRows;

  LeadImportData({
    required this.importId,
    required this.totalRows,
  });

  factory LeadImportData.fromJson(Map<String, dynamic> json) {
    return LeadImportData(
      importId: json['import_id'] as int,
      totalRows: json['total_rows'] as int,
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
      data: json['data'] != null
          ? LeadImportData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
