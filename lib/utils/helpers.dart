import 'package:flutter/material.dart';

class UiHelpers {
  static void showSnackBar(
    BuildContext context,
    String message,
    Color bgColor, {
    Color textColor = Colors.black87,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showMessengerSnackBar(
    ScaffoldMessengerState messenger,
    String message,
    Color bgColor, {
    Color textColor = Colors.black87,
  }) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static DateTime parseUtcDateTime(String str) {
    if (str.isEmpty) return DateTime.now();
    if (str.contains('Z') || str.contains('+')) {
      return DateTime.parse(str).toLocal();
    }
    final normalized = str.replaceFirst(' ', 'T');
    return DateTime.parse(normalized);
  }

  static DateTime? parseNullableUtcDateTime(String? str) {
    if (str == null || str.isEmpty) return null;
    return parseUtcDateTime(str);
  }

  static bool parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final lower = val.toLowerCase().trim();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  static int parseInt(dynamic val, [int defaultValue = 0]) {
    if (val == null) return defaultValue;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val.trim()) ??
          (double.tryParse(val.trim())?.toInt() ?? defaultValue);
    }
    return defaultValue;
  }

  static double parseDouble(dynamic val, [double defaultValue = 0.0]) {
    if (val == null) return defaultValue;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  static num parseNum(dynamic val, [num defaultValue = 0]) {
    if (val == null) return defaultValue;
    if (val is num) return val;
    if (val is String) {
      return num.tryParse(val.trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  static int? parseIntNullable(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      final trimmed = val.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt();
    }
    return null;
  }
}
