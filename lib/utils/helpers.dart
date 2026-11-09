import 'package:flutter/material.dart';
import '../services/common/navigation_services.dart';

class UiHelpers {
  static OverlayEntry? _currentToastEntry;

  /// Displays a floating top toast banner above all modal sheets, dialogs, and navigation stacks.
  static void showToast(
    String message, {
    bool isError = true,
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlayState = context != null
        ? (Overlay.maybeOf(context) ?? navigatorKey.currentState?.overlay)
        : navigatorKey.currentState?.overlay;

    if (overlayState == null) return;

    try {
      _currentToastEntry?.remove();
    } catch (_) {}
    _currentToastEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          top: MediaQuery.of(ctx).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -16 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isError ? const Color(0xFFDC2626) : const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isError ? const Color(0xFFDC2626) : const Color(0xFF0F766E))
                          .withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    _currentToastEntry = entry;
    overlayState.insert(entry);

    Future.delayed(duration, () {
      if (_currentToastEntry == entry) {
        try {
          entry.remove();
        } catch (_) {}
        _currentToastEntry = null;
      }
    });
  }

  static void showSnackBar(
    BuildContext context,
    String message,
    Color bgColor, {
    Color textColor = Colors.black87,
  }) {
    final bool isError = bgColor == Colors.redAccent ||
        bgColor == Colors.red ||
        bgColor == Colors.orange ||
        bgColor == Colors.orangeAccent;
    showToast(message, isError: isError, context: context);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {}
  }

  static void showMessengerSnackBar(
    ScaffoldMessengerState messenger,
    String message,
    Color bgColor, {
    Color textColor = Colors.black87,
  }) {
    final bool isError = bgColor == Colors.redAccent ||
        bgColor == Colors.red ||
        bgColor == Colors.orange ||
        bgColor == Colors.orangeAccent;
    showToast(message, isError: isError);

    try {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {}
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
