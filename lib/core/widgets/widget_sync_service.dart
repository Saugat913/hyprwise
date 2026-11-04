import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetSyncService {
  WidgetSyncService._();

  static const String appGroupId = 'group.com.hypr.hyprwise';
  static const MethodChannel _androidChannel = MethodChannel('com.hypr.hyprwise/widget');

  static const String _keyJobName = 'widget_shift_job';
  static const String _keySubtitle = 'widget_shift_subtitle';
  static const String _keyIsOnBreak = 'widget_shift_is_on_break';
  static const String _keyActive = 'widget_shift_active';

  static bool _initialized = false;

  /// Sets up shared App Group storage for iOS WidgetKit and Android Glance/RemoteViews.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      _initialized = true;
    } catch (e) {
      debugPrint('[WidgetSyncService] initialize error: $e');
    }
  }

  /// Updates the cached shift details used by native home screen widgets on Android & iOS.
  static Future<void> updateShift({
    required String jobName,
    required String subtitle,
    bool isOnBreak = false,
  }) async {
    try {
      await initialize();

      // 1. Persist to HomeWidget shared storage (UserDefaults on iOS, HomeWidgetPreferences on Android)
      await HomeWidget.saveWidgetData<String>(_keyJobName, jobName);
      await HomeWidget.saveWidgetData<String>(_keySubtitle, subtitle);
      await HomeWidget.saveWidgetData<bool>(_keyIsOnBreak, isOnBreak);
      await HomeWidget.saveWidgetData<bool>(_keyActive, true);

      // 2. Also persist to standard Flutter SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyJobName, jobName);
      await prefs.setString(_keySubtitle, subtitle);
      await prefs.setBool(_keyIsOnBreak, isOnBreak);
      await prefs.setBool(_keyActive, true);

      // 3. Request native widget timeline reload for both iOS & Android
      await HomeWidget.updateWidget(
        name: 'ShiftWidgetProvider',
        androidName: 'ShiftWidgetProvider',
        iOSName: 'ShiftWidget',
      );

      // 4. Notify Android custom broadcast receiver
      await _notifyNativeWidgets();
    } catch (e, stack) {
      debugPrint('[WidgetSyncService] updateShift error: $e\n$stack');
    }
  }

  /// Resets widget state when no active shift is running.
  static Future<void> clearShift() async {
    try {
      await initialize();

      await HomeWidget.saveWidgetData<String>(_keyJobName, 'NO ACTIVE SHIFT');
      await HomeWidget.saveWidgetData<String>(_keySubtitle, 'Tap to start a shift');
      await HomeWidget.saveWidgetData<bool>(_keyIsOnBreak, false);
      await HomeWidget.saveWidgetData<bool>(_keyActive, false);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyJobName, 'NO ACTIVE SHIFT');
      await prefs.setString(_keySubtitle, 'Tap to start a shift');
      await prefs.setBool(_keyIsOnBreak, false);
      await prefs.setBool(_keyActive, false);

      await HomeWidget.updateWidget(
        name: 'ShiftWidgetProvider',
        androidName: 'ShiftWidgetProvider',
        iOSName: 'ShiftWidget',
      );

      await _notifyNativeWidgets();
    } catch (e, stack) {
      debugPrint('[WidgetSyncService] clearShift error: $e\n$stack');
    }
  }

  /// Refreshes all widgets (Quick Actions, HyprAI, Live Shift Tracker).
  static Future<void> refreshAllWidgets() async {
    try {
      await initialize();

      await HomeWidget.updateWidget(
        name: 'ShiftWidgetProvider',
        androidName: 'ShiftWidgetProvider',
        iOSName: 'ShiftWidget',
      );
      await HomeWidget.updateWidget(
        name: 'QuickActionsWidgetProvider',
        androidName: 'QuickActionsWidgetProvider',
        iOSName: 'QuickActionsWidget',
      );
      await HomeWidget.updateWidget(
        name: 'HyprAiWidgetProvider',
        androidName: 'HyprAiWidgetProvider',
        iOSName: 'HyprAiWidget',
      );

      await _notifyNativeWidgets();
    } catch (e) {
      debugPrint('[WidgetSyncService] refreshAllWidgets error: $e');
    }
  }

  static Future<void> _notifyNativeWidgets() async {
    try {
      await _androidChannel.invokeMethod('updateWidgets');
    } catch (_) {}
  }
}
