import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetSyncService {
  WidgetSyncService._();

  static const String _keyJobName = 'widget_shift_job';
  static const String _keySubtitle = 'widget_shift_subtitle';

  /// Updates the cached shift details used by the native home screen widgets.
  static Future<void> updateShift({
    required String jobName,
    required String subtitle,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyJobName, jobName);
      await prefs.setString(_keySubtitle, subtitle);
    } catch (e, stack) {
      debugPrint('[WidgetSyncService] updateShift error: $e\n$stack');
    }
  }

  /// Resets widget state when no active shift is running.
  static Future<void> clearShift() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyJobName, 'NO ACTIVE SHIFT');
      await prefs.setString(_keySubtitle, 'Tap to start a shift');
    } catch (e, stack) {
      debugPrint('[WidgetSyncService] clearShift error: $e\n$stack');
    }
  }
}
