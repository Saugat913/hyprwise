import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

/// Synchronizes live shift state and idle quick-start metadata to native
/// Android AppWidgets (`ShiftWidgetProvider`) and iOS WidgetKit (`ShiftWidget`).
///
/// Uses `HomeWidget` storage (`HomeWidgetPreferences` on Android, App Group
/// `UserDefaults(suiteName: "group.com.hypr.hyprwise")` on iOS) as the single
/// source of truth so native widgets can run their own zero-battery live timers
/// (`Chronometer` on Android, `Text(date, style: .timer)` + minute `Timeline`
/// on iOS) even when the Flutter app is backgrounded or terminated.
class WidgetSyncService {
  WidgetSyncService._();

  static const String appGroupId = 'group.com.hypr.hyprwise';
  static const MethodChannel _androidChannel = MethodChannel('com.hypr.hyprwise/widget');

  // Primary state keys
  static const String keyActive = 'widget_shift_active';
  static const String keyShiftId = 'widget_shift_id';
  static const String keyJobName = 'widget_shift_job';
  static const String keySubtitle = 'widget_shift_subtitle';
  static const String keyIsOnBreak = 'widget_shift_is_on_break';

  // Live native calculation keys
  static const String keyStartMs = 'widget_shift_start_ms';
  static const String keyEffectiveStartMs = 'widget_shift_effective_start_ms';
  static const String keyWorkedSeconds = 'widget_shift_worked_seconds';
  static const String keyBreakMinutes = 'widget_shift_break_minutes';
  static const String keyRateMinor = 'widget_shift_rate_minor';
  static const String keyOtThresholdMin = 'widget_shift_ot_threshold_min';
  static const String keyOtRateMinor = 'widget_shift_ot_rate_minor';
  static const String keyCurrencyCode = 'widget_shift_currency_code';
  static const String keyCurrencySymbol = 'widget_shift_currency_symbol';
  static const String keyRateLabel = 'widget_shift_rate_label';
  static const String keyEarningsLabel = 'widget_shift_earnings_label';
  static const String keyDefaultJob = 'widget_default_job';
  static const String keyDefaultRateLabel = 'widget_default_rate_label';
  static const String keyUpdatedAtMs = 'widget_updated_at_ms';

  static Future<void>? _initFuture;
  static bool _initialized = false;

  /// Sets up shared App Group storage for iOS WidgetKit and Android AppWidgets.
  /// Serialized so concurrent startup calls never write before App Group ID is set.
  static Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initFuture ??= _doInitialize();
  }

  static Future<void> _doInitialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      _initialized = true;
    } catch (e) {
      _initFuture = null;
      if (kDebugMode) {
        debugPrint('[WidgetSyncService] initialize error: $e');
      }
    }
  }

  /// Pushes active shift state & native live-timer parameters to Android & iOS widgets.
  static Future<void> updateShift({
    required String jobName,
    required String subtitle,
    bool isOnBreak = false,
    int shiftId = 0,
    int? startAtMs,
    int? effectiveStartMs,
    int workedSeconds = 0,
    int breakMinutes = 0,
    int rateMinor = 0,
    int overtimeThresholdMinutes = 0,
    int overtimeRateMinor = 0,
    String currencyCode = 'USD',
    String currencySymbol = r'$',
    String rateLabel = '',
    String earningsLabel = '',
  }) async {
    try {
      await initialize();

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final resolvedEffectiveStart =
          effectiveStartMs ?? (nowMs - (workedSeconds * 1000));

      await Future.wait([
        HomeWidget.saveWidgetData<bool>(keyActive, true),
        HomeWidget.saveWidgetData<int>(keyShiftId, shiftId),
        HomeWidget.saveWidgetData<String>(keyJobName, jobName),
        HomeWidget.saveWidgetData<String>(keySubtitle, subtitle),
        HomeWidget.saveWidgetData<bool>(keyIsOnBreak, isOnBreak),
        HomeWidget.saveWidgetData<int>(keyStartMs, startAtMs ?? resolvedEffectiveStart),
        HomeWidget.saveWidgetData<int>(keyEffectiveStartMs, resolvedEffectiveStart),
        HomeWidget.saveWidgetData<int>(keyWorkedSeconds, workedSeconds),
        HomeWidget.saveWidgetData<int>(keyBreakMinutes, breakMinutes),
        HomeWidget.saveWidgetData<int>(keyRateMinor, rateMinor),
        HomeWidget.saveWidgetData<int>(keyOtThresholdMin, overtimeThresholdMinutes),
        HomeWidget.saveWidgetData<int>(keyOtRateMinor, overtimeRateMinor),
        HomeWidget.saveWidgetData<String>(keyCurrencyCode, currencyCode),
        HomeWidget.saveWidgetData<String>(keyCurrencySymbol, currencySymbol),
        HomeWidget.saveWidgetData<String>(keyRateLabel, rateLabel),
        HomeWidget.saveWidgetData<String>(keyEarningsLabel, earningsLabel),
        HomeWidget.saveWidgetData<int>(keyUpdatedAtMs, nowMs),
      ]);

      await _reloadShiftWidget();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[WidgetSyncService] updateShift error: $e\n$stack');
      }
    }
  }

  /// Resets widget state when no active shift is running, preserving the user's
  /// primary job name & rate so the idle widget feels personal and ready to start.
  static Future<void> clearShift({
    String? defaultJobName,
    String? defaultRateLabel,
  }) async {
    try {
      await initialize();

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final jobLabel = (defaultJobName != null && defaultJobName.trim().isNotEmpty)
          ? defaultJobName.trim()
          : '';
      final rateStr = (defaultRateLabel != null && defaultRateLabel.trim().isNotEmpty)
          ? defaultRateLabel.trim()
          : '';
      final idleSubtitle = jobLabel.isNotEmpty && rateStr.isNotEmpty
          ? '$jobLabel · $rateStr'
          : (jobLabel.isNotEmpty ? jobLabel : 'Tap to start tracking');

      await Future.wait([
        HomeWidget.saveWidgetData<bool>(keyActive, false),
        HomeWidget.saveWidgetData<int>(keyShiftId, 0),
        HomeWidget.saveWidgetData<String>(keyJobName, ''),
        HomeWidget.saveWidgetData<String>(keySubtitle, idleSubtitle),
        HomeWidget.saveWidgetData<bool>(keyIsOnBreak, false),
        HomeWidget.saveWidgetData<int>(keyStartMs, 0),
        HomeWidget.saveWidgetData<int>(keyEffectiveStartMs, 0),
        HomeWidget.saveWidgetData<int>(keyWorkedSeconds, 0),
        HomeWidget.saveWidgetData<int>(keyBreakMinutes, 0),
        HomeWidget.saveWidgetData<int>(keyRateMinor, 0),
        HomeWidget.saveWidgetData<int>(keyOtThresholdMin, 0),
        HomeWidget.saveWidgetData<int>(keyOtRateMinor, 0),
        HomeWidget.saveWidgetData<String>(keyRateLabel, rateStr),
        HomeWidget.saveWidgetData<String>(keyEarningsLabel, ''),
        HomeWidget.saveWidgetData<String>(keyDefaultJob, jobLabel),
        HomeWidget.saveWidgetData<String>(keyDefaultRateLabel, rateStr),
        HomeWidget.saveWidgetData<int>(keyUpdatedAtMs, nowMs),
      ]);

      await _reloadShiftWidget();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[WidgetSyncService] clearShift error: $e\n$stack');
      }
    }
  }

  /// Refreshes all widgets (Quick Actions, HyprAI, Live Shift Tracker).
  static Future<void> refreshAllWidgets() async {
    try {
      await initialize();

      await HomeWidget.updateWidget(
        name: 'ShiftWidgetProvider',
        androidName: 'ShiftWidgetProvider',
        qualifiedAndroidName: 'com.hypr.hyprwise.ShiftWidgetProvider',
        iOSName: 'ShiftWidget',
      );
      await HomeWidget.updateWidget(
        name: 'QuickActionsWidgetProvider',
        androidName: 'QuickActionsWidgetProvider',
        qualifiedAndroidName: 'com.hypr.hyprwise.QuickActionsWidgetProvider',
        iOSName: 'QuickActionsWidget',
      );
      await HomeWidget.updateWidget(
        name: 'HyprAiWidgetProvider',
        androidName: 'HyprAiWidgetProvider',
        qualifiedAndroidName: 'com.hypr.hyprwise.HyprAiWidgetProvider',
        iOSName: 'HyprAiWidget',
      );

      await _notifyAndroidNative(target: 'all');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WidgetSyncService] refreshAllWidgets error: $e');
      }
    }
  }

  static Future<void> _reloadShiftWidget() async {
    await HomeWidget.updateWidget(
      name: 'ShiftWidgetProvider',
      androidName: 'ShiftWidgetProvider',
      qualifiedAndroidName: 'com.hypr.hyprwise.ShiftWidgetProvider',
      iOSName: 'ShiftWidget',
    );
    await _notifyAndroidNative(target: 'shift');
  }

  static Future<void> _notifyAndroidNative({required String target}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _androidChannel.invokeMethod('updateWidgets', {'target': target});
    } catch (_) {}
  }
}
