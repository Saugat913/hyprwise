import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:finance_tracker/features/auth/data/auth_service.dart';
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OptionTile(
                    title: tr.takePhotoReceiptBill,
                    subtitle: tr.opensCameraToScan,
                    icon: HugeIcons.strokeRoundedCamera01,
                    selected: false,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  OptionTile(
                    title: tr.uploadFromLibrary,
                    subtitle: tr.chooseExistingBill,
                    icon: HugeIcons.strokeRoundedImage01,
                    selected: false,
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
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
    final subService = getIt<SubscriptionService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, subService]),
      builder:
          (context, _) {
            final isPro = subService.isPro;
            return PopScope(
              canPop: context.canPop(),
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                context.go(AppRoutes.home);
              },
              child: Scaffold(
                appBar: AppTopBar(
                  title: '',
                  showBackButton: true,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.home);
                    }
                  },
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
                    HugeIcons.strokeRoundedDelete02,
                    tooltip: tr.t(
                      'New Chat',
                      ne: 'नयाँ च्याट',
                      hi: 'नया चैट',
                      es: 'Nuevo chat',
                      fr: 'Nouvelle discussion',
                      de: 'Neuer Chat',
                      ja: '新しいチャット',
                      zh: '开启新会话',
                      it: 'Nuova chat',
                    ),
                    onPressed: () {
                      if (_viewModel.messages.isNotEmpty) {
                        _viewModel.clear();
                      }
                    },
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.page,
                              vertical: AppSpace.sm,
                            ),
                            children: [
                              const SizedBox(height: AppSpace.md),
                              // Centered Hyprwise Logo Emblem
                              Center(
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scheme.primary.withValues(alpha: 0.08),
                                    border: Border.all(
                                      color: scheme.primary.withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withValues(
                                          alpha: isDark ? 0.22 : 0.12,
                                        ),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: SvgPicture.asset(
                                    isDark
                                        ? 'assets/brandings/hyprwise_logo_white.svg'
                                        : 'assets/brandings/hyprwise_logo.svg',
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpace.lg),

                              // What can I do for you headline
                              Text(
                                tr.whatCanIDoForYou,
                                textAlign: TextAlign.center,
                                style: text.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.md,
                                ),
                                child: Text(
                                  tr.t(
                                    'Your private AI copilot for personal finance & shift management. Ask questions, record expenses, schedule shifts, or snap receipts.',
                                    ne:
                                        'व्यक्तिगत वित्त र सिफ्ट व्यवस्थापनको लागि तपाईंको निजी एआई सहायक। प्रश्न सोध्नुहोस्, खर्च रेकर्ड गर्नुहोस्, वा रसिद स्क्यान गर्नुहोस्।',
                                    hi:
                                        'व्यक्तिगत वित्त और शिफ्ट प्रबंधन के लिए आपका निजी एआई सहायक। प्रश्न पूछें, खर्च दर्ज करें, या रसीद स्कैन करें।',
                                    es:
                                        'Tu copiloto de IA privado para finanzas y turnos. Pregunta, registra gastos, planifica turnos o escanea recibos.',
                                    fr:
                                        'Votre copilote IA privé pour vos finances et vos quarts. Posez des questions, enregistrez des dépenses ou scannez des reçus.',
                                    de:
                                        'Ihr privater KI-Assistent für Finanzen und Schichten. Fragen stellen, Ausgaben erfassen oder Belege scannen.',
                                    ja:
                                        '個人の財務とシフト管理のためのAIアシスタント。質問、支出の記録、レシートのスキャンができます。',
                                    zh:
                                        '用于个人财务和排班管理的私人AI助手。解答疑问、记录支出、安排排班或扫描收据。',
                                    it:
                                        'Il tuo copilota IA privato per finanze e turni. Fai domande, registra spese o scansiona ricevute.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: text.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpace.xl),

                              // Section 1: Quick Actions
                              SectionHeader(
                                tr.t(
                                  'Quick Actions',
                                  ne: 'द्रुत कार्यहरू',
                                  hi: 'त्वरित कार्य',
                                  es: 'Acciones Rápidas',
                                  fr: 'Actions rapides',
                                  de: 'Schnellaktionen',
                                  ja: 'クイックアクション',
                                  zh: '快捷操作',
                                  it: 'Azioni rapide',
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              _PromptCard(
                                title: tr.addExpense,
                                subtitle: tr.spentLunchSubtitle,
                                icon: HugeIcons.strokeRoundedCoins01,
                                badge: tr.t('Expense', ne: 'खर्च', hi: 'खर्च', es: 'Gasto'),
                                onTap: () => _send(tr.spentLunchPrompt),
                              ),
                              _PromptCard(
                                title: tr.scheduleShift,
                                subtitle: tr.cafeFridaySubtitle,
                                icon: HugeIcons.strokeRoundedCalendar03,
                                badge: tr.t('Shift', ne: 'सिफ्ट', hi: 'शिफ्ट', es: 'Turno'),
                                onTap: () => _send(tr.cafeFridayPrompt),
                              ),
                              _PromptCard(
                                title: tr.moveMoneyToGoal,
                                subtitle: tr.emergencyFundMoveSubtitle,
                                icon: HugeIcons.strokeRoundedTarget02,
                                badge: tr.t('Goal', ne: 'लक्ष्य', hi: 'लक्ष्य', es: 'Meta'),
                                onTap: () => _send(tr.emergencyFundMovePrompt),
                              ),
                              _PromptCard(
                                title: tr.takePhotoReceiptBill,
                                subtitle: tr.opensCameraToScan,
                                icon: HugeIcons.strokeRoundedCamera01,
                                badge: tr.t('OCR', ne: 'स्क्यान', hi: 'स्कैन', es: 'OCR'),
                                onTap: () => _pickBillImage(context),
                              ),
                              const SizedBox(height: AppSpace.lg),

                              // Section 2: Financial Intelligence
                              SectionHeader(
                                tr.t(
                                  'Financial Intelligence',
                                  ne: 'वित्तीय बुद्धिमत्ता',
                                  hi: 'वित्तीय बुद्धिमत्ता',
                                  es: 'Inteligencia Financiera',
                                  fr: 'Intelligence financière',
                                  de: 'Finanzielle Intelligenz',
                                  ja: '財務インテリジェンス',
                                  zh: '财务分析智能',
                                  it: 'Intelligenza finanziaria',
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              _PromptCard(
                                title: tr.howMuchSpendFoodTitle,
                                subtitle: tr.thisMonthSoFarSubtitle,
                                icon: HugeIcons.strokeRoundedChartHistogram,
                                onTap: () => _send(tr.howMuchFoodPrompt),
                              ),
                              _PromptCard(
                                title: tr.canIAffordTitle,
                                subtitle: tr.basedOnForecastSubtitle,
                                icon: HugeIcons.strokeRoundedShieldCheck,
                                onTap: () => _send(tr.canIAffordPrompt),
                              ),
                              _PromptCard(
                                title: tr.t(
                                  'Next upcoming shift',
                                  ne: 'आगामी कार्य सिफ्ट',
                                  hi: 'आगामी कार्य शिफ्ट',
                                  es: 'Próximo turno programado',
                                  fr: 'Prochain quart prévu',
                                  de: 'Nächste Schicht',
                                  ja: '次の予定シフト',
                                  zh: '下一次待排班次',
                                  it: 'Prossimo turno programmato',
                                ),
                                subtitle: tr.t(
                                  'When is my next shift and how much will I earn?',
                                  ne: 'मेरो अर्को सिफ्ट कहिले छ र कति कमाइ हुन्छ?',
                                  hi: 'मेरी अगली शिफ्ट कब है और मैं कितना कमाऊँगा?',
                                  es: '¿Cuándo es mi próximo turno y cuánto ganaré?',
                                  fr: 'Quand aura lieu mon prochain quart et combien vais-je gagner ?',
                                  de: 'Wann ist meine nächste Schicht und wie viel werde ich verdienen?',
                                  ja: '次のシフトはいつで、いくら稼げますか？',
                                  zh: '我的下一个班次是什么时候，预计收入是多少？',
                                  it: 'Quando sarà il mio prossimo turno e quanto guadagnerò?',
                                ),
                                icon: HugeIcons.strokeRoundedClock01,
                                onTap: () => _send('When is my next shift and what are my hours?'),
                              ),
                              const SizedBox(height: AppSpace.xl),
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
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpace.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _AssistantChatAvatar(isDark: isDark, scheme: scheme),
                                    const SizedBox(width: AppSpace.sm),
                                    const Flexible(child: TypingIndicator()),
                                  ],
                                ),
                              );
                            }
                            final msg = _viewModel.messages[i];
                            if (msg.isUser) {
                              return ChatEntrance(
                                fromRight: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpace.md),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          margin: const EdgeInsets.only(left: 48),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpace.md,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.hero,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(AppRadius.lg),
                                              topRight: Radius.circular(AppRadius.xs),
                                              bottomLeft: Radius.circular(AppRadius.lg),
                                              bottomRight: Radius.circular(AppRadius.lg),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
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
                                              Text(
                                                msg.text,
                                                style: text.bodyMedium?.copyWith(
                                                  color: colors.onHero,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpace.sm),
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: _UserChatAvatar(),
                                      ),
                                    ],
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
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: AppSpace.md),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: _AssistantChatAvatar(isDark: isDark, scheme: scheme),
                                    ),
                                    const SizedBox(width: AppSpace.sm),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(right: 24),
                                            padding: const EdgeInsets.all(AppSpace.md),
                                            decoration: BoxDecoration(
                                              color: scheme.surface,
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(AppRadius.xs),
                                                topRight: Radius.circular(AppRadius.lg),
                                                bottomLeft: Radius.circular(AppRadius.lg),
                                                bottomRight: Radius.circular(AppRadius.lg),
                                              ),
                                              border: Border.all(
                                                color: scheme.outlineVariant,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Body text only (Response headline HyperAI removed)
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
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                        );
                      },
                    ),
                  ),

                  // Modern clean input bar with suggestions and animated send button
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _inputController,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      return Container(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.md,
                          AppSpace.xs,
                          AppSpace.md,
                          AppSpace.sm,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          border: Border(
                            top: BorderSide(
                              color: scheme.outlineVariant.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Camera / Bill Scanner button
                                IconButton(
                                  style: IconButton.styleFrom(
                                    foregroundColor: scheme.primary,
                                    backgroundColor: scheme.primary.withValues(alpha: 0.08),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                      side: BorderSide(
                                        color: scheme.primary.withValues(alpha: 0.2),
                                      ),
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

                                // Rounded input container
                                Expanded(
                                  child: Container(
                                    constraints: const BoxConstraints(maxHeight: 120),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.md,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest.withValues(
                                        alpha: 0.45,
                                      ),
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                      border: Border.all(
                                        color: hasText
                                            ? scheme.primary.withValues(alpha: 0.5)
                                            : scheme.outlineVariant.withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _inputController,
                                      maxLines: null,
                                      textInputAction: TextInputAction.send,
                                      style: text.bodyMedium,
                                      decoration: InputDecoration(
                                        hintText: tr.askOrTypeNotesHint,
                                        hintStyle: text.bodyMedium?.copyWith(
                                          color: scheme.onSurfaceVariant.withValues(
                                            alpha: 0.65,
                                          ),
                                          fontSize: 13.5,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
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

                                // Animated dynamic send button
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  child: IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor: hasText
                                          ? scheme.primary
                                          : scheme.surfaceContainerHighest,
                                      foregroundColor: hasText
                                          ? scheme.onPrimary
                                          : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(10),
                                      minimumSize: const Size(44, 44),
                                    ),
                                    onPressed: hasText ? () => _send() : null,
                                    icon: const Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconGlyph icon;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm + 2,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: AppIcon(
                      icon,
                      size: 20,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              child: Text(
                                badge!,
                                style: text.labelSmall?.copyWith(
                                  color: scheme.primary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: scheme.primary, width: 1.5),
                ),
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

class _UserChatAvatar extends StatelessWidget {
  const _UserChatAvatar();

  @override
  Widget build(BuildContext context) {
    final authService = getIt<AuthService>();
    final user = authService.currentUser;
    final scheme = Theme.of(context).colorScheme;
    final isAnon = authService.isGuest || user == null;
    if (isAnon) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: scheme.surfaceContainerHighest,
        child: AppIcon(
          HugeIcons.strokeRoundedUser,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    final displayName = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : (user.email.contains('@') ? user.email.split('@').first : 'User');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return CircleAvatar(
      radius: 16,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
          ? NetworkImage(user.photoUrl!)
          : null,
      child: (user.photoUrl == null || user.photoUrl!.isEmpty)
          ? Text(
              initial,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
          : null,
    );
  }
}

class _AssistantChatAvatar extends StatelessWidget {
  const _AssistantChatAvatar({required this.isDark, required this.scheme});
  final bool isDark;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary.withValues(alpha: 0.1),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(5),
      child: Image.asset(
        'assets/brandings/hyprwise_app_icon_1024.png',
        errorBuilder: (context, error, stackTrace) => SvgPicture.asset(
          isDark
              ? 'assets/brandings/hyprwise_logo_white.svg'
              : 'assets/brandings/hyprwise_logo.svg',
        ),
      ),
    );
  }
}
