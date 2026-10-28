import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/assistant/view/widgets/chat_widgets.dart';
import 'package:finance_tracker/features/assistant/viewmodels/assistant_view_model.dart';
import 'package:finance_tracker/features/subscription/data/subscription_service.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastCount = 0;
  late final AssistantViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<AssistantViewModel>();
    _viewModel.syncQuotaFromServer();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showLimitSheet() {
    showProUpgradeSheet(
      context,
      title: context.strings.dailyAiLimitReached,
      message: context.strings.freeAiLimitReachedMessage,
      featureHighlight: 'ai',
    );
  }

  Future<void> _send([String? query]) async {
    final text = query ?? _inputController.text;
    if (text.trim().isEmpty) return;

    final subService = getIt<SubscriptionService>();
    if (_viewModel.isLimitReached(isPro: subService.isPro)) {
      _showLimitSheet();
      return;
    }

    _inputController.clear();
    final allowed = await _viewModel.sendMessage(text, isPro: subService.isPro);
    if (!allowed && mounted) {
      _showLimitSheet();
    }
  }

  Future<void> _pickBillImage(BuildContext context) async {
    final subService = getIt<SubscriptionService>();
    if (_viewModel.isLimitReached(isPro: subService.isPro)) {
      _showLimitSheet();
      return;
    }

    final tr = context.strings;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: AppSpace.md,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpace.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const IconTile(HugeIcons.strokeRoundedCamera01),
                  title: Text(tr.takePhotoReceiptBill),
                  subtitle: Text(tr.opensCameraToScan),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const IconTile(HugeIcons.strokeRoundedImage01),
                  title: Text(tr.uploadFromLibrary),
                  subtitle: Text(tr.chooseExistingBill),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      if (_viewModel.isLimitReached(isPro: subService.isPro)) {
        if (mounted) _showLimitSheet();
        return;
      }
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        if (picked != null) {
          final allowed = await _viewModel.scanBillImage(
            picked,
            isPro: subService.isPro,
          );
          if (!allowed && mounted) {
            _showLimitSheet();
          }
        }
      } catch (e) {
        debugPrint('Error picking bill image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final tr = context.strings;
    final isPro = getIt<SubscriptionService>().isPro;

    return ListenableBuilder(
      listenable: _viewModel,
      builder:
          (context, _) => Scaffold(
            appBar: AppTopBar(
              title: tr.assistantTitle,
              subtitle:
                  _viewModel.messages.isEmpty
                      ? null
                      : (isPro ? tr.unlimitedAiPro : tr.asksBeforeChanges),
              actions: [
                if (!isPro)
                  IconButton(
                    icon: const ProCrownBadge(isCompact: true),
                    tooltip: tr.upgradeToPro,
                    onPressed:
                        () => showProUpgradeSheet(
                          context,
                          title: tr.unlimitedAiAssistantTitle,
                          message: tr.unlimitedAiAssistantDesc,
                          featureHighlight: 'ai',
                        ),
                  ),
                TopBarAction(
                  HugeIcons.strokeRoundedRefresh,
                  onPressed: _viewModel.clear,
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _viewModel,
                      builder: (context, _) {
                        if (_viewModel.messages.isEmpty) {
                          return ListView(
                            padding: const EdgeInsets.all(AppSpace.page),
                            children: [
                              Text(
                                tr.whatCanIDoForYou,
                                style: text.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr.assistantIntroSubtitle,
                                style: text.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xxl),

                              Text(
                                tr.doSection,
                                style: text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              _PromptCard(
                                title: tr.addExpense,
                                subtitle: tr.spentLunchSubtitle,
                                icon: HugeIcons.strokeRoundedCoins01,
                                onTap: () => _send(tr.spentLunchPrompt),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              _PromptCard(
                                title: tr.scheduleShift,
                                subtitle: tr.cafeFridaySubtitle,
                                icon: HugeIcons.strokeRoundedCalendar03,
                                onTap: () => _send(tr.cafeFridayPrompt),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              _PromptCard(
                                title: tr.moveMoneyToGoal,
                                subtitle: tr.emergencyFundMoveSubtitle,
                                icon: HugeIcons.strokeRoundedTarget02,
                                onTap: () => _send(tr.emergencyFundMovePrompt),
                              ),
                              const SizedBox(height: AppSpace.xl),

                              Text(
                                tr.askSection,
                                style: text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              _PromptCard(
                                title: tr.howMuchSpendFoodTitle,
                                subtitle: tr.thisMonthSoFarSubtitle,
                                icon: HugeIcons.strokeRoundedChartHistogram,
                                onTap: () => _send(tr.howMuchFoodPrompt),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              _PromptCard(
                                title: tr.canIAffordTitle,
                                subtitle: tr.basedOnForecastSubtitle,
                                icon: HugeIcons.strokeRoundedShieldCheck,
                                onTap: () => _send(tr.canIAffordPrompt),
                              ),
                            ],
                          );
                        }

                        final count =
                            _viewModel.messages.length +
                            (_viewModel.isTyping ? 1 : 0);
                        if (count != _lastCount) {
                          _lastCount = count;
                          _scrollToEnd();
                        }
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppSpace.page),
                          itemCount: count,
                          itemBuilder: (context, i) {
                            if (i == _viewModel.messages.length) {
                              return const TypingIndicator();
                            }
                            final msg = _viewModel.messages[i];
                            if (msg.isUser) {
                              return ChatEntrance(
                                fromRight: true,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      bottom: AppSpace.md,
                                      left: 48,
                                    ),
                                    padding: const EdgeInsets.all(AppSpace.sm),
                                    decoration: BoxDecoration(
                                      color: colors.hero,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.lg,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (msg.imageBytes != null) ...[
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.md,
                                            ),
                                            child: Image.memory(
                                              msg.imageBytes!,
                                              width: 220,
                                              height: 160,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpace.xs),
                                        ],
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpace.sm,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            msg.text,
                                            style: text.bodyMedium?.copyWith(
                                              color: colors.onHero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Assistant message
                            final prevUser =
                                i > 0 && _viewModel.messages[i - 1].isUser
                                    ? _viewModel.messages[i - 1].text
                                    : null;
                            final chartKind =
                                prevUser == null ||
                                        msg.pendingAction != null ||
                                        msg.isConfirmed
                                    ? null
                                    : chartKindForQuery(prevUser);
                            final isLast = i == _viewModel.messages.length - 1;
                            return ChatEntrance(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                      bottom: AppSpace.md,
                                      right: 32,
                                    ),
                                    padding: const EdgeInsets.all(AppSpace.lg),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.lg,
                                      ),
                                      border: Border.all(
                                        color: scheme.outlineVariant,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (msg.headline != null &&
                                            msg.headline!.isNotEmpty) ...[
                                          Text(
                                            msg.headline!,
                                            style: text.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpace.xs),
                                        ],
                                        MarkdownBody(
                                          data: msg.text,
                                          selectable: true,
                                          styleSheet:
                                              MarkdownStyleSheet.fromTheme(
                                                Theme.of(context),
                                              ).copyWith(
                                                p: text.bodyMedium?.copyWith(
                                                  height: 1.45,
                                                ),
                                                strong: text.bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      height: 1.45,
                                                    ),
                                                em: text.bodyMedium?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                  height: 1.45,
                                                ),
                                                listBullet: text.bodyMedium
                                                    ?.copyWith(
                                                      color: scheme.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                h1: text.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                                h2: text.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                h3: text.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                blockquote: text.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          scheme
                                                              .onSurfaceVariant,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                code: text.bodySmall?.copyWith(
                                                  fontFamily: 'monospace',
                                                  backgroundColor: scheme
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.5),
                                                ),
                                                codeblockDecoration:
                                                    BoxDecoration(
                                                      color: scheme
                                                          .surfaceContainerHighest
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppRadius.sm,
                                                          ),
                                                    ),
                                              ),
                                        ),
                                        if (msg.explanation != null) ...[
                                          const SizedBox(height: AppSpace.sm),
                                          Text(
                                            msg.explanation!,
                                            style: text.bodySmall?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  if (chartKind != null)
                                    ChatChartCard(
                                      kind: chartKind,
                                      snapshot:
                                          _viewModel.financeStore.snapshot,
                                      currency: _viewModel.baseCurrency,
                                    ),

                                  if (isLast &&
                                      msg.suggestions.isNotEmpty &&
                                      !_viewModel.isTyping)
                                    AnimatedSuggestionChips(
                                      suggestions: msg.suggestions,
                                      onTap: _send,
                                    ),

                                  // Interactive editable confirmation card
                                  if (msg.pendingAction != null &&
                                      !msg.isConfirmed) ...[
                                    _InteractiveActionCard(
                                      msg: msg,
                                      viewModel: _viewModel,
                                    ),
                                    const SizedBox(height: AppSpace.md),
                                  ],

                                  // Confirmed status card
                                  if (msg.isConfirmed) ...[
                                    AppCard(
                                      child: Row(
                                        children: [
                                          IconTile(
                                            HugeIcons
                                                .strokeRoundedCheckmarkCircle02,
                                            size: 36,
                                          ),
                                          const SizedBox(width: AppSpace.md),
                                          Expanded(
                                            child: Text(
                                              msg.confirmedSummary ??
                                                  tr.t(
                                                    'Action completed',
                                                    ne: 'कार्य सम्पन्न भयो',
                                                    es: 'Acción completada',
                                                    fr: 'Action terminée',
                                                    de: 'Aktion abgeschlossen',
                                                    ja: '操作が完了しました',
                                                    zh: '操作已完成',
                                                    it: 'Azione completata',
                                                  ),
                                              style: text.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (msg.createdTransactionId !=
                                              null) ...[
                                            const SizedBox(width: AppSpace.sm),
                                            OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 0,
                                                    ),
                                              ),
                                              onPressed:
                                                  () => _viewModel
                                                      .undoTransaction(msg),
                                              child: Text(tr.undo),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.md),
                                    if (i ==
                                        _viewModel.messages.length - 1) ...[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            tr.whatNextTitle,
                                            style: text.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _viewModel.clear,
                                            child: Text(tr.startFresh),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpace.sm),
                                      _PromptCard(
                                        title: tr.addExpense,
                                        subtitle: tr.spentLunchSubtitle,
                                        icon: HugeIcons.strokeRoundedCoins01,
                                        onTap: () => _send(tr.spentLunchPrompt),
                                      ),
                                      const SizedBox(height: AppSpace.sm),
                                      _PromptCard(
                                        title: tr.scheduleShift,
                                        subtitle: tr.cafeFridaySubtitle,
                                        icon: HugeIcons.strokeRoundedCalendar03,
                                        onTap: () => _send(tr.cafeFridayPrompt),
                                      ),
                                      const SizedBox(height: AppSpace.sm),
                                      _PromptCard(
                                        title: tr.moveMoneyToGoal,
                                        subtitle: tr.emergencyFundMoveSubtitle,
                                        icon: HugeIcons.strokeRoundedTarget02,
                                        onTap:
                                            () => _send(
                                              tr.emergencyFundMovePrompt,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpace.lg),
                                    ],
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Input bar with rounded inbox, camera bill scanner, and highlighted outlined send button
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md,
                      AppSpace.sm,
                      AppSpace.md,
                      AppSpace.md,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: Border(
                        top: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Camera / Bill Scanner button
                        IconButton.outlined(
                          style: IconButton.styleFrom(
                            foregroundColor: scheme.onSurfaceVariant,
                            side: BorderSide(color: scheme.outlineVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            padding: const EdgeInsets.all(10),
                            minimumSize: const Size(44, 44),
                          ),
                          icon: const AppIcon(
                            HugeIcons.strokeRoundedCamera01,
                            size: 20,
                          ),
                          tooltip: tr.scanBillTooltip,
                          onPressed: () => _pickBillImage(context),
                        ),
                        const SizedBox(width: AppSpace.sm),

                        // Proper rounded inbox container
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.md,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.45,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: TextField(
                              controller: _inputController,
                              style: text.bodyMedium,
                              decoration: InputDecoration(
                                hintText: tr.askOrTypeNotesHint,
                                hintStyle: text.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),

                        // Highlighted outlined send button
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.primary,
                            backgroundColor: scheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            side: BorderSide(color: scheme.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () => _send(),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 20,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconGlyph icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OptionTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      selected: false,
      onTap: onTap,
    );
  }
}

class _InteractiveActionCard extends StatefulWidget {
  const _InteractiveActionCard({required this.msg, required this.viewModel});

  final AssistantMessage msg;
  final AssistantViewModel viewModel;

  @override
  State<_InteractiveActionCard> createState() => _InteractiveActionCardState();
}

class _InteractiveActionCardState extends State<_InteractiveActionCard> {
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late String _category;

  static const _quickCategories = [
    'Groceries',
    'Eating out',
    'Transport',
    'Bills',
    'Entertainment',
  ];

  @override
  void initState() {
    super.initState();
    final action = widget.msg.pendingAction;
    final amtMinor = action?.amountMinor ?? 5420;
    _amountController = TextEditingController(
      text: (amtMinor / 100).toStringAsFixed(2),
    );
    _merchantController = TextEditingController(
      text: action?.merchant ?? 'Woolworths',
    );
    _category = action?.category ?? 'Groceries';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _confirm() {
    final amt = (double.tryParse(_amountController.text.trim()) ?? 54.20) * 100;
    widget.viewModel.confirmAction(
      widget.msg,
      customAmountMinor: amt.round(),
      customMerchant: _merchantController.text.trim(),
      customCategory: _category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tr = context.strings;
    final action = widget.msg.pendingAction;
    if (action == null) return const SizedBox.shrink();

    final isExpense = action.kind == AssistantActionKind.addExpense;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                action.title,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              StatusChip(tr.needsYourOk, tone: ChipTone.warning),
            ],
          ),
          const SizedBox(height: AppSpace.md),

          if (isExpense) ...[
            // Amount Input
            Row(
              children: [
                Text(
                  widget.viewModel.baseCurrency,
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: UnderlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),

            // Merchant / Note Input
            TextField(
              controller: _merchantController,
              decoration: InputDecoration(
                labelText: tr.merchantOrNoteLabel,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpace.md),

            // Category choice pills
            Text(
              tr.categories,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cat in _quickCategories) ...[
                    ChoicePill(
                      tr.categoryLabel(cat, cat),
                      selected: _category.toLowerCase() == cat.toLowerCase(),
                      onTap: () => setState(() => _category = cat),
                    ),
                    const SizedBox(width: AppSpace.xs),
                  ],
                ],
              ),
            ),
          ] else ...[
            if (action.amountMinor != null)
              Text(
                MoneyFormatter.format(
                  action.amountMinor!,
                  widget.viewModel.baseCurrency,
                ),
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (action.merchant != null) ...[
              const SizedBox(height: 4),
              Text(
                '${tr.merchantLabel}: ${action.merchant}',
                style: text.bodySmall,
              ),
            ],
            if (action.jobName != null) ...[
              const SizedBox(height: 4),
              Text(
                '${tr.jobLabel}: ${action.jobName} · ${action.startTime}–${action.endTime}',
                style: text.bodySmall,
              ),
            ],
            if (action.goalName != null) ...[
              const SizedBox(height: 4),
              Text(
                '${tr.goalLabel}: ${action.goalName}',
                style: text.bodySmall,
              ),
            ],
          ],

          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(child: AppButton(tr.confirmAction, onPressed: _confirm)),
              if (isExpense) ...[
                const SizedBox(width: AppSpace.sm),
                IconButton(
                  tooltip: tr.openInFullAddForm,
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  onPressed: () => context.push(AppRoutes.addTransaction),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
