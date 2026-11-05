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

  /// Parses a working-hours value that may be a number (e.g. `1.5`),
  /// a colon-formatted string (e.g. `"0:44 hours"` -> 0 + 44/60 = 0.7333),
  /// or a plain number string (e.g. `"1.5 hours"`).
  static double parseWorkingHours(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble().abs();
    final str = val.toString().trim();
    if (str.isEmpty || str == 'null') return 0.0;

    final colonMatch = RegExp(r'(\d+)\s*:\s*(\d+)').firstMatch(str);
    if (colonMatch != null) {
      final hrs = int.tryParse(colonMatch.group(1)!) ?? 0;
      final mins = int.tryParse(colonMatch.group(2)!) ?? 0;
      return hrs + (mins / 60.0);
    }

    final numMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(str);
    if (numMatch != null) {
      return (double.tryParse(numMatch.group(1)!) ?? 0.0).abs();
    }
    return 0.0;
  }

  /// Formats working hours into a readable string like `"0:44 hrs"` (or uses
  /// the backend's formatted string if provided).
  static String formatWorkingHours(
    double? hours, {
    String? rawFormatted,
    DateTime? checkIn,
    DateTime? checkOut,
  }) {
    if (rawFormatted != null &&
        rawFormatted.trim().isNotEmpty &&
        rawFormatted.trim() != 'null') {
      final trimmed = rawFormatted.trim();
      if (RegExp(r'\d+\s*:\s*\d+').hasMatch(trimmed)) {
        return trimmed;
      }
    }

    int totalMinutes = 0;
    if (checkIn != null && checkOut != null) {
      final diff = checkOut.difference(checkIn).inMinutes;
      if (diff > 0) {
        totalMinutes = diff;
      }
    }
    if (totalMinutes == 0 && hours != null && hours > 0) {
      totalMinutes = (hours * 60).round();
    }

    final int h = totalMinutes ~/ 60;
    final int m = totalMinutes % 60;
    return '$h:${m.toString().padLeft(2, '0')} hrs';
  }
}
