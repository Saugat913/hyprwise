import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay, WidgetsBinding;

import 'package:finance_tracker/app/router/app_router.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/notifications/shift_notification_service.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

class WorkViewModel extends ChangeNotifier {
  WorkViewModel({
    required this.financeStore,
    required this.jobRepo,
    required this.shiftRepo,
  }) {
    financeStore.addListener(_onStoreChanged);
    _initNotifications();
    _startTimer();
  }

  final FinanceStore financeStore;
  final JobRepository jobRepo;
  final ShiftRepository shiftRepo;

  Timer? _ticker;
  int? _selectedJobId;
  int? get selectedJobId => _selectedJobId;

  bool _isOnBreak = false;
  bool get isOnBreak => _isOnBreak;
  DateTime? _breakStartTime;
  int _accumulatedBreakSeconds = 0;
  int? _activeBreakId;

  Future<List<ShiftBreak>> breaksForShift(int shiftId) => shiftRepo.breaksFor(shiftId);

  int get currentBreakSeconds {
    var totalSec = _accumulatedBreakSeconds;
    if (_isOnBreak && _breakStartTime != null) {
      totalSec += DateTime.now().difference(_breakStartTime!).inSeconds;
    }
    return totalSec;
  }

  int get currentBreakMinutes => (currentBreakSeconds / 60).floor();

  Duration get currentBreakDuration => Duration(seconds: currentBreakSeconds);

  bool get _isTestEnvironment {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  void _initNotifications() {
    if (_isTestEnvironment) {
      return;
    }
    ShiftNotificationService.instance.initialize(
      onAction: (action) {
        if (action == 'toggle_break') {
          toggleBreak();
        } else if (action == 'stop_shift') {
          final s = activeShift;
          if (s != null) {
            endShift(s.id, breakMinutes: currentBreakMinutes);
          }
        }
      },
      onSelectNotification: (payload) {
        if (payload != null && payload.isNotEmpty) {
          appRouter.push(payload);
        }
      },
    );
  }

  void toggleBreak() {
    final now = DateTime.now();
    final shift = activeShift;
    if (_isOnBreak) {
      if (_breakStartTime != null) {
        _accumulatedBreakSeconds += now.difference(_breakStartTime!).inSeconds;
        _breakStartTime = null;
      }
      if (_activeBreakId != null) {
        final breakId = _activeBreakId!;
        _activeBreakId = null;
        unawaited(shiftRepo.endBreak(breakId, now));
      }
      _isOnBreak = false;
    } else {
      _isOnBreak = true;
      _breakStartTime = now;
      if (shift != null) {
        unawaited(
          shiftRepo.startBreak(shift.id, now).then((id) {
            _activeBreakId = id;
          }),
        );
      }
    }
    _syncNotification();
    notifyListeners();
  }

  void _syncNotification() {
    final shift = activeShift;
    if (shift == null) {
      ShiftNotificationService.instance.cancelShiftNotification();
      return;
    }
    final job = jobsById[shift.jobId];
    if (job == null) return;
    final worked = activeShiftWorkedDuration;
    final h = worked.inHours.toString().padLeft(2, '0');
    final m = (worked.inMinutes % 60).toString().padLeft(2, '0');
    final s = (worked.inSeconds % 60).toString().padLeft(2, '0');
    final earnings = activeShiftLiveEarnings;
    final earningsStr = earnings != null
        ? MoneyFormatter.format(earnings.earningsMinor, job.currencyCode)
        : '';
    final effectiveStartMs = shift.startAt + (currentBreakSeconds * 1000);
    ShiftNotificationService.instance.showActiveShiftNotification(
      jobName: job.name,
      startAtMs: effectiveStartMs,
      elapsedFormatted: '$h:$m:$s',
      earningsFormatted: earningsStr,
      isOnBreak: _isOnBreak,
      breakMinutes: currentBreakMinutes,
    );
  }

  void _onStoreChanged() {
    _syncNotification();
    notifyListeners();
  }

  void _startTimer() {
    if (_isTestEnvironment) {
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (activeShift != null) {
        // Live notification sync while working; frozen during breaks
        if (!_isOnBreak) {
          _syncNotification();
        }
        notifyListeners();
      }
    });
  }

  bool get isClockedIn => activeShift != null;

  List<Job> get jobs => financeStore.jobs;
  List<Shift> get shifts => financeStore.shifts;
  String get baseCurrency => financeStore.baseCurrency;

  Map<int, Job> get jobsById => {for (final j in jobs) j.id: j};

  Job? get selectedJob {
    if (jobs.isEmpty) return null;
    if (_selectedJobId != null) {
      return jobsById[_selectedJobId] ?? jobs.first;
    }
    return jobs.first;
  }

  int? _filterJobId;
  int? get filterJobId => _filterJobId;

  String? _filterStatus;
  String? get filterStatus => _filterStatus;

  void selectJob(int id) {
    _selectedJobId = id;
    notifyListeners();
  }

  void setFilterJobId(int? id) {
    _filterJobId = id;
    notifyListeners();
  }

  void setFilterStatus(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  List<Shift> get filteredShifts {
    final list = shifts.where((s) {
      if (_filterJobId != null && s.jobId != _filterJobId) return false;
      if (_filterStatus != null && s.status != _filterStatus) return false;
      return true;
    }).toList();
    list.sort((a, b) => b.startAt.compareTo(a.startAt));
    return list;
  }

  /// Shifts for today only (scheduled, active, completed)
  List<Shift> get todayShifts {
    final today = AppDate.dateOnly(DateTime.now());
    final list = shifts.where((s) {
      if (_filterJobId != null && s.jobId != _filterJobId) return false;
      if (_filterStatus != null && s.status != _filterStatus) return false;
      final start = DateTime.fromMillisecondsSinceEpoch(s.startAt);
      return AppDate.dateOnly(start) == today;
    }).toList();
    list.sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  int get todayTotalCount {
    final today = AppDate.dateOnly(DateTime.now());
    return shifts.where((s) => AppDate.dateOnly(DateTime.fromMillisecondsSinceEpoch(s.startAt)) == today).length;
  }

  int get todayCompletedCount {
    final today = AppDate.dateOnly(DateTime.now());
    return shifts.where((s) => s.status == ShiftStatus.completed.value && AppDate.dateOnly(DateTime.fromMillisecondsSinceEpoch(s.startAt)) == today).length;
  }

  int get todayScheduledCount {
    final today = AppDate.dateOnly(DateTime.now());
    return shifts.where((s) => s.status == ShiftStatus.scheduled.value && AppDate.dateOnly(DateTime.fromMillisecondsSinceEpoch(s.startAt)) == today).length;
  }

  Shift? get activeShift {
    for (final s in shifts) {
      if (s.status == ShiftStatus.inProgress.value) return s;
    }
    return null;
  }

  Duration get activeShiftTotalClockDuration {
    final shift = activeShift;
    if (shift == null) return Duration.zero;
    final start = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
    return DateTime.now().difference(start);
  }

  Duration get activeShiftWorkedDuration {
    final total = activeShiftTotalClockDuration;
    final breakSec = currentBreakSeconds;
    final worked = total - Duration(seconds: breakSec);
    return worked.isNegative ? Duration.zero : worked;
  }

  Duration get activeShiftElapsed => activeShiftWorkedDuration;

  ShiftEarnings? get activeShiftLiveEarnings {
    final shift = activeShift;
    if (shift == null) return null;
    final job = jobsById[shift.jobId];
    if (job == null) return null;

    final rate = shift.rateOverrideMinor ?? job.hourlyRateMinor;
    return ShiftEarnings.compute(
      workedSeconds: activeShiftWorkedDuration.inSeconds,
      rateMinor: rate,
      overtimeThresholdMinutes: shift.overtimeThresholdMinutes,
      overtimeRateMinor: shift.overtimeRateMinor,
    );
  }

  double get hoursThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final jById = jobsById;
    var totalMin = 0;

    for (final s in shifts) {
      if (s.status != ShiftStatus.completed.value || s.endAt == null) continue;
      final start = DateTime.fromMillisecondsSinceEpoch(s.startAt);
      if (!start.isBefore(weekStart)) {
        final job = jById[s.jobId];
        if (job != null) {
          final earnings = ShiftEarnings.forShift(s, job);
          totalMin += earnings.workedMinutes;
        }
      }
    }
    return totalMin / 60;
  }

  int get shiftsLeftThisWeek {
    final now = DateTime.now();
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    var count = 0;

    for (final s in shifts) {
      if (s.status == ShiftStatus.scheduled.value) {
        final start = DateTime.fromMillisecondsSinceEpoch(s.startAt);
        if (start.isAfter(now) && !start.isAfter(weekEnd)) {
          count++;
        }
      }
    }
    return count;
  }

  Future<int> addJob({
    required String name,
    required int hourlyRateMinor,
    String? employer,
    String? currencyCode,
    int colorIndex = 0,
    int defaultBreakMinutes = 0,
    int longShiftAlertMinutes = 360,
  }) async {
    final id = await jobRepo.add(
      name: name,
      hourlyRateMinor: hourlyRateMinor,
      employer: employer,
      currencyCode: currencyCode ?? baseCurrency,
      colorIndex: colorIndex,
      defaultBreakMinutes: defaultBreakMinutes,
      longShiftAlertMinutes: longShiftAlertMinutes,
    );
    TelemetryService.instance.trackEvent('job_added', {'name': name});
    return id;
  }

  Future<void> updateJob(
    int id, {
    required String name,
    required int hourlyRateMinor,
    String? employer,
    int colorIndex = 0,
    int? defaultBreakMinutes,
    int? longShiftAlertMinutes,
  }) async {
    final existingJob = jobsById[id];
    if (existingJob != null && existingJob.hourlyRateMinor != hourlyRateMinor) {
      // Historical rate retention: ensure past shifts retain their old rate
      final pastShifts = shifts.where((s) => s.jobId == id && s.rateOverrideMinor == null).toList();
      for (final s in pastShifts) {
        await shiftRepo.update(s.id, rateOverrideMinor: existingJob.hourlyRateMinor);
      }
    }

    await jobRepo.update(
      id,
      name: name,
      hourlyRateMinor: hourlyRateMinor,
      currencyCode: existingJob?.currencyCode ?? baseCurrency,
      employer: employer,
      colorIndex: colorIndex,
      defaultBreakMinutes: defaultBreakMinutes,
      longShiftAlertMinutes: longShiftAlertMinutes,
    );
    TelemetryService.instance.trackEvent('job_updated', {'id': id, 'name': name});
  }

  Future<int> scheduleShift({
    required int jobId,
    required DateTime startAt,
    DateTime? endAt,
    int breakMinutes = 0,
    String? note,
    int? rateOverrideMinor,
    int? overtimeThresholdMinutes,
    int? overtimeRateMinor,
    int? longShiftAlertMinutes,
  }) async {
    final id = await shiftRepo.add(
      jobId: jobId,
      startAt: startAt,
      endAt: endAt,
      breakMinutes: breakMinutes,
      status: ShiftStatus.scheduled,
      note: note,
      rateOverrideMinor: rateOverrideMinor,
      overtimeThresholdMinutes: overtimeThresholdMinutes,
      overtimeRateMinor: overtimeRateMinor,
      longShiftAlertMinutes: longShiftAlertMinutes,
    );
    TelemetryService.instance.trackEvent('shift_scheduled', {'jobId': jobId});

    final job = jobsById[jobId];
    if (job != null && financeStore.settingsRepo.settings.shiftReminders) {
      await ShiftNotificationService.instance.scheduleShiftReminder(
        shiftId: id,
        jobName: job.name,
        startAt: startAt,
      );
    }

    return id;
  }

  Future<void> updateShift(
    int id, {
    int? jobId,
    DateTime? startAt,
    DateTime? endAt,
    int? breakMinutes,
    ShiftStatus? status,
    String? note,
    int? rateOverrideMinor,
    int? overtimeThresholdMinutes,
    int? overtimeRateMinor,
    int? longShiftAlertMinutes,
  }) async {
    await shiftRepo.update(
      id,
      jobId: jobId,
      startAt: startAt,
      endAt: endAt,
      breakMinutes: breakMinutes,
      status: status,
      note: note,
      rateOverrideMinor: rateOverrideMinor,
      overtimeThresholdMinutes: overtimeThresholdMinutes,
      overtimeRateMinor: overtimeRateMinor,
      longShiftAlertMinutes: longShiftAlertMinutes,
    );
    TelemetryService.instance.trackEvent('shift_updated', {'id': id});
  }

  Future<void> deleteShift(int id) async {
    await shiftRepo.delete(id);
    TelemetryService.instance.trackEvent('shift_deleted', {'id': id});
  }

  Future<List<int>> scheduleRecurringShifts({
    required int jobId,
    required Set<int> weekdays,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int weeksCount,
    int breakMinutes = 0,
    String? note,
    int? rateOverrideMinor,
    int? overtimeThresholdMinutes,
    int? overtimeRateMinor,
    int? longShiftAlertMinutes,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totalDays = weeksCount * 7;
    final createdIds = <int>[];

    for (var i = 0; i < totalDays; i++) {
      final date = today.add(Duration(days: i));
      if (weekdays.contains(date.weekday)) {
        final startAt = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
        final isNextDay = (endTime.hour < startTime.hour) ||
            (endTime.hour == startTime.hour && endTime.minute <= startTime.minute);
        final endBaseDate = isNextDay ? date.add(const Duration(days: 1)) : date;
        final endAt = DateTime(endBaseDate.year, endBaseDate.month, endBaseDate.day, endTime.hour, endTime.minute);

        final alreadyExists = shifts.any((s) {
          if (s.jobId != jobId) return false;
          final sDate = DateTime.fromMillisecondsSinceEpoch(s.startAt);
          return sDate.year == date.year && sDate.month == date.month && sDate.day == date.day;
        });

        if (!alreadyExists) {
          final id = await scheduleShift(
            jobId: jobId,
            startAt: startAt,
            endAt: endAt,
            breakMinutes: breakMinutes,
            note: note,
            rateOverrideMinor: rateOverrideMinor,
            overtimeThresholdMinutes: overtimeThresholdMinutes,
            overtimeRateMinor: overtimeRateMinor,
            longShiftAlertMinutes: longShiftAlertMinutes,
          );
          createdIds.add(id);
        }
      }
    }
    return createdIds;
  }

  Future<int> startShift({
    required int jobId,
    DateTime? startAt,
    int? rateOverrideMinor,
    int? overtimeThresholdMinutes,
    int? overtimeRateMinor,
    int? longShiftAlertMinutes,
  }) async {
    _isOnBreak = false;
    _breakStartTime = null;
    _accumulatedBreakSeconds = 0;
    _activeBreakId = null;

    final job = jobsById[jobId];
    final effectiveAlertMinutes = longShiftAlertMinutes ?? job?.longShiftAlertMinutes ?? 360;
    final start = startAt ?? DateTime.now();
    final id = await shiftRepo.add(
      jobId: jobId,
      startAt: start,
      breakMinutes: 0,
      status: ShiftStatus.inProgress,
      rateOverrideMinor: rateOverrideMinor,
      overtimeThresholdMinutes: overtimeThresholdMinutes,
      overtimeRateMinor: overtimeRateMinor,
      longShiftAlertMinutes: effectiveAlertMinutes,
    );
    TelemetryService.instance.trackEvent('shift_started', {'jobId': jobId});

    if (job != null) {
      await ShiftNotificationService.instance.requestPermission();
      ShiftNotificationService.instance.showActiveShiftNotification(
        jobName: job.name,
        startAtMs: start.millisecondsSinceEpoch,
        elapsedFormatted: '00:00:00',
        earningsFormatted: MoneyFormatter.format(0, job.currencyCode),
        isOnBreak: false,
      );
      if (effectiveAlertMinutes > 0 && financeStore.settingsRepo.settings.clockOutReminder) {
        final hours = (effectiveAlertMinutes / 60).round();
        await ShiftNotificationService.instance.scheduleLongShiftAlert(
          title: '⏰ Long Shift · ${job.name}',
          body: 'You have been clocked in for ${hours > 0 ? "$hours hours" : "$effectiveAlertMinutes mins"}. Remember to take a break or clock out.',
          at: start.add(Duration(minutes: effectiveAlertMinutes)),
        );
      }
    }
    return id;
  }

  Future<ShiftEarnings> endShift(int shiftId, {int breakMinutes = 0, DateTime? endAt}) async {
    final endTime = endAt ?? DateTime.now();
    if (_activeBreakId != null) {
      await shiftRepo.endBreak(_activeBreakId!, endTime);
      _activeBreakId = null;
    }
    await shiftRepo.finish(shiftId, breakMinutes: breakMinutes, endAt: endTime);

    final shift = shifts.firstWhere((s) => s.id == shiftId, orElse: () => shifts.first);
    final job = jobsById[shift.jobId] ?? jobs.first;
    final completedShift = Shift(
      id: shift.id,
      jobId: shift.jobId,
      startAt: shift.startAt,
      endAt: endTime.millisecondsSinceEpoch,
      breakMinutes: breakMinutes,
      status: ShiftStatus.completed.value,
      note: shift.note,
      rateOverrideMinor: shift.rateOverrideMinor,
      overtimeThresholdMinutes: shift.overtimeThresholdMinutes,
      overtimeRateMinor: shift.overtimeRateMinor,
      longShiftAlertMinutes: shift.longShiftAlertMinutes,
      createdAt: shift.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final earnings = ShiftEarnings.forShift(completedShift, job);
    _isOnBreak = false;
    _breakStartTime = null;
    _accumulatedBreakSeconds = 0;
    ShiftNotificationService.instance.cancelShiftNotification();
    ShiftNotificationService.instance.cancelLongShiftAlert();

    TelemetryService.instance.trackEvent('shift_ended', {
      'jobId': shift.jobId,
      'workedMinutes': earnings.workedMinutes,
      'earningsMinor': earnings.earningsMinor,
    });
    return earnings;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
