import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show AppLifecycleState, TimeOfDay, WidgetsBinding, WidgetsBindingObserver;

import 'package:finance_tracker/app/router/app_router.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/notifications/shift_notification_service.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/core/widgets/widget_sync_service.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/shared/data/repo_utils.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

class WorkViewModel extends ChangeNotifier with WidgetsBindingObserver {
  WorkViewModel({
    required this.financeStore,
    required this.jobRepo,
    required this.shiftRepo,
  }) {
    financeStore.addListener(_onStoreChanged);
    if (!_isTestEnvironment) {
      WidgetsBinding.instance.addObserver(this);
    }
    _initNotifications();
    _startTimer();
    unawaited(_hydrateActiveShiftBreaks());
  }

  final FinanceStore financeStore;
  final JobRepository jobRepo;
  final ShiftRepository shiftRepo;

  /// Lightweight 1-second ticker notifier for live shift counters so full pages
  /// (HomeScreen, WorkScreen) don't rebuild their entire trees every second.
  final ValueNotifier<int> liveTick = ValueNotifier<int>(0);

  Timer? _ticker;
  int? _selectedJobId;
  int? get selectedJobId => _selectedJobId;

  bool _isOnBreak = false;
  bool get isOnBreak => _isOnBreak;
  DateTime? _breakStartTime;
  int _accumulatedBreakSeconds = 0;
  int? _activeBreakId;
  int? _hydratedShiftId;
  DateTime? _lastWidgetPushAt;
  String? _lastWidgetStateKey;

  Future<List<ShiftBreak>> breaksForShift(int shiftId) => shiftRepo.breaksFor(shiftId);

  int get currentBreakSeconds {
    var totalSec = _accumulatedBreakSeconds;
    if (_isOnBreak && _breakStartTime != null) {
      totalSec += DateTime.now().difference(_breakStartTime!).inSeconds;
    }
    return totalSec < 0 ? 0 : totalSec;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || state == AppLifecycleState.paused) {
      syncWidgetNow(force: true);
    }
  }

  /// Restores accumulated & currently-open breaks from Drift so break state
  /// survives app termination / cold restarts.
  Future<void> _hydrateActiveShiftBreaks() async {
    final shift = activeShift;
    if (shift == null) {
      _hydratedShiftId = null;
      return;
    }
    if (_hydratedShiftId == shift.id) return;
    _hydratedShiftId = shift.id;

    try {
      final breaks = await shiftRepo.breaksFor(shift.id);
      if (activeShift?.id != shift.id) return;

      var closedSec = 0;
      DateTime? openStart;
      int? openId;

      for (final b in breaks) {
        if (b.endAt != null) {
          final diff = ((b.endAt! - b.startAt) / 1000).floor();
          if (diff > 0) closedSec += diff;
        } else {
          openStart = DateTime.fromMillisecondsSinceEpoch(b.startAt);
          openId = b.id;
        }
      }

      _accumulatedBreakSeconds = closedSec;
      _isOnBreak = openStart != null;
      _breakStartTime = openStart;
      _activeBreakId = openId;

      _syncNotificationAndWidget(forceWidget: true);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WorkViewModel] Error hydrating active shift breaks: $e');
      }
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
        final delta = now.difference(_breakStartTime!).inSeconds;
        if (delta > 0) _accumulatedBreakSeconds += delta;
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
    _syncNotificationAndWidget(forceWidget: true);
    liveTick.value++;
    notifyListeners();
  }

  /// Explicitly triggers a native home widget sync (e.g., on startup or app resume).
  void syncWidgetNow({bool force = false}) {
    _syncNotificationAndWidget(forceWidget: force);
  }

  void _syncNotificationAndWidget({bool forceWidget = false}) {
    final shift = activeShift;
    if (shift == null) {
      ShiftNotificationService.instance.cancelShiftNotification();
      if (!_isTestEnvironment) {
        final fallbackJob = selectedJob;
        final rateLabel = fallbackJob != null
            ? '${MoneyFormatter.format(fallbackJob.hourlyRateMinor, fallbackJob.currencyCode)}/${AppStrings.current().hourAbbr}'
            : '';
        final idleKey = 'idle|${fallbackJob?.name ?? ''}|$rateLabel';
        if (forceWidget || _lastWidgetStateKey != idleKey) {
          _lastWidgetStateKey = idleKey;
          _lastWidgetPushAt = DateTime.now();
          unawaited(
            WidgetSyncService.clearShift(
              defaultJobName: fallbackJob?.name,
              defaultRateLabel: rateLabel,
            ),
          );
        }
      }
      return;
    }

    final job = jobsById[shift.jobId];
    if (job == null) {
      // Jobs stream has not emitted yet; do NOT wipe widget with clearShift.
      return;
    }

    final tr = AppStrings.current();
    final worked = activeShiftWorkedDuration;
    final h = worked.inHours.toString().padLeft(2, '0');
    final m = (worked.inMinutes % 60).toString().padLeft(2, '0');
    final s = (worked.inSeconds % 60).toString().padLeft(2, '0');
    final earnings = activeShiftLiveEarnings;
    final earningsStr = earnings != null
        ? MoneyFormatter.format(earnings.earningsMinor, job.currencyCode)
        : MoneyFormatter.format(0, job.currencyCode);
    final rateMinor = shift.rateOverrideMinor ?? job.hourlyRateMinor;
    final rateLabel = '${MoneyFormatter.format(rateMinor, job.currencyCode)}/${tr.hourAbbr}';
    final effectiveStartMs = shift.startAt + (currentBreakSeconds * 1000);

    ShiftNotificationService.instance.showActiveShiftNotification(
      jobName: job.name,
      startAtMs: effectiveStartMs,
      elapsedFormatted: '$h:$m:$s',
      earningsFormatted: earningsStr,
      isOnBreak: _isOnBreak,
      breakMinutes: currentBreakMinutes,
    );

    if (!_isTestEnvironment) {
      final stateKey =
          'active|${shift.id}|${job.name}|$_isOnBreak|$effectiveStartMs|$rateMinor|${shift.overtimeThresholdMinutes ?? 0}|${shift.overtimeRateMinor ?? 0}';
      final now = DateTime.now();
      final elapsedSincePush = _lastWidgetPushAt == null
          ? const Duration(hours: 1)
          : now.difference(_lastWidgetPushAt!);

      // Push immediately on state changes, and at most once per 60s while working
      // (native Android Chronometer & iOS Text(date, style: .timer) tick every second!).
      if (forceWidget || stateKey != _lastWidgetStateKey || elapsedSincePush >= const Duration(seconds: 60)) {
        _lastWidgetStateKey = stateKey;
        _lastWidgetPushAt = now;
        final subtitle = _isOnBreak
            ? '${tr.takeBreak} · $earningsStr'
            : '$h:$m:$s · $earningsStr';
        unawaited(
          WidgetSyncService.updateShift(
            shiftId: shift.id,
            jobName: job.name,
            subtitle: subtitle,
            isOnBreak: _isOnBreak,
            startAtMs: shift.startAt,
            effectiveStartMs: effectiveStartMs,
            workedSeconds: worked.inSeconds,
            breakMinutes: currentBreakMinutes,
            rateMinor: rateMinor,
            overtimeThresholdMinutes: shift.overtimeThresholdMinutes ?? 0,
            overtimeRateMinor: shift.overtimeRateMinor ?? 0,
            currencyCode: job.currencyCode,
            currencySymbol: MoneyFormatter.symbolFor(job.currencyCode),
            rateLabel: rateLabel,
            earningsLabel: earningsStr,
          ),
        );
      }
    }
  }

  void _onStoreChanged() {
    _invalidateDerivedCaches();
    final shift = activeShift;
    if (shift != null && _hydratedShiftId != shift.id) {
      unawaited(_hydrateActiveShiftBreaks());
    } else if (shift == null) {
      _hydratedShiftId = null;
    }
    _syncNotificationAndWidget();
    notifyListeners();
  }

  void _startTimer() {
    if (_isTestEnvironment) {
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (activeShift != null) {
        if (!_isOnBreak) {
          if (defaultTargetPlatform == TargetPlatform.android) {
            _syncNotificationAndWidget();
          } else {
            // On iOS, still allow throttled (60s) widget snapshot refresh while foregrounded
            final last = _lastWidgetPushAt;
            if (last == null || DateTime.now().difference(last) >= const Duration(seconds: 60)) {
              _syncNotificationAndWidget();
            }
          }
        }
        // Tick only lightweight live-counter listeners instead of rebuilding full tabs!
        liveTick.value++;
      }
    });
  }

  bool get isClockedIn => activeShift != null;

  List<Job> get jobs => financeStore.jobs;
  List<Shift> get shifts => financeStore.shifts;
  String get baseCurrency => financeStore.baseCurrency;

  // Derived caches invalidated on snapshot change, filter change, or day rollover.
  Object? _cachedSnapshotRef;
  Map<int, Job>? _jobsByIdCache;
  Shift? _activeShiftCache;
  bool _activeShiftCached = false;
  int? _todayStatsDayKey;
  List<Shift> _todayAllShiftsCache = const [];
  int _todayCompletedCountCache = 0;
  int _todayScheduledCountCache = 0;
  List<Shift>? _todayFilteredShiftsCache;
  double? _hoursThisWeekCache;
  int? _shiftsLeftThisWeekCache;

  void _invalidateDerivedCaches() {
    _cachedSnapshotRef = null;
    _jobsByIdCache = null;
    _activeShiftCached = false;
    _activeShiftCache = null;
    _todayStatsDayKey = null;
    _todayAllShiftsCache = const [];
    _todayFilteredShiftsCache = null;
    _hoursThisWeekCache = null;
    _shiftsLeftThisWeekCache = null;
  }

  void _ensureSnapshotFresh() {
    final snap = financeStore.snapshot;
    if (!identical(_cachedSnapshotRef, snap)) {
      _invalidateDerivedCaches();
      _cachedSnapshotRef = snap;
    }
  }

  void _ensureTodayAndWeekStats() {
    _ensureSnapshotFresh();
    final now = DateTime.now();
    final dayKey = now.year * 10000 + now.month * 100 + now.day;
    if (_todayStatsDayKey == dayKey) return;

    final todayMidnight = DateTime(now.year, now.month, now.day);
    final todayStartMs = todayMidnight.millisecondsSinceEpoch;
    final todayEndMs = todayMidnight.add(const Duration(days: 1)).millisecondsSinceEpoch;
    final weekStartMs =
        todayMidnight.subtract(Duration(days: now.weekday - 1)).millisecondsSinceEpoch;
    final weekEndExclusiveMs =
        todayMidnight.add(Duration(days: 8 - now.weekday)).millisecondsSinceEpoch;
    final nowMsVal = now.millisecondsSinceEpoch;
    final jById = jobsById;

    final todayAll = <Shift>[];
    var todayCompleted = 0;
    var todayScheduled = 0;
    var weekWorkedMin = 0;
    var shiftsLeft = 0;

    for (final s in shifts) {
      final startMs = s.startAt;
      if (startMs >= todayStartMs && startMs < todayEndMs) {
        todayAll.add(s);
        if (s.status == ShiftStatus.completed.value) {
          todayCompleted++;
        } else if (s.status == ShiftStatus.scheduled.value) {
          todayScheduled++;
        }
      }
      if (s.status == ShiftStatus.completed.value &&
          s.endAt != null &&
          startMs >= weekStartMs) {
        final job = jById[s.jobId];
        if (job != null) {
          weekWorkedMin += ShiftEarnings.forShift(s, job).workedMinutes;
        }
      } else if (s.status == ShiftStatus.scheduled.value &&
          startMs > nowMsVal &&
          startMs < weekEndExclusiveMs) {
        shiftsLeft++;
      }
    }

    todayAll.sort((a, b) => a.startAt.compareTo(b.startAt));
    _todayStatsDayKey = dayKey;
    _todayAllShiftsCache = todayAll;
    _todayCompletedCountCache = todayCompleted;
    _todayScheduledCountCache = todayScheduled;
    _todayFilteredShiftsCache = null;
    _hoursThisWeekCache = weekWorkedMin / 60.0;
    _shiftsLeftThisWeekCache = shiftsLeft;
  }

  Map<int, Job> get jobsById {
    _ensureSnapshotFresh();
    return _jobsByIdCache ??= {for (final j in jobs) j.id: j};
  }

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
    if (!isClockedIn) {
      _syncNotificationAndWidget(forceWidget: true);
    }
    notifyListeners();
  }

  void setFilterJobId(int? id) {
    _filterJobId = id;
    _todayFilteredShiftsCache = null;
    notifyListeners();
  }

  void setFilterStatus(String? status) {
    _filterStatus = status;
    _todayFilteredShiftsCache = null;
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
    _ensureTodayAndWeekStats();
    if (_todayFilteredShiftsCache != null) return _todayFilteredShiftsCache!;
    if (_filterJobId == null && _filterStatus == null) {
      return _todayFilteredShiftsCache = _todayAllShiftsCache;
    }
    return _todayFilteredShiftsCache = _todayAllShiftsCache
        .where((s) {
          if (_filterJobId != null && s.jobId != _filterJobId) return false;
          if (_filterStatus != null && s.status != _filterStatus) return false;
          return true;
        })
        .toList(growable: false);
  }

  int get todayTotalCount {
    _ensureTodayAndWeekStats();
    return _todayAllShiftsCache.length;
  }

  int get todayCompletedCount {
    _ensureTodayAndWeekStats();
    return _todayCompletedCountCache;
  }

  int get todayScheduledCount {
    _ensureTodayAndWeekStats();
    return _todayScheduledCountCache;
  }

  Shift? get activeShift {
    _ensureSnapshotFresh();
    if (_activeShiftCached) return _activeShiftCache;
    Shift? found;
    for (final s in shifts) {
      if (s.status == ShiftStatus.inProgress.value) {
        found = s;
        break;
      }
    }
    _activeShiftCache = found;
    _activeShiftCached = true;
    return found;
  }

  Duration get activeShiftTotalClockDuration {
    final shift = activeShift;
    if (shift == null) return Duration.zero;
    final start = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
    final diff = DateTime.now().difference(start);
    return diff.isNegative ? Duration.zero : diff;
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
    _ensureTodayAndWeekStats();
    return _hoursThisWeekCache ?? 0.0;
  }

  int get shiftsLeftThisWeek {
    _ensureTodayAndWeekStats();
    return _shiftsLeftThisWeekCache ?? 0;
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
      // Historical rate retention in one SQL UPDATE instead of N per-shift writes.
      await shiftRepo.setRateOverrideForJobShifts(
        jobId: id,
        rateOverrideMinor: existingJob.hourlyRateMinor,
      );
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
    ShiftStatus status = ShiftStatus.scheduled,
  }) async {
    final id = await shiftRepo.add(
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
    TelemetryService.instance.trackEvent('shift_scheduled', {'jobId': jobId});

    final job = jobsById[jobId];
    if (status == ShiftStatus.scheduled &&
        job != null &&
        financeStore.settingsRepo.settings.shiftReminders) {
      unawaited(
        ShiftNotificationService.instance.scheduleShiftReminder(
          shiftId: id,
          jobName: job.name,
          startAt: startAt,
        ),
      );
    }

    return id;
  }

  /// Inserts a batch of specific-date shifts inside a single SQLite transaction
  /// so Drift emits once and notification sync runs once (debounced).
  Future<List<int>> scheduleManyShifts({
    required int jobId,
    required Iterable<({DateTime startAt, DateTime? endAt})> slots,
    int breakMinutes = 0,
    String? note,
    int? rateOverrideMinor,
    int? overtimeThresholdMinutes,
    int? overtimeRateMinor,
    int? longShiftAlertMinutes,
    ShiftStatus status = ShiftStatus.scheduled,
  }) async {
    final normalizedNote = normalizeText(note);
    final ts = nowMs();
    final companions = <ShiftsCompanion>[
      for (final slot in slots)
        ShiftsCompanion.insert(
          jobId: jobId,
          startAt: slot.startAt.millisecondsSinceEpoch,
          endAt: Value(slot.endAt?.millisecondsSinceEpoch),
          breakMinutes: Value(breakMinutes),
          status: status.value,
          note: Value(normalizedNote),
          rateOverrideMinor: Value(rateOverrideMinor),
          overtimeThresholdMinutes: Value(overtimeThresholdMinutes),
          overtimeRateMinor: Value(overtimeRateMinor),
          longShiftAlertMinutes: Value(longShiftAlertMinutes),
          createdAt: ts,
          updatedAt: ts,
        ),
    ];
    if (companions.isEmpty) return const [];
    final createdIds = await shiftRepo.addMany(companions);
    TelemetryService.instance.trackEvent('shift_scheduled_batch', {
      'jobId': jobId,
      'count': createdIds.length,
    });
    return createdIds;
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
    if (activeShift?.id == id) {
      _syncNotificationAndWidget(forceWidget: true);
    }
    TelemetryService.instance.trackEvent('shift_updated', {'id': id});
  }

  Future<void> deleteShift(int id) async {
    final wasActive = activeShift?.id == id;
    await shiftRepo.delete(id);
    if (wasActive) {
      _isOnBreak = false;
      _breakStartTime = null;
      _accumulatedBreakSeconds = 0;
      _activeBreakId = null;
      _hydratedShiftId = null;
      _syncNotificationAndWidget(forceWidget: true);
    }
    TelemetryService.instance.trackEvent('shift_deleted', {'id': id});
  }

  Future<void> deleteShifts(List<int> ids) async {
    if (ids.isEmpty) return;
    final activeId = activeShift?.id;
    final wasActive = activeId != null && ids.contains(activeId);
    await shiftRepo.deleteMany(ids);
    if (wasActive) {
      _isOnBreak = false;
      _breakStartTime = null;
      _accumulatedBreakSeconds = 0;
      _activeBreakId = null;
      _hydratedShiftId = null;
      _syncNotificationAndWidget(forceWidget: true);
    }
    TelemetryService.instance.trackEvent('shift_deleted_batch', {'count': ids.length});
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

    // Pre-index existing shift dates for this job in O(N) so duplicate checks are O(1).
    final existingDayKeys = <int>{};
    for (final s in shifts) {
      if (s.jobId != jobId) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(s.startAt);
      existingDayKeys.add(d.year * 10000 + d.month * 100 + d.day);
    }

    final isNextDay = (endTime.hour < startTime.hour) ||
        (endTime.hour == startTime.hour && endTime.minute <= startTime.minute);
    final slots = <({DateTime startAt, DateTime? endAt})>[];

    for (var i = 0; i < totalDays; i++) {
      final date = today.add(Duration(days: i));
      if (!weekdays.contains(date.weekday)) continue;
      final dayKey = date.year * 10000 + date.month * 100 + date.day;
      if (!existingDayKeys.add(dayKey)) continue;

      final startAt = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
      final endBaseDate = isNextDay ? date.add(const Duration(days: 1)) : date;
      final endAt = DateTime(
        endBaseDate.year,
        endBaseDate.month,
        endBaseDate.day,
        endTime.hour,
        endTime.minute,
      );
      slots.add((startAt: startAt, endAt: endAt));
    }

    return scheduleManyShifts(
      jobId: jobId,
      slots: slots,
      breakMinutes: breakMinutes,
      note: note,
      rateOverrideMinor: rateOverrideMinor,
      overtimeThresholdMinutes: overtimeThresholdMinutes,
      overtimeRateMinor: overtimeRateMinor,
      longShiftAlertMinutes: longShiftAlertMinutes,
    );
  }

  /// Transitions an existing scheduled shift to `in_progress` in-place
  /// (avoiding duplicate shifts and preserving rate overrides & overtime rules).
  Future<int> startScheduledShift(Shift scheduled) async {
    final existing = activeShift ?? await shiftRepo.findActiveShift();
    if (existing != null) {
      return existing.id;
    }

    _isOnBreak = false;
    _breakStartTime = null;
    _accumulatedBreakSeconds = 0;
    _activeBreakId = null;
    _hydratedShiftId = scheduled.id;

    final now = DateTime.now();
    await shiftRepo.update(
      scheduled.id,
      startAt: now,
      status: ShiftStatus.inProgress,
    );

    final job = jobsById[scheduled.jobId];
    final effectiveAlertMinutes = scheduled.longShiftAlertMinutes ?? job?.longShiftAlertMinutes ?? 360;
    await _activateShiftSideEffects(
      shiftId: scheduled.id,
      job: job,
      start: now,
      rateOverrideMinor: scheduled.rateOverrideMinor,
      overtimeThresholdMinutes: scheduled.overtimeThresholdMinutes,
      overtimeRateMinor: scheduled.overtimeRateMinor,
      effectiveAlertMinutes: effectiveAlertMinutes,
    );
    TelemetryService.instance.trackEvent('shift_started', {'jobId': scheduled.jobId, 'from_scheduled': true});
    return scheduled.id;
  }

  Future<int> startShift({
    required int jobId,
    DateTime? startAt,
    int? rateOverrideMinor,
    int? overtimeThresholdMinutes,
    int? overtimeRateMinor,
    int? longShiftAlertMinutes,
  }) async {
    // Guard against creating concurrent in-progress shifts (checked atomically against SQLite)
    final existing = activeShift ?? await shiftRepo.findActiveShift();
    if (existing != null) {
      return existing.id;
    }

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
    _hydratedShiftId = id;
    TelemetryService.instance.trackEvent('shift_started', {'jobId': jobId});

    await _activateShiftSideEffects(
      shiftId: id,
      job: job,
      start: start,
      rateOverrideMinor: rateOverrideMinor,
      overtimeThresholdMinutes: overtimeThresholdMinutes,
      overtimeRateMinor: overtimeRateMinor,
      effectiveAlertMinutes: effectiveAlertMinutes,
    );
    return id;
  }

  Future<void> _activateShiftSideEffects({
    required int shiftId,
    required Job? job,
    required DateTime start,
    required int? rateOverrideMinor,
    required int? overtimeThresholdMinutes,
    required int? overtimeRateMinor,
    required int effectiveAlertMinutes,
  }) async {
    if (job == null) return;
    final tr = AppStrings.current();
    final effectiveRate = rateOverrideMinor ?? job.hourlyRateMinor;
    final rateLabel = '${MoneyFormatter.format(effectiveRate, job.currencyCode)}/${tr.hourAbbr}';
    final initialEarnings = MoneyFormatter.format(0, job.currencyCode);

    await ShiftNotificationService.instance.requestPermission();
    ShiftNotificationService.instance.showActiveShiftNotification(
      jobName: job.name,
      startAtMs: start.millisecondsSinceEpoch,
      elapsedFormatted: '00:00:00',
      earningsFormatted: initialEarnings,
      isOnBreak: false,
      force: true,
    );

    if (!_isTestEnvironment) {
      _lastWidgetStateKey =
          'active|$shiftId|${job.name}|false|${start.millisecondsSinceEpoch}|$effectiveRate|${overtimeThresholdMinutes ?? 0}|${overtimeRateMinor ?? 0}';
      _lastWidgetPushAt = DateTime.now();
      unawaited(
        WidgetSyncService.updateShift(
          shiftId: shiftId,
          jobName: job.name,
          subtitle: '00:00:00 · $initialEarnings',
          isOnBreak: false,
          startAtMs: start.millisecondsSinceEpoch,
          effectiveStartMs: start.millisecondsSinceEpoch,
          workedSeconds: 0,
          breakMinutes: 0,
          rateMinor: effectiveRate,
          overtimeThresholdMinutes: overtimeThresholdMinutes ?? 0,
          overtimeRateMinor: overtimeRateMinor ?? 0,
          currencyCode: job.currencyCode,
          currencySymbol: MoneyFormatter.symbolFor(job.currencyCode),
          rateLabel: rateLabel,
          earningsLabel: initialEarnings,
        ),
      );
    }

    if (effectiveAlertMinutes > 0 && financeStore.settingsRepo.settings.clockOutReminder) {
      final hours = (effectiveAlertMinutes / 60).round();
      await ShiftNotificationService.instance.scheduleLongShiftAlert(
        title: '${tr.longShiftNotificationLabel} · ${job.name}',
        body: tr.t(
          'You have been clocked in for ${hours > 0 ? "$hours hours" : "$effectiveAlertMinutes mins"}. Remember to take a break or clock out.',
          ne: 'तपाईं ${hours > 0 ? "$hours घण्टा" : "$effectiveAlertMinutes मिनेट"} देखि काममा हुनुहुन्छ। विश्राम लिन वा सिफ्ट समाप्त गर्न नबिर्सनुहोस्।',
          hi: 'आप ${hours > 0 ? "$hours घंटे" : "$effectiveAlertMinutes मिनट"} से शिफ्ट में हैं। ब्रेक लेना या क्लॉक आउट करना न भूलें।',
        ),
        at: start.add(Duration(minutes: effectiveAlertMinutes)),
      );
    }
  }

  Future<ShiftEarnings> endShift(int shiftId, {int breakMinutes = 0, DateTime? endAt}) async {
    final endTime = endAt ?? DateTime.now();
    if (_activeBreakId != null) {
      await shiftRepo.endBreak(_activeBreakId!, endTime);
      _activeBreakId = null;
    }
    await shiftRepo.finish(shiftId, breakMinutes: breakMinutes, endAt: endTime);

    final shift = shifts.where((s) => s.id == shiftId).firstOrNull ?? shifts.firstOrNull;
    final job = shift != null ? (jobsById[shift.jobId] ?? jobs.firstOrNull) : jobs.firstOrNull;

    final ShiftEarnings earnings;
    if (shift != null && job != null) {
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
      earnings = ShiftEarnings.forShift(completedShift, job);
    } else {
      earnings = ShiftEarnings.compute(workedSeconds: 0, rateMinor: 0);
    }

    _isOnBreak = false;
    _breakStartTime = null;
    _accumulatedBreakSeconds = 0;
    _hydratedShiftId = null;
    ShiftNotificationService.instance.cancelShiftNotification();
    ShiftNotificationService.instance.cancelLongShiftAlert();

    if (!_isTestEnvironment) {
      final fallbackJob = selectedJob;
      final rateLabel = fallbackJob != null
          ? '${MoneyFormatter.format(fallbackJob.hourlyRateMinor, fallbackJob.currencyCode)}/${AppStrings.current().hourAbbr}'
          : '';
      _lastWidgetStateKey = 'idle|${fallbackJob?.name ?? ''}|$rateLabel';
      _lastWidgetPushAt = DateTime.now();
      unawaited(
        WidgetSyncService.clearShift(
          defaultJobName: fallbackJob?.name,
          defaultRateLabel: rateLabel,
        ),
      );
    }

    if (shift != null) {
      TelemetryService.instance.trackEvent('shift_ended', {
        'jobId': shift.jobId,
        'workedMinutes': earnings.workedMinutes,
        'earningsMinor': earnings.earningsMinor,
      });
    }
    notifyListeners();
    return earnings;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (!_isTestEnvironment) {
      WidgetsBinding.instance.removeObserver(this);
    }
    financeStore.removeListener(_onStoreChanged);
    liveTick.dispose();
    super.dispose();
  }
}
