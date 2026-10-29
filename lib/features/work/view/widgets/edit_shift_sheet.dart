import 'package:flutter/material.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

void showEditShiftDialog(
  BuildContext context,
  Shift shift,
  Job? job,
  WorkViewModel viewModel,
) {
  final startDt = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
  final endDt = shift.endAt != null
      ? DateTime.fromMillisecondsSinceEpoch(shift.endAt!)
      : startDt.add(const Duration(hours: 8));

  DateTime selectedDate = DateTime(startDt.year, startDt.month, startDt.day);
  TimeOfDay startTime = TimeOfDay(hour: startDt.hour, minute: startDt.minute);
  TimeOfDay endTime = TimeOfDay(hour: endDt.hour, minute: endDt.minute);
  final breakController = TextEditingController(text: '${shift.breakMinutes}');
  final noteController = TextEditingController(text: shift.note ?? '');
  ShiftStatus selectedStatus = ShiftStatus.fromValue(shift.status);
  int selectedJobId = shift.jobId;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final text = Theme.of(ctx).textTheme;
        final tr = ctx.strings;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSpace.page,
            right: AppSpace.page,
            top: AppSpace.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr.editShift, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpace.md),

              // Job picker
              if (viewModel.jobs.length > 1) ...[
                Text(
                  tr.jobs,
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                HorizontalOptionSelector<int>(
                  height: 48,
                  selectedValue: selectedJobId,
                  onChanged: (val) => setDialogState(() => selectedJobId = val),
                  items: [
                    for (final j in viewModel.jobs)
                      HorizontalOptionItem<int>(
                        value: j.id,
                        label: j.name,
                        icon: HugeIcons.strokeRoundedBriefcase01,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
              ],

              // Date Picker tile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(tr.date),
                subtitle: Text(AppDate.weekdayDay(selectedDate)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),

              // Time range row
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: Text(tr.starts),
                      subtitle: Text(AppDate.timeOnly(DateTime(2000, 1, 1, startTime.hour, startTime.minute))),
                      onTap: () async {
                        final t = await showTimePicker(context: ctx, initialTime: startTime);
                        if (t != null) setDialogState(() => startTime = t);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time_filled),
                      title: Text(tr.ends),
                      subtitle: Text(AppDate.timeOnly(DateTime(2000, 1, 1, endTime.hour, endTime.minute))),
                      onTap: () async {
                        final t = await showTimePicker(context: ctx, initialTime: endTime);
                        if (t != null) setDialogState(() => endTime = t);
                      },
                    ),
                  ),
                ],
              ),

              // Status Selector
              Text(
                tr.status,
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              HorizontalOptionSelector<ShiftStatus>(
                height: 48,
                selectedValue: selectedStatus,
                onChanged: (val) => setDialogState(() => selectedStatus = val),
                items: [
                  HorizontalOptionItem(
                    value: ShiftStatus.scheduled,
                    label: tr.scheduled,
                    icon: HugeIcons.strokeRoundedCalendar01,
                  ),
                  HorizontalOptionItem(
                    value: ShiftStatus.completed,
                    label: tr.completed,
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  ),
                  HorizontalOptionItem(
                    value: ShiftStatus.inProgress,
                    label: tr.inProgress,
                    icon: HugeIcons.strokeRoundedPlay,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),

              // Break Minutes
              TextField(
                controller: breakController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr.breakMinutesLabel,
                  hintText: '30',
                ),
              ),
              const SizedBox(height: AppSpace.sm),

              // Note
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: tr.notesOptional,
                  hintText: tr.notesHint,
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(tr.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final newStart = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          startTime.hour,
                          startTime.minute,
                        );
                        final newEnd = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          endTime.hour,
                          endTime.minute,
                        );
                        final breakMin = int.tryParse(breakController.text.trim()) ?? 0;
                        final note = noteController.text.trim();

                        await viewModel.updateShift(
                          shift.id,
                          jobId: selectedJobId,
                          startAt: newStart,
                          endAt: newEnd,
                          breakMinutes: breakMin,
                          status: selectedStatus,
                          note: note.isEmpty ? null : note,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) showToast(context, tr.shiftUpdatedSuccess);
                      },
                      child: Text(tr.saveChanges),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
