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
}
