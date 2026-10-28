import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';

enum OvertimePricingType { multiplier, fixedRate }

class ShiftRateConfig {
  const ShiftRateConfig({
    required this.isCustom,
    required this.customHourlyRate,
    this.hasOvertime = false,
    this.overtimeThresholdHours = 8.0,
    this.overtimeType = OvertimePricingType.multiplier,
    this.overtimeMultiplier = 1.5,
    this.overtimeFixedRate = 0.0,
  });

  final bool isCustom;
  final double customHourlyRate;
  final bool hasOvertime;
  final double overtimeThresholdHours;
  final OvertimePricingType overtimeType;
  final double overtimeMultiplier;
  final double overtimeFixedRate;

  double get effectiveOvertimeHourlyRate =>
      overtimeType == OvertimePricingType.fixedRate && overtimeFixedRate > 0
          ? overtimeFixedRate
          : (customHourlyRate * overtimeMultiplier);

  int calculateEffectiveHourlyRateMinor({
    required int baseHourlyRateMinor,
    double durationHours = 8.0,
  }) {
    if (!isCustom) return baseHourlyRateMinor;
    if (!hasOvertime || durationHours <= overtimeThresholdHours || durationHours <= 0) {
      return (customHourlyRate * 100).round();
    }

    final regularHours = overtimeThresholdHours;
    final otHours = durationHours - regularHours;
    final otRate = effectiveOvertimeHourlyRate;
    final totalPay = (regularHours * customHourlyRate) + (otHours * otRate);
    final effectiveRate = totalPay / durationHours;
    return (effectiveRate * 100).round();
  }

  int? getRateOverrideMinor({
    required int baseHourlyRateMinor,
    double durationHours = 8.0,
  }) {
    if (!isCustom) return null;
    return calculateEffectiveHourlyRateMinor(
      baseHourlyRateMinor: baseHourlyRateMinor,
      durationHours: durationHours,
    );
  }
}

class ShiftRateSliderProtocol extends StatefulWidget {
  const ShiftRateSliderProtocol({
    super.key,
    required this.baseHourlyRateMinor,
    required this.currencyCode,
    this.shiftDurationHours,
    required this.onChanged,
    this.initialConfig,
  });

  final int baseHourlyRateMinor;
  final String currencyCode;
  final double? shiftDurationHours;
  final ValueChanged<ShiftRateConfig> onChanged;
  final ShiftRateConfig? initialConfig;

  @override
  State<ShiftRateSliderProtocol> createState() => _ShiftRateSliderProtocolState();
}

class _ShiftRateSliderProtocolState extends State<ShiftRateSliderProtocol> {
  late bool _isCustom;
  late double _customHourlyRate;
  late bool _hasOvertime;
  late double _overtimeThreshold;
  late OvertimePricingType _overtimeType;
  late double _overtimeMultiplier;
  late double _overtimeFixedRate;

  double get _baseRateDouble => widget.baseHourlyRateMinor / 100.0;

  @override
  void initState() {
    super.initState();
    _isCustom = widget.initialConfig?.isCustom ?? false;
    _customHourlyRate = widget.initialConfig?.customHourlyRate ?? _baseRateDouble;
    _hasOvertime = widget.initialConfig?.hasOvertime ?? false;
    _overtimeThreshold = widget.initialConfig?.overtimeThresholdHours ?? 8.0;
    _overtimeType = widget.initialConfig?.overtimeType ?? OvertimePricingType.multiplier;
    _overtimeMultiplier = widget.initialConfig?.overtimeMultiplier ?? 1.5;
    _overtimeFixedRate = widget.initialConfig?.overtimeFixedRate ?? (_customHourlyRate * 1.5);
  }

  @override
  void didUpdateWidget(covariant ShiftRateSliderProtocol oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.baseHourlyRateMinor != widget.baseHourlyRateMinor && !_isCustom) {
      _customHourlyRate = _baseRateDouble;
      _overtimeFixedRate = _baseRateDouble * _overtimeMultiplier;
    }
  }

  void _notify() {
    widget.onChanged(
      ShiftRateConfig(
        isCustom: _isCustom,
        customHourlyRate: _customHourlyRate,
        hasOvertime: _hasOvertime,
        overtimeThresholdHours: _overtimeThreshold,
        overtimeType: _overtimeType,
        overtimeMultiplier: _overtimeMultiplier,
        overtimeFixedRate: _overtimeFixedRate,
      ),
    );
  }

  void _setMultiplier(double multiplier) {
    setState(() {
      _isCustom = true;
      _customHourlyRate = (_baseRateDouble * multiplier);
      _overtimeFixedRate = _customHourlyRate * _overtimeMultiplier;
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tr = context.strings;

    final minRate = math.max(5.0, (_baseRateDouble * 0.4).floorToDouble());
    final maxRate = math.max(120.0, (_baseRateDouble * 3.0).ceilToDouble());
    final currentSliderVal = _customHourlyRate.clamp(minRate, maxRate);

    final otMinFixed = minRate;
    final otMaxFixed = math.max(150.0, (_customHourlyRate * 3.5).ceilToDouble());
    final currentOtFixedVal = _overtimeFixedRate.clamp(otMinFixed, otMaxFixed);

    final duration = widget.shiftDurationHours ?? 8.0;
    final config = ShiftRateConfig(
      isCustom: _isCustom,
      customHourlyRate: _customHourlyRate,
      hasOvertime: _hasOvertime,
      overtimeThresholdHours: _overtimeThreshold,
      overtimeType: _overtimeType,
      overtimeMultiplier: _overtimeMultiplier,
      overtimeFixedRate: _overtimeFixedRate,
    );
    final effectiveRateMinor = config.calculateEffectiveHourlyRateMinor(
      baseHourlyRateMinor: widget.baseHourlyRateMinor,
      durationHours: duration,
    );
    final effectiveOtRate = config.effectiveOvertimeHourlyRate;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _isCustom ? scheme.primary.withValues(alpha: 0.5) : scheme.outlineVariant,
          width: _isCustom ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_isCustom ? scheme.primary : scheme.outlineVariant).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSlidersHorizontal,
                  size: 20,
                  color: _isCustom ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.shiftHourlyRatePricing,
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _isCustom ? tr.customRateActive : tr.standardJobRateActive,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isCustom,
                onChanged: (val) {
                  setState(() {
                    _isCustom = val;
                    if (!val) {
                      _customHourlyRate = _baseRateDouble;
                      _hasOvertime = false;
                    }
                  });
                  _notify();
                },
              ),
            ],
          ),

          if (_isCustom) ...[
            const Divider(height: AppSpace.lg),

            // Quick preset chips
            Text(
              tr.quickRatePreset,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpace.xs),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                _PresetChip(
                  label: '1.0x ${tr.t("Base", ne: "आधार", es: "Base", fr: "Base", de: "Basis", ja: "基本", zh: "基础", it: "Base")}',
                  isSelected: (_customHourlyRate - _baseRateDouble).abs() < 0.05,
                  onTap: () => _setMultiplier(1.0),
                ),
                _PresetChip(
                  label: '1.25x ${tr.t("Night", ne: "रात्रि", es: "Noche", fr: "Nuit", de: "Nacht", ja: "夜間", zh: "夜班", it: "Notturno")}',
                  isSelected: (_customHourlyRate - (_baseRateDouble * 1.25)).abs() < 0.05,
                  onTap: () => _setMultiplier(1.25),
                ),
                _PresetChip(
                  label: '1.5x ${tr.t("Overtime", ne: "ओभरटाइम", es: "Horas extras", fr: "Heures sup", de: "Überstunden", ja: "残業", zh: "加班", it: "Straordinari")}',
                  isSelected: (_customHourlyRate - (_baseRateDouble * 1.5)).abs() < 0.05,
                  onTap: () => _setMultiplier(1.5),
                ),
                _PresetChip(
                  label: '2.0x ${tr.t("Holiday", ne: "बिदा", es: "Festivo", fr: "Férié", de: "Feiertag", ja: "休日", zh: "假日", it: "Festivo")}',
                  isSelected: (_customHourlyRate - (_baseRateDouble * 2.0)).abs() < 0.05,
                  onTap: () => _setMultiplier(2.0),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),

            // Base hourly rate slider protocol
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr.baseRate,
                  style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${MoneyFormatter.format((_customHourlyRate * 100).round(), widget.currencyCode)} / hr',
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),

            Row(
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: _customHourlyRate > minRate
                      ? () {
                          setState(() {
                            _customHourlyRate = math.max(minRate, _customHourlyRate - 1.0);
                          });
                          _notify();
                        }
                      : null,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: scheme.primary,
                      thumbColor: scheme.primary,
                      overlayColor: scheme.primary.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: currentSliderVal,
                      min: minRate,
                      max: maxRate,
                      divisions: ((maxRate - minRate) * 2).round(),
                      onChanged: (val) {
                        setState(() {
                          _customHourlyRate = val;
                        });
                        _notify();
                      },
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: _customHourlyRate < maxRate
                      ? () {
                          setState(() {
                            _customHourlyRate = math.min(maxRate, _customHourlyRate + 1.0);
                          });
                          _notify();
                        }
                      : null,
                ),
              ],
            ),

            const SizedBox(height: AppSpace.sm),

            // Overtime manipulation protocol
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedTime04,
                        size: 16,
                        color: _hasOvertime ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          tr.applyOvertimePricing,
                          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: _hasOvertime,
                        onChanged: (val) {
                          setState(() => _hasOvertime = val);
                          _notify();
                        },
                      ),
                    ],
                  ),

                  if (_hasOvertime) ...[
                    const SizedBox(height: AppSpace.xs),

                    // Overtime Mode Selector: Multiplier vs Fixed Rate
                    Row(
                      children: [
                        Expanded(
                          child: _PricingTypePill(
                            label: tr.overtimeMultiplierLabel,
                            isSelected: _overtimeType == OvertimePricingType.multiplier,
                            onTap: () {
                              setState(() => _overtimeType = OvertimePricingType.multiplier);
                              _notify();
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: _PricingTypePill(
                            label: tr.fixedRateWithCurrency(widget.currencyCode),
                            isSelected: _overtimeType == OvertimePricingType.fixedRate,
                            onTap: () {
                              setState(() {
                                _overtimeType = OvertimePricingType.fixedRate;
                                if (_overtimeFixedRate <= 0) {
                                  _overtimeFixedRate = (_customHourlyRate * 1.5);
                                }
                              });
                              _notify();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),

                    // Threshold slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr.overtimeBeginsAfter,
                          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        Text(
                          '${_overtimeThreshold.toStringAsFixed(1)} ${tr.hoursUnit}',
                          style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Slider(
                      value: _overtimeThreshold.clamp(2.0, 12.0),
                      min: 2.0,
                      max: 12.0,
                      divisions: 20, // 0.5h step
                      onChanged: (val) {
                        setState(() => _overtimeThreshold = val);
                        _notify();
                      },
                    ),

                    if (_overtimeType == OvertimePricingType.multiplier) ...[
                      // Multiplier slider & presets
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr.overtimeMultiplier,
                            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          Text(
                            '${_overtimeMultiplier.toStringAsFixed(2)}x (${MoneyFormatter.format((_customHourlyRate * _overtimeMultiplier * 100).round(), widget.currencyCode)}/hr)',
                            style: text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _overtimeMultiplier.clamp(1.1, 3.0),
                        min: 1.1,
                        max: 3.0,
                        divisions: 19, // 0.1 step
                        onChanged: (val) {
                          setState(() => _overtimeMultiplier = val);
                          _notify();
                        },
                      ),
                    ] else ...[
                      // Fixed hourly rate slider for overtime
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr.fixedOvertimeRate,
                            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              '${MoneyFormatter.format((_overtimeFixedRate * 100).round(), widget.currencyCode)} / hr',
                              style: text.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.remove, size: 14),
                            visualDensity: VisualDensity.compact,
                            onPressed: _overtimeFixedRate > otMinFixed
                                ? () {
                                    setState(() {
                                      _overtimeFixedRate = math.max(otMinFixed, _overtimeFixedRate - 1.0);
                                    });
                                    _notify();
                                  }
                                : null,
                          ),
                          Expanded(
                            child: Slider(
                              value: currentOtFixedVal,
                              min: otMinFixed,
                              max: otMaxFixed,
                              divisions: ((otMaxFixed - otMinFixed) * 2).round(),
                              onChanged: (val) {
                                setState(() => _overtimeFixedRate = val);
                                _notify();
                              },
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add, size: 14),
                            visualDensity: VisualDensity.compact,
                            onPressed: _overtimeFixedRate < otMaxFixed
                                ? () {
                                    setState(() {
                                      _overtimeFixedRate = math.min(otMaxFixed, _overtimeFixedRate + 1.0);
                                    });
                                    _notify();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],

                    // Rate Breakdown Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: scheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              duration > _overtimeThreshold
                                  ? '${_overtimeThreshold.toStringAsFixed(1)}h reg + ${(duration - _overtimeThreshold).toStringAsFixed(1)}h OT @ ${MoneyFormatter.format((effectiveOtRate * 100).round(), widget.currencyCode)}/h → avg ${MoneyFormatter.format(effectiveRateMinor, widget.currencyCode)}/h'
                                  : 'Regular: ${MoneyFormatter.format((_customHourlyRate * 100).round(), widget.currencyCode)}/h · OT: ${MoneyFormatter.format((effectiveOtRate * 100).round(), widget.currencyCode)}/h after ${_overtimeThreshold.toStringAsFixed(1)}h',
                              style: text.labelSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PricingTypePill extends StatelessWidget {
  const _PricingTypePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: text.labelSmall?.copyWith(
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: text.labelSmall?.copyWith(
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
