import 'package:intl/intl.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/settings/data/repository/reminder_rule_repository.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

/// One concrete notification produced from a [ReminderRule].
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    required this.payload,
    this.weekly = false,
  });

  final int id;
  final String title;
  final String body;
  final DateTime at;
  final String payload;

  /// Repeats every week on the same weekday and time.
  final bool weekly;
}

/// Turns user-defined reminder rules plus live app data into notifications.
/// Pure logic (no plugin access) so it can be unit tested.
class ReminderPlanner {
  const ReminderPlanner._();

  /// Notification ids at or above this belong to reminder rules.
  static const int idBase = 100000;
  static const int maxPlanned = 60;
  static const int defaultBillMinutes = 9 * 60;
  static const int defaultDebtMinutes = 10 * 60;

  static int notificationId(int ruleId, int slot) => idBase + (ruleId % 1000) * 1000 + (slot % 1000);

  static bool weekdayInMask(int mask, int weekday) => mask == 0 || (mask & (1 << (weekday - 1))) != 0;

  static List<PlannedReminder> plan({
    required List<ReminderRule> rules,
    required List<Shift> shifts,
    required List<Job> jobs,
    required List<RecurringRule> recurring,
    required List<Debt> debts,
    required AppStrings tr,
    required DateTime now,
    bool shiftsEnabled = true,
    bool billsEnabled = true,
  }) {
    final jobsById = {for (final j in jobs) j.id: j};
    final out = <PlannedReminder>[];

    for (final rule in rules) {
      if (!rule.isEnabled) continue;
      final offset = Duration(minutes: rule.offsetMinutes);
      var slot = 0;

      switch (ReminderType.fromValue(rule.type)) {
        case ReminderType.shift:
          if (!shiftsEnabled) continue;
          for (final shift in shifts) {
            if (shift.status != ShiftStatus.scheduled.value) continue;
            final start = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
            if (!weekdayInMask(rule.repeatDays, start.weekday)) continue;
            final at = start.subtract(offset);
            if (!at.isAfter(now)) continue;
            final jobName = jobsById[shift.jobId]?.name ?? tr.shiftLabel;
            out.add(PlannedReminder(
              id: notificationId(rule.id, slot++),
              title: tr.reminderShiftTitle(jobName),
              body: tr.reminderShiftBody(tr.reminderOffsetLabel(rule.offsetMinutes), AppDate.timeOnly(start)),
              at: at,
              payload: '/work',
            ));
          }
        case ReminderType.bill:
          if (!billsEnabled) continue;
          for (final bill in recurring) {
            if (!bill.isActive || (bill.kind != 'bill' && bill.kind != 'subscription')) continue;
            final at = _atTimeOfDay(
              DateTime.fromMillisecondsSinceEpoch(bill.nextDueAt),
              rule.timeOfDayMinutes ?? defaultBillMinutes,
            ).subtract(offset);
            if (!at.isAfter(now)) continue;
            out.add(PlannedReminder(
              id: notificationId(rule.id, slot++),
              title: tr.reminderBillTitle(bill.name),
              body: tr.reminderDueBody(
                MoneyFormatter.format(bill.amountMinor, bill.currencyCode),
                DateFormat('MMM d').format(DateTime.fromMillisecondsSinceEpoch(bill.nextDueAt)),
              ),
              at: at,
              payload: '/money',
            ));
          }
        case ReminderType.debt:
          if (!billsEnabled) continue;
          for (final debt in debts) {
            if (debt.isSettled || debt.dueDate == null) continue;
            final due = DateTime.fromMillisecondsSinceEpoch(debt.dueDate!);
            final at = _atTimeOfDay(due, rule.timeOfDayMinutes ?? defaultDebtMinutes).subtract(offset);
            if (!at.isAfter(now)) continue;
            out.add(PlannedReminder(
              id: notificationId(rule.id, slot++),
              title: tr.reminderDebtTitle(debt.personName),
              body: tr.reminderDueBody(
                MoneyFormatter.format(debt.amountMinor, debt.currencyCode),
                DateFormat('MMM d').format(due),
              ),
              at: at,
              payload: '/debts',
            ));
          }
        case ReminderType.custom:
          final minutes = rule.timeOfDayMinutes ?? defaultBillMinutes;
          final title = rule.title.isEmpty ? tr.reminderCustomDefault : rule.title;
          final today = DateTime(now.year, now.month, now.day);
          if (rule.repeatDays == 0) {
            var at = _atTimeOfDay(today, minutes);
            if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
            // DateTime + Duration can drift an hour across DST; re-anchor.
            at = _atTimeOfDay(DateTime(at.year, at.month, at.day), minutes);
            out.add(PlannedReminder(
              id: notificationId(rule.id, 0),
              title: title,
              body: tr.reminderCustomBody,
              at: at,
              payload: '/notifications',
            ));
          } else {
            for (var weekday = 1; weekday <= 7; weekday++) {
              if (!weekdayInMask(rule.repeatDays, weekday)) continue;
              for (var d = 0; d < 8; d++) {
                final day = DateTime(today.year, today.month, today.day + d);
                if (day.weekday != weekday) continue;
                final at = _atTimeOfDay(day, minutes);
                if (!at.isAfter(now)) continue;
                out.add(PlannedReminder(
                  id: notificationId(rule.id, weekday),
                  title: title,
                  body: tr.reminderCustomBody,
                  at: at,
                  payload: '/notifications',
                  weekly: true,
                ));
                break;
              }
            }
          }
      }
    }

    out.sort((a, b) {
      if (a.weekly != b.weekly) return a.weekly ? -1 : 1;
      return a.at.compareTo(b.at);
    });
    return out.length > maxPlanned ? out.sublist(0, maxPlanned) : out;
  }

  static DateTime _atTimeOfDay(DateTime day, int minutes) =>
      DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
}
