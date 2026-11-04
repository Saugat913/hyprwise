import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetSyncService {
  WidgetSyncService._();

  static const MethodChannel _channel = MethodChannel('com.hypr.hyprwise/widget');

  static const String _keyJobName = 'widget_shift_job';
  static const String _keySubtitle = 'widget_shift_subtitle';
  static const String _keyIsOnBreak = 'widget_shift_is_on_break';
  static const String _keyActive = 'widget_shift_active';

  /// Updates the cached shift details used by native home screen widgets.
  static Future<void> updateShift({
    required String jobName,
    required String subtitle,
    bool isOnBreak = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyJobName, jobName);
      await prefs.setString(_keySubtitle, subtitle);
      await prefs.setBool(_keyIsOnBreak, isOnBreak);
      await prefs.setBool(_keyActive, true);
      await _notifyNativeWidgets();
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
      await prefs.setBool(_keyIsOnBreak, false);
      await prefs.setBool(_keyActive, false);
      await _notifyNativeWidgets();
    } catch (e, stack) {
      debugPrint('[WidgetSyncService] clearShift error: $e\n$stack');
    }
  }

  static Future<void> _notifyNativeWidgets() async {
    try {
      await _channel.invokeMethod('updateWidgets');
    } catch (e) {
      // In tests or if platform method is not handled, ignore gracefully
      debugPrint('[WidgetSyncService] _notifyNativeWidgets ignored: $e');
    }
  }
}
