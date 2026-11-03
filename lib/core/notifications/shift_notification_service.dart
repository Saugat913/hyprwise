import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/notifications/reminder_planner.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  ShiftNotificationService.handleActionResponse(response);
}

class ShiftNotificationService {
  ShiftNotificationService._();
  static final ShiftNotificationService instance = ShiftNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _isAvailable = false;

  static const int shiftNotificationId = 9001;
  static const int longShiftAlertId = 9002;
  static const Duration _shiftNotifyMinInterval = Duration(milliseconds: 900);

  String? _lastShiftNotifyKey;
  DateTime? _lastShiftNotifyAt;
  static const String shiftChannelId = 'hyprwise_active_shift_channel';
  static const String alertsChannelId = 'hyprwise_scheduled_alerts_channel';
  static const DarwinNotificationDetails _darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.active,
  );

  bool get _isNepali {
    try {
      if (getIt.isRegistered<SettingsRepository>()) {
        return getIt<SettingsRepository>().localeCode == 'ne';
      }
    } catch (_) {}
    return false;
  }

  static void handleActionResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId == null || actionId.isEmpty) return;

    if (!getIt.isRegistered<WorkViewModel>()) return;
    final workVm = getIt<WorkViewModel>();

    if (actionId == 'toggle_break') {
      workVm.toggleBreak();
    } else if (actionId == 'stop_shift') {
      final s = workVm.activeShift;
      if (s != null) {
        workVm.endShift(s.id, breakMinutes: workVm.currentBreakMinutes);
      }
    }
  }

  /// Initializes notification channels, timezone data, and tap handlers.
  /// Note: NEVER requests permissions on startup without user context.
  Future<void> initialize({
    void Function(String action)? onAction,
    void Function(String? payload)? onSelectNotification,
  }) async {
    if (_initialized) return;

    // Initialize Timezone for accurate scheduled notifications
    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization warning: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.actionId != null && response.actionId!.isNotEmpty) {
            handleActionResponse(response);
            onAction?.call(response.actionId!);
          } else {
            onSelectNotification?.call(response.payload);
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      final launchDetails = await _notifications.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final resp = launchDetails.notificationResponse;
        if (resp != null) {
          if (resp.actionId != null && resp.actionId!.isNotEmpty) {
            handleActionResponse(resp);
          } else if (resp.payload != null) {
            onSelectNotification?.call(resp.payload);
          }
        }
      }

      final isNe = _isNepali;
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // Register active shift channel
        final shiftChannel = AndroidNotificationChannel(
          shiftChannelId,
          isNe ? 'सक्रिय सिफ्ट ट्र्याकिङ' : 'Active Shift Tracking',
          description: isNe
              ? 'सिफ्ट काम गर्दाको प्रत्यक्ष स्थिति र नियन्त्रणहरू'
              : 'Live status and controls while working a shift',
          importance: Importance.high,
          playSound: false,
          enableVibration: false,
          showBadge: true,
        );
        await android.createNotificationChannel(shiftChannel);

        // Register scheduled alerts channel
        final alertChannel = AndroidNotificationChannel(
          alertsChannelId,
          isNe ? 'रिमाइन्डर तथा अलर्टहरू' : 'Reminders & Scheduled Alerts',
          description: isNe
              ? 'आगामी सिफ्ट, बिल तथा ऋणको भुक्तानी मिति रिमाइन्डर'
              : 'Timely reminders for upcoming shifts, bills, and loan due dates',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await android.createNotificationChannel(alertChannel);
      }

      _initialized = true;
      _isAvailable = true;
    } catch (e) {
      _initialized = true;
      _isAvailable = false;
      if (!e.toString().contains('LateInitializationError') &&
          !e.toString().contains('MissingPluginException')) {
        debugPrint('Failed to initialize notifications: $e');
      }
    }
  }

  /// Explicitly requests notification permission with user context (e.g. clocking in, toggling alerts).
  Future<bool> requestPermission() async {
    if (!_initialized) await initialize();
    if (!_isAvailable) return false;
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      final mac = _notifications.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (mac != null) {
        final granted = await mac.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Failed to request notification permission: $e');
    }
    return true;
  }

  /// Explicitly requests exact alarms permission on Android 13/14+ if not yet granted.
  Future<bool> requestExactAlarmsPermission() async {
    if (!_initialized) await initialize();
    if (!_isAvailable) return false;
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestExactAlarmsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Failed to request exact alarms permission: $e');
    }
    return true;
  }

  /// Safely schedules zoned notification using exact mode, asking for permission
  /// and falling back to inexact mode if exact alarms are not permitted.
  Future<void> _safeZonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } catch (e) {
      final isExactAlarmError = e is PlatformException &&
          (e.code == 'exact_alarms_not_permitted' ||
              (e.message?.contains('exact_alarms') ?? false));

      if (isExactAlarmError) {
        await requestExactAlarmsPermission();
        try {
          await _notifications.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: matchDateTimeComponents,
            payload: payload,
          );
          return;
        } catch (e2) {
          debugPrint('Inexact fallback error for reminder $id: $e2');
        }
      }
      debugPrint('Error scheduling reminder $id: $e');
    }
  }

  /// Live persistent notification displayed during an active shift
  Future<void> showActiveShiftNotification({
    required String jobName,
    required int startAtMs,
    required String elapsedFormatted,
    required String earningsFormatted,
    bool isOnBreak = false,
    int breakMinutes = 0,
    bool force = false,
  }) async {
    if (!_initialized) await initialize();
    if (!_isAvailable) return;

    // Called every second by the work view model: skip unchanged content and
    // never post more than about once per second.
    final key = '$jobName|$elapsedFormatted|$earningsFormatted|$isOnBreak|$breakMinutes';
    final nowTs = DateTime.now();
    if (!force) {
      if (key == _lastShiftNotifyKey) return;
      final last = _lastShiftNotifyAt;
      if (last != null && nowTs.difference(last) < _shiftNotifyMinInterval) return;
    }
    _lastShiftNotifyKey = key;
    _lastShiftNotifyAt = nowTs;

    final isNe = _isNepali;
    final breakInfo = isOnBreak
        ? (isNe ? ' (विश्राम: $breakMinutes मिनेट)' : ' (Break: ${breakMinutes}m)')
        : '';
    final earningsInfo = earningsFormatted.isNotEmpty ? ' · $earningsFormatted' : '';

    final androidDetails = AndroidNotificationDetails(
      shiftChannelId,
      isNe ? 'सक्रिय सिफ्ट ट्र्याकिङ' : 'Active Shift Tracking',
      channelDescription: isNe
          ? 'सिफ्ट काम गर्दाको प्रत्यक्ष स्थिति र नियन्त्रणहरू'
          : 'Live status and controls while working a shift',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: !isOnBreak,
      usesChronometer: !isOnBreak,
      when: isOnBreak ? null : startAtMs,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFFFF6500),
      category: AndroidNotificationCategory.status,
      actions: [
        AndroidNotificationAction(
          'toggle_break',
          isOnBreak
              ? (isNe ? 'काम जारी राख्नुहोस्' : 'Resume Shift')
              : (isNe ? 'विश्राम लिनुहोस्' : 'Take Break'),
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'stop_shift',
          isNe ? 'सिफ्ट समाप्त' : 'Clock Out',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails, iOS: _darwinDetails);

    try {
      await _notifications.show(
        id: shiftNotificationId,
        title: isOnBreak
            ? (isNe ? '⏸ विश्राममा · $jobName' : '⏸ On Break · $jobName')
            : (isNe ? 'सक्रिय सिफ्ट · $jobName' : 'Active Shift · $jobName'),
        body: isOnBreak
            ? (isNe
                ? 'समय रोकियो · $elapsedFormatted काम गरियो$breakInfo$earningsInfo'
                : 'Timer paused · $elapsedFormatted worked$breakInfo$earningsInfo')
            : (isNe
                ? '$elapsedFormatted बित्यो$earningsInfo'
                : '$elapsedFormatted elapsed$earningsInfo'),
        notificationDetails: details,
        payload: '/work/shift/live',
      );
    } catch (e) {
      debugPrint('Error showing shift notification: $e');
    }
  }

  Future<void> cancelShiftNotification() async {
    _lastShiftNotifyKey = null;
    _lastShiftNotifyAt = null;
    if (!_initialized || !_isAvailable) return;
    try {
      await _notifications.cancel(id: shiftNotificationId);
    } catch (e) {
      debugPrint('Error cancelling shift notification: $e');
    }
  }

  /// Schedules a reminder for an upcoming shift (e.g. 30 or 60 minutes before)
  Future<void> scheduleShiftReminder({
    required int shiftId,
    required String jobName,
    required DateTime startAt,
    int minutesBefore = 30,
  }) async {
    if (!_initialized) await initialize();
    if (!_isAvailable) return;
    final reminderTime = startAt.subtract(Duration(minutes: minutesBefore));
    if (reminderTime.isBefore(DateTime.now())) return;

    final isNe = _isNepali;
    final scheduledTz = tz.TZDateTime.from(reminderTime, tz.local);
    final notificationId = 10000 + (shiftId % 50000);

    final androidDetails = AndroidNotificationDetails(
      alertsChannelId,
      isNe ? 'रिमाइन्डर तथा अलर्टहरू' : 'Reminders & Scheduled Alerts',
      channelDescription: isNe
          ? 'आगामी सिफ्ट, बिल तथा ऋणको भुक्तानी मिति रिमाइन्डर'
          : 'Timely reminders for upcoming shifts, bills, and loan due dates',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFFFF6500),
    );

    await _safeZonedSchedule(
      id: notificationId,
      title: isNe ? '⏰ आगामी सिफ्ट: $jobName' : '⏰ Upcoming Shift: $jobName',
      body: isNe
          ? '$minutesBefore मिनेटमा सुरु हुँदैछ (${DateFormat('h:mm a').format(startAt)})'
          : 'Starts in $minutesBefore mins at ${DateFormat('h:mm a').format(startAt)}',
      scheduledDate: scheduledTz,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: _darwinDetails),
      payload: '/work',
    );
  }

  /// Schedules a reminder for a recurring bill
  Future<void> scheduleBillReminder({
    required int recurringId,
    required String title,
    required int amountMinor,
    required String currencyCode,
    required DateTime dueDate,
  }) async {
    if (!_initialized) await initialize();
    if (!_isAvailable) return;
    final reminderTime = DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0); // 9:00 AM on due day
    if (reminderTime.isBefore(DateTime.now())) return;

    final isNe = _isNepali;
    final scheduledTz = tz.TZDateTime.from(reminderTime, tz.local);
    final notificationId = 20000 + (recurringId % 50000);

    final androidDetails = AndroidNotificationDetails(
      alertsChannelId,
      isNe ? 'रिमाइन्डर तथा अलर्टहरू' : 'Reminders & Scheduled Alerts',
      channelDescription: isNe
          ? 'आगामी सिफ्ट, बिल तथा ऋणको भुक्तानी मिति रिमाइन्डर'
          : 'Timely reminders for upcoming shifts, bills, and loan due dates',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFFEA580C),
    );

    await _safeZonedSchedule(
      id: notificationId,
      title: isNe ? '📋 बिल तिर्ने दिन आज: $title' : '📋 Bill Due Today: $title',
      body: isNe
          ? '$currencyCode ${(amountMinor / 100.0).toStringAsFixed(2)} आज तिर्नुपर्नेछ'
          : '$currencyCode ${(amountMinor / 100.0).toStringAsFixed(2)} is due today',
      scheduledDate: scheduledTz,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: _darwinDetails),
      payload: '/money',
    );
  }

  /// Schedules a reminder for an active loan or debt settlement
  Future<void> scheduleDebtReminder({
    required int debtId,
    required String partyName,
    required int amountMinor,
    required String currencyCode,
    required DateTime dueDate,
    required bool isLent,
  }) async {
    if (!_initialized) await initialize();
    if (!_isAvailable) return;
    final reminderTime = DateTime(dueDate.year, dueDate.month, dueDate.day, 10, 0); // 10:00 AM on due day
    if (reminderTime.isBefore(DateTime.now())) return;

    final isNe = _isNepali;
    final scheduledTz = tz.TZDateTime.from(reminderTime, tz.local);
    final notificationId = 30000 + (debtId % 50000);

    final androidDetails = AndroidNotificationDetails(
      alertsChannelId,
      isNe ? 'रिमाइन्डर तथा अलर्टहरू' : 'Reminders & Scheduled Alerts',
      channelDescription: isNe
          ? 'आगामी सिफ्ट, बिल तथा ऋणको भुक्तानी मिति रिमाइन्डर'
          : 'Timely reminders for upcoming shifts, bills, and loan due dates',
      importance: Importance.high,
      priority: Priority.high,
      color: isLent ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
    );

    final amountStr = '$currencyCode ${(amountMinor / 100.0).toStringAsFixed(2)}';
    final title = isLent
        ? (isNe ? '💰 सापटी फिर्ता मिति: $partyName' : '💰 Loan Due: $partyName')
        : (isNe ? '⚠️ ऋण भुक्तानी मिति: $partyName' : '⚠️ Debt Due: $partyName');
    final body = isLent
        ? (isNe
            ? '$partyName ले आज $amountStr फिर्ता गर्ने तालिका छ'
            : '$partyName is scheduled to repay $amountStr today')
        : (isNe
            ? '$partyName लाई आज $amountStr भुक्तानी गर्नुपर्नेछ'
            : 'Repayment of $amountStr to $partyName is due today');

    await _safeZonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledTz,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: _darwinDetails),
      payload: '/debts',
    );
  }

  /// Cancels any scheduled or active notification by ID
  Future<void> cancelNotification(int id) async {
    if (!_initialized || !_isAvailable) return;
    try {
      await _notifications.cancel(id: id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  AndroidNotificationDetails _alertDetails(Color color) {
    final isNe = _isNepali;
    return AndroidNotificationDetails(
      alertsChannelId,
      isNe ? 'रिमाइन्डर तथा अलर्टहरू' : 'Reminders & Scheduled Alerts',
      channelDescription: isNe
          ? 'आगामी सिफ्ट, बिल तथा ऋणको भुक्तानी मिति रिमाइन्डर'
          : 'Timely reminders for upcoming shifts, bills, and loan due dates',
      importance: Importance.high,
      priority: Priority.high,
      color: color,
    );
  }

  /// Schedules the "you have been working a long time" alert for a live shift.
  Future<void> scheduleLongShiftAlert({
    required String title,
    required String body,
    required DateTime at,
  }) async {
    if (!_initialized) await initialize();
    if (!_isAvailable || !at.isAfter(DateTime.now())) return;
    await _safeZonedSchedule(
      id: longShiftAlertId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: NotificationDetails(android: _alertDetails(const Color(0xFFFF6500)), iOS: _darwinDetails),
      payload: '/work/shift/live',
    );
  }

  Future<void> cancelLongShiftAlert() => cancelNotification(longShiftAlertId);

  /// Replaces every pending rule-based reminder with [plan].
  Future<void> syncReminders(List<PlannedReminder> plan) async {
    if (!_initialized) await initialize();
    if (!_isAvailable) return;
    try {
      final pending = await _notifications.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id >= ReminderPlanner.idBase) await _notifications.cancel(id: p.id);
      }
    } catch (e) {
      debugPrint('Error clearing reminder notifications: $e');
    }
    for (final r in plan) {
      await _safeZonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: NotificationDetails(android: _alertDetails(const Color(0xFFFF6500)), iOS: _darwinDetails),
        matchDateTimeComponents: r.weekly ? DateTimeComponents.dayOfWeekAndTime : null,
        payload: r.payload,
      );
    }
  }
}
