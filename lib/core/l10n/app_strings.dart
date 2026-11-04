import 'package:flutter/widgets.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';

/// Comprehensive multilingual translation dictionary for Hyprwise.
/// Supports English ('en'), Nepali ('ne'), Spanish ('es'), French ('fr'),
/// German ('de'), Japanese ('ja'), Chinese ('zh'), and Italian ('it').
class AppStrings {
  const AppStrings(this.localeCode);

  final String localeCode;

  bool get isNepali => localeCode == 'ne';
  bool get isHindi => localeCode == 'hi';
  bool get isSpanish => localeCode == 'es';
  bool get isFrench => localeCode == 'fr';
  bool get isGerman => localeCode == 'de';
  bool get isJapanese => localeCode == 'ja';
  bool get isChinese => localeCode == 'zh';
  bool get isItalian => localeCode == 'it';

  String _t(
    String en, {
    String? ne,
    String? hi,
    String? es,
    String? fr,
    String? de,
    String? ja,
    String? zh,
    String? it,
  }) {
    switch (localeCode.toLowerCase()) {
      case 'ne':
        return localizeDigits(ne ?? en);
      case 'hi':
        return localizeDigits(hi ?? ne ?? en);
      case 'es':
        return es ?? en;
      case 'fr':
        return fr ?? en;
      case 'de':
        return de ?? en;
      case 'ja':
        return ja ?? en;
      case 'zh':
        return zh ?? en;
      case 'it':
        return it ?? en;
      default:
        return en;
    }
  }

  /// General translation helper for strings with inline multilingual support.
  String t(
    String en, {
    String? ne,
    String? hi,
    String? es,
    String? fr,
    String? de,
    String? ja,
    String? zh,
    String? it,
  }) => _t(en, ne: ne, hi: hi, es: es, fr: fr, de: de, ja: ja, zh: zh, it: it);

  static AppStrings of(BuildContext context) {
    if (getIt.isRegistered<SettingsRepository>()) {
      return AppStrings(getIt<SettingsRepository>().localeCode);
    }
    final locale = Localizations.maybeLocaleOf(context);
    return AppStrings(locale?.languageCode ?? 'en');
  }

  static AppStrings current() {
    if (getIt.isRegistered<SettingsRepository>()) {
      return AppStrings(getIt<SettingsRepository>().localeCode);
    }
    return const AppStrings('en');
  }

  static String localizeDigitsForLocale(String input, String localeCode) {
    final loc = localeCode.toLowerCase();
    if (loc != 'ne' && loc != 'hi') return input;
    const devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        buffer.write(devanagariDigits[code - 48]);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  String localizeDigits(String input) => localizeDigitsForLocale(input, localeCode);

  String formatTransactionNote(String note) {
    if (note.startsWith('Borrowed from ')) {
      final person = note.substring('Borrowed from '.length);
      return borrowedFromPerson(person);
    }
    if (note.startsWith('Lent to ')) {
      final person = note.substring('Lent to '.length);
      return lentToPerson(person);
    }
    if (note.startsWith('Repayment from ')) {
      final person = note.substring('Repayment from '.length);
      return repaymentFromPerson(person);
    }
    if (note.startsWith('Repayment to ')) {
      final person = note.substring('Repayment to '.length);
      return repaymentToPerson(person);
    }
    return note;
  }

  String borrowedFromPerson(String person) => _t(
        'Borrowed from $person',
        ne: '$person बाट सापटी लिएको',
        hi: '$person से उधार लिया',
        es: 'Tomado prestado de $person',
        fr: 'Emprunté à $person',
        de: 'Von $person geliehen',
        ja: '$person から借入',
        zh: '向 $person 借入',
        it: 'Preso in prestito da $person',
      );

  String lentToPerson(String person) => _t(
        'Lent to $person',
        ne: '$person लाई सापटी दिएको',
        hi: '$person को उधार दिया',
        es: 'Prestado a $person',
        fr: 'Prêté à $person',
        de: 'An $person geliehen',
        ja: '$person に貸出',
        zh: '借给 $person',
        it: 'Prestato a $person',
      );

  String repaymentFromPerson(String person) => _t(
        'Repayment from $person',
        ne: '$person बाट फिर्ता भुक्तानी',
        hi: '$person से पुनर्भुगतान',
        es: 'Reembolso de $person',
        fr: 'Remboursement de $person',
        de: 'Rückzahlung von $person',
        ja: '$person からの返済',
        zh: '来自 $person 的还款',
        it: 'Rimborso da $person',
      );

  String repaymentToPerson(String person) => _t(
        'Repayment to $person',
        ne: '$person लाई फिर्ता भुक्तानी',
        hi: '$person को पुनर्भुगतान',
        es: 'Reembolso a $person',
        fr: 'Remboursement à $person',
        de: 'Rückzahlung an $person',
        ja: '$person への返済',
        zh: '向 $person 还款',
        it: 'Rimborso a $person',
      );

  String get privacyPolicyTitle => _t('Privacy Policy', ne: 'गोपनीयता नीति', hi: 'गोपनीयता नीति', es: 'Política de Privacidad', fr: 'Politique de Confidentialité', de: 'Datenschutzerklärung', ja: 'プライバシーポリシー', zh: '隐私政策', it: 'Informativa sulla Privacy');
  String get termsOfServiceTitle => _t('Terms of Service', ne: 'सेवाका सर्तहरू', hi: 'सेवा की शर्तें', es: 'Términos del Servicio', fr: 'Conditions d\'Utilisation', de: 'Nutzungsbedingungen', ja: '利用規約', zh: '服务条款', it: 'Termini di Servizio');
  String get editJob => _t('Edit Job', ne: 'काम सम्पादन', hi: 'काम संपादित करें', es: 'Editar trabajo', fr: 'Modifier l\'emploi', de: 'Job bearbeiten', ja: '仕事を編集', zh: '编辑工作', it: 'Modifica lavoro');


  // Common Navigation
  String get home => _t('Home', ne: 'गृहपृष्ठ', es: 'Inicio', fr: 'Accueil', de: 'Startseite', ja: 'ホーム', zh: '首页', it: 'Home');
  String get money => _t('Money', ne: 'कारोबार', es: 'Dinero', fr: 'Argent', de: 'Finanzen', ja: 'お金', zh: '资金', it: 'Finanze');
  String get work => _t('Work', ne: 'काम', es: 'Trabajo', fr: 'Travail', de: 'Arbeit', ja: '仕事', zh: '工作', it: 'Lavoro');
  String get plan => _t('Plan', ne: 'योजना', es: 'Plan', fr: 'Plan', de: 'Plan', ja: '計画', zh: '计划', it: 'Piano');
  String get calendar => _t('Calendar', ne: 'पात्रो', es: 'Calendario', fr: 'Calendrier', de: 'Kalender', ja: 'カレンダー', zh: '日历', it: 'Calendario');
  String get settings => _t('Settings', ne: 'सेटिङहरू', es: 'Ajustes', fr: 'Paramètres', de: 'Einstellungen', ja: '設定', zh: '设置', it: 'Impostazioni');
  String get alerts => _t('Alerts', ne: 'सूचनाहरू', es: 'Alertas', fr: 'Alertes', de: 'Warnungen', ja: '通知', zh: '提醒', it: 'Avvisi');
  String get analytics => _t('Analytics', ne: 'विश्लेषिकी', es: 'Analíticas', fr: 'Analyses', de: 'Analysen', ja: '分析', zh: '分析', it: 'Analisi');
  String get today => _t('Today', ne: 'आज', es: 'Hoy', fr: 'Aujourd\'hui', de: 'Heute', ja: '今日', zh: '今天', it: 'Oggi');
  String get addExpense => _t('Add expense', ne: 'खर्च थप्नुहोस्', es: 'Añadir gasto', fr: 'Ajouter une dépense', de: 'Ausgabe hinzufügen', ja: '支出を追加', zh: '添加支出', it: 'Aggiungi spesa');
  String get addIncome => _t('Add income', ne: 'आम्दानी थप्नुहोस्', es: 'Añadir ingreso', fr: 'Ajouter un revenu', de: 'Einnahme hinzufügen', ja: '収入を追加', zh: '添加收入', it: 'Aggiungi entrata');

  // Accounts & Balances
  String get everyday => _t('Everyday', ne: 'दैनिक खाता', es: 'Diario', fr: 'Courant', de: 'Alltagskonto', ja: '日常口座', zh: '日常账户', it: 'Conto corrente');
  String get savings => _t('Savings', ne: 'बचत खाता', es: 'Ahorros', fr: 'Épargne', de: 'Sparkonto', ja: '貯金口座', zh: '储蓄账户', it: 'Conto risparmio');
  String get netPosition => _t('Net Position', ne: 'कुल सम्पत्ति', es: 'Posición Neta', fr: 'Position Nette', de: 'Nettovermögen', ja: '純資産', zh: '净资产', it: 'Patrimonio netto');
  String get income => _t('Income', ne: 'आम्दानी', es: 'Ingresos', fr: 'Revenus', de: 'Einnahmen', ja: '収入', zh: '收入', it: 'Entrate');
  String get expense => _t('Expense', ne: 'खर्च', es: 'Gastos', fr: 'Dépenses', de: 'Ausgaben', ja: '支出', zh: '支出', it: 'Spese');
  String get transfer => _t('Transfer', ne: 'स्थानान्तरण', es: 'Transferencia', fr: 'Transfert', de: 'Überweisung', ja: '振替', zh: '转账', it: 'Trasferimento');
  String get accounts => _t('Accounts', ne: 'खाताहरू', es: 'Cuentas', fr: 'Comptes', de: 'Konten', ja: '口座', zh: '账户', it: 'Conti');
  String get currency => _t('Currency', ne: 'मुद्रा', es: 'Moneda', fr: 'Devise', de: 'Währung', ja: '通貨', zh: '货币', it: 'Valuta');

  // Home Dashboard
  String get recentTransactions => _t('Recent Transactions', ne: 'हालैका कारोबारहरू', es: 'Transacciones Recientes', fr: 'Transactions Récentes', de: 'Letzte Transaktionen', ja: '最近の取引', zh: '最近交易');
  String get upcomingEvents => _t('Upcoming', ne: 'आगामी कार्यहरू', es: 'Próximos', fr: 'À venir', de: 'Bevorstehend', ja: '予定', zh: '即将到来');
  String get seeAll => _t('See all', ne: 'सबै हेर्नुहोस्', es: 'Ver todo', fr: 'Voir tout', de: 'Alle ansehen', ja: 'すべて見る', zh: '查看全部');
  String get noTransactionsYet => _t('No transactions yet', ne: 'कुनै कारोबार दर्ता भएको छैन', es: 'Sin transacciones aún', fr: 'Aucune transaction', de: 'Noch keine Transaktionen', ja: '取引はまだありません', zh: '暂无交易');
  String get noUpcomingEvents => _t('Nothing coming up this week', ne: 'यस हप्ता केही तालिका छैन', es: 'Nada programado esta semana', fr: 'Rien de prévu cette semaine', de: 'Diese Woche steht nichts an', ja: '今週の予定はありません', zh: '本周无日程');
  String get todayShift => _t('Today\'s Shift', ne: 'आजको सिफ्ट', es: 'Turno de Hoy', fr: 'Quart d\'Aujourd\'hui', de: 'Heutige Schicht', ja: '今日のシフト', zh: '今日班次');
  String get upcomingShift => _t('Next shift', ne: 'अर्को सिफ्ट', es: 'Próximo turno', fr: 'Prochain quart', de: 'Nächste Schicht', ja: '次のシフト', zh: '下一班次');

  // Debts & Lending
  String get debts => _t('Lending & Borrowing', ne: 'सापटी र लेनदेन', es: 'Préstamos y Deudas', fr: 'Prêts et Dettes', de: 'Leihen & Schulden', ja: '貸し借り', zh: '借贷与债务');
  String get lent => _t('Lent', ne: 'सापटी दिएको', es: 'Prestado', fr: 'Prêté', de: 'Verliehen', ja: '貸出', zh: '借出');
  String get borrowed => _t('Borrowed', ne: 'सापटी लिएको', es: 'Tomado prestado', fr: 'Emprunté', de: 'Geliehen', ja: '借入', zh: '借入');
  String get recordPayment => _t('Record Payment', ne: 'भुक्तानी दर्ता', es: 'Registrar Pago', fr: 'Enregistrer Paiement', de: 'Zahlung erfassen', ja: '支払いを記録', zh: '记录还款');
  String get netBalance => _t('Net Balance', ne: 'खुद रकम', es: 'Saldo Neto', fr: 'Solde Net', de: 'Nettosaldo', ja: '差引残高', zh: '净余额');
  String get allParties => _t('All Parties', ne: 'सबै व्यक्तिहरू', es: 'Todas las partes', fr: 'Toutes les parties', de: 'Alle Parteien', ja: 'すべての関係者', zh: '所有对象', it: 'Tutte le parti');
  String get noDebtsYet => _t('No lending or debts', ne: 'कुनै लेनदेन बाँकी छैन', es: 'Sin deudas registradas', fr: 'Aucune dette', de: 'Keine Schulden', ja: '貸し借りの記録はありません', zh: '暂无借贷');

  // Work & Shifts
  String get activeShift => _t('Active Shift', ne: 'सक्रिय सिफ्ट', es: 'Turno Activo', fr: 'Quart Actif', de: 'Aktive Schicht', ja: '稼働中のシフト', zh: '进行中班次');
  String get startShift => _t('Start Shift', ne: 'सिफ्ट सुरु गर्नुहोस्', es: 'Iniciar Turno', fr: 'Démarrer le quart', de: 'Schicht beginnen', ja: 'シフト開始', zh: '开始上班');
  String get endShift => _t('End Shift', ne: 'सिफ्ट समाप्त', es: 'Terminar Turno', fr: 'Terminer le quart', de: 'Schicht beenden', ja: 'シフト終了', zh: '下班打卡');
  String get takeBreak => _t('Take Break', ne: 'विश्राम लिनुहोस्', es: 'Tomar Pausa', fr: 'Prendre une pause', de: 'Pause machen', ja: '休憩する', zh: '休息一下');
  String get resumeShift => _t('Resume Shift', ne: 'सिफ्ट पुनः सुरु', es: 'Reanudar Turno', fr: 'Reprendre le quart', de: 'Schicht fortsetzen', ja: 'シフト再開', zh: '继续工作');
  String get noActiveShift => _t('No active shift', ne: 'कुनै सक्रिय सिफ्ट छैन', es: 'Sin turno activo', fr: 'Aucun quart actif', de: 'Keine aktive Schicht', ja: 'アクティブなシフトはありません', zh: '无活跃班次');
  String get onBreak => _t('On break', ne: 'विश्राममा', es: 'En pausa', fr: 'En pause', de: 'In der Pause', ja: '休憩中', zh: '休息中');
  String get scheduledToday => _t('Scheduled Today', ne: 'आजको तालिका', es: 'Programado Hoy', fr: 'Prévu Aujourd\'hui', de: 'Heute geplant', ja: '今日の予定', zh: '今日安排');
  String get completedToday => _t('Completed Today', ne: 'आज सम्पन्न सिफ्ट', es: 'Completado Hoy', fr: 'Terminé Aujourd\'hui', de: 'Heute abgeschlossen', ja: '本日完了', zh: '今日已完成');
  String get noShiftsToday => _t('No shifts scheduled today', ne: 'आज कुनै सिफ्ट तालिका छैन', es: 'Sin turnos para hoy', fr: 'Aucun quart aujourd\'hui', de: 'Heute keine Schichten', ja: '今日のシフトはありません', zh: '今日无排班');
  String get jobs => _t('Jobs', ne: 'रोजगारहरू', es: 'Empleos', fr: 'Emplois', de: 'Jobs', ja: '仕事', zh: '工作岗位');
  String get addJob => _t('Add Job', ne: 'नयाँ काम थप्नुहोस्', es: 'Añadir Empleo', fr: 'Ajouter un emploi', de: 'Job hinzufügen', ja: '仕事を追加', zh: '添加工作');
  String get hoursWorked => _t('Hours worked', ne: 'काम गरेको समय', es: 'Horas trabajadas', fr: 'Heures travaillées', de: 'Arbeitsstunden', ja: '労働時間', zh: '工作时长');
  String get earnedThisMonth => _t('Earned this month', ne: 'यस महिनाको कमाइ', es: 'Ganado este mes', fr: 'Gagné ce mois', de: 'Diesen Monat verdient', ja: '今月の収入', zh: '本月已赚取', it: 'Guadagnato questo mese');

  // Job & Shift Wizard Localizations
  String get suggestions => _t('Suggestions', ne: 'सुझावहरू', es: 'Sugerencias', fr: 'Suggestions', de: 'Vorschläge', ja: 'おすすめ', zh: '推荐', it: 'Suggerimenti');
  String get jobCafe => _t('Café', ne: 'क्याफे', es: 'Cafetería', fr: 'Café', de: 'Café', ja: 'カフェ', zh: '咖啡馆', it: 'Bar / Caffè');
  String get jobWarehouse => _t('Warehouse', ne: 'गोदाम', es: 'Almacén', fr: 'Entrepôt', de: 'Lager', ja: '倉庫', zh: '仓库', it: 'Magazzino');
  String get jobTutoring => _t('Tutoring', ne: 'ट्युसन / अध्यापन', es: 'Tutoría', fr: 'Tutorat', de: 'Nachhilfe', ja: '家庭教師', zh: '家教辅导', it: 'Ripetizioni');
  String get jobDelivery => _t('Delivery', ne: 'डेलिभरी', es: 'Reparto', fr: 'Livraison', de: 'Lieferung', ja: 'デリバリー', zh: '配送外卖', it: 'Consegna');
  String get jobName => _t('Job name', ne: 'कामको नाम', es: 'Nombre del trabajo', fr: 'Nom du travail', de: 'Job-Bezeichnung', ja: '仕事の名前', zh: '工作名称', it: 'Nome lavoro');
  String get jobNameHint => _t('e.g. Café', ne: 'जस्तै: क्याफे, पसल', es: 'ej. Cafetería', fr: 'ex. Café', de: 'z.B. Café', ja: '例: カフェ', zh: '例如：咖啡馆', it: 'es. Bar');
  String get enterJobNameError => _t('Please enter a job name', ne: 'कृपया कामको नाम प्रविष्ट गर्नुहोस्', es: 'Por favor ingrese un nombre de trabajo', fr: 'Veuillez saisir un nom d\'emploi', de: 'Bitte geben Sie einen Jobnamen ein', ja: '仕事名を入力してください', zh: '请输入工作名称', it: 'Inserisci un nome di lavoro');
  String get enterValidRateError => _t('Please enter a valid rate', ne: 'कृपया मान्य दर प्रविष्ट गर्नुहोस्', es: 'Por favor ingrese una tarifa válida', fr: 'Veuillez saisir un tarif valide', de: 'Bitte geben Sie einen gültigen Stundensatz ein', ja: '有効なレートを入力してください', zh: '请输入有效时薪', it: 'Inserisci una tariffa valida');
  String get jobSaved => _t('Job saved', ne: 'काम सुरक्षित गरियो', es: 'Trabajo guardado', fr: 'Emploi enregistré', de: 'Job gespeichert', ja: '仕事を保存しました', zh: '工作已保存', it: 'Lavoro salvato');
  String get view => _t('View', ne: 'हेर्नुहोस्', es: 'Ver', fr: 'Voir', de: 'Ansehen', ja: '表示', zh: '查看', it: 'Visualizza');
  String get undo => _t('Undo', ne: 'पूर्ववत', es: 'Deshacer', fr: 'Annuler', de: 'Rückgängig', ja: '元に戻す', zh: '撤销', it: 'Annulla');
  String get discardThis => _t('Discard this?', ne: 'रद्द गर्ने?', es: '¿Descartar?', fr: 'Abandonner ?', de: 'Verwerfen?', ja: '破棄しますか？', zh: '放弃此项？', it: 'Annullare?');
  String get next => _t('Next', ne: 'अर्को', es: 'Siguiente', fr: 'Suivant', de: 'Weiter', ja: '次へ', zh: '下一步', it: 'Avanti');
  String get whatIsJobCalled => _t('What is the job called?', ne: 'काम वा जागिरको नाम के हो?', es: '¿Cómo se llama el empleo?', fr: 'Comment s\'appelle le travail ?', de: 'Wie heißt der Job?', ja: '仕事の名前は何ですか？', zh: '工作岗位叫什么？', it: 'Come si chiama il lavoro?');
  String get recogniseAtGlance => _t('A name you will recognise at a glance.', ne: 'एक नजरमै चिन्न सकिने नाम राख्नुहोस्।', es: 'Un nombre reconocible a simple vista.', fr: 'Un nom reconnaissable en un clin d\'œil.', de: 'Ein Name, den Sie sofort erkennen.', ja: '一目でわかる名前を設定してください。', zh: '一目了然的名称。', it: 'Un nome che riconoscerai a colpo d\'occhio.');
  String get howDoYouGetPaid => _t('How do you get paid?', ne: 'भुक्तानी कसरी प्राप्त हुन्छ?', es: '¿Cómo te pagan?', fr: 'Comment êtes-vous payé ?', de: 'Wie werden Sie bezahlt?', ja: '給与の支払い形式は？', zh: '结算方式是什么？', it: 'Come vieni pagato?');
  String get keepsForecastsAccurate => _t('This keeps your forecasts accurate.', ne: 'यसले तपाईंको आम्दानी पूर्वानुमान सटिक बनाउँछ।', es: 'Mantiene tus pronósticos precisos.', fr: 'Cela maintient vos prévisions exactes.', de: 'Das hält Ihre Prognosen präzise.', ja: '収支予測を正確に保ちます。', zh: '这能确保预算预测准确。', it: 'Mantiene accurate le tue previsioni.');
  String get hourly => _t('Hourly', ne: 'प्रति घण्टा', es: 'Por hora', fr: 'Horaire', de: 'Stündlich', ja: '時給制', zh: '时薪制', it: 'Orario');
  String get paidForHoursWorked => _t('Paid for the hours you work', ne: 'काम गरेको समय अनुसार', es: 'Se paga por las horas trabajadas', fr: 'Payé selon les heures travaillées', de: 'Bezahlung nach Stunden', ja: '実働時間に応じて支給', zh: '按实际工作小时结算', it: 'Pagato per le ore lavorate');
  String get perShift => _t('Per shift', ne: 'प्रति सिफ्ट', es: 'Por turno', fr: 'Par quart', de: 'Pro Schicht', ja: 'シフト単位', zh: '按班次', it: 'A turno');
  String get sameAmountEveryShift => _t('Same amount every shift', ne: 'प्रत्येक सिफ्टको निश्चित रकम', es: 'Misma cantidad por turno', fr: 'Même montant à chaque quart', de: 'Gleicher Betrag pro Schicht', ja: 'シフトごとに固定額', zh: '每班固定金额', it: 'Stesso importo a turno');
  String get salary => _t('Salary', ne: 'मासिक तलब', es: 'Salario', fr: 'Salaire', de: 'Festgehalt', ja: '固定給', zh: '固定薪资', it: 'Stipendio fisso');
  String get fixedAmountEachPayPeriod => _t('Fixed amount each pay period', ne: 'प्रत्येक भुक्तानी अवधिको निश्चित रकम', es: 'Cantidad fija en cada periodo de pago', fr: 'Montant fixe par période de paie', de: 'Fester Betrag pro Abrechnungszeitraum', ja: '給与期間ごとの固定額', zh: '每个支付周期固定金额', it: 'Importo fisso per periodo di paga');
  String get rate => _t('Rate', ne: 'दर', es: 'Tarifa', fr: 'Tarif', de: 'Satz', ja: 'レート', zh: '费率', it: 'Tariffa');
  String get whichDaysUsuallyWork => _t('Which days do you usually work?', ne: 'सामान्यतया कुन दिन काम गर्नुहुन्छ?', es: '¿Qué días sueles trabajar?', fr: 'Quels jours travaillez-vous habituellement ?', de: 'An welchen Tagen arbeiten Sie normalerweise?', ja: '通常どの曜日に勤務しますか？', zh: '您通常周几上班？', it: 'Quali giorni lavori di solito?');
  String get pickDaysTimesPerShift => _t('Pick the days. Times are set per shift.', ne: 'दिनहरू छान्नुहोस्। समय सिफ्ट अनुसार तय हुन्छ।', es: 'Elige los días. Los horarios se fijan por turno.', fr: 'Choisissez les jours. Les heures sont fixées par quart.', de: 'Tage wählen. Zeiten werden pro Schicht festgelegt.', ja: '曜日を選択。時間はシフトごとに設定。', zh: '选择日期。具体时间按班次单独设置。', it: 'Scegli i giorni. Gli orari sono fissati per turno.');
  String get saveJob => _t('Save job', ne: 'काम सुरक्षित गर्नुहोस्', es: 'Guardar empleo', fr: 'Enregistrer l\'emploi', de: 'Job speichern', ja: '仕事を保存', zh: '保存工作', it: 'Salva lavoro');

  String get whichJobForShift => _t('Which job is this shift for?', ne: 'यो सिफ्ट कुन कामको लागि हो?', es: '¿Para qué empleo es este turno?', fr: 'Pour quel emploi est ce quart ?', de: 'Für welchen Job ist diese Schicht?', ja: 'このシフトはどの仕事用ですか？', zh: '此班次属于哪个工作？', it: 'Per quale lavoro è questo turno?');
  String get pickOne => _t('Pick one.', ne: 'एउटा छान्नुहोस्।', es: 'Elige uno.', fr: 'Choisissez-en un.', de: 'Wählen Sie einen aus.', ja: '選択してください。', zh: '请选择一个。', it: 'Scegline uno.');
  String get scheduleRoster => _t('Schedule Roster', ne: 'सिफ्ट तालिका', es: 'Programación de Turnos', fr: 'Planning des Quarts', de: 'Dienstplan', ja: 'シフト計画', zh: '排班日程', it: 'Programmazione Turni');
  String get weeklyRecurring => _t('Weekly Recurring', ne: 'साप्ताहिक दोहोरिने', es: 'Semanal Recurrente', fr: 'Récurrent hebdomadaire', de: 'Wöchentlich wiederholend', ja: '毎週の繰り返し', zh: '每周重复', it: 'Ricorrenza settimanale');
  String get specificDates => _t('Specific Dates', ne: 'निश्चित मितिहरू', es: 'Fechas Específicas', fr: 'Dates spécifiques', de: 'Bestimmte Termine', ja: '指定日', zh: '特定日期', it: 'Date specifiche');
  String get whichWeekdaysWork => _t('1. Which weekdays do you work?', ne: '१. कुन बार काम गर्नुहुन्छ?', es: '1. ¿Qué días de la semana trabajas?', fr: '1. Quels jours travaillez-vous ?', de: '1. An welchen Wochentagen arbeiten Sie?', ja: '1. 勤務する曜日を選択', zh: '1. 您在周几工作？', it: '1. Quali giorni lavori?');
  String get howManyWeeksSchedule => _t('2. How many weeks to schedule?', ne: '२. कति हप्ताको तालिका बनाउने?', es: '2. ¿Cuántas semanas programar?', fr: '2. Combien de semaines planifier ?', de: '2. Wie viele Wochen planen?', ja: '2. 計画する週数を選択', zh: '2. 计划排班几周？', it: '2. Quante settimane vuoi programmare?');
  String get whatTimeAreShifts => _t('What time are the shifts?', ne: 'सिफ्टको समय कति हो?', es: '¿A qué hora son los turnos?', fr: 'À quelle heure sont les quarts ?', de: 'Um welche Uhrzeit sind die Schichten?', ja: 'シフトの時間帯は？', zh: '排班时间是几点？', it: 'A che ora sono i turni?');
  String get starts => _t('Starts', ne: 'सुरु', es: 'Empieza', fr: 'Début', de: 'Beginn', ja: '開始', zh: '开始', it: 'Inizio');
  String get ends => _t('Ends', ne: 'समाप्त', es: 'Termina', fr: 'Fin', de: 'Ende', ja: '終了', zh: '结束', it: 'Fine');
  String get breakDuration => _t('Break duration', ne: 'विश्राम समय', es: 'Duración del descanso', fr: 'Durée de la pause', de: 'Pausendauer', ja: '休憩時間', zh: '休息时长', it: 'Durata pausa');
  String get noBreak => _t('No break', ne: 'विश्राम छैन', es: 'Sin descanso', fr: 'Sans pause', de: 'Keine Pause', ja: '休憩なし', zh: '无休息', it: 'Nessuna pausa');
  String minsBreak(int mins) => _t('${mins}m break', ne: '$mins मिनेट', es: '$mins min descanso', fr: 'Pause de $mins min', de: '$mins Min Pause', ja: '$mins 分休憩', zh: '$mins 分钟休息', it: 'Pausa di $mins min');
  String get fixedEnd => _t('Fixed end', ne: 'निश्चित समाप्त समय', es: 'Fin fijo', fr: 'Fin fixe', de: 'Festes Ende', ja: '固定終了時刻', zh: '固定下班时间', it: 'Fine fissa');
  String get shiftEndsAutomatically => _t('Shift ends automatically at selected time', ne: 'तोकिएको समयमा सिफ्ट स्वतः समाप्त हुनेछ', es: 'El turno finaliza automáticamente a la hora seleccionada', fr: 'Le quart se termine automatiquement à l\'heure choisie', de: 'Schicht endet automatisch zur gewählten Zeit', ja: '選択した時刻に自動的にシフトが終了します', zh: '在选定时间自动下班', it: 'Il turno termina automaticamente all\'ora stabilita');
  String get shiftContinuesUntilEnd => _t('Shift continues until you end it', ne: 'सिफ्ट समाप्त नभएसम्म चालु रहनेछ', es: 'El turno continúa hasta que lo finalices', fr: 'Le quart continue jusqu\'à ce que vous le terminiez', de: 'Schicht läuft bis zur manuellen Beendigung', ja: '手動で終了するまでシフトが継続します', zh: '持续计时直到您手动下班', it: 'Il turno prosegue finché non lo chiudi tu');
  String get shiftHourlyRatePricing => _t('Shift Hourly Rate & Pricing', ne: 'सिफ्ट घण्टा दर / मूल्य निर्धारण', es: 'Tarifa Horaria y Precios del Turno', fr: 'Tarif Horaire et Tarification du Quart', de: 'Stundensatz & Preisgestaltung der Schicht', ja: 'シフト時給と料金設定', zh: '班次时薪与费率设置', it: 'Tariffa oraria e prezzi turno');
  String get customRateActive => _t('Custom rate active for this shift', ne: 'यस सिफ्टको लागि विशेष दर लागू', es: 'Tarifa personalizada activa para este turno', fr: 'Tarif personnalisé actif pour ce quart', de: 'Individueller Satz für diese Schicht aktiv', ja: 'このシフトにカスタムレートが適用されています', zh: '此班次使用自定义时薪', it: 'Tariffa personalizzata attiva');
  String get standardJobRateActive => _t('Standard job rate active', ne: 'मानक रोजगार दर प्रयोग भइरहेको छ', es: 'Tarifa estándar del empleo activa', fr: 'Tarif standard de l\'emploi actif', de: 'Standard-Jobsatz aktiv', ja: '標準の職種時給が適用されています', zh: '使用岗位标准时薪', it: 'Tariffa standard attiva');
  String get quickRatePreset => _t('Quick rate preset', ne: 'छिटो दर छनोट', es: 'Ajuste rápido de tarifa', fr: 'Préréglage rapide', de: 'Schnellvorwahl Satz', ja: 'クイックレート設定', zh: '快捷费率预设', it: 'Preimpostazione rapida tariffa');
  String get baseRate => _t('Base rate', ne: 'आधार दर', es: 'Tarifa base', fr: 'Tarif de base', de: 'Basissatz', ja: '基本時給', zh: '基础时薪', it: 'Tariffa base');
  String get applyOvertimePricing => _t('Apply overtime pricing', ne: 'ओभरटाइम दर लागू गर्नुहोस्', es: 'Aplicar tarifa de horas extras', fr: 'Appliquer tarif heures sup', de: 'Überstundensatz anwenden', ja: '残業割増を適用', zh: '启用加班费率', it: 'Applica tariffa straordinari');
  String get overtimeMultiplierLabel => _t('Multiplier (e.g. 1.5x)', ne: 'गुणक (जस्तै १.५x)', es: 'Multiplicador (ej. 1.5x)', fr: 'Multiplicateur (ex. 1.5x)', de: 'Multiplikator (z.B. 1,5x)', ja: '倍率（例: 1.5倍）', zh: '加班倍率（例如 1.5x）', it: 'Moltiplicatore (es. 1.5x)');
  String fixedRateWithCurrency(String code) => _t('Fixed Rate ($code/hr)', ne: 'निश्चित दर ($code/घण्टा)', es: 'Tarifa fija ($code/h)', fr: 'Tarif fixe ($code/h)', de: 'Festsatz ($code/Std.)', ja: '固定時給 ($code/時間)', zh: '固定费率 ($code/小时)', it: 'Tariffa fissa ($code/ora)');
  String get overtimeBeginsAfter => _t('Overtime begins after', ne: 'ओभरटाइम सुरु हुने घण्टा', es: 'Horas extras inician tras', fr: 'Heures sup après', de: 'Überstunden ab', ja: '残業適用開始時間', zh: '加班开始于满', it: 'Straordinari a partire da');
  String get overtimeMultiplier => _t('Overtime multiplier', ne: 'ओभरटाइम गुणक', es: 'Multiplicador de horas extras', fr: 'Multiplicateur d\'heures sup', de: 'Überstunden-Multiplikator', ja: '残業倍率', zh: '加班倍数', it: 'Moltiplicatore straordinari');
  String get fixedOvertimeRate => _t('Fixed overtime rate', ne: 'ओभरटाइम निश्चित दर', es: 'Tarifa fija de horas extras', fr: 'Tarif fixe heures sup', de: 'Fester Überstundensatz', ja: '固定残業時給', zh: '固定加班时薪', it: 'Tariffa fissa straordinari');
  String get hoursPerShift => _t('Hours per shift', ne: 'प्रति सिफ्ट घण्टा', es: 'Horas por turno', fr: 'Heures par quart', de: 'Stunden pro Schicht', ja: '1シフトあたりの時間', zh: '每班工作时长', it: 'Ore per turno');
  String get estPayPerShift => _t('Est. pay per shift', ne: 'प्रति सिफ्ट अनुमानित कमाइ', es: 'Pago estimado por turno', fr: 'Paie estimée par quart', de: 'Geschätzter Lohn pro Schicht', ja: 'シフトごとの推定給与', zh: '每班预估收入', it: 'Paga stimata per turno');
  String get totalProjectedEarnings => _t('Total projected earnings', ne: 'कुल अनुमानित कमाइ', es: 'Ganancias totales proyectadas', fr: 'Gains totaux prévus', de: 'Gesamte geschätzte Einnahmen', ja: '合計推定収入', zh: '总预估预计收益', it: 'Guadagno totale stimato');
  String get pickDateFromCalendar => _t('Pick another date from calendar', ne: 'पात्रोबाट अर्को मिति छान्नुहोस्', es: 'Elegir otra fecha del calendario', fr: 'Choisir une autre date sur le calendrier', de: 'Anderes Datum aus Kalender wählen', ja: 'カレンダーから別の日付を選択', zh: '从日历中选择其他日期', it: 'Scegli un\'altra data dal calendario');
  String get noJobsYet => _t('No jobs yet', ne: 'कुनै काम छैन', es: 'Sin empleos aún', fr: 'Aucun emploi pour le moment', de: 'Noch keine Jobs', ja: '登録された仕事はありません', zh: '暂无工作', it: 'Nessun lavoro registrato');
  String get addJobBeforeShift => _t('You need to add a job before scheduling a shift.', ne: 'सिफ्ट तालिका बनाउन पहिले काम थप्नुपर्छ।', es: 'Debes añadir un empleo antes de programar un turno.', fr: 'Vous devez ajouter un emploi avant de planifier un quart.', de: 'Fügen Sie einen Job hinzu, bevor Sie eine Schicht planen.', ja: 'シフトを計画する前に仕事を追加してください。', zh: '在排班前需先添加一项工作。', it: 'Devi aggiungere un lavoro prima di programmare un turno.');

  // Transaction Wizard Localizations
  String get howMuchWasIt => _t('How much was it?', ne: 'रकम कति हो?', es: '¿Cuánto fue?', fr: 'Quel était le montant ?', de: 'Wie hoch war der Betrag?', ja: '金額はいくらですか？', zh: '金额是多少？', it: 'Quanto è stato speso?');
  String get whatWasItFor => _t('What was it for?', ne: 'के को लागि थियो?', es: '¿Para qué fue?', fr: 'C\'était pour quoi ?', de: 'Wofür war es?', ja: '何のための支払いでしたか？', zh: '这是什么支出？', it: 'A cosa serviva?');
  String get pickCategoryAndSpent => _t('Pick a category and where you spent it.', ne: 'वर्ग र व्यापारी छान्नुहोस्।', es: 'Elige una categoría y el lugar del gasto.', fr: 'Choisissez une catégorie et le lieu de dépense.', de: 'Kategorie und Händler wählen.', ja: 'カテゴリーと利用先を選択してください。', zh: '选择分类和消费商户。', it: 'Scegli categoria ed esercente.');
  String get merchantName => _t('Merchant name', ne: 'व्यापारी वा पसल', es: 'Comercio / Tienda', fr: 'Commerçant', de: 'Händler', ja: '店舗・利用先名', zh: '商户名称', it: 'Esercente');
  String get merchantHint => _t('e.g. Local Bakery', ne: 'जस्तै: स्थानीय बेकरी', es: 'ej. Panadería Local', fr: 'ex. Boulangerie', de: 'z.B. Bäckerei', ja: '例: ベーカリー', zh: '例如：超市、咖啡店', it: 'es. Panetteria');
  String get saving => _t('Saving...', ne: 'सुरक्षित गर्दै...', es: 'Guardando...', fr: 'Enregistrement...', de: 'Speichern...', ja: '保存中...', zh: '正在保存...', it: 'Salvataggio...');
  String get saveExpense => _t('Save expense', ne: 'खर्च सेभ गर्नुहोस्', es: 'Guardar gasto', fr: 'Enregistrer la dépense', de: 'Ausgabe speichern', ja: '支出を保存', zh: '保存支出', it: 'Salva spesa');
  String get saveIncome => _t('Save income', ne: 'आम्दानी सेभ गर्नुहोस्', es: 'Guardar ingreso', fr: 'Enregistrer le revenu', de: 'Einnahme speichern', ja: '収入を保存', zh: '保存收入', it: 'Salva entrata');
  String get expenseAdded => _t('Expense added', ne: 'खर्च थपियो', es: 'Gasto añadido', fr: 'Dépense ajoutée', de: 'Ausgabe hinzugefügt', ja: '支出を追加しました', zh: '已记录支出', it: 'Spesa aggiunta');
  String get incomeAdded => _t('Income added', ne: 'आम्दानी थपियो', es: 'Ingreso añadido', fr: 'Revenu ajouté', de: 'Einnahme hinzugefügt', ja: '収入を追加しました', zh: '已记录收入', it: 'Entrata aggiunta');
  String get enterValidAmount => _t('Please enter a valid amount', ne: 'कृपया मान्य रकम प्रविष्ट गर्नुहोस्', es: 'Por favor ingrese un monto válido', fr: 'Veuillez saisir un montant valide', de: 'Bitte geben Sie einen gültigen Betrag ein', ja: '有効な金額を入力してください', zh: '请输入有效金额', it: 'Inserisci un importo valido');
  String get enterMerchantName => _t('Please enter a merchant name', ne: 'कृपया व्यापारी वा पसलको नाम प्रविष्ट गर्नुहोस्', es: 'Por favor ingrese un comercio', fr: 'Veuillez saisir un nom de commerçant', de: 'Bitte geben Sie einen Händlernamen ein', ja: '店舗名を入力してください', zh: '请输入商户名称', it: 'Inserisci il nome dell\'esercente');
  String get insufficientBalance => _t('Insufficient balance', ne: 'अपर्याप्त ब्यालेन्स', es: 'Saldo insuficiente', fr: 'Solde insuffisant', de: 'Unzureichendes Guthaben', ja: '残高不足', zh: '余额不足', it: 'Saldo insufficiente');
  String insufficientBalanceMessage(String formattedBalance) => _t('Insufficient balance: Only $formattedBalance available in this account.', ne: 'अपर्याप्त ब्यालेन्स: यस खातामा मात्र $formattedBalance उपलब्ध छ।', es: 'Saldo insuficiente: Solo $formattedBalance disponible en esta cuenta.', fr: 'Solde insuffisant : Seulement $formattedBalance disponible sur ce compte.', de: 'Unzureichendes Guthaben: Nur $formattedBalance auf diesem Konto verfügbar.', ja: '残高不足: この口座には $formattedBalance のみ利用可能です。', zh: '余额不足：此账户仅剩 $formattedBalance 可用。', it: 'Saldo insufficiente: Solo $formattedBalance disponibile su questo conto.');
  String get exchangeRate => _t('Rate', ne: 'विनिमय दर', es: 'Tipo de cambio', fr: 'Taux', de: 'Wechselkurs', ja: '為替レート', zh: '汇率', it: 'Tasso');
  String get discardExpense => _t('Discard this expense?', ne: 'यो खर्च खारेज गर्ने?', es: '¿Descartar este gasto?', fr: 'Abandonner cette dépense ?', de: 'Diese Ausgabe verwerfen?', ja: 'この支出を破棄しますか？', zh: '放弃此支出？', it: 'Annullare questa spesa?');
  String get discardIncome => _t('Discard this income?', ne: 'यो आम्दानी खारेज गर्ने?', es: '¿Descartar este ingreso?', fr: 'Abandonner ce revenu ?', de: 'Diese Einnahme verwerfen?', ja: 'この収入を破棄しますか？', zh: '放弃此收入？', it: 'Annullare questa entrata?');
  String get tomorrow => _t('Tomorrow', ne: 'भोलि', es: 'Mañana', fr: 'Demain', de: 'Morgen', ja: '明日', zh: '明天', it: 'Domani');
  String get weekdaysLabel => _t('Weekdays', ne: 'कामका दिनहरू', es: 'Días laborales', fr: 'Jours de semaine', de: 'Wochentage', ja: '平日', zh: '工作日', it: 'Giorni feriali');
  String get next7Days => _t('Next 7 days', ne: 'आगामी ७ दिन', es: 'Próximos 7 días', fr: '7 prochains jours', de: 'Nächste 7 Tage', ja: '今後7日間', zh: '未来7天', it: 'Prossimi 7 giorni');
  String get hoursUnit => _t('hours', ne: 'घण्टा', es: 'horas', fr: 'heures', de: 'Stunden', ja: '時間', zh: '小时', it: 'ore');
  String get minsUnit => _t('mins', ne: 'मिनेट', es: 'min', fr: 'min', de: 'Min.', ja: '分', zh: '分钟', it: 'min');
  String convertedIn(String code) => _t('Converted in $code', ne: '$code मा रूपान्तरित', es: 'Convertido en $code', fr: 'Converti en $code', de: 'Umgerechnet in $code', ja: '$code 換算', zh: '折合 $code', it: 'Convertito in $code');
  String shiftsScheduled(int count) => _t('$count ${count == 1 ? "shift" : "shifts"} scheduled', ne: '$count सिफ्ट तालिका बनाइयो', es: '$count turnos programados', fr: '$count quarts planifiés', de: '$count Schichten geplant', ja: '$count 件のシフトを予定', zh: '已安排 $count 个班次', it: '$count turni programmati');

  String weekdayShort(int day) {
    switch (day) {
      case 1:
        return _t('Mon', ne: 'सोम', es: 'Lun', fr: 'Lun', de: 'Mo', ja: '月', zh: '周一', it: 'Lun');
      case 2:
        return _t('Tue', ne: 'मङ्गल', es: 'Mar', fr: 'Mar', de: 'Di', ja: '火', zh: '周二', it: 'Mar');
      case 3:
        return _t('Wed', ne: 'बुध', es: 'Mié', fr: 'Mer', de: 'Mi', ja: '水', zh: '周三', it: 'Mer');
      case 4:
        return _t('Thu', ne: 'बिही', es: 'Jue', fr: 'Jeu', de: 'Do', ja: '木', zh: '周四', it: 'Gio');
      case 5:
        return _t('Fri', ne: 'शुक्र', es: 'Vie', fr: 'Ven', de: 'Fr', ja: '金', zh: '周五', it: 'Ven');
      case 6:
        return _t('Sat', ne: 'शनि', es: 'Sáb', fr: 'Sam', de: 'Sa', ja: '土', zh: '周六', it: 'Sab');
      case 7:
        return _t('Sun', ne: 'आइत', es: 'Dom', fr: 'Dim', de: 'So', ja: '日', zh: '周日', it: 'Dom');
      default:
        return '';
    }
  }

  String horizonOption(int weeks) {
    switch (weeks) {
      case 2:
        return _t('2 weeks', ne: '२ हप्ता', es: '2 semanas', fr: '2 semaines', de: '2 Wochen', ja: '2週間', zh: '2周', it: '2 settimane');
      case 4:
        return _t('4 weeks (1 mo)', ne: '४ हप्ता (१ महिना)', es: '4 semanas (1 m)', fr: '4 semaines (1 m)', de: '4 Wochen (1 M)', ja: '4週間 (1ヶ月)', zh: '4周 (1个月)', it: '4 settimane (1 m)');
      case 8:
        return _t('8 weeks (2 mo)', ne: '८ हप्ता (२ महिना)', es: '8 semanas (2 m)', fr: '8 semaines (2 m)', de: '8 Wochen (2 M)', ja: '8週間 (2ヶ月)', zh: '8周 (2个月)', it: '8 settimane (2 m)');
      case 12:
        return _t('12 weeks (3 mo)', ne: '१२ हप्ता (३ महिना)', es: '12 semanas (3 m)', fr: '12 semaines (3 m)', de: '12 Wochen (3 M)', ja: '12週間 (3ヶ月)', zh: '12周 (3个月)', it: '12 settimane (3 m)');
      case 26:
        return _t('26 weeks (6 mo)', ne: '२६ हप्ता (६ महिना)', es: '26 semanas (6 m)', fr: '26 semaines (6 m)', de: '26 Wochen (6 M)', ja: '26週間 (半年)', zh: '26周 (半年)', it: '26 settimane (6 m)');
      case 52:
        return _t('52 weeks (1 yr)', ne: '५२ हप्ता (१ वर्ष)', es: '52 semanas (1 año)', fr: '52 semaines (1 an)', de: '52 Wochen (1 J)', ja: '52週間 (1年)', zh: '52周 (1年)', it: '52 settimane (1 anno)');
      default:
        return '$weeks w';
    }
  }

  String get shiftsAndJobs => _t('Shifts and jobs', ne: 'सिफ्ट र काम', es: 'Turnos y empleos', fr: 'Quarts et emplois', de: 'Schichten und Jobs', ja: 'シフトと仕事', zh: '班次与工作', it: 'Turni e lavori');
  String get onBreakTimerPaused => _t('On break (Timer paused)', ne: 'विश्राममा (समय रोकिएको)', es: 'En descanso (temporizador en pausa)', fr: 'En pause (minuteur suspendu)', de: 'In der Pause (Timer pausiert)', ja: '休憩中 (タイマー一時停止)', zh: '休息中（计时暂停）', it: 'In pausa (timer fermato)');
  String get inProgress => _t('In progress', ne: 'सक्रिय छ', es: 'En curso', fr: 'En cours', de: 'In Bearbeitung', ja: '進行中', zh: '进行中', it: 'In corso');
  String get viewLiveShift => _t('View live shift', ne: 'प्रत्यक्ष सिफ्ट हेर्नुहोस्', es: 'Ver turno en vivo', fr: 'Voir le quart en direct', de: 'Live-Schicht ansehen', ja: '現在のシフトを表示', zh: '查看当前进行班次', it: 'Vedi turno in diretta');
  String get addJobToTrack => _t('Add a job to start tracking shifts and pay.', ne: 'सिफ्ट र कमाइ ट्र्याक गर्न काम थप्नुहोस्।', es: 'Añade un empleo para registrar turnos y pagos.', fr: 'Ajoutez un travail pour suivre quarts et paie.', de: 'Fügen Sie einen Job hinzu, um Schichten zu erfassen.', ja: 'シフトと給与を記録するために仕事を追加してください。', zh: '添加工作以开始记录工时与薪资。', it: 'Aggiungi un lavoro per monitorare turni e paga.');
  String get whichJobStarting => _t('Which job are you starting?', ne: 'कुन काम सुरु गर्दै हुनुहुन्छ?', es: '¿Qué empleo estás empezando?', fr: 'Quel travail commencez-vous ?', de: 'Welchen Job beginnen Sie?', ja: 'どの仕事を始めますか？', zh: '您要开始哪项工作？', it: 'Quale lavoro stai iniziando?');
  String get hoursThisWeek => _t('Hours this week', ne: 'यस हप्ताका घण्टा', es: 'Horas esta semana', fr: 'Heures cette semaine', de: 'Stunden diese Woche', ja: '今週の労働時間', zh: '本周工时', it: 'Ore questa settimana');
  String get shiftsLeft => _t('Shifts left', ne: 'बाँकी सिफ्टहरू', es: 'Turnos restantes', fr: 'Quarts restants', de: 'Verbleibende Schichten', ja: '残りシフト数', zh: '剩余班次', it: 'Turni rimanenti');
  String get todayShifts => _t('Today\'s shifts', ne: 'आजका सिफ्टहरू', es: 'Turnos de hoy', fr: 'Quarts d\'aujourd\'hui', de: 'Heutige Schichten', ja: '本日のシフト', zh: '今日班次', it: 'Turni di oggi');
  String get scheduled => _t('Scheduled', ne: 'तालिकाबद्ध', es: 'Programado', fr: 'Planifié', de: 'Geplant', ja: '予定', zh: '已安排', it: 'Programmato');
  String get completed => _t('Completed', ne: 'सम्पन्न', es: 'Completado', fr: 'Terminé', de: 'Abgeschlossen', ja: '完了', zh: '已完成', it: 'Completato');
  String get noShiftsForToday => _t('No shifts for today', ne: 'आज कुनै सिफ्ट छैन', es: 'Sin turnos para hoy', fr: 'Aucun quart aujourd\'hui', de: 'Heute keine Schichten', ja: '本日のシフトはありません', zh: '今天无排班', it: 'Nessun turno oggi');
  String get viewAllInCalendar => _t('View all in Calendar', ne: 'पात्रोमा सबै हेर्नुहोस्', es: 'Ver todo en el calendario', fr: 'Tout voir dans le calendrier', de: 'Alle im Kalender ansehen', ja: 'カレンダーで全て見る', zh: '在日历中查看全部', it: 'Vedi tutto nel calendario');
  String get viewFullScheduleInCalendar => _t('View full schedule in Calendar →', ne: 'पात्रोमा पूरा तालिका हेर्नुहोस् →', es: 'Ver programación completa en Calendario →', fr: 'Voir le planning complet dans le Calendrier →', de: 'Vollständigen Dienstplan im Kalender ansehen →', ja: 'カレンダーで全スケジュールを見る →', zh: '在日历中查看完整排班 →', it: 'Vedi programma completo nel calendario →');
  String get duration => _t('Duration', ne: 'समय अवधि', es: 'Duración', fr: 'Durée', de: 'Dauer', ja: '期間', zh: '时长', it: 'Durata');
  String get breakTime => _t('Break time', ne: 'विश्राम समय', es: 'Tiempo de descanso', fr: 'Temps de pause', de: 'Pausenzeit', ja: '休憩時間', zh: '休息时间', it: 'Tempo di pausa');
  String get hourlyRate => _t('Hourly rate', ne: 'घण्टाको दर', es: 'Tarifa horaria', fr: 'Taux horaire', de: 'Stundensatz', ja: '時給', zh: '时薪', it: 'Tariffa oraria');
  String get earnedTotal => _t('Earned total', ne: 'कुल कमाइ', es: 'Total ganado', fr: 'Total gagné', de: 'Gesamtverdienst', ja: '総獲得額', zh: '已获总收入', it: 'Totale guadagnato');
  String get projectedPay => _t('Projected pay', ne: 'अनुमानित कमाइ', es: 'Pago proyectado', fr: 'Paie prévue', de: 'Geschätzter Lohn', ja: '推定給与', zh: '预计收入', it: 'Paga prevista');
  String get notes => _t('Notes', ne: 'कैफियत', es: 'Notas', fr: 'Notes', de: 'Notizen', ja: 'メモ', zh: '备注', it: 'Note');
  String get startShiftNow => _t('Start shift now', ne: 'अहिले सिफ्ट सुरु गर्नुहोस्', es: 'Comenzar turno ahora', fr: 'Démarrer le quart maintenant', de: 'Schicht jetzt starten', ja: '今すぐシフトを開始', zh: '现在开工', it: 'Inizia turno adesso');
  String get markAsCompleted => _t('Mark as completed', ne: 'सम्पन्न भएको चिन्ह लगाउनुहोस्', es: 'Marcar como completado', fr: 'Marquer comme terminé', de: 'Als abgeschlossen markieren', ja: '完了としてマーク', zh: '标记为已完成', it: 'Segna come completato');
  String get shiftMarkedCompleted => _t('Shift marked as completed', ne: 'सिफ्ट सम्पन्न भएको चिन्ह लगाइयो', es: 'Turno marcado como completado', fr: 'Quart marqué comme terminé', de: 'Schicht als abgeschlossen markiert', ja: 'シフトを完了として記録しました', zh: '班次已标记为完成', it: 'Turno segnato come completato');
  String get editShift => _t('Edit shift', ne: 'सिफ्ट सम्पादन', es: 'Editar turno', fr: 'Modifier le quart', de: 'Schicht bearbeiten', ja: 'シフトを編集', zh: '编辑班次', it: 'Modifica turno');
  String get deleteThisShift => _t('Delete this shift?', ne: 'यो सिफ्ट हटाउने?', es: '¿Eliminar este turno?', fr: 'Supprimer ce quart ?', de: 'Diese Schicht löschen?', ja: 'このシフトを削除しますか？', zh: '删除此班次？', it: 'Eliminare questo turno?');
  String get shiftDeleted => _t('Shift deleted', ne: 'सिफ्ट हटाइयो', es: 'Turno eliminado', fr: 'Quart supprimé', de: 'Schicht gelöscht', ja: 'シフトを削除しました', zh: '班次已删除', it: 'Turno eliminato');
  String get date => _t('Date', ne: 'मिति', es: 'Fecha', fr: 'Date', de: 'Datum', ja: '日付', zh: '日期', it: 'Data');
  String get status => _t('Status', ne: 'स्थिति', es: 'Estado', fr: 'Statut', de: 'Status', ja: 'ステータス', zh: '状态', it: 'Stato');
  String get breakMinutesLabel => _t('Break (minutes)', ne: 'विश्राम (मिनेट)', es: 'Descanso (minutos)', fr: 'Pause (minutes)', de: 'Pause (Minuten)', ja: '休憩（分）', zh: '休息（分钟）', it: 'Pausa (minuti)');
  String get notesOptional => _t('Notes (optional)', ne: 'कैफियत (वैकल्पिक)', es: 'Notas (opcional)', fr: 'Notes (facultatif)', de: 'Notizen (optional)', ja: 'メモ（任意）', zh: '备注（选填）', it: 'Note (opzionale)');
  String get notesHint => _t('Add note about this shift', ne: 'यस सिफ्टको बारेमा टिपोट थप्नुहोस्', es: 'Añadir nota sobre este turno', fr: 'Ajouter une note sur ce quart', de: 'Notiz zu dieser Schicht hinzufügen', ja: 'このシフトのメモを追加', zh: '添加关于此班次的备注', it: 'Aggiungi una nota su questo turno');
  String get shiftUpdatedSuccess => _t('Shift updated successfully', ne: 'सिफ्ट अद्यावधिक गरियो', es: 'Turno actualizado con éxito', fr: 'Quart mis à jour avec succès', de: 'Schicht erfolgreich aktualisiert', ja: 'シフトを更新しました', zh: '班次更新成功', it: 'Turno aggiornato con successo');
  String get saveChanges => _t('Save changes', ne: 'परिवर्तन सुरक्षित गर्नुहोस्', es: 'Guardar cambios', fr: 'Enregistrer les modifications', de: 'Änderungen speichern', ja: '変更を保存', zh: '保存修改', it: 'Salva modifiche');

  String get addNewJob => _t('Add new job', ne: 'नयाँ काम थप्नुहोस्', es: 'Añadir nuevo empleo', fr: 'Ajouter un travail', de: 'Neuen Job hinzufügen', ja: '新しい仕事を追加', zh: '添加新工作', it: 'Aggiungi nuovo lavoro');
  String get createWorkspace => _t('Create workspace', ne: 'जागिर सिर्जना', es: 'Crear empleo', fr: 'Créer un espace', de: 'Arbeitsbereich erstellen', ja: '職場を作成', zh: '创建工作', it: 'Crea lavoro');
  String get noJobsFound => _t('No jobs found', ne: 'कुनै रोजगार फेला परेन', es: 'No se encontraron empleos', fr: 'Aucun emploi trouvé', de: 'Keine Jobs gefunden', ja: '仕事が見つかりません', zh: '未找到工作', it: 'Nessun lavoro trovato');
  String get clockIn => _t('Clock In', ne: 'सिफ्ट सुरु', es: 'Fichar entrada', fr: 'Pointer l\'entrée', de: 'Einstempeln', ja: '出勤打刻', zh: '上班打卡', it: 'Inizia turno');
  String get manageJobs => _t('Manage jobs', ne: 'काम व्यवस्थापन', es: 'Gestionar empleos', fr: 'Gérer les emplois', de: 'Jobs verwalten', ja: '仕事を管理', zh: '管理工作', it: 'Gestisci lavori');
  String get startYourShift => _t('Start your shift', ne: 'आफ्नो सिफ्ट सुरु गर्नुहोस्', es: 'Inicia tu turno', fr: 'Démarrez votre quart', de: 'Starten Sie Ihre Schicht', ja: 'シフトを開始する', zh: '开启您的班次', it: 'Inizia il tuo turno');
  String get selectWhichJobClocking => _t('Select which job you are clocking into today.', ne: 'आज कुन काम सुरु गर्दै हुनुहुन्छ चयन गर्नुहोस्।', es: 'Selecciona qué empleo estás comenzando hoy.', fr: 'Sélectionnez le travail que vous commencez aujourd\'hui.', de: 'Wählen Sie den Job aus, den Sie heute beginnen.', ja: '本日出勤する仕事を選択してください。', zh: '选择您今天上班的工作。', it: 'Seleziona quale lavoro stai iniziando oggi.');
  String get workplace => _t('Workplace', ne: 'कार्यस्थल', es: 'Lugar de trabajo', fr: 'Lieu de travail', de: 'Arbeitsplatz', ja: '勤務先', zh: '工作地点', it: 'Luogo di lavoro');
  String get clockInTime => _t('Clock in time', ne: 'सुरु भएको समय', es: 'Hora de entrada', fr: 'Heure de pointage', de: 'Einstempel-Zeit', ja: '出勤時刻', zh: '打卡时间', it: 'Orario di inizio');
  String get liveBadge => _t('LIVE', ne: 'प्रत्यक्ष', es: 'EN VIVO', fr: 'EN DIRECT', de: 'LIVE', ja: '稼働中', zh: '进行中', it: 'LIVE');
  String get remindMeClockOut => _t('Remind me to clock out', ne: 'सिफ्ट समाप्त गर्ने स्मरण गराउनुहोस्', es: 'Recordarme fichar salida', fr: 'Me rappeler de pointer la sortie', de: 'An Ausstempeln erinnern', ja: '退勤打刻をリマインド', zh: '提醒我下班打卡', it: 'Ricordami di uscire');
  String get alertAfter6Hours => _t('Alert after 6 hours on shift', ne: 'सिफ्ट सुरु भएको ६ घण्टापछि सूचना', es: 'Alerta tras 6 horas de turno', fr: 'Alerte après 6 heures de quart', de: 'Benachrichtigung nach 6 Stunden Schicht', ja: 'シフト開始6時間後に通知', zh: '开工6小时后提醒', it: 'Avviso dopo 6 ore di turno');
  String clockInAs(String name) => _t('Clock In as $name', ne: '$name मा सिफ्ट सुरु', es: 'Fichar entrada en $name', fr: 'Pointer pour $name', de: 'Einstempeln für $name', ja: '$name で出勤', zh: '在 $name 上班打卡', it: 'Inizia per $name');
  String get liveShift => _t('Live Shift', ne: 'प्रत्यक्ष सिफ्ट', es: 'Turno en Vivo', fr: 'Quart en direct', de: 'Aktuelle Schicht', ja: '現在のシフト', zh: '实时班次', it: 'Turno in diretta');
  String get notCurrentlyClockedIn => _t('You are not currently clocked into a shift.', ne: 'तपाईं हाल कुनै सिफ्टमा सक्रिय हुनुहुन्न।', es: 'Actualmente no has fichado en ningún turno.', fr: 'Vous n\'êtes actuellement pas en quart.', de: 'Sie sind derzeit nicht eingestempelt.', ja: '現在進行中のシフトはありません。', zh: '您目前未处于上班打卡状态。', it: 'Al momento non sei in turno.');
  String get editStartTime => _t('Edit start time', ne: 'सुरु समय सम्पादन', es: 'Editar hora de inicio', fr: 'Modifier l\'heure de début', de: 'Startzeit bearbeiten', ja: '開始時刻を編集', zh: '修改上班时间', it: 'Modifica ora di inizio');
  String startedAt(String time) => _t('Started $time', ne: 'सुरु भयो: $time', es: 'Iniciado $time', fr: 'Commencé à $time', de: 'Gestartet um $time', ja: '開始: $time', zh: '开始于 $time', it: 'Iniziato alle $time');
  String get onBreakTimerPausedUpper => _t('On Break · Timer Paused', ne: 'विश्राममा · समय रोकियो', es: 'En descanso · Temporizador en pausa', fr: 'En pause · Minuteur suspendu', de: 'In der Pause · Timer pausiert', ja: '休憩中 · タイマー一時停止', zh: '休息中 · 计时暂停', it: 'In pausa · Timer fermato');
  String get endShiftNow => _t('End shift now?', ne: 'अहिले सिफ्ट समाप्त गर्ने?', es: '¿Terminar turno ahora?', fr: 'Terminer le quart maintenant ?', de: 'Schicht jetzt beenden?', ja: '今すぐシフトを終了しますか？', zh: '现在结束打卡下班？', it: 'Terminare il turno adesso?');
  String get keepWorking => _t('Keep working', ne: 'काम जारी राख्नुहोस्', es: 'Seguir trabajando', fr: 'Continuer à travailler', de: 'Weiterarbeiten', ja: '仕事を続ける', zh: '继续工作', it: 'Continua a lavorare');
  String get shiftComplete => _t('Shift Complete', ne: 'सिफ्ट सम्पन्न', es: 'Turno Completado', fr: 'Quart Terminé', de: 'Schicht beendet', ja: 'シフト完了', zh: '班次已完成', it: 'Turno completato');
  String get earned => _t('Earned', ne: 'कमाइ', es: 'Ganado', fr: 'Gagné', de: 'Verdient', ja: '獲得金額', zh: '已赚得', it: 'Guadagnato');

  // Categories & Merchants
  String get categoriesAndMerchants => _t('Categories & Merchants', ne: 'वर्ग र व्यापारीहरू', es: 'Categorías y Comercios', fr: 'Catégories et Commerçants', de: 'Kategorien & Händler', ja: 'カテゴリーと店舗', zh: '分类与商户', it: 'Categorie ed Esercenti');
  String get addCategory => _t('Add category', ne: 'नयाँ वर्ग', es: 'Añadir categoría', fr: 'Ajouter une catégorie', de: 'Kategorie hinzufügen', ja: 'カテゴリーを追加', zh: '添加分类', it: 'Aggiungi categoria');
  String get expenseCategories => _t('Expense Categories', ne: 'खर्च वर्गहरू', es: 'Categorías de Gastos', fr: 'Catégories de Dépenses', de: 'Ausgabenkategorien', ja: '支出カテゴリー', zh: '支出分类', it: 'Categorie di Spesa');
  String get incomeCategories => _t('Income Categories', ne: 'आम्दानी वर्गहरू', es: 'Categorías de Ingresos', fr: 'Catégories de Revenus', de: 'Einnahmekategorien', ja: '収入カテゴリー', zh: '收入分类', it: 'Categorie di Entrata');
  String get createCustomCategory => _t('Create Custom Category', ne: 'नयाँ वर्ग सिर्जना गर्नुहोस्', es: 'Crear categoría personalizada', fr: 'Créer une catégorie personnalisée', de: 'Eigene Kategorie erstellen', ja: 'カスタムカテゴリーを作成', zh: '创建自定义分类', it: 'Crea categoria personalizzata');
  String get categoryName => _t('Category name', ne: 'वर्गको नाम', es: 'Nombre de la categoría', fr: 'Nom de la catégorie', de: 'Kategoriename', ja: 'カテゴリー名', zh: '分类名称', it: 'Nome categoria');
  String get categoryNameHint => _t('e.g. Gym, Freelance, Subscriptions', ne: 'जस्तै: जिम, फ्रिलान्स, सदस्यता', es: 'ej. Gimnasio, Freelance, Suscripciones', fr: 'ex. Salle de sport, Freelance', de: 'z.B. Fitness, Freelance', ja: '例: ジム、副業、サブスク', zh: '例如：健身、自由职业、订阅', it: 'es. Palestra, Abbonamenti');
  String get saveCategory => _t('Save Category', ne: 'वर्ग सुरक्षित गर्नुहोस्', es: 'Guardar categoría', fr: 'Enregistrer la catégorie', de: 'Kategorie speichern', ja: 'カテゴリーを保存', zh: '保存分类', it: 'Salva categoria');
  String get pleaseEnterCategoryName => _t('Please enter a category name', ne: 'कृपया वर्गको नाम प्रविष्ट गर्नुहोस्', es: 'Por favor ingrese un nombre de categoría', fr: 'Veuillez saisir un nom de catégorie', de: 'Bitte geben Sie einen Kategorienamen ein', ja: 'カテゴリー名を入力してください', zh: '请输入分类名称', it: 'Inserisci un nome di categoria');
  String get addMerchant => _t('Add Merchant', ne: 'व्यापारी थप्नुहोस्', es: 'Añadir comercio', fr: 'Ajouter un commerçant', de: 'Händler hinzufügen', ja: '店舗を追加', zh: '添加商户', it: 'Aggiungi esercente');
  String get merchantOrPayee => _t('Merchant or Payee', ne: 'व्यापारी वा भुक्तानीकर्ता', es: 'Comercio o Destinatario', fr: 'Commerçant ou Bénéficiaire', de: 'Händler oder Zahlungsempfänger', ja: '店舗または支払先', zh: '商户或收款方', it: 'Esercente o Beneficiario');
  String get pleaseEnterName => _t('Please enter a name', ne: 'कृपया नाम प्रविष्ट गर्नुहोस्', es: 'Por favor ingrese un nombre', fr: 'Veuillez saisir un nom', de: 'Bitte geben Sie einen Namen ein', ja: '名前を入力してください', zh: '请输入名称', it: 'Inserisci un nome');
  String get categoryRemoved => _t('Category removed', ne: 'वर्ग हटाइयो', es: 'Categoría eliminada', fr: 'Catégorie supprimée', de: 'Kategorie entfernt', ja: 'カテゴリーを削除しました', zh: '分类已删除', it: 'Categoria rimossa');
  String get systemDefault => _t('System default', ne: 'प्रणालीगत', es: 'Predeterminado del sistema', fr: 'Par défaut', de: 'Systemstandard', ja: 'システム既定', zh: '系统默认', it: 'Predefinito');
  String get customCategory => _t('Custom category', ne: 'अनुकूलित वर्ग', es: 'Categoría personalizada', fr: 'Catégorie personnalisée', de: 'Benutzerdefinierte Kategorie', ja: 'カスタムカテゴリー', zh: '自定义分类', it: 'Categoria personalizzata');
  String get deleteCategory => _t('Delete category', ne: 'वर्ग मेटाउनुहोस्', es: 'Eliminar categoría', fr: 'Supprimer la catégorie', de: 'Kategorie löschen', ja: 'カテゴリーを削除', zh: '删除分类', it: 'Elimina categoria');
  String get addStore => _t('Add store', ne: 'पसल थप्नुहोस्', es: 'Añadir tienda', fr: 'Ajouter magasin', de: 'Geschäft hinzufügen', ja: '店舗を追加', zh: '添加店铺', it: 'Aggiungi negozio');

  // Accounts Localizations
  String get noAccountsYet => _t('No accounts yet', ne: 'कुनै खाता छैन', es: 'Sin cuentas aún', fr: 'Aucun compte', de: 'Noch keine Konten', ja: '登録された口座はありません', zh: '暂无账户', it: 'Nessun conto registrato');
  String get addAccountFillsIn => _t('Add an account and this fills in.', ne: 'खाता थप्नुहोस् र यो भरिनेछ।', es: 'Añade una cuenta y esto se completará.', fr: 'Ajoutez un compte et cette section se remplira.', de: 'Fügen Sie ein Konto hinzu, um diese Übersicht zu füllen.', ja: '口座を追加するとここに表示されます。', zh: '添加账户即可填充此区域。', it: 'Aggiungi un conto per completare questa sezione.');
  String get addAccountNetPositionReal => _t('Add an account so your balance and net position are real.', ne: 'आफ्नो मौज्दात र वास्तविक वित्तीय अवस्था हेर्न खाता थप्नुहोस्।', es: 'Añade una cuenta para reflejar tu saldo y patrimonio real.', fr: 'Ajoutez un compte pour afficher votre solde réel.', de: 'Fügen Sie ein Konto hinzu, damit Ihr Saldo stimmt.', ja: '正確な残高管理のために口座を追加してください。', zh: '添加账户以记录准确的资金与净资产।', it: 'Aggiungi un conto per vedere il tuo saldo reale.');
  String get totalAcrossAccounts => _t('Total across accounts', ne: 'खाताहरूको जम्मा मौज्दात', es: 'Total en cuentas', fr: 'Total des comptes', de: 'Gesamt über alle Konten', ja: '全口座の合計残高', zh: '各账户资金总计', it: 'Totale su tutti i conti');
  String get cash => _t('Cash', ne: 'नगद', es: 'Efectivo', fr: 'Espèces', de: 'Bargeld', ja: '現金', zh: '现金', it: 'Contanti');
  String get everydayAccount => _t('Everyday account', ne: 'दैनिक बैंक खाता', es: 'Cuenta diaria', fr: 'Compte courant', de: 'Alltagskonto', ja: '日常利用口座', zh: '日常消费账户', it: 'Conto corrente');
  String get digitalWallet => _t('Digital wallet', ne: 'डिजिटल वालेट', es: 'Billetera digital', fr: 'Portefeuille numérique', de: 'Digitale Geldbörse', ja: '電子マネー', zh: '电子钱包', it: 'Portafoglio digitale');
  String get savingsAccount => _t('Savings', ne: 'बचत खाता', es: 'Cuenta de ahorros', fr: 'Compte d\'épargne', de: 'Sparkonto', ja: '貯蓄口座', zh: '储蓄账户', it: 'Conto risparmio');
  String get pleaseEnterAccountName => _t('Please enter an account name', ne: 'कृपया खाताको नाम प्रविष्ट गर्नुहोस्', es: 'Por favor ingrese un nombre de cuenta', fr: 'Veuillez saisir un nom de compte', de: 'Bitte geben Sie einen Kontonamen ein', ja: '口座名を入力してください', zh: '请输入账户名称', it: 'Inserisci un nome per il conto');
  String get accountAdded => _t('Account added', ne: 'खाता सफलतापूर्वक थपियो', es: 'Cuenta añadida', fr: 'Compte ajouté', de: 'Konto hinzugefügt', ja: '口座を追加しました', zh: '账户已添加', it: 'Conto aggiunto');
  String get whatKindOfAccount => _t('What kind of account?', ne: 'कुन प्रकारको खाता हो?', es: '¿Qué tipo de cuenta?', fr: 'Quel type de compte ?', de: 'Welche Art von Konto?', ja: '口座の種類を選択', zh: '这是什么类型的账户？', it: 'Che tipo di conto?');
  String get startWithMostUsed => _t('Start with the one you use most.', ne: 'तपाईंले सबैभन्दा बढी प्रयोग गर्ने खाताबाट सुरु गर्नुहोस्।', es: 'Empieza con la que más usas.', fr: 'Commencez par celui que vous utilisez le plus.', de: 'Beginnen Sie mit dem am häufigsten genutzten Konto.', ja: '最もよく使う口座から始めましょう。', zh: '建议从最常用的账户开始。', it: 'Inizia con quello che usi di più.');
  String get moneyInYourPocket => _t('Money in your pocket', ne: 'तपाईंको खल्तीको रकम', es: 'Dinero en tu bolsillo', fr: 'Argent de poche', de: 'Bargeld in der Tasche', ja: 'お手元のお金', zh: '随身现金', it: 'Denaro in tasca');
  String get everydaySpending => _t('Everyday spending', ne: 'दैनिक कारोबार तथा भुक्तानीका लागि', es: 'Gastos del día a día', fr: 'Dépenses quotidiennes', de: 'Tägliche Ausgaben', ja: '毎日の支出用', zh: '日常开支', it: 'Spese quotidiane');
  String get appsAndCards => _t('Apps and cards', ne: 'ई-सेवा, खल्ती वा कार्डहरू', es: 'Tarjetas y apps', fr: 'Cartes et applications', de: 'Apps und Karten', ja: 'アプリ・決済カード', zh: '支付应用与银行卡', it: 'App e carte');
  String get moneySetAside => _t('Money set aside', ne: 'सुरक्षित छुट्याइएको रकम', es: 'Dinero reservado', fr: 'Argent mis de côté', de: 'Zurückgelegtes Geld', ja: '積み立てた貯金', zh: '专门留存的资金', it: 'Denaro accantonato');
  String get whatIsBalanceNow => _t('What is the balance right now?', ne: 'अहिलेको मौज्दात कति छ?', es: '¿Cuál es el saldo ahora?', fr: 'Quel est le solde actuel ?', de: 'Wie hoch ist der aktuelle Saldo?', ja: '現在の残高はいくらですか？', zh: '当前账户余额是多少？', it: 'Qual è il saldo attuale?');
  String get roughlyIsFine => _t('Roughly is fine. You can fix it later.', ne: 'अन्दाजी भए पनि हुन्छ, पछि मिलाउन सकिन्छ।', es: 'Un aproximado está bien. Puedes ajustarlo luego.', fr: 'Une estimation suffit. Modifiable plus tard.', de: 'Ein Schätzwert reicht. Sie können es später anpassen.', ja: '概算で構いません。後からいつでも修正できます。', zh: '大致数字即可，后续随时调整。', it: 'Anche approssimativo va bene. Puoi modificarlo dopo.');
  String get saveAccount => _t('Save account', ne: 'खाता सुरक्षित गर्नुहोस्', es: 'Guardar cuenta', fr: 'Enregistrer le compte', de: 'Konto speichern', ja: '口座を保存', zh: '保存账户', it: 'Salva conto');
  String get accountName => _t('Account name', ne: 'खाताको नाम', es: 'Nombre de la cuenta', fr: 'Nom du compte', de: 'Kontoname', ja: '口座名', zh: '账户名称', it: 'Nome conto');
  String get openingBalance => _t('Opening balance', ne: 'सुरुवाती मौज्दात', es: 'Saldo inicial', fr: 'Solde initial', de: 'Anfangssaldo', ja: '開始残高', zh: '期初余额', it: 'Saldo iniziale');
  String get editAccountDetails => _t('Edit account details', ne: 'खाता विवरण सम्पादन', es: 'Editar detalles de la cuenta', fr: 'Modifier les détails du compte', de: 'Kontodetails bearbeiten', ja: '口座情報を編集', zh: '编辑账户详情', it: 'Modifica dettagli conto');
  String get deleteAccount => _t('Delete account', ne: 'खाता मेटाउनुहोस्', es: 'Eliminar cuenta', fr: 'Supprimer le compte', de: 'Konto löschen', ja: '口座を削除', zh: '删除账户', it: 'Elimina conto');
  String get accountDeleted => _t('Account deleted', ne: 'खाता हटाइयो', es: 'Cuenta eliminada', fr: 'Compte supprimé', de: 'Konto gelöscht', ja: '口座を削除しました', zh: '账户已删除', it: 'Conto eliminato');
  String get accountUpdated => _t('Account updated', ne: 'खाता अद्यावधिक गरियो', es: 'Cuenta actualizada', fr: 'Compte mis à jour', de: 'Konto aktualisiert', ja: '口座を更新しました', zh: '账户已更新', it: 'Conto aggiornato');
  String get type => _t('Type', ne: 'प्रकार', es: 'Tipo', fr: 'Type', de: 'Typ', ja: '種類', zh: '类型', it: 'Tipo');
  String get balance => _t('Balance', ne: 'मौज्दात', es: 'Saldo', fr: 'Solde', de: 'Saldo', ja: '残高', zh: '余额', it: 'Saldo');

  // Plan & Goals
  String get goal => _t('Goal', ne: 'लक्ष्य', es: 'Meta', fr: 'Objectif', de: 'Ziel', ja: '目標', zh: '目标', it: 'Obiettivo');
  String get goals => _t('Goals', ne: 'लक्ष्यहरू', es: 'Metas', fr: 'Objectifs', de: 'Ziele', ja: '目標', zh: '目标');
  String get forecast => _t('Forecast', ne: 'पूर्वानुमान', es: 'Pronóstico', fr: 'Prévisions', de: 'Prognose', ja: '予測', zh: '预测');
  String get reports => _t('Reports', ne: 'मासिक प्रतिवेदन', es: 'Informes', fr: 'Rapports', de: 'Berichte', ja: 'レポート', zh: '报告');
  String get addGoal => _t('Add Goal', ne: 'नयाँ लक्ष्य थप्नुहोस्', es: 'Añadir Meta', fr: 'Ajouter un objectif', de: 'Ziel hinzufügen', ja: '目標を追加', zh: '添加目标');
  String get onTrack => _t('On track', ne: 'सही गतिमा', es: 'En curso', fr: 'Sur la bonne voie', de: 'Auf Kurs', ja: '順調', zh: '正常推进');
  String get atRisk => _t('At risk', ne: 'जोखिममा', es: 'En riesgo', fr: 'À risque', de: 'Gefährdet', ja: 'リスクあり', zh: '有风险');
  String get neededPerWeek => _t('Needed / week', ne: 'प्रति हप्ता आवश्यक', es: 'Necesario / semana', fr: 'Nécessaire / sem', de: 'Nötig / Woche', ja: '週あたり必要', zh: '每周需存');
  String get noGoalsYet => _t('No goals yet', ne: 'कुनै लक्ष्य सेट गरिएको छैन', es: 'Sin metas aún', fr: 'Aucun objectif', de: 'Noch keine Ziele', ja: '目標はまだありません', zh: '暂无目标');

  // Calendar
  String get shiftsOnly => _t('Shifts', ne: 'सिफ्ट मात्र', es: 'Turnos', fr: 'Quarts', de: 'Schichten', ja: 'シフト', zh: '班次');
  String get transactionsOnly => _t('Transactions', ne: 'कारोबार मात्र', es: 'Transacciones', fr: 'Transactions', de: 'Transaktionen', ja: '取引', zh: '交易');
  String get allEvents => _t('All', ne: 'सबै', es: 'Todo', fr: 'Tout', de: 'Alle', ja: 'すべて', zh: '全部');
  String get nothingScheduledForThisDay => _t('Nothing scheduled for this day', ne: 'यस दिन कुनै तालिका छैन', es: 'Nada programado para este día', fr: 'Rien de prévu ce jour', de: 'Für diesen Tag ist nichts geplant', ja: 'この日の予定はありません', zh: '本日无安排');
  String get scheduleShift => _t('Schedule a shift', ne: 'सिफ्ट तालिका बनाउनुहोस्', es: 'Programar turno', fr: 'Planifier un quart', de: 'Schicht planen', ja: 'シフトを予約', zh: '安排排班');

  // Settings & Preferences
  String get appearance => _t('Appearance', ne: 'रुपरेखा', es: 'Apariencia', fr: 'Apparence', de: 'Erscheinungsbild', ja: '外観', zh: '外观');
  String get theme => _t('Theme', ne: 'थिम', es: 'Tema', fr: 'Thème', de: 'Design', ja: 'テーマ', zh: '主题');
  String get language => _t('Language', ne: 'भाषा', es: 'Idioma', fr: 'Langue', de: 'Sprache', ja: '言語', zh: '语言');
  String get aiAssistant => _t('Hypr AI', ne: 'Hypr AI', es: 'Hypr AI', fr: 'Hypr AI', de: 'Hypr AI', ja: 'Hypr AI', zh: 'Hypr AI', it: 'Hypr AI');
  String get askAiAssistant => _t('Ask Hypr AI', ne: 'Hypr AI सँग सोध्नुहोस्', es: 'Preguntar a Hypr AI', fr: 'Demander à Hypr AI', de: 'Hypr AI fragen', ja: 'Hypr AIに質問', zh: '询问 Hypr AI', it: 'Chiedi a Hypr AI');
  String get dataAndBackup => _t('Data & Backup', ne: 'डाटा र ब्याकअप', es: 'Datos y Copia', fr: 'Données et Sauvegarde', de: 'Daten & Backup', ja: 'データとバックアップ', zh: '数据与备份');
  String get backupExportRestore => _t('Backup, Export & Restore', ne: 'ब्याकअप, निर्यात र पुनर्स्थापना', es: 'Copia, Exportar y Restaurar', fr: 'Sauvegarde, Export et Restauration', de: 'Sichern, Exportieren & Wiederherstellen', ja: 'バックアップ・エクスポート・復元', zh: '备份、导出与恢复');
  String get dangerZone => _t('Danger zone', ne: 'खतरा क्षेत्र', es: 'Zona de peligro', fr: 'Zone de danger', de: 'Gefahrenzone', ja: '危険ゾーン', zh: '危险区域');
  String get eraseAllData => _t('Erase all data', ne: 'सबै डाटा मेटाउनुहोस्', es: 'Borrar todos los datos', fr: 'Effacer toutes les données', de: 'Alle Daten löschen', ja: 'すべてのデータを消去', zh: '清除所有数据');
  String get proActive => _t('Hyprwise Pro Active', ne: 'सक्रिय Hyprwise Pro', es: 'Hyprwise Pro Activo', fr: 'Hyprwise Pro Actif', de: 'Hyprwise Pro Aktiv', ja: 'Hyprwise Pro 有効', zh: 'Hyprwise Pro 已激活');
  String get upgradeToPro => _t('Upgrade to Hyprwise Pro', ne: 'Hyprwise Pro मा अपग्रेड गर्नुहोस्', es: 'Mejorar a Hyprwise Pro', fr: 'Passer à Hyprwise Pro', de: 'Auf Hyprwise Pro upgraden', ja: 'Hyprwise Pro にアップグレード', zh: '升级至 Hyprwise Pro');
  String get supportHyprwise => _t('Support Hyprwise', ne: 'Hyprwise लाई समर्थन गर्नुहोस्', es: 'Apoyar a Hyprwise', fr: 'Soutenir Hyprwise', de: 'Hyprwise unterstützen', ja: 'Hyprwiseを応援する', zh: '支持 Hyprwise', it: 'Supporta Hyprwise');
  String get supportHyprwiseSubtitle => _t('Tip jar to support ongoing development', ne: 'विकासलाई निरन्तरता दिन सहयोग गर्नुहोस्', es: 'Bote de propinas para apoyar el desarrollo', fr: 'Pourboire pour soutenir le développement continu', de: 'Trinkgeld zur Unterstützung der Weiterentwicklung', ja: '開発をサポートするチップ', zh: '打赏支持持续开发', it: 'Mancia per supportare lo sviluppo continuo');
  String get supporterBadge => _t('Supporter', ne: 'समर्थक', es: 'Partidario', fr: 'Supporter', de: 'Unterstützer', ja: 'サポーター', zh: '支持者', it: 'Supporter');
  String get restorePurchases => _t('Restore purchases', ne: 'खरिदहरू पुनर्स्थापना गर्नुहोस्', es: 'Restaurar compras', fr: 'Restaurer les achats', de: 'Käufe wiederherstellen', ja: '購入を復元', zh: '恢复购买', it: 'Ripristina acquisti');
  String get purchasesRestored => _t('Purchases restored successfully.', ne: 'खरिदहरू सफलतापूर्वक पुनर्स्थापना गरियो।', es: 'Compras restauradas con éxito.', fr: 'Achats restaurés avec succès.', de: 'Käufe erfolgreich wiederhergestellt.', ja: '購入が正常に復元されました。', zh: '购买已成功恢复。', it: 'Acquisti ripristinati con successo.');
  String get noPurchasesFound => _t('No previous purchases found.', ne: 'कुनै अघिल्लो खरिद फेला परेन।', es: 'No se encontraron compras anteriores.', fr: 'Aucun achat antérieur trouvé.', de: 'Keine früheren Käufe gefunden.', ja: '以前の購入は見つかりませんでした。', zh: '未找到先前的购买记录。', it: 'Nessun acquisto precedente trovato.');
  String get signOut => _t('Sign out', ne: 'साइन आउट', es: 'Cerrar sesión', fr: 'Se déconnecter', de: 'Abmelden', ja: 'サインアウト', zh: '退出登录');
  String get signOutWarningTitle => _t('Unsaved Data Warning', ne: 'असुरक्षित डेटा चेतावनी', es: 'Aviso de datos no guardados', fr: 'Avertissement de données non sauvegardées', de: 'Warnung vor ungesicherten Daten', ja: '未保存データ警告', zh: '未保存数据警告', it: 'Avviso dati non salvati');
  String get signOutWarningDesc => _t(
    'Your accounts, transactions, and shifts are stored locally on this device. Because you are on the free plan, cloud backup is inactive and your data may be lost upon signing out. Upgrade to Hyprwise Pro to automatically sync and protect your finances in the cloud.',
    ne: 'तपाईंका खाताहरू, कारोबारहरू र सिफ्टहरू हाल यो यन्त्रमा मात्र सुरक्षित छन्। तपाईं फ्रि योजनामा हुनुभएकाले क्लाउड ब्याकअप सक्रिय छैन र साइन आउट गर्दा डेटा हराउन सक्छ। आफ्नो वित्तीय डेटा क्लाउडमा सुरक्षित रूपमा सिंक र संरक्षण गर्न Hyprwise Pro मा अपग्रेड गर्नुहोस्।',
    es: 'Tus cuentas, transacciones y turnos se guardan únicamente en este dispositivo. Al estar en el plan gratuito, la copia en la nube no está activa y tus datos podrían perderse al cerrar sesión. Actualiza a Hyprwise Pro para sincronizar y proteger tus finanzas en la nube.',
    fr: 'Vos comptes, transactions et quarts sont stockés localement sur cet appareil. Avec le forfait gratuit, la sauvegarde cloud n\'est pas active et vos données pourraient être perdues. Passez à Hyprwise Pro pour synchroniser et protéger vos finances dans le cloud.',
    de: 'Ihre Konten, Transaktionen und Schichten sind lokal auf diesem Gerät gespeichert. Im kostenlosen Plan ist das Cloud-Backup inaktiv und Ihre Daten können beim Abmelden verloren gehen. Upgraden Sie auf Hyprwise Pro, um Ihre Finanzen in der Cloud zu sichern.',
    ja: 'アカウント、取引、シフトはこの端末にのみローカル保存されています。無料プランではクラウドバックアップが無効なため、サインアウトするとデータが失われる可能性があります。クラウドで安全に同期・保護するには、Hyprwise Proにアップグレードしてください。',
    zh: '您的账户、交易和班次记录仅保存在此设备上。由于您使用的是免费版，云端备份未激活，退出登录后数据可能会丢失。升级到 Hyprwise Pro 可自动在云端备份和保护您的财务数据。',
    it: 'I tuoi account, transazioni e turni sono salvati localmente su questo dispositivo. Con il piano gratuito il backup cloud non è attivo e i dati potrebbero andare persi. Passa a Hyprwise Pro per proteggere le tue finanze nel cloud.',
  );
  String get signOutAnyway => _t('Sign out anyway', ne: 'तैपनि साइन आउट गर्नुहोस्', es: 'Cerrar sesión de todos modos', fr: 'Se déconnecter quand même', de: 'Trotzdem abmelden', ja: 'それでもサインアウト', zh: '仍然退出登录', it: 'Esci comunque');
  String get staySignedIn => _t('Stay signed in', ne: 'साइन इन नै रहनुहोस्', es: 'Permanecer conectado', fr: 'Rester connecté', de: 'Angemeldet bleiben', ja: 'サインインのまま', zh: '保持登录', it: 'Rimani connesso');
  String get proSignOutConfirmDesc => _t(
    'Your accounts and financial data are safely backed up to the cloud and will be restored when you sign in again.',
    ne: 'तपाईंका खाताहरू र वित्तीय डेटा क्लाउडमा सुरक्षित छन् र अर्को पटक साइन इन गर्दा पुनर्स्थापना हुनेछन्।',
    es: 'Tus cuentas y datos financieros están respaldados de forma segura en la nube y se restaurarán cuando vuelvas a iniciar sesión.',
    fr: 'Vos comptes et données financières sont sauvegardés en toute sécurité dans le cloud et seront restaurés lors de votre prochaine connexion.',
    de: 'Ihre Konten und Finanzdaten sind sicher in der Cloud gesichert und werden bei der nächsten Anmeldung wiederhergestellt.',
    ja: 'アカウントと財務データはクラウドに安全にバックアップされており、次回サインイン時に復元されます。',
    zh: '您的账户和财务数据已安全备份到云端，再次登录时将自动恢复。',
    it: 'I tuoi account e dati finanziari sono al sicuro nel cloud e saranno ripristinati al prossimo accesso.',
  );

  String get categories => _t('Categories', ne: 'वर्गहरू', es: 'Categorías', fr: 'Catégories', de: 'Kategorien', ja: 'カテゴリー', zh: '分类');
  String get systemTheme => _t('System', ne: 'प्रणाली', es: 'Sistema', fr: 'Système', de: 'System', ja: 'システム', zh: '跟随系统');
  String get lightTheme => _t('Light', ne: 'उज्यालो', es: 'Claro', fr: 'Clair', de: 'Hell', ja: 'ライト', zh: '浅色');
  String get darkTheme => _t('Dark', ne: 'अँध्यारो', es: 'Oscuro', fr: 'Sombre', de: 'Dunkel', ja: 'ダーク', zh: '深色');
  String get alertPreferences => _t('Alert Preferences', ne: 'सूचना प्राथमिकताहरू', es: 'Preferencias de alerta', fr: 'Préférences d\'alerte', de: 'Benachrichtigungseinstellungen', ja: '通知設定', zh: '通知偏好');

  // Actions & Buttons
  String get save => _t('Save', ne: 'सुरक्षित गर्नुहोस्', es: 'Guardar', fr: 'Enregistrer', de: 'Speichern', ja: '保存', zh: '保存');
  String get cancel => _t('Cancel', ne: 'रद्द गर्नुहोस्', es: 'Cancelar', fr: 'Annuler', de: 'Abbrechen', ja: 'キャンセル', zh: '取消');
  String get done => _t('Done', ne: 'सम्पन्न', es: 'Listo', fr: 'Terminé', de: 'Fertig', ja: '完了', zh: '完成');
  String get delete => _t('Delete', ne: 'हटाउनुहोस्', es: 'Eliminar', fr: 'Supprimer', de: 'Löschen', ja: '削除', zh: '删除');
  String get edit => _t('Edit', ne: 'सम्पादन', es: 'Editar', fr: 'Modifier', de: 'Bearbeiten', ja: '編集', zh: '编辑');
  String get search => _t('Search', ne: 'खोज्नुहोस्', es: 'Buscar', fr: 'Rechercher', de: 'Suchen', ja: '検索', zh: '搜索');
  String get currencyConverter => _t('Currency Converter', ne: 'मुद्रा रूपान्तरण', es: 'Conversor de Moneda', fr: 'Convertisseur de devises', de: 'Währungsumrechner', ja: '通貨換算', zh: '货币兑换');
  String get returnHome => _t('Return Home', ne: 'गृहपृष्ठमा फर्कनुहोस्', es: 'Volver al Inicio', fr: 'Retour à l\'accueil', de: 'Zurück zur Startseite', ja: 'ホームに戻る', zh: '返回首页');
  String get continueAction => _t('Continue', ne: 'अगाडि बढ्नुहोस्', es: 'Continuar', fr: 'Continuer', de: 'Weiter', ja: '続ける', zh: '继续');
  String get chooseLanguage => _t('Choose your language', ne: 'आफ्नो भाषा छान्नुहोस्', es: 'Elige tu idioma', fr: 'Choisissez votre langue', de: 'Wählen Sie Ihre Sprache', ja: '言語を選択', zh: '选择语言');
  String get chooseLanguageSubtitle => _t('You can change this anytime in Settings.', ne: 'पछि सेटिङहरूबाट पनि फेर्न सक्नुहुन्छ।', es: 'Puedes cambiar esto en cualquier momento en Ajustes.', fr: 'Modifiable à tout moment dans les Paramètres.', de: 'Jederzeit in den Einstellungen änderbar.', ja: '設定からいつでも変更できます。', zh: '随时可在设置中更改。');
  String get selectLanguage => _t('Select Language', ne: 'भाषा चयन गर्नुहोस्', es: 'Seleccionar idioma', fr: 'Sélectionner la langue', de: 'Sprache wählen', ja: '言語を選択', zh: '选择语言');
  String get baseCurrency => _t('Base currency', ne: 'आधार मुद्रा', es: 'Moneda base', fr: 'Devise de base', de: 'Basiswährung', ja: '基準通貨', zh: '基础货币');
  String get chooseDefaultCurrency => _t('Choose your default currency', ne: 'आफ्नो पूर्वनिर्धारित मुद्रा छान्नुहोस्', es: 'Elige tu moneda predeterminada', fr: 'Choisissez votre devise par défaut', de: 'Wählen Sie Ihre Standardwährung', ja: 'デフォルトの通貨を選択', zh: '选择默认货币');
  String get internetRequired => _t('Internet required', ne: 'इन्टरनेट आवश्यक', es: 'Internet requerido', fr: 'Connexion Internet requise', de: 'Internet erforderlich', ja: 'インターネット接続が必要です', zh: '需要网络连接');
  String get internetRequiredDesc => _t(
    'An active internet connection is needed to fetch live exchange rates and convert your money accurately before switching currency.',
    ne: 'मुद्रा परिवर्तन गर्नुअघि प्रत्यक्ष विनिमय दरहरू प्राप्त गर्न र आफ्नो रकम सही रूपमा रूपान्तरण गर्न सक्रिय इन्टरनेट जडान आवश्यक पर्दछ।',
    es: 'Se necesita una conexión a Internet activa para obtener tipos de cambio en vivo y convertir su dinero con precisión antes de cambiar de moneda.',
    fr: 'Une connexion Internet active est nécessaire pour récupérer les taux de change en direct et convertir votre argent avec précision avant de changer de devise.',
    de: 'Eine aktive Internetverbindung ist erforderlich, um Live-Wechselkurse abzurufen und Ihr Geld vor dem Währungswechsel genau umzurechnen.',
    ja: '通貨を切り替える前に、リアルタイムの為替レートを取得して正確に換算するために、アクティブなインターネット接続が必要です。',
    zh: '在切换货币之前，需要网络连接来获取实时汇率并准确换算您的资金。',
  );
  String get gotIt => _t('Got it', ne: 'बुझें', es: 'Entendido', fr: 'Compris', de: 'Verstanden', ja: '了解', zh: '知道了');

  // Quick Add Menu
  String get whatWouldYouLikeToAdd => _t('What would you like to add?', ne: 'के थप्न चाहनुहुन्छ?', es: '¿Qué deseas añadir?', fr: 'Que souhaitez-vous ajouter?', de: 'Was möchten Sie hinzufügen?', ja: '何を追加しますか？', zh: '您想要添加什么？');
  String get logMoneySpent => _t('Log money spent', ne: 'भएको खर्च लेख्नुहोस्', es: 'Registrar gasto', fr: 'Enregistrer une dépense', de: 'Ausgabe protokollieren', ja: '支出を記録', zh: '记录支出');
  String get salaryAndPay => _t('Salary & pay', ne: 'तलब तथा आम्दानी', es: 'Salario e ingresos', fr: 'Salaire et revenus', de: 'Gehalt & Lohn', ja: '給与・収入', zh: '工资与收入');
  String get depositSavings => _t('Deposit Savings', ne: 'बचत जम्मा', es: 'Depositar ahorros', fr: 'Déposer des économies', de: 'Sparguthaben einzahlen', ja: '貯金する', zh: '存入储蓄');
  String get fundAGoal => _t('Fund a goal', ne: 'लक्ष्यमा रकम थप्नुहोस्', es: 'Aportar a una meta', fr: 'Financer un objectif', de: 'Ziel besparen', ja: '目標に積立', zh: '为目标注资');
  String get scheduleHours => _t('Schedule hours', ne: 'कामको समय तय गर्नुहोस्', es: 'Programar horas', fr: 'Planifier des heures', de: 'Arbeitszeiten planen', ja: '勤務時間を予定', zh: '安排工时');
  String get liveTimeTracking => _t('Live time tracking', ne: 'प्रत्यक्ष समय गणना', es: 'Seguimiento en vivo', fr: 'Suivi en direct', de: 'Live-Zeiterfassung', ja: 'リアルタイム時間計測', zh: '实时工时追踪');
  String get lendBorrow => _t('Lend / Borrow', ne: 'सापटी / ऋण', es: 'Prestar / Pedir prestado', fr: 'Prêter / Emprunter', de: 'Leihen / Borgen', ja: '貸す / 借りる', zh: '借出 / 借入');
  String get debtsAndIous => _t('Debts & IOUs', ne: 'लिनु-दिनु र हिसाब', es: 'Deudas y préstamos', fr: 'Dettes et créances', de: 'Schulden & Kredite', ja: '貸し借りの記録', zh: '借贷与债务');
  String get savingsGoal => _t('Savings Goal', ne: 'बचत लक्ष्य', es: 'Meta de ahorro', fr: 'Objectif d\'épargne', de: 'Sparziel', ja: '貯金目標', zh: '储蓄目标');
  String get setTargetSavings => _t('Set target savings', ne: 'नयाँ लक्ष्य राख्नुहोस्', es: 'Fijar objetivo de ahorro', fr: 'Définir un objectif d\'épargne', de: 'Sparziel festlegen', ja: '貯金目標を設定', zh: '设定目标存款');
  String get workplaceJob => _t('Workplace Job', ne: 'कामको जागिर', es: 'Empleo / Trabajo', fr: 'Emploi / Poste', de: 'Arbeitsstelle', ja: '勤務先・仕事', zh: '工作岗位');
  String get hourlyRateAndDays => _t('Hourly rate & days', ne: 'घण्टाको दर र विवरण', es: 'Tarifa horaria y días', fr: 'Taux horaire et jours', de: 'Stundensatz & Tage', ja: '時給と勤務日', zh: '时薪与工作日');
  String get perHour => _t('/ hour', ne: '/ घण्टा', es: '/ hora', fr: '/ h', de: '/ Std.', ja: '/ 時間', zh: '/ 小时');
  String get perMonth => _t('/ month', ne: '/ महिना', es: '/ mes', fr: '/ mois', de: '/ Monat', ja: '/ 月', zh: '/ 月');

  // Onboarding & Setup Checklist (Blank Home)
  String get getSetUp => _t('Get set up', ne: 'सुरुवात गर्नुहोस्', es: 'Comenzar', fr: 'Démarrer', de: 'Einrichten', ja: '初期設定', zh: '开始设置');
  String get addAccountChecklist => _t('Add an account', ne: 'खाता थप्नुहोस्', es: 'Añadir cuenta', fr: 'Ajouter un compte', de: 'Konto hinzufügen', ja: '口座を追加', zh: '添加账户');
  String get balanceRealSubtitle => _t('So your balance is real', ne: 'सम्पत्ति र मौज्दात यकिन गर्न', es: 'Para un saldo real', fr: 'Pour un solde réel', de: 'Damit der Saldo stimmt', ja: '正確な残高管理のために', zh: '确保余额准确');
  String get addJobChecklist => _t('Add a job', ne: 'काम / रोजगार थप्नुहोस्', es: 'Añadir empleo', fr: 'Ajouter un travail', de: 'Job hinzufügen', ja: '仕事を追加', zh: '添加工作');
  String get shiftsLiveHereSubtitle => _t('Your shifts will live here', ne: 'तपाईंका सिफ्टहरू यहाँ रहनेछन्', es: 'Tus turnos estarán aquí', fr: 'Vos quarts seront ici', de: 'Hier erscheinen Ihre Schichten', ja: 'シフトはここに表示されます', zh: '班次将在此显示');
  String get setGoalChecklist => _t('Set a goal', ne: 'लक्ष्य निर्धारण गर्नुहोस्', es: 'Fijar una meta', fr: 'Fixer un objectif', de: 'Ziel setzen', ja: '目標を設定', zh: '设立目标');
  String get giveMoneyReasonSubtitle => _t('Give your money a reason', ne: 'आफ्नो बचतलाई उद्देश्य दिनुहोस्', es: 'Dale propósito a tu dinero', fr: 'Donnez un sens à votre argent', de: 'Geben Sie Ihrem Geld ein Ziel', ja: 'お金に目的を', zh: '给存钱一个目标');
  String get turnOnAlertsChecklist => _t('Turn on alerts', ne: 'सूचनाहरू सक्रिय गर्नुहोस्', es: 'Activar alertas', fr: 'Activer les alertes', de: 'Benachrichtigungen an', ja: '通知をオン', zh: '开启提醒');
  String get neverMissShiftOrBillSubtitle => _t('Never miss a shift or a bill', ne: 'सिफ्ट वा बिलको पूर्व जानकारी पाउनुहोस्', es: 'No te pierdas turnos ni facturas', fr: 'Ne manquez jamais un quart ni une facture', de: 'Nie eine Schicht oder Rechnung verpassen', ja: 'シフトや支払いを逃しません', zh: '不错过任何班次与账单');
  String setupStepsProgress(int completed, int total) => _t(
        '$completed of $total',
        ne: '$completed / $total पूरा',
        es: '$completed de $total',
        fr: '$completed sur $total',
        de: '$completed von $total',
        ja: '$total中$completed完了',
        zh: '$completed / $total 完成',
        it: '$completed di $total',
      );

  // Shell, Navigation & Add Menu
  String get customTagsAndStores => _t('Custom tags & stores', ne: 'कोटि तथा पसलहरू', es: 'Etiquetas y tiendas', fr: 'Balises et magasins', de: 'Kategorien & Geschäfte', ja: 'タグと店舗', zh: '标签与商户', it: 'Tag e negozi');
  String get chooseActionToRecordOrPlan => _t('Choose an action below to quickly record or plan', ne: 'छिटो रेकर्ड वा योजना गर्न तलको कार्य रोज्नुहोस्', es: 'Elige una acción para registrar o planificar', fr: 'Choisissez une action pour enregistrer ou planifier', de: 'Wählen Sie eine Aktion zum Erfassen oder Planen', ja: 'すばやく記録または計画するアクションを選択してください', zh: '在下方选择操作以快速记账或规划', it: 'Scegli un\'azione per registrare o pianificare');
  String get netPositionTotalExplanation => _t('Your net position on Home is the total of these accounts.', ne: 'गृहपृष्ठमा देखिने नेट मौज्दात यिनै खाताहरूको योगफल हो।', es: 'Tu posición neta en Inicio es el total de estas cuentas.', fr: 'Votre position nette sur l\'Accueil est le total de ces comptes.', de: 'Ihr Nettovermögen auf der Startseite entspricht der Summe dieser Konten.', ja: 'ホームに表示される純資産はこれらの口座の合計です。', zh: '主页上的净资产是这些账户的总和。', it: 'Il tuo patrimonio netto nella Home è il totale di questi conti.');

  // Debts & Lending
  String get resetFilters => _t('Reset filters', ne: 'फिल्टर रिसेट', es: 'Restablecer filtros', fr: 'Réinitialiser les filtres', de: 'Filter zurücksetzen', ja: 'フィルターをリセット', zh: '重置筛选', it: 'Reimposta filtri');
  String get addRecord => _t('Add record', ne: 'नयाँ रेकर्ड', es: 'Añadir registro', fr: 'Ajouter un enregistrement', de: 'Eintrag hinzufügen', ja: '記録を追加', zh: '添加记录', it: 'Aggiungi voce');
  String get noMatchingRecords => _t('No matching records', ne: 'कुनै मिल्दो रेकर्ड भेटिएन', es: 'No hay registros coincidentes', fr: 'Aucun enregistrement correspondant', de: 'Keine passenden Einträge', ja: '一致する記録がありません', zh: '未找到符合条件的记录', it: 'Nessun elemento corrispondente');
  String get noDebtRecordsFound => _t('No debt records found', ne: 'कुनै ऋण रेकर्ड छैन', es: 'No se encontraron deudas', fr: 'Aucune dette trouvée', de: 'Keine Schuldeneinträge gefunden', ja: '貸し借りの記録はありません', zh: '暂无借贷记录', it: 'Nessun debito trovato');
  String get addLoanOrDebt => _t('Add Loan or Debt', ne: 'नयाँ रेकर्ड थप्नुहोस्', es: 'Añadir préstamo o deuda', fr: 'Ajouter un prêt ou une dette', de: 'Kredit oder Schulden hinzufügen', ja: '貸し借りを記録', zh: '添加借贷记录', it: 'Aggiungi prestito o debito');
  String get netDebtBalance => _t('NET DEBT BALANCE', ne: 'कुल बाँकी ब्यालेन्स', es: 'SALDO NETO DE DEUDA', fr: 'SOLDE NET DE LA DETTE', de: 'NETTO-SCHULDENSTAND', ja: '純借入残高', zh: '净借贷差额', it: 'SALDO NETTO DEBITO');
  String get netReceivable => _t('Net Receivable', ne: 'उठ्न बाँकी', es: 'Cobro neto', fr: 'Créance nette', de: 'Netto-Forderung', ja: '回収予定額', zh: '应收总额', it: 'Credito netto');
  String get netPayable => _t('Net Payable', ne: 'तिर्न बाँकी', es: 'Deuda neta', fr: 'Dette nette', de: 'Netto-Verbindlichkeit', ja: '支払予定額', zh: '应付总额', it: 'Debito netto');
  String get lentToOthers => _t('Lent to others', ne: 'सापटी दिएको', es: 'Prestado a otros', fr: 'Prêté à autrui', de: 'Anderen geliehen', ja: '他者に貸出', zh: '借出款项', it: 'Prestato ad altri');
  String get borrowedFromOthers => _t('Borrowed from others', ne: 'सापटी लिएको', es: 'Tomado prestado', fr: 'Emprunté à autrui', de: 'Von anderen geliehen', ja: '他者から借入', zh: '借入款项', it: 'Preso in prestito');
  String get theyOweYou => _t('They owe you', ne: 'उनीहरूले तिर्नुपर्ने', es: 'Te deben', fr: 'Ils vous doivent', de: 'Sie schulden Ihnen', ja: '受け取り待ち', zh: '对方待还', it: 'Ti devono');
  String get youOweThem => _t('You owe them', ne: 'मैले तिर्नुपर्ने', es: 'Les debes', fr: 'Vous leur devez', de: 'Sie schulden ihnen', ja: '支払い待ち', zh: '待还对方', it: 'Devi loro');
  String get duePrefix => _t('Due', ne: 'फिर्ता', es: 'Vence', fr: 'Échéance', de: 'Fällig', ja: '期日', zh: '到期', it: 'Scadenza');
  String get settled => _t('Settled', ne: 'फर्स्यौट भयो', es: 'Liquidado', fr: 'Régle', de: 'Beglichen', ja: '清算済み', zh: '已结清', it: 'Saldato');
  String get active => _t('Active', ne: 'सक्रिय', es: 'Activo', fr: 'Actif', de: 'Aktiv', ja: '進行中', zh: '进行中', it: 'Attivo');
  String get lentReceivable => _t('Lent (Receivable)', ne: 'सापटी दिएको (Receivable)', es: 'Prestado (Por cobrar)', fr: 'Prêté (À recouvrer)', de: 'Geliehen (Forderung)', ja: '貸出（回収予定）', zh: '借出（待收款）', it: 'Prestato (Da ricevere)');
  String get borrowedPayable => _t('Borrowed (Payable)', ne: 'सापटी लिएको (Payable)', es: 'Tomado (Por pagar)', fr: 'Emprunté (À payer)', de: 'Geborgt (Verbindlichkeit)', ja: '借入（支払い予定）', zh: '借入（待付款）', it: 'Preso in prestito (Da pagare)');
  String get currentBalance => _t('Current Balance', ne: 'बाँकी रकम', es: 'Saldo actual', fr: 'Solde actuel', de: 'Aktueller Saldo', ja: '現在の残高', zh: '当前欠额', it: 'Saldo attuale');
  String get dueDateLabel => _t('Due date:', ne: 'फिर्ता मिति:', es: 'Fecha de vencimiento:', fr: 'Date d\'échéance:', de: 'Fälligkeitsdatum:', ja: '返済期日:', zh: '到期日期:', it: 'Data di scadenza:');
  String get recordRepayment => _t('Record Repayment', ne: 'आंशिक भुक्तानी / फर्स्यौट', es: 'Registrar reembolso', fr: 'Enregistrer le remboursement', de: 'Rückzahlung erfassen', ja: '返済を記録', zh: '记录还款', it: 'Registra rimborso');
  String get quickSettle => _t('Quick Settle', ne: 'सीधै फर्स्यौट चिन्ह लगाउनुहोस्', es: 'Liquidar rápido', fr: 'Règlement rapide', de: 'Schnell begleichen', ja: '全額清算', zh: '快捷结清', it: 'Saldo rapido');
  String get markedAsSettled => _t('Marked as settled', ne: 'ऋण फर्स्यौट गरियो', es: 'Marcado como liquidado', fr: 'Marqué comme réglé', de: 'Als beglichen markiert', ja: '清算済みとして記録しました', zh: '已标记为结清', it: 'Contrassegnato come saldato');
  String get markAsUnsettled => _t('Mark as Unsettled', ne: 'पुनः सक्रिय गर्नुहोस्', es: 'Marcar como pendiente', fr: 'Marquer comme non réglé', de: 'Als unbeglichen markieren', ja: '未清算に戻す', zh: '标记为未结清', it: 'Contrassegna come non saldato');
  String get markedAsUnsettled => _t('Marked as unsettled', ne: 'ऋण पुनः सक्रिय गरियो', es: 'Marcado como pendiente', fr: 'Marqué comme non réglé', de: 'Als unbeglichen markiert', ja: '未清算に戻しました', zh: '已标记为未结清', it: 'Contrassegnato come non saldato');
  String get deleteRecordTitle => _t('Delete Record', ne: 'रेकर्ड मेटाउनुहोस्', es: 'Eliminar registro', fr: 'Supprimer l\'enregistrement', de: 'Eintrag löschen', ja: '記録を削除', zh: '删除记录', it: 'Elimina record');
  String get deleteRecordQuestion => _t('Delete record?', ne: 'रेकर्ड मेटाउने?', es: '¿Eliminar registro?', fr: 'Supprimer l\'enregistrement ?', de: 'Eintrag löschen?', ja: '記録を削除しますか？', zh: '确定删除此记录？', it: 'Eliminare il record?');
  String get recordDeleted => _t('Record deleted', ne: 'रेकर्ड मेटाइयो', es: 'Registro eliminado', fr: 'Enregistrement supprimé', de: 'Eintrag gelöscht', ja: '記録を削除しました', zh: '记录已删除', it: 'Record eliminato');
  String get remainingLabel => _t('Remaining:', ne: 'कुल बाँकी:', es: 'Restante:', fr: 'Restant:', de: 'Verbleibend:', ja: '残高:', zh: '剩余:', it: 'Rimanente:');
  String get paymentAmount => _t('Payment amount', ne: 'भुक्तानी रकम', es: 'Importe del pago', fr: 'Montant du paiement', de: 'Zahlungsbetrag', ja: '支払額', zh: '还款金额', it: 'Importo pagamento');
  String get recordInEverydayAccount => _t('Record in Everyday account', ne: 'दैनिक खातामा समायोजन गर्नुहोस्', es: 'Registrar en cuenta corriente', fr: 'Enregistrer dans le compte courant', de: 'Im Alltagskonto erfassen', ja: '日常口座に反映', zh: '记入日常消费账户', it: 'Registra sul conto corrente');
  String get inflowEverydayBalance => _t('Inflow into Everyday balance', ne: 'रकम दैनिक खातामा थपिनेछ', es: 'Entrada en el saldo diario', fr: 'Entrée sur le solde courant', de: 'Eingang auf das Alltagskonto', ja: '日常口座に入金', zh: '日常账户余额增加', it: 'Entrata sul conto corrente');
  String get outflowEverydayBalance => _t('Outflow from Everyday balance', ne: 'रकम दैनिक खाताबाट घट्नेछ', es: 'Salida del saldo diario', fr: 'Sortie du solde courant', de: 'Abgang vom Alltagskonto', ja: '日常口座から出金', zh: '日常账户余额扣减', it: 'Uscita dal conto corrente');
  String get savePayment => _t('Save Payment', ne: 'भुक्तानी सुरक्षित गर्नुहोस्', es: 'Guardar pago', fr: 'Enregistrer le paiement', de: 'Zahlung speichern', ja: '支払いを保存', zh: '保存还款', it: 'Salva pagamento');
  String get paymentRecordedSuccess => _t('Payment recorded successfully', ne: 'भुक्तानी रेकर्ड गरियो', es: 'Pago registrado con éxito', fr: 'Paiement enregistré avec succès', de: 'Zahlung erfolgreich erfasst', ja: '支払いを記録しました', zh: '还款记录成功', it: 'Pagamento registrato con successo');
  String get filterByCounterparty => _t('Filter by Counterparty', ne: 'व्यक्ति अनुसार फिल्टर', es: 'Filtrar por contraparte', fr: 'Filtrer par contrepartie', de: 'Nach Gegenpartei filtern', ja: '相手で絞り込む', zh: '按往来对象筛选', it: 'Filtra per controparte');
  String get clearAction => _t('Clear', ne: 'हटाउनुहोस्', es: 'Borrar', fr: 'Effacer', de: 'Löschen', ja: 'クリア', zh: '清除', it: 'Cancella');
  String get noCounterpartiesYet => _t('No counterparties recorded yet', ne: 'कुनै व्यक्ति भेटिएन', es: 'Sin contrapartes registradas aún', fr: 'Aucune contrepartie enregistrée', de: 'Noch keine Parteien erfasst', ja: '登録された相手はいません', zh: '暂无往来对象记录', it: 'Nessuna controparte registrata');
  String get partyNameLabel => _t('Party name (Person or Entity)', ne: 'पार्टीको नाम (व्यक्ति वा संस्था)', es: 'Nombre de la parte (persona o entidad)', fr: 'Nom de la partie (personne ou entité)', de: 'Name der Gegenpartei (Person/Firma)', ja: '相手の名前（人物または組織）', zh: '对方姓名（个人或机构）', it: 'Nome controparte (Persona o entità)');
  String get partyNameHint => _t('e.g. Ram, Sita, Dave', ne: 'जस्तै: राम, सिता', es: 'p. ej. María, Carlos', fr: 'ex. Jean, Claire', de: 'z.B. Max, Anna', ja: '例: 田中, 佐藤', zh: '例如：张三、李四', it: 'es. Marco, Giulia');
  String get noFixedDateOptional => _t('No fixed date (Optional)', ne: 'कुनै निश्चित छैन (वैकल्पिक)', es: 'Sin fecha fija (Opcional)', fr: 'Sans date fixe (Facultatif)', de: 'Kein festes Datum (Optional)', ja: '期限なし（任意）', zh: '无固定期限（选填）', it: 'Nessuna data fissa (Opzionale)');
  String get interestRateOptional => _t('Interest rate (%) (Optional)', ne: 'ब्याज दर (%) (वैकल्पिक)', es: 'Tasa de interés (%) (Opcional)', fr: 'Taux d\'intérêt (%) (Facultatif)', de: 'Zinssatz (%) (Optional)', ja: '金利 (%)（任意）', zh: '利率 (%)（选填）', it: 'Tasso di interesse (%) (Opzionale)');
  String get noteOrReasonOptional => _t('Note or reason (Optional)', ne: 'कैफियत / कारण (वैकल्पिक)', es: 'Nota o motivo (Opcional)', fr: 'Note ou motif (Facultatif)', de: 'Notiz oder Grund (Optional)', ja: 'メモ・理由（任意）', zh: '备注或事由（选填）', it: 'Nota o motivo (Opzionale)');
  String get noteReasonHint => _t('e.g. Dinner bill split, emergency', ne: 'जस्तै: खाजाको बिल, आपतकालीन', es: 'ej. Cena compartida, urgencia', fr: 'ex. Partage de restaurant, urgence', de: 'z.B. Restaurantrechnung, Notfall', ja: '例: 割り勘代、急な出費', zh: '例如：聚餐AA分摊、应急借支', it: 'es. Conto cena, emergenza');
  String get deductEverydayBalanceNow => _t('Deduct principal from Everyday balance now', ne: 'रकम सिधै दैनिक ब्यालेन्सबाट घट्नेछ', es: 'Deducir principal del saldo diario', fr: 'Déduire le montant du solde courant', de: 'Hauptbetrag sofort vom Alltagskonto abziehen', ja: '日常口座から元金を即座に出金', zh: '立即从日常账户中扣除本金', it: 'Detrai capitale dal conto corrente');
  String get addEverydayBalanceNow => _t('Add principal to Everyday balance now', ne: 'रकम सिधै दैनिक ब्यालेन्समा थपिनेछ', es: 'Añadir principal al saldo diario', fr: 'Ajouter le montant au solde courant', de: 'Hauptbetrag sofort zum Alltagskonto hinzufügen', ja: '日常口座に元金を即座に入金', zh: '立即将本金存入日常账户', it: 'Aggiungi capitale al conto corrente');
  String get currencyAssistant => _t('Currency Assistant', ne: 'मुद्रा सहायक', es: 'Asistente de divisas', fr: 'Assistant de devises', de: 'Währungsassistent', ja: '通貨アシスタント', zh: '货币助手', it: 'Assistente valuta');
  String amountInCurrency(String currency) => _t('Amount in $currency', ne: '$currency मा रकम', es: 'Importe en $currency', fr: 'Montant en $currency', de: 'Betrag in $currency', ja: '$currencyでの金額', zh: '$currency金额', it: 'Importo in $currency');
  String get rateLabel => _t('Rate', ne: 'विनिमय दर', es: 'Tipo de cambio', fr: 'Taux', de: 'Kurs', ja: 'レート', zh: '汇率', it: 'Tasso');
  String convertedInBase(String base) => _t('Converted in $base', ne: '$base मा रूपान्तरित', es: 'Convertido en $base', fr: 'Converti en $base', de: 'Umgerechnet in $base', ja: '$baseに換算', zh: '换算为 $base', it: 'Convertito in $base');
  String couldNotSave(String e) => _t('Could not save: $e', ne: 'सुरक्षित गर्न सकिएन: $e', es: 'No se pudo guardar: $e', fr: 'Impossible d\'enregistrer : $e', de: 'Konnte nicht gespeichert werden: $e', ja: '保存できませんでした: $e', zh: '保存失败: $e', it: 'Impossibile salvare: $e');

  // Plan & Goals Extended
  String get forecastAndGoals => _t('Forecast and goals', ne: 'पूर्वानुमान र लक्ष्यहरू', es: 'Pronóstico y metas', fr: 'Prévisions et objectifs', de: 'Prognose und Ziele', ja: '予測と目標', zh: '预测与目标', it: 'Previsioni e obiettivi');
  String get newGoal => _t('New goal', ne: 'नयाँ लक्ष्य', es: 'Nueva meta', fr: 'Nouvel objectif', de: 'Neues Ziel', ja: '新しい目標', zh: '新目标', it: 'Nuovo obiettivo');
  String get projectedBalanceIn3Months => _t('Projected balance in 3 months', ne: '३ महिनामा अनुमानित मौज्दात', es: 'Saldo proyectado en 3 meses', fr: 'Solde projeté dans 3 mois', de: 'Prognostizierter Saldo in 3 Monaten', ja: '3ヶ月後の予測残高', zh: '3个月后预估余额', it: 'Saldo previsto tra 3 mesi');
  String allWithCount(int count) => _t('All ($count)', ne: 'सबै ($count)', es: 'Todos ($count)', fr: 'Tous ($count)', de: 'Alle ($count)', ja: 'すべて ($count)', zh: '全部 ($count)', it: 'Tutti ($count)');
  String get goalPlanningAdvice => _t('Set a goal and we will work out how much to save each month.', ne: 'लक्ष्य निर्धारण गर्नुहोस् र हामी प्रत्येक महिना कति बचत गर्ने हिसाब गर्नेछौं।', es: 'Fija una meta y calcularemos cuánto ahorrar al mes.', fr: 'Fixez un objectif et nous calculerons combien épargner chaque mois.', de: 'Legen Sie ein Ziel fest, und wir berechnen die monatliche Sparrate.', ja: '目標を設定すれば、毎月の必要積立額を自動計算します。', zh: '设立目标，我们将为您计算每月所需储蓄。', it: 'Imposta un obiettivo e calcoleremo quanto risparmiare ogni mese.');
  String get noMatchingGoals => _t('No matching goals', ne: 'कुनै मिल्दो लक्ष्य फेला परेन', es: 'No hay metas coincidentes', fr: 'Aucun objectif correspondant', de: 'Keine passenden Ziele', ja: '一致する目標がありません', zh: '无符合条件的目标', it: 'Nessun obiettivo corrispondente');
  String get tryDifferentFilter => _t('Try selecting a different filter.', ne: 'फरक फिल्टर छान्नुहोस्।', es: 'Prueba a seleccionar otro filtro.', fr: 'Essayez un autre filtre.', de: 'Versuchen Sie einen anderen Filter.', ja: '別のフィルターを選択してください。', zh: '请尝试其他筛选条件。', it: 'Prova a selezionare un filtro diverso.');
  String get highPriority => _t('★ High Priority', ne: '★ उच्च प्राथमिकता', es: '★ Alta prioridad', fr: '★ Haute priorité', de: '★ Hohe Priorität', ja: '★ 高優先度', zh: '★ 高优先级', it: '★ Alta priorità');
  String ofTarget(String formattedTarget) => _t('of $formattedTarget', ne: 'मध्ये $formattedTarget', es: 'de $formattedTarget', fr: 'sur $formattedTarget', de: 'von $formattedTarget', ja: '/ $formattedTarget', zh: '/ $formattedTarget', it: 'di $formattedTarget');
  String get depositOrSave => _t('Deposit / Save', ne: 'बचत जम्मा', es: 'Depositar / Ahorrar', fr: 'Déposer / Épargner', de: 'Einzahlen / Sparen', ja: '積立 / 貯金', zh: '存入 / 储蓄', it: 'Deposita / Risparmia');
  String depositToGoalName(String name) => _t('Deposit to $name', ne: '$name मा बचत जम्मा', es: 'Depositar en $name', fr: 'Déposer sur $name', de: 'Auf $name einzahlen', ja: '$nameに積立', zh: '存入 $name', it: 'Deposita su $name');
  String get distributesIntoLinkedSavings => _t('Distributes funds directly into linked savings account', ne: 'जोडिएको बचत खातामा सिधै जम्मा हुनेछ', es: 'Distribuye fondos en la cuenta de ahorro vinculada', fr: 'Transfère les fonds sur le compte d\'épargne associé', de: 'Überweist Betrag direkt auf das verknüpfte Sparkonto', ja: '連携された貯金口座に直接入金されます', zh: '资金将直接转入关联的储蓄账户', it: 'Trasferisce i fondi direttamente sul conto risparmio collegato');
  String get contributeFundsTowardsGoal => _t('Contribute funds towards this goal', ne: 'यस लक्ष्यका लागि रकम योगदान गर्नुहोस्', es: 'Aportar fondos a esta meta', fr: 'Contribuer à cet objectif', de: 'Betrag zu diesem Ziel beitragen', ja: 'この目標に積立資金を追加します', zh: '为该目标追加储蓄资金', it: 'Contribuisci con fondi a questo obiettivo');
  String amountToAddWithCurrency(String currency) => _t('Amount to add ($currency)', ne: 'थप्ने रकम ($currency)', es: 'Importe a añadir ($currency)', fr: 'Montant à ajouter ($currency)', de: 'Betrag hinzufügen ($currency)', ja: '追加する金額 ($currency)', zh: '追加金额 ($currency)', it: 'Importo da aggiungere ($currency)');
  String get transferFrom => _t('Transfer from', ne: 'स्रोत खाता', es: 'Transferir desde', fr: 'Transférer depuis', de: 'Überweisen von', ja: '送金元口座', zh: '出资账户', it: 'Trasferisci da');
  String get directDepositOrExternal => _t('Direct deposit / External funds', ne: 'सिधा जम्मा / बाह्य स्रोत', es: 'Depósito directo / Fondos externos', fr: 'Dépôt direct / Fonds externes', de: 'Direkteinzahlung / Externe Mittel', ja: '直接入金・外部資金', zh: '直接存入 / 外部资金', it: 'Deposito diretto / Fondi esterni');
  String addedToGoalMessage(String amount, String goal) => _t('Added $amount to $goal', ne: '$goal मा $amount थपियो', es: 'Añadido $amount a $goal', fr: '$amount ajoutés à $goal', de: '$amount zu $goal hinzugefügt', ja: '$goalに$amountを追加しました', zh: '已向 $goal 存入 $amount', it: 'Aggiunto $amount a $goal');
  String get saveToGoal => _t('Save to Goal', ne: 'लक्ष्यमा बचत गर्नुहोस्', es: 'Guardar en la meta', fr: 'Enregistrer dans l\'objectif', de: 'Im Ziel ansparen', ja: '目標に保存', zh: '确认存入目标', it: 'Salva nell\'obiettivo');
  String get myGoal => _t('My goal', ne: 'मेरो लक्ष्य', es: 'Mi meta', fr: 'Mon objectif', de: 'Mein Ziel', ja: '私の目標', zh: '我的目标', it: 'Il mio obiettivo');
  String get emergencyFund => _t('Emergency fund', ne: 'आपतकालीन कोष', es: 'Fondo de emergencia', fr: 'Fonds d\'urgence', de: 'Notgroschen', ja: '緊急予備資金', zh: '应急备用金', it: 'Fondo di emergenza');
  String get cushionForSurprises => _t('A cushion for surprises', ne: 'अनपेक्षित खर्चहरूको लागि सुरक्षा', es: 'Un colchón para imprevistos', fr: 'Un coussin pour les imprévus', de: 'Ein Puffer für Überraschungen', ja: '不測の事態に備えるクッション', zh: '应对突发事件的资金缓冲', it: 'Un cuscinetto per imprevisti');
  String get somethingToBuy => _t('Something to buy', ne: 'केही किन्नको लागि', es: 'Algo para comprar', fr: 'Un achat prévu', de: 'Anschaffung', ja: '買いたいもの', zh: '想要购买的大件', it: 'Qualcosa da comprare');
  String get laptopBikeGift => _t('A laptop, a bike, a gift', ne: 'ल्यापटप, बाइक, वा उपहार', es: 'Un portátil, una bici, un regalo', fr: 'Un ordinateur, un vélo, un cadeau', de: 'Ein Laptop, ein Fahrrad, ein Geschenk', ja: 'パソコン、自転車、贈り物など', zh: '笔记本、自行车或礼物', it: 'Un portatile, una bici, un regalo');
  String get aTrip => _t('A trip', ne: 'यात्रा / भ्रमण', es: 'Un viaje', fr: 'Un voyage', de: 'Eine Reise', ja: '旅行', zh: '旅行出行', it: 'Un viaggio');
  String get somewhereYouWantToGo => _t('Somewhere you want to go', ne: 'तपाईं जान चाहेको स्थान', es: 'Un lugar al que quieres ir', fr: 'Un endroit où vous voulez aller', de: 'Ein Ort, den Sie besuchen möchten', ja: '行きたい場所への資金', zh: '想去的地方', it: 'Un posto in cui vuoi andare');
  String get somethingElse => _t('Something else', ne: 'अन्य लक्ष्य', es: 'Otro objetivo', fr: 'Autre chose', de: 'Etwas anderes', ja: 'その他の目的', zh: '其他目标', it: 'Altro');
  String get nameItYourself => _t('Name it yourself', ne: 'आफ्नै नाम दिनुहोस्', es: 'Nómbralo tú mismo', fr: 'Nommez-le vous-même', de: 'Selbst benennen', ja: '自由に名前をつける', zh: '自定义名称', it: 'Dai un nome personalizzato');
  String get goalName => _t('Goal name', ne: 'लक्ष्यको नाम', es: 'Nombre de la meta', fr: 'Nom de l\'objectif', de: 'Name des Ziels', ja: '目標名', zh: '目标名称', it: 'Nome obiettivo');
  String get goalNameHint => _t('e.g. Tuition', ne: 'जस्तै: ट्युसन फी', es: 'ej. Matrícula universitaria', fr: 'ex. Frais de scolarité', de: 'z.B. Studiengebühren', ja: '例: 学費、資格取得費', zh: '例如：学费、证书考取', it: 'es. Tassa universitaria');
  String get howMuchDoYouNeed => _t('How much do you need?', ne: 'कति रकम आवश्यक छ?', es: '¿Cuánto necesitas?', fr: 'De combien avez-vous besoin ?', de: 'Wie viel benötigen Sie?', ja: 'いくら必要ですか？', zh: '需要多少资金？', it: 'Di quanto hai bisogno?');
  String get roughNumberIsFine => _t('A rough number is fine.', ne: 'अन्दाजी भए पनि हुन्छ।', es: 'Una cifra aproximada está bien.', fr: 'Une estimation suffit.', de: 'Ein ungefährer Betrag genügt.', ja: '概算で構いません。', zh: '大概金额即可。', it: 'Una cifra approssimativa va bene.');
  String get targetAmount => _t('Target amount', ne: 'लक्ष्य रकम', es: 'Importe objetivo', fr: 'Montant cible', de: 'Zielbetrag', ja: '目標金額', zh: '目标金额', it: 'Importo obiettivo');
  String get initialDepositSavingsOptional => _t('Initial deposit to savings (Optional)', ne: 'सुरुवाती जम्मा रकम (वैकल्पिक)', es: 'Depósito inicial a ahorros (Opcional)', fr: 'Dépôt initial d\'épargne (Facultatif)', de: 'Anfangseinzahlung (Optional)', ja: '初回貯金額（任意）', zh: '初始存入资金（选填）', it: 'Deposito iniziale risparmi (Opzionale)');
  String get createSavingsAccountTitle => _t('Create Savings Account', ne: 'बचत खाता सिर्जना गर्नुहोस्', es: 'Crear cuenta de ahorros', fr: 'Créer un compte d\'épargne', de: 'Sparkonto erstellen', ja: '貯金口座を新規作成', zh: '新建储蓄账户', it: 'Crea conto risparmio');
  String get trackGoalWithoutAccount => _t('Track goal without a dedicated savings account', ne: 'खाता बिना लक्ष्य मात्र ट्र्याक गर्नुहोस्', es: 'Seguir meta sin cuenta dedicada', fr: 'Suivre l\'objectif sans compte dédié', de: 'Ziel ohne eigenes Sparkonto verfolgen', ja: '専用口座なしで目標のみ記録', zh: '仅跟踪目标，不绑定独立账户', it: 'Monitora obiettivo senza conto dedicato');
  String get byWhen => _t('By when?', ne: 'कहिलेसम्म पूरा गर्ने?', es: '¿Para cuándo?', fr: 'Pour quand ?', de: 'Bis wann?', ja: 'いつまでに達成しますか？', zh: '预计何时达成？', it: 'Entro quando?');
  String get workOutMonthlyAmount => _t('We will work out the monthly amount.', ne: 'हामी प्रति महिना चाहिने रकम हिसाब गर्नेछौं।', es: 'Calcularemos la cuota mensual.', fr: 'Nous calculerons la mensualité.', de: 'Wir ermitteln den monatlichen Sparbetrag.', ja: '毎月の必要積立額を算出します。', zh: '我们将自动计算每月所需金额。', it: 'Calcoleremo l\'importo mensile.');
  String get saveGoal => _t('Save goal', ne: 'लक्ष्य सुरक्षित गर्नुहोस्', es: 'Guardar meta', fr: 'Enregistrer l\'objectif', de: 'Ziel speichern', ja: '目標を保存', zh: '保存目标', it: 'Salva obiettivo');
  String monthsCountShort(int m) => _t('$m mo', ne: '$m महिना', es: '$m m', fr: '$m mois', de: '$m Mon.', ja: '$m ヶ月', zh: '$m 个月', it: '$m m');
  String get selectDatePrompt => _t('Date', ne: 'मिति छान्नुहोस्', es: 'Fecha', fr: 'Date', de: 'Datum', ja: '日付を選択', zh: '选择日期', it: 'Data');
  String get neededPerMonth => _t('Needed / month', ne: 'प्रति महिना आवश्यक', es: 'Necesario / mes', fr: 'Nécessaire / mois', de: 'Nötig / Monat', ja: '月あたり必要', zh: '每月需存', it: 'Necessario / mese');
  String get perMonthSuffix => _t('/ month', ne: '/ महिना', es: '/ mes', fr: '/ mois', de: '/ Monat', ja: '/ 月', zh: '/ 月', it: '/ mese');
  String get monthlyReminder => _t('Monthly reminder', ne: 'मासिक सम्झना (रिमाइन्डर)', es: 'Recordatorio mensual', fr: 'Rappel mensuel', de: 'Monatliche Erinnerung', ja: '月次リマインダー', zh: '每月提醒', it: 'Promemoria mensile');
  String get getNudgedMonthly => _t('Get nudged every month to stay on track', ne: 'प्रगतिको लागि प्रत्येक महिना सूचना प्राप्त गर्नुहोस्', es: 'Recibe avisos mensuales para no desviarte', fr: 'Recevez un rappel mensuel pour garder le cap', de: 'Erhalten Sie jeden Monat Erinnerungen', ja: '進捗を維持するために毎月通知を受け取る', zh: '每月接收提醒助您稳步达成目标', it: 'Ricevi promemoria mensili per rimanere in carreggiata');

  // Calendar Extended
  String get previousWeek => _t('Previous week', ne: 'अघिल्लो हप्ता', es: 'Semana anterior', fr: 'Semaine précédente', de: 'Vorherige Woche', ja: '前の週', zh: '上一周', it: 'Settimana precedente');
  String get nextWeek => _t('Next week', ne: 'अर्को हप्ता', es: 'Semana siguiente', fr: 'Semaine suivante', de: 'Nächste Woche', ja: '次の週', zh: '下一周', it: 'Settimana successiva');
  String get addEvent => _t('Add event', ne: 'इभेन्ट थप्नुहोस्', es: 'Añadir evento', fr: 'Ajouter un événement', de: 'Termin hinzufügen', ja: '予定を追加', zh: '添加日程', it: 'Aggiungi evento');
  String get bills => _t('Bills', ne: 'बिलहरू', es: 'Facturas', fr: 'Factures', de: 'Rechnungen', ja: '請求書・固定費', zh: '账单', it: 'Bollette');
  String addToDateTitle(String dateStr) => _t('Add to $dateStr', ne: '$dateStr मा थप्नुहोस्', es: 'Añadir a $dateStr', fr: 'Ajouter au $dateStr', de: 'Zu $dateStr hinzufügen', ja: '$dateStrに追加', zh: '添加到 $dateStr', it: 'Aggiungi a $dateStr');
  String get addWorkShiftWithRate => _t('Add a work shift with hours & hourly rate', ne: 'घण्टा र प्रति घण्टा दर सहित कामको सिफ्ट थप्नुहोस्', es: 'Añade turno con horas y tarifa', fr: 'Ajouter un quart avec heures et taux horaire', de: 'Arbeitsschicht mit Stunden und Stundensatz hinzufügen', ja: '勤務時間と時給を設定してシフトを追加', zh: '添加包含工时与时薪的排班', it: 'Aggiungi turno con ore e tariffa');
  String get recordExpenseOnDate => _t('Record money spent on this date', ne: 'यस मितिमा खर्च भएको रकम रेकर्ड गर्नुहोस्', es: 'Registrar gasto en esta fecha', fr: 'Enregistrer une dépense à cette date', de: 'Ausgabe für dieses Datum erfassen', ja: 'この日付の支出を記録', zh: '记录此日期的支出', it: 'Registra spesa in questa data');
  String get recordIncomeOnDate => _t('Record money received on this date', ne: 'यस मितिमा प्राप्त भएको रकम रेकर्ड गर्नुहोस्', es: 'Registrar ingreso en esta fecha', fr: 'Enregistrer un revenu à cette date', de: 'Einnahme für dieses Datum erfassen', ja: 'この日付の収入を記録', zh: '记录此日期的收入', it: 'Registra entrata in questa data');
  String get nothingScheduledForToday => _t('Nothing scheduled for today', ne: 'आज कुनै तालिका छैन', es: 'Nada programado para hoy', fr: 'Rien de prévu pour aujourd\'hui', de: 'Heute steht nichts an', ja: '今日の予定はありません', zh: '今日无日程', it: 'Niente in programma oggi');
  String get calendarEmptyAdvice => _t('Keep your schedule and money on track. Plan a shift or log an expense.', ne: 'आफ्नो तालिका र पैसा ट्र्याकमा राख्नुहोस्। सिफ्ट योजना बनाउनुहोस् वा खर्च रेकर्ड गर्नुहोस्।', es: 'Mantén tus horarios y finanzas al día. Planifica un turno o anota un gasto.', fr: 'Gardez le contrôle sur vos quarts et vos finances. Planifiez ou enregistrez.', de: 'Behalten Sie Schichten und Finanzen im Griff. Schicht planen oder Ausgabe erfassen.', ja: 'スケジュールと家計を管理しましょう。シフトを予定するか支出を記録してください。', zh: '保持日程与财务井然有序。计划班次或记录开销。', it: 'Tieni traccia di turni e finanze. Pianifica un turno o registra una spesa.');
  String get workShiftTag => _t('Work Shift', ne: 'कामको सिफ्ट', es: 'Turno de trabajo', fr: 'Quart de travail', de: 'Arbeitsschicht', ja: '勤務シフト', zh: '工作班次', it: 'Turno di lavoro');
  String get billTag => _t('Bill', ne: 'बिल', es: 'Factura', fr: 'Facture', de: 'Rechnung', ja: '請求書', zh: '账单', it: 'Bolletta');
  String get goalTag => _t('Goal', ne: 'लक्ष्य', es: 'Meta', fr: 'Objectif', de: 'Ziel', ja: '目標', zh: '目标', it: 'Obiettivo');
  String get scheduledStatus => _t('Scheduled', ne: 'तालिकाबद्ध', es: 'Programado', fr: 'Planifié', de: 'Geplant', ja: '予定済み', zh: '已安排', it: 'Pianificato');
  String get completedStatus => _t('Completed', ne: 'सम्पन्न', es: 'Completado', fr: 'Terminé', de: 'Abgeschlossen', ja: '完了', zh: '已完成', it: 'Completato');
  String get tapToManageShift => _t('Tap to manage shift', ne: 'सिफ्ट व्यवस्थापन गर्न ट्याप गर्नुहोस्', es: 'Toca para gestionar turno', fr: 'Appuyez pour gérer le quart', de: 'Tippen, um Schicht zu verwalten', ja: 'タップしてシフトを管理', zh: '轻触以管理班次', it: 'Tocca per gestire il turno');
  String get tapToViewDetails => _t('Tap to view details', ne: 'विवरण हेर्न ट्याप गर्नुहोस्', es: 'Toca para ver detalles', fr: 'Appuyez pour voir les détails', de: 'Tippen, um Details anzuzeigen', ja: 'タップして詳細を表示', zh: '轻触以查看详情', it: 'Tocca per vedere i dettagli');
  String get viewInWork => _t('View in Work', ne: 'काम पृष्ठमा हेर्नुहोस्', es: 'Ver en Trabajo', fr: 'Voir dans Travail', de: 'In Arbeit ansehen', ja: '仕事タブで表示', zh: '在工作面板查看', it: 'Visualizza in Lavoro');
  String get closeAction => _t('Close', ne: 'बन्द गर्नुहोस्', es: 'Cerrar', fr: 'Fermer', de: 'Schließen', ja: '閉じる', zh: '关闭', it: 'Chiudi');

  // Notifications & Alerts
  String get notifications => _t('Notifications', ne: 'सूचनाहरू', es: 'Notificaciones', fr: 'Notifications', de: 'Benachrichtigungen', ja: 'お知らせ', zh: '通知中心', it: 'Notifiche');
  String get allCaughtUp => _t('You are all caught up', ne: 'सबै ठीकठाक छ', es: 'Estás al día', fr: 'Vous êtes à jour', de: 'Alles auf dem neuesten Stand', ja: 'すべて確認済みです', zh: '您已查看所有提醒', it: 'Nessun nuovo avviso');
  String get notificationsEmptySubtitle => _t('Shift, bill and goal reminders will appear here.', ne: 'सिफ्ट, बिल तथा लक्ष्यका रिमाइन्डरहरू यहाँ देखिनेछन्।', es: 'Los recordatorios de turnos, facturas y metas aparecerán aquí.', fr: 'Les rappels de quarts, factures et objectifs s\'afficheront ici.', de: 'Erinnerungen an Schichten, Rechnungen und Ziele erscheinen hier.', ja: 'シフトや請求書、目標のリマインダーがここに表示されます。', zh: '排班、账单与目标提醒将在这里展示。', it: 'I promemoria per turni, bollette e obiettivi appariranno qui.');
  String get manageAlerts => _t('Manage alerts', ne: 'सूचना व्यवस्थापन', es: 'Gestionar alertas', fr: 'Gérer les alertes', de: 'Benachrichtigungen verwalten', ja: '通知を管理', zh: '管理通知提醒', it: 'Gestisci avvisi');
  String get whichAlertsQuestion => _t('Which alerts do you want?', ne: 'तपाईंलाई कुन सूचनाहरू चाहिन्छ?', es: '¿Qué alertas deseas?', fr: 'Quelles alertes souhaitez-vous ?', de: 'Welche Benachrichtigungen wünschen Sie?', ja: 'どの通知を受け取りますか？', zh: '您希望接收哪些提醒？', it: 'Quali avvisi desideri?');
  String get changeThemAnytime => _t('Change them any time.', ne: 'कुनै पनि समय परिवर्तन गर्न सक्नुहुन्छ।', es: 'Cámbialas cuando quieras.', fr: 'Modifiables à tout moment.', de: 'Jederzeit änderbar.', ja: 'いつでも変更できます。', zh: '随时可在设置中调整。', it: 'Modificali in qualsiasi momento.');
  String get shiftRemindersTitle => _t('Shift reminders', ne: 'सिफ्ट सूचना', es: 'Recordatorios de turnos', fr: 'Rappels de quarts', de: 'Schichterinnerungen', ja: 'シフトのリマインダー', zh: '班次提醒', it: 'Promemoria turni');
  String get oneHourBefore => _t('1 hour before', ne: '१ घण्टा अगाडि', es: '1 hora antes', fr: '1 heure avant', de: '1 Stunde vorher', ja: '1時間前', zh: '提前1小时', it: '1 ora prima');
  String get clockOutReminderTitle => _t('Clock-out reminder', ne: 'सिफ्ट समाप्त सम्झना', es: 'Recordatorio de salida', fr: 'Rappel de fin de quart', de: 'Erinnerung zum Ausstempeln', ja: '退勤リマインダー', zh: '下班打卡提醒', it: 'Promemoria uscita turno');
  String get after6Hours => _t('After 6 hours', ne: '६ घण्टा पछि', es: 'Tras 6 horas', fr: 'Après 6 heures', de: 'Nach 6 Stunden', ja: '6時間経過後', zh: '工作6小时后', it: 'Dopo 6 ore');
  String get billsDueTitle => _t('Bills due', ne: 'बिल भुक्तानी बाँकी', es: 'Facturas pendientes', fr: 'Factures à payer', de: 'Fällige Rechnungen', ja: '支払い期日のお知らせ', zh: '待付账单提醒', it: 'Bollette in scadenza');
  String get oneDayBefore => _t('1 day before', ne: '१ दिन अगाडि', es: '1 día antes', fr: '1 jour avant', de: '1 Tag vorher', ja: '前日', zh: '提前1天', it: '1 giorno prima');
  String get goalNudgesTitle => _t('Goal nudges', ne: 'लक्ष्य सुझाव', es: 'Avisos de metas', fr: 'Encouragements d\'objectifs', de: 'Ziel-Anstupser', ja: '目標の進捗アドバイス', zh: '目标储蓄进度督促', it: 'Solleciti obiettivi');
  String get weekly => _t('Weekly', ne: 'साप्ताहिक', es: 'Semanal', fr: 'Hebdomadaire', de: 'Wöchentlich', ja: '毎週', zh: '每周', it: 'Settimanale');
  String get weeklySummaryTitle => _t('Weekly summary', ne: 'साप्ताहिक सारांश', es: 'Resumen semanal', fr: 'Résumé hebdomadaire', de: 'Wöchentliche Zusammenfassung', ja: '週間サマリーレポート', zh: '每周财务周报', it: 'Riepilogo settimanale');
  String get sundayEvening => _t('Sunday evening', ne: 'आइतबार साँझ', es: 'Domingo por la tarde', fr: 'Dimanche soir', de: 'Sonntagabend', ja: '日曜日の夕方', zh: '周日晚上', it: 'Domenica sera');
  String get quietHoursTitle => _t('Quiet hours', ne: 'शान्त समय', es: 'Horas de silencio', fr: 'Heures de repos', de: 'Ruhezeiten', ja: 'おやすみモード', zh: '静音免打扰时段', it: 'Ore di silenzio');
  String get quietHoursTimeRange => _t('10 pm to 7 am', ne: 'राती १० देखि बिहान ७ बजेसम्म', es: '22:00 a 7:00', fr: '22h00 à 7h00', de: '22:00 bis 07:00 Uhr', ja: '22:00 〜 07:00', zh: '22:00 至 07:00', it: 'Dalle 22:00 alle 07:00');

  // Analytics Extended
  String get exportAnalytics => _t('Export analytics', ne: 'विश्लेषिकी निर्यात', es: 'Exportar analíticas', fr: 'Exporter les analyses', de: 'Analysen exportieren', ja: '分析データをエクスポート', zh: '导出财务分析', it: 'Esporta statistiche');
  String get noDataForThisFilter => _t('No data for this filter', ne: 'यस फिल्टरको लागि कुनै डाटा छैन', es: 'Sin datos para este filtro', fr: 'Aucune donnée pour ce filtre', de: 'Keine Daten für diesen Filter', ja: 'この条件に該当するデータはありません', zh: '当前筛选条件下无数据', it: 'Nessun dato per questo filtro');
  String get noDataFilterAdvice => _t('Try selecting a different date range or resetting category filters.', ne: 'फरक मिति दायरा छान्नुहोस् वा वर्ग फिल्टर हटाउनुहोस्।', es: 'Prueba con otro rango de fechas o restablece los filtros.', fr: 'Essayez une autre plage de dates ou réinitialisez les filtres.', de: 'Anderen Zeitraum wählen oder Filter zurücksetzen.', ja: '別の日付範囲を選択するか、フィルターをリセットしてください。', zh: '请尝试选择不同日期范围或清除分类筛选。', it: 'Prova a selezionare un periodo diverso o a reimpostare i filtri.');
  String get addExpensesForSpendingAdvice => _t('Add a few expense transactions and your spending will show up here.', ne: 'केही खर्च कारोबारहरू थप्नुहोस्, तपाईंको खर्च यहाँ देखा पर्नेछ।', es: 'Añade transacciones de gasto para ver tus estadísticas.', fr: 'Ajoutez des dépenses pour voir apparaître vos statistiques.', de: 'Fügen Sie Ausgaben hinzu, um hier Auswertungen zu sehen.', ja: '支出を記録すると、ここにグラフが表示されます。', zh: '添加几笔支出记账，您的消费分析将在此展示。', it: 'Aggiungi alcune spese per visualizzare i tuoi grafici qui.');
  String get addIncomeForEarningsAdvice => _t('Add income transactions and your earnings will show up here.', ne: 'आम्दानी कारोबारहरू थप्नुहोस् र तपाईंको आम्दानी यहाँ देखा पर्नेछ।', es: 'Añade ingresos para ver reflejadas tus ganancias.', fr: 'Ajoutez des revenus pour voir vos gains s\'afficher.', de: 'Fügen Sie Einnahmen hinzu, um Ihre Verdienste zu sehen.', ja: '収入を記録すると、ここに収支推移が表示されます。', zh: '添加收入记账，您的进账分析将在此展示。', it: 'Aggiungi entrate per visualizzare i tuoi guadagni qui.');
  String categorySpendingLabel(String cat) => _t('$cat spending', ne: '$cat खर्च', es: 'Gasto en $cat', fr: 'Dépenses en $cat', de: '$cat Ausgaben', ja: '$catの支出', zh: '$cat开支', it: 'Spese per $cat');
  String categoryIncomeLabel(String cat) => _t('$cat income', ne: '$cat आम्दानी', es: 'Ingresos por $cat', fr: 'Revenus de $cat', de: '$cat Einnahmen', ja: '$catの収入', zh: '$cat进账', it: 'Entrate da $cat');
  String get totalSpending => _t('Total spending', ne: 'कुल खर्च', es: 'Gasto total', fr: 'Dépenses totales', de: 'Gesamtausgaben', ja: '総支出', zh: '总支出', it: 'Spesa totale');
  String get totalIncome => _t('Total income', ne: 'कुल आम्दानी', es: 'Ingresos totales', fr: 'Revenus totaux', de: 'Gesamteinnahmen', ja: '総収入', zh: '总收入', it: 'Entrate totali');
  String get filteredLabel => _t('Filtered', ne: 'फिल्टर गरिएको', es: 'Filtrado', fr: 'Filtré', de: 'Gefiltert', ja: 'フィルター適用中', zh: '已筛选', it: 'Filtrato');
  String get netSavings => _t('Net savings', ne: 'खुद बचत', es: 'Ahorro neto', fr: 'Épargne nette', de: 'Nettoersparnis', ja: '純貯蓄額', zh: '净结余', it: 'Risparmio netto');
  String get whereItWent => _t('Where it went', ne: 'कहाँ खर्च भयो', es: 'En qué se fue', fr: 'Où est passé l\'argent', de: 'Wohin das Geld floss', ja: '支出の内訳', zh: '资金去向', it: 'Dove sono andati');
  String get incomeSources => _t('Income sources', ne: 'आम्दानीका स्रोतहरू', es: 'Fuentes de ingresos', fr: 'Sources de revenus', de: 'Einnahmequellen', ja: '収入の内訳', zh: '收入来源', it: 'Fonti di reddito');
  String get topSourcesForCategory => _t('Top sources for this category', ne: 'यस वर्गका प्रमुख स्रोतहरू', es: 'Principales fuentes para esta categoría', fr: 'Principales sources pour cette catégorie', de: 'Top-Quellen dieser Kategorie', ja: 'このカテゴリーの主な取引先', zh: '该分类的主要往来来源', it: 'Fonti principali per questa categoria');
  String get topMerchants => _t('Top merchants', ne: 'शीर्ष व्यापारीहरू', es: 'Principales comercios', fr: 'Principaux commerçants', de: 'Top-Geschäfte', ja: '利用頻度の高い店舗', zh: '主要消费商户', it: 'Commercianti principali');
  String get topIncomeSources => _t('Top income sources', ne: 'शीर्ष आम्दानी स्रोतहरू', es: 'Principales fuentes de ingresos', fr: 'Principales sources de revenus', de: 'Top-Einnahmequellen', ja: '主な収入源', zh: '主要进账渠道', it: 'Fonti di reddito principali');
  String projectedMonthEndText(String amount) => _t('Projected month-end: $amount', ne: 'महिनाको अन्त्य अनुमानित: $amount', es: 'Fin de mes proyectado: $amount', fr: 'Fin de mois projetée : $amount', de: 'Prognostiziertes Monatsende: $amount', ja: '月末の予測着地残高: $amount', zh: '预计月末结余: $amount', it: 'Fine mese previsto: $amount');
  String get basedOnShiftsAndRecurring => _t('Based on active shifts and recurring rules', ne: 'सक्रिय सिफ्टहरू र आवर्ती नियमहरूमा आधारित', es: 'Basado en turnos activos y reglas recurrentes', fr: 'Basé sur les quarts actifs et règles récurrentes', de: 'Basiert auf aktiven Schichten und Wiederholungen', ja: '予定されたシフトと定期収支に基づきます', zh: '基于排班计划与固定收支规则测算', it: 'Basato su turni attivi e regole ricorrenti');
  String get netDebtPositionHeader => _t('NET DEBT POSITION', ne: 'कुल बाँकी ब्यालेन्स', es: 'POSICIÓN NETA DE DEUDA', fr: 'POSITION NETTE DE DETTE', de: 'NETTO-SCHULDENPOSITION', ja: '純借入ポジション', zh: '净借贷状况', it: 'POSIZIONE NETTA DEBITO');
  String get filterByCategoryTitle => _t('Filter by Category', ne: 'वर्ग अनुसार फिल्टर', es: 'Filtrar por categoría', fr: 'Filtrer par catégorie', de: 'Nach Kategorie filtern', ja: 'カテゴリーで絞り込む', zh: '按分类筛选', it: 'Filtra per categoria');
  String get allCategoriesTitle => _t('All Categories', ne: 'सबै वर्गहरू', es: 'Todas las categorías', fr: 'Toutes les catégories', de: 'Alle Kategorien', ja: 'すべてのカテゴリー', zh: '全部分类', it: 'Tutte le categorie');
  String get owesYou => _t('Owes you', ne: 'उनीहरूले तिर्नुपर्ने', es: 'Te debe', fr: 'Vous doit', de: 'Schuldet Ihnen', ja: '回収待ち', zh: '待还给您', it: 'Ti deve');

  // Settings & Manage Jobs Extended
  String get newJob => _t('New Job', ne: 'नयाँ काम', es: 'Nuevo empleo', fr: 'Nouvel emploi', de: 'Neuer Job', ja: '新しい仕事', zh: '新增工作', it: 'Nuovo lavoro');
  String get noJobsAddedYet => _t('No jobs added yet', ne: 'कुनै रोजगार थपिएको छैन', es: 'Sin empleos registrados aún', fr: 'Aucun emploi ajouté', de: 'Noch keine Jobs erfasst', ja: '勤務先がまだ登録されていません', zh: '暂未添加任何工作岗位', it: 'Nessun lavoro aggiunto');
  String get addFirstJob => _t('Add First Job', ne: 'पहिलो रोजगार थप्नुहोस्', es: 'Añadir primer empleo', fr: 'Ajouter un premier emploi', de: 'Ersten Job hinzufügen', ja: '最初の仕事を登録', zh: '添加首个工作岗位', it: 'Aggiungi primo lavoro');
  String get archived => _t('Archived', ne: 'अभिलेख', es: 'Archivado', fr: 'Archivé', de: 'Archiviert', ja: 'アーカイブ済み', zh: '已归档', it: 'Archiviato');
  String get hourlyRateLabel => _t('Hourly Rate', ne: 'प्रति घण्टा दर', es: 'Tarifa por hora', fr: 'Taux horaire', de: 'Stundensatz', ja: '基本時給', zh: '基础时薪', it: 'Tariffa oraria');
  String get editRate => _t('Edit Rate', ne: 'दर सम्पादन', es: 'Editar tarifa', fr: 'Modifier le taux', de: 'Satz bearbeiten', ja: '時給を編集', zh: '修改时薪', it: 'Modifica tariffa');
  String editJobName(String name) => _t('Edit $name', ne: '$name सम्पादन गर्नुहोस्', es: 'Editar $name', fr: 'Modifier $name', de: '$name bearbeiten', ja: '$nameを編集', zh: '编辑 $name', it: 'Modifica $name');
  String get jobNameLabel => _t('Job name', ne: 'रोजगारको नाम', es: 'Nombre del puesto', fr: 'Nom du poste', de: 'Jobbezeichnung', ja: '職種・役職名', zh: '工作名称', it: 'Nome lavoro');
  String hourlyRateWithCurrency(String c) => _t('Hourly rate ($c)', ne: 'प्रति घण्टा दर ($c)', es: 'Tarifa por hora ($c)', fr: 'Taux horaire ($c)', de: 'Stundensatz ($c)', ja: '時給 ($c)', zh: '时薪 ($c)', it: 'Tariffa oraria ($c)');
  String get employerVenueOptional => _t('Employer / Venue (Optional)', ne: 'रोजगारदाता / स्थान (वैकल्पिक)', es: 'Empleador / Lugar (Opcional)', fr: 'Employeur / Lieu (Facultatif)', de: 'Arbeitgeber / Ort (Optional)', ja: '勤務先 / 店舗名（任意）', zh: '雇主 / 工作地点（选填）', it: 'Datore / Luogo (Opzionale)');
  String get onState => _t('On', ne: 'चालु', es: 'Activado', fr: 'Activé', de: 'Ein', ja: 'オン', zh: '开', it: 'Acceso');
  String get offState => _t('Off', ne: 'बन्द', es: 'Desactivado', fr: 'Désactivé', de: 'Aus', ja: 'オフ', zh: '关', it: 'Spento');
  String get financialInsightsAdvice => _t('Chat for financial insights & shift advice', ne: 'वित्तीय सल्लाह र सिफ्ट योजना', es: 'Consejos financieros y planificación', fr: 'Conseils financiers et analyse de quarts', de: 'Finanztipps und Schichtberatung', ja: 'お金の分析やシフトの相談ができます', zh: '智能分析收支与排班规划建议', it: 'Consigli finanziari e pianificazione turni');
  String get floatingAssistantButton => _t('Floating assistant button', ne: 'फ्लोटिंग एआई बटन', es: 'Botón flotante del asistente', fr: 'Bouton flottant d\'assistant', de: 'Schwebende Assistententaste', ja: 'AIアシスタントの常時フローティング表示', zh: '悬浮AI助手快捷入口', it: 'Pulsante assistente fluttuante');
  String get floatingAssistantDesc => _t('Show quick AI button above the bottom bar', ne: 'तल्लो पट्टी माथि द्रुत एआई बटन देखाउनुहोस्', es: 'Mostrar botón de acceso rápido sobre la barra', fr: 'Afficher un bouton rapide au-dessus de la barre', de: 'Schnellzugriffstaste über der Leiste anzeigen', ja: '下部ナビゲーションの上にAI呼び出しボタンを表示', zh: '在底部导航栏上方显示AI快捷入口', it: 'Mostra pulsante rapido sopra la barra inferiore');
  String get backupSyncDesc => _t('Hyprwise Cloud sync, PDF reports, JSON restore', ne: 'हाइपरवाइज क्लाउड सिंक, पीडीएफ रिपोर्ट, डाटा रिस्टोर', hi: 'हाइपरवाइज क्लाउड सिंक, पीडीएफ रिपोर्ट, डेटा रिस्टोर', es: 'Sincronización en la nube, informes PDF y JSON', fr: 'Sync cloud Hyprwise, rapports PDF, restauration JSON', de: 'Hyprwise Cloud-Sync, PDF-Berichte, JSON-Restore', ja: 'Hyprwiseクラウド同期・PDFレポート・JSON復元', zh: 'Hyprwise 云端同步、PDF财务报表与数据恢复', it: 'Sync cloud Hyprwise, report PDF, ripristino JSON');
  String get aboutAndLegal => _t('About & Legal', ne: 'कानुनी र बारेमा', es: 'Acerca de y legal', fr: 'À propos et mentions légales', de: 'Rechtliches & Über uns', ja: '規約とアプリ情報', zh: '法律条款与关于', it: 'Info e note legali');
  String get localFirstDataProtection => _t('Local-first & data protection', ne: 'स्थानीय-पहिलो र डाटा सुरक्षा', es: 'Local-first y protección de datos', fr: 'Local d\'abord et protection des données', de: 'Lokal-First und Datenschutz', ja: '端末ローカル保存・完全データ保護', zh: '本地优先架构与数据隐私保护', it: 'Locale e protezione dei dati');
  String get userAgreementSubscriptionRules => _t('User agreement & subscription rules', ne: 'प्रयोगकर्ता सम्झौता र सदस्यता नियम', es: 'Términos de servicio y suscripción', fr: 'Conditions d\'utilisation et abonnement', de: 'Nutzungsbedingungen & Abo-Regeln', ja: '利用規約およびサブスクリプション規約', zh: '用户协议与会员订阅规则', it: 'Accordo utente e regole di abbonamento');
  String get eraseAllDataQuestion => _t('Erase all data?', ne: 'सबै डाटा मेटाउने?', es: '¿Borrar todos los datos?', fr: 'Effacer toutes les données ?', de: 'Alle Daten löschen?', ja: 'すべてのデータを削除しますか？', zh: '确定清除所有数据？', it: 'Cancellare tutti i dati?');
  String get eraseEverything => _t('Erase everything', ne: 'सबै मेटाउनुहोस्', es: 'Borrar todo', fr: 'Tout effacer', de: 'Alles löschen', ja: 'すべて消去', zh: '彻底清除', it: 'Cancella tutto');
  String get deleteAccountAndCloudBackups => _t('Delete Account & Cloud Backups', ne: 'खाता र क्लाउड डाटा मेटाउनुहोस्', es: 'Eliminar cuenta y copias en la nube', fr: 'Supprimer le compte et les sauvegardes cloud', de: 'Konto und Cloud-Backups löschen', ja: 'アカウントおよびクラウドデータの削除', zh: '注销账户及云端备份', it: 'Elimina account e backup cloud');
  String get deleteAccountSubtitle => _t('Permanently remove cloud backups & user profile', ne: 'क्लाउड ब्याकअप र प्रयोगकर्ता प्रोफाइल स्थायी रूपमा हटाउनुहोस्', hi: 'क्लाउड बैकअप और उपयोगकर्ता प्रोफ़ाइल हमेशा के लिए हटाएं', es: 'Eliminar copias y perfil permanentemente', fr: 'Supprimer définitivement sauvegardes et profil', de: 'Cloud-Backups & Profil dauerhaft löschen', ja: 'クラウドデータおよび登録情報を完全に削除します', zh: '永久删除云端备份数据与用户资料', it: 'Rimuovi definitivamente backup cloud e profilo');
  String get deleteAccountPermanentlyQuestion => _t('Delete account permanently?', ne: 'खाता स्थायी रूपमा मेटाउने?', es: '¿Eliminar la cuenta permanentemente?', fr: 'Supprimer définitivement le compte ?', de: 'Konto dauerhaft löschen?', ja: 'アカウントを完全に削除しますか？', zh: '确定要永久注销账户？', it: 'Eliminare definitivamente l\'account?');
  String get backUpYourData => _t('Back up your data', ne: 'डाटा ब्याकअप तथा सुरक्षा', es: 'Haz una copia de tus datos', fr: 'Sauvegardez vos données', de: 'Sichern Sie Ihre Daten', ja: 'データのバックアップと保護', zh: '数据备份与迁移', it: 'Esegui il backup dei dati');
  String get encryptedBeforeUpload => _t('Encrypted before upload', ne: 'अपलोड अघि सुरक्षित इन्क्रिप्टेड', es: 'Cifrado antes de subir', fr: 'Chiffré avant envoi', de: 'Vor dem Upload verschlüsselt', ja: '送信前に端末内で暗号化', zh: '上传前本地高强度加密', it: 'Crittografato prima dell\'upload');
  String get leavesPhoneUnreadable => _t('It leaves your phone unreadable to others', ne: 'तपाईंको अनुमति बिना कसैले पढ्न सक्दैन', es: 'Nadie más puede leer tus datos', fr: 'Illisible pour les tiers hors de votre téléphone', de: 'Für Dritte unlesbar geschützt', ja: '暗号化されているため第三者は閲覧できません', zh: '数据脱敏加密，未经许可无法查看', it: 'I tuoi dati non possono essere letti da altri');
  String get storedInCloud => _t('Stored in Hyprwise Cloud & local storage', ne: 'हाइपरवाइज क्लाउड वा फोनमा सुरक्षित भण्डारण', hi: 'हाइपरवाइज क्लाउड या फोन में सुरक्षित स्टोरेज', es: 'Guardado en la nube Hyprwise y almacenamiento local', fr: 'Stocké dans Hyprwise Cloud et en local', de: 'In Hyprwise Cloud & lokal gespeichert', ja: 'Hyprwiseクラウドおよび端末ローカルに安全に保存', zh: '安全保存在 Hyprwise 云端及本地存储中', it: 'Archiviato su Hyprwise Cloud e in locale');
  String get directlyInPrivateStorage => _t('Directly in your private storage', ne: 'तपाईंको आफ्नै नियन्त्रणमा रहन्छ', es: 'Directamente en tu almacenamiento privado', fr: 'Dans votre espace privé exclusivement', de: 'Direkt in Ihrem privaten Speicher', ja: 'プライベートな個人領域で安全に保管', zh: '完全归属于您的个人私有存储空间', it: 'Direttamente nel tuo spazio privato');
  String get restoreAnytimeNewPhone => _t('Restore anytime on a new phone', ne: 'नयाँ फोनमा तुरुन्त रिस्टोर', es: 'Restaura cuando quieras en un móvil nuevo', fr: 'Restaurez à tout moment sur un nouvel appareil', de: 'Jederzeit auf neuem Telefon wiederherstellen', ja: '新しいスマートフォンでも即座に復元可能', zh: '更换手机时随时随地一键还原', it: 'Ripristina quando vuoi su un nuovo telefono');
  String get oneClickToRestore => _t('One click to restore all jobs and shifts', ne: 'एक क्लिकमा सम्पूर्ण डाटा फिर्ता', es: 'Un clic para recuperar turnos y datos', fr: 'Restaurez tous vos quarts en un clic', de: 'Mit einem Klick alle Schichten wiederherstellen', ja: 'ワンタップですべての仕事やシフトを復旧', zh: '一键完整恢复工作、班次及账单数据', it: 'Un clic per ripristinare tutti i turni');
  String get cloudBackupTitle => _t('Hyprwise Cloud Backup', ne: 'हाइपरवाइज क्लाउड ब्याकअप', hi: 'हाइपरवाइज क्लाउड बैकअप', es: 'Copia en la nube Hyprwise', fr: 'Sauvegarde Hyprwise Cloud', de: 'Hyprwise Cloud-Backup', ja: 'Hyprwiseクラウドバックアップ', zh: 'Hyprwise 云端备份', it: 'Backup Hyprwise Cloud');
  String get cloudBackupSubtitle => _t('Export & upload encrypted backup to Hyprwise Cloud', ne: 'इन्क्रिप्टेड ब्याकअप हाइपरवाइज क्लाउडमा सुरक्षित गर्नुहोस्', hi: 'एन्क्रिप्टेड बैकअप हाइपरवाइज क्लाउड में सुरक्षित करें', es: 'Exporta y sube copia cifrada a la nube Hyprwise', fr: 'Exporter et envoyer la sauvegarde chiffrée sur Hyprwise Cloud', de: 'Verschlüsseltes Backup in die Hyprwise Cloud laden', ja: '暗号化バックアップをHyprwiseクラウドに安全に同期', zh: '导出加密备份文件并上传到 Hyprwise 专属云端', it: 'Esporta e carica backup crittografato su Hyprwise Cloud');
  String get hyprwiseCloudSync => _t('Hyprwise Cloud Sync', ne: 'हाइपरवाइज क्लाउड सिंक', es: 'Sincronización en la nube Hyprwise', fr: 'Synchronisation Cloud Hyprwise', de: 'Hyprwise Cloud-Synchronisierung', ja: 'Hyprwise クラウド同期', zh: 'Hyprwise 云端同步', it: 'Sincronizzazione Cloud Hyprwise');
  String connectedAccountEmail(String email) => _t('Connected: $email', ne: 'जोडिएको खाता: $email', es: 'Conectado: $email', fr: 'Connecté : $email', de: 'Verbunden: $email', ja: '接続中: $email', zh: '已绑定: $email', it: 'Collegato: $email');
  String get signInToSyncHono => _t('Sign in to sync with Hono cloud server', ne: 'सर्भरसँग सिंक गर्न लगइन गर्नुहोस्', es: 'Inicia sesión para sincronizar con el servidor', fr: 'Connectez-vous pour synchroniser avec le serveur', de: 'Anmelden, um mit Server zu synchronisieren', ja: 'クラウドサーバーと同期するにはログインしてください', zh: '登录以同步到专属云端服务器', it: 'Accedi per sincronizzare con il server cloud');
  String get cloudSyncProFeature => _t('Cloud Sync is a Pro Feature', ne: 'क्लाउड सिंक प्रो सुविधा हो', es: 'La sincronización en la nube es Pro', fr: 'La synchro cloud est une fonction Pro', de: 'Cloud-Sync ist eine Pro-Funktion', ja: 'クラウド同期はPro限定機能です', zh: '云端同步为会员专享功能', it: 'La sincronizzazione cloud è una funzione Pro');
  String get exportDataFormats => _t('Export data (CSV, JSON, Report)', ne: 'डाटा निर्यात (CSV, JSON, रिपोर्ट)', es: 'Exportar datos (CSV, JSON, Informe)', fr: 'Exporter les données (CSV, JSON, Rapport)', de: 'Daten exportieren (CSV, JSON, Bericht)', ja: 'データのエクスポート (CSV, JSON, レポート)', zh: '导出个人财务数据 (CSV, JSON, 报表)', it: 'Esporta dati (CSV, JSON, Report)');
  String get saveToDownloadsOrShare => _t('Save to device Downloads folder or share to app', ne: 'डाउनलोड फोल्डरमा सेभ गर्नुहोस् वा सेयर गर्नुहोस्', es: 'Guardar en descargas o compartir', fr: 'Enregistrer dans Téléchargements ou partager', de: 'In Downloads speichern oder teilen', ja: '端末のダウンロードフォルダに保存または共有', zh: '保存到手机下载目录或分享到其他应用', it: 'Salva nei download o condividi');
  String get restoreFromJsonBackup => _t('Restore from JSON backup', ne: 'JSON ब्याकअपबाट रिस्टोर गर्नुहोस्', es: 'Restaurar desde copia JSON', fr: 'Restaurer depuis sauvegarde JSON', de: 'Aus JSON-Backup wiederherstellen', ja: 'JSONバックアップファイルから復元', zh: '从 JSON 备份文件还原', it: 'Ripristina da backup JSON');
  String get chooseJsonBackupFile => _t('Choose a .json backup file from device storage', ne: 'यन्त्रबाट .json ब्याकअप फाइल रोज्नुहोस्', es: 'Elige un archivo .json del almacenamiento', fr: 'Choisissez un fichier .json sur l\'appareil', de: 'Wählen Sie eine .json-Datei aus dem Speicher', ja: '端末ストレージから.jsonファイルを選択', zh: '从本地存储选择 .json 格式备份文件', it: 'Scegli un file di backup .json dal dispositivo');
  String get preparingDriveBackup => _t('Preparing backup...', ne: 'ब्याकअप तयार हुँदैछ...', hi: 'बैकअप तैयार हो रहा है...', es: 'Preparando copia...', fr: 'Préparation de la sauvegarde...', de: 'Backup wird vorbereitet...', ja: 'バックアップを準備しています...', zh: '正在生成备份...', it: 'Preparazione backup...');
  String get chooseDriveToComplete => _t('Save or share backup file', ne: 'ब्याकअप फाइल सुरक्षित गर्नुहोस्', hi: 'बैकअप फ़ाइल सुरक्षित करें', es: 'Guarda o comparte el archivo de respaldo', fr: 'Enregistrez ou partagez le fichier de sauvegarde', de: 'Backup-Datei speichern oder teilen', ja: 'バックアップファイルを保存または共有', zh: '保存或分享备份文件', it: 'Salva o condividi il file di backup');
  String get offlineSignInRequired => _t('Offline / Sign in required', ne: 'अफलाइन / लगइन आवश्यक', es: 'Desconectado / Iniciar sesión requerido', fr: 'Hors ligne / Connexion requise', de: 'Offline / Anmeldung erforderlich', ja: 'オフライン / ログインが必要です', zh: '离线状态 / 需先登录', it: 'Offline / Accesso richiesto');
  String get serverSyncStatus => _t('Server Sync Status', ne: 'सर्भर सिंक स्थिति', es: 'Estado de sincronización', fr: 'État de synchronisation du serveur', de: 'Server-Synchronisierungsstatus', ja: 'サーバー同期ステータス', zh: '服务器同步状态', it: 'Stato sincronizzazione server');
  String get pushDataToCloud => _t('Push Data to Cloud', ne: 'डाटा क्लाउडमा अपलोड गर्नुहोस् (Push)', es: 'Subir datos a la nube', fr: 'Envoyer les données vers le cloud', de: 'Daten in die Cloud hochladen', ja: '端末データをクラウドへ送信 (Push)', zh: '上传数据至云端 (Push)', it: 'Invia dati al cloud');
  String get couldNotConnectServer => _t('Could not connect to Hyprwise server', ne: 'सर्भर जडान हुन सकेन', es: 'No se pudo conectar al servidor Hyprwise', fr: 'Impossible de se connecter au serveur Hyprwise', de: 'Verbindung zum Hyprwise-Server fehlgeschlagen', ja: 'Hyprwise サーバーに接続できませんでした', zh: '无法连接至 Hyprwise 云端服务器', it: 'Impossibile connettersi al server Hyprwise');
  String get pullDataFromCloud => _t('Pull Data from Cloud', ne: 'क्लाउडबाट डाटा फिर्ता लिनुहोस् (Pull)', es: 'Descargar datos de la nube', fr: 'Récupérer les données du cloud', de: 'Daten aus der Cloud abrufen', ja: 'クラウドからデータを復元 (Pull)', zh: '从云端同步还原 (Pull)', it: 'Scarica dati dal cloud');
  String get restoreFromCloudQuestion => _t('Restore from Cloud?', ne: 'क्लाउडबाट रिस्टोर गर्ने?', es: '¿Restaurar desde la nube?', fr: 'Restaurer depuis le cloud ?', de: 'Aus der Cloud wiederherstellen?', ja: 'クラウドから復元しますか？', zh: '确定从云端恢复数据？', it: 'Ripristinare dal cloud?');
  String get restoreFromCloudAction => _t('Restore from Cloud', ne: 'रिस्टोर गर्नुहोस्', es: 'Restaurar de la nube', fr: 'Restaurer du cloud', de: 'Aus Cloud wiederherstellen', ja: 'クラウドから復元', zh: '从云端还原', it: 'Ripristina dal cloud');
  String get couldNotReadFile => _t('Could not read chosen file', ne: 'फाइल पढ्न सकिएन', es: 'No se pudo leer el archivo', fr: 'Impossible de lire le fichier', de: 'Datei konnte nicht gelesen werden', ja: '選択したファイルを読み込めませんでした', zh: '无法读取所选备份文件', it: 'Impossibile leggere il file selezionato');
  String get restoreFromBackupQuestion => _t('Restore from Backup?', ne: 'ब्याकअपबाट रिस्टोर गर्ने?', es: '¿Restaurar desde la copia?', fr: 'Restaurer depuis la sauvegarde ?', de: 'Aus Backup wiederherstellen?', ja: 'バックアップから復元しますか？', zh: '确定从该备份还原？', it: 'Ripristinare dal backup?');
  String get restoreDataAction => _t('Restore data', ne: 'डाटा रिस्टोर गर्नुहोस्', es: 'Restaurar datos', fr: 'Restaurer les données', de: 'Daten wiederherstellen', ja: 'データを復元', zh: '确认恢复数据', it: 'Ripristina dati');

  // AI Assistant Extended
  String get dailyAiLimitReached => _t('Daily AI Limit Reached', ne: 'दैनिक एआई सीमा पुग्यो', es: 'Límite diario de IA alcanzado', fr: 'Limite quotidienne d\'IA atteinte', de: 'Tägliches KI-Limit erreicht', ja: '本日のAI利用上限に達しました', zh: '今日AI使用额度已达上限', it: 'Limite giornaliero IA raggiunto');
  String get takePhotoReceiptBill => _t('Take a photo of receipt / bill', ne: 'क्यामेराबाट फोटो खिच्नुहोस्', es: 'Tomar foto de recibo / factura', fr: 'Prendre une photo du ticket / facture', de: 'Foto von Quittung / Rechnung aufnehmen', ja: 'レシート・請求書をカメラで撮影', zh: '拍照扫描收据或发票', it: 'Scatta foto a scontrino / fattura');
  String get opensCameraToScan => _t('Opens camera to scan invoice or receipt', ne: 'सिधै क्यामेरा खोलेर स्क्यान गर्नुहोस्', es: 'Abre la cámara para escanear', fr: 'Ouvre l\'appareil photo pour numériser', de: 'Kamera zum Scannen öffnen', ja: 'カメラを起動して請求書や領収書をスキャン', zh: '启动相机拍照识别消费发票', it: 'Apre la fotocamera per scansionare la fattura');
  String get uploadFromLibrary => _t('Upload from photo library', ne: 'ग्यालेरीबाट छान्नुहोस्', es: 'Subir desde la galería', fr: 'Téléverser depuis la galerie', de: 'Aus Mediathek hochladen', ja: 'アルバムから画像を選択', zh: '从手机相册上传', it: 'Carica dalla galleria');
  String get chooseExistingBill => _t('Choose existing bill or screenshot', ne: 'पहिले नै खिचिएको बिल वा रसिद', es: 'Elegir factura existente o captura', fr: 'Choisir une photo existante ou capture', de: 'Vorhandene Rechnung oder Screenshot wählen', ja: '保存済みの領収書やスクリーンショットを選択', zh: '选择相册中的账单照片或账目截图', it: 'Scegli fattura o screenshot esistente');
  String get assistantTitle => _t('Hypr AI', ne: 'Hypr AI', es: 'Hypr AI', fr: 'Hypr AI', de: 'Hypr AI', ja: 'Hypr AI', zh: 'Hypr AI', it: 'Hypr AI');
  String get unlimitedAiPro => _t('Hyprwise Pro · Unlimited AI', ne: 'हाइपरवाइज प्रो · असीमित एआई', es: 'Hyprwise Pro · IA ilimitada', fr: 'Hyprwise Pro · IA illimitée', de: 'Hyprwise Pro · Unbegrenzte KI', ja: 'Hyprwise Pro · AI無制限利用', zh: 'Hyprwise Pro · 无限次智能分析', it: 'Hyprwise Pro · IA illimitata');
  String get asksBeforeChanges => _t('Asks before it changes anything', ne: 'कुनै परिवर्तन गर्नु अघि पुष्टि माग्छ', es: 'Pide confirmación antes de cambiar nada', fr: 'Demande confirmation avant toute modification', de: 'Fragt vor jeder Änderung nach', ja: '変更前に必ず確認を求めます', zh: '执行任何账目更改前均需您确认', it: 'Chiede conferma prima di qualsiasi modifica');
  String get unlimitedAiAssistantTitle => _t('Unlimited Hypr AI', ne: 'असीमित Hypr AI', es: 'Hypr AI ilimitado', fr: 'Hypr AI illimité', de: 'Unbegrenzte Hypr AI', ja: '無制限Hypr AI', zh: '无限次 Hypr AI', it: 'Hypr AI illimitato');
  String get whatCanIDoForYou => _t('What can I do for you?', ne: 'म तपाईंलाई कसरी सहयोग गर्न सक्छु?', es: '¿En qué puedo ayudarte?', fr: 'Que puis-je faire pour vous ?', de: 'Wie kann ich Ihnen helfen?', ja: '何かお手伝いできることはありますか？', zh: '今天有什么我可以帮您的？', it: 'Cosa posso fare per te?');
  String get doSection => _t('Do', ne: 'कार्यहरू (Do)', es: 'Hacer', fr: 'Faire', de: 'Aktionen', ja: '実行する (Do)', zh: '快速记账 (Do)', it: 'Fai');
  String get askSection => _t('Ask', ne: 'जिज्ञासा (Ask)', es: 'Preguntar', fr: 'Demander', de: 'Fragen', ja: '質問する (Ask)', zh: '财务咨询 (Ask)', it: 'Chiedi');
  String get spentLunchSubtitle => _t('Spent 54.20 at Woolworths today', ne: 'आज खाजामा रु २५० खर्च भयो', es: 'Gasté 54.20 en el supermercado hoy', fr: 'Dépensé 54,20 aujourd\'hui au supermarché', de: 'Heute 54,20 im Supermarkt ausgegeben', ja: '本日スーパーで54.20支払いました', zh: '今天在超市消费了54.20', it: 'Spesi 54,20 al supermercato oggi');
  String get cafeFridaySubtitle => _t('Café Friday, 4 to 10 pm', ne: 'क्याफे शुक्रबार, दिउँसो ४ देखि १० सम्म', es: 'Café viernes, de 16 a 22 h', fr: 'Café vendredi, 16h à 22h', de: 'Café Freitag, 16 bis 22 Uhr', ja: '金曜カフェ 16:00〜22:00', zh: '周五咖啡厅 16:00-22:00 排班', it: 'Caffè venerdì, dalle 16 alle 22');
  String get emergencyFundMoveSubtitle => _t('Put 50 into Emergency fund', ne: 'आपतकालीन कोषमा ५० डलर थप्नुहोस्', es: 'Guardar 50 en fondo de emergencia', fr: 'Mettre 50 sur le fonds d\'urgence', de: '50 in den Notgroschen einzahlen', ja: '緊急予備資金に50を積立', zh: '向应急备用金存入50', it: 'Metti 50 nel fondo di emergenza');
  String get spentLunchPrompt => _t('Spent 54.20 at Woolworths today', ne: 'आज खाजामा २५० खर्च भयो', es: 'Gasté 54.20 en el supermercado hoy', fr: 'Dépensé 54,20 aujourd\'hui au supermarché', de: 'Heute 54,20 im Supermarkt ausgegeben', ja: '本日スーパーで54.20支払いました', zh: '今天在超市消费了54.20', it: 'Spesi 54,20 al supermercato oggi');
  String get cafeFridayPrompt => _t('Schedule a Café shift on Friday, 4 to 10 pm', ne: 'क्याफे शुक्रबार ४ देखि १० बजेसम्म सिफ्ट तय गर्नुहोस्', es: 'Programa un turno en el café el viernes de 16 a 22 h', fr: 'Planifie un quart au café vendredi de 16h à 22h', de: 'Schicht im Café für Freitag, 16 bis 22 Uhr planen', ja: '金曜日の16時から22時までカフェのシフトを予約して', zh: '安排周五16点到22点咖啡厅的排班', it: 'Pianifica un turno al caffè venerdì dalle 16 alle 22');
  String get emergencyFundMovePrompt => _t('Put 50 into Emergency fund', ne: 'आपतकालीन कोषमा ५० डलर थप्नुहोस्', es: 'Guardar 50 en fondo de emergencia', fr: 'Mettre 50 sur le fonds d\'urgence', de: '50 in den Notgroschen einzahlen', ja: '緊急予備資金に50積立して', zh: '往应急备用金转入50', it: 'Metti 50 nel fondo di emergenza');
  String get howMuchSpendFoodTitle => _t('How much did I spend on food?', ne: 'मैले खानामा कति खर्च गरें?', es: '¿Cuánto gasté en comida?', fr: 'Combien ai-je dépensé en nourriture ?', de: 'Wie viel habe ich für Essen ausgegeben?', ja: '食費にいくら使いましたか？', zh: '我这个月在餐饮上花了多少钱？', it: 'Quanto ho speso per il cibo?');
  String get thisMonthSoFarSubtitle => _t('This month so far', ne: 'यस महिना हालसम्म', es: 'En lo que va de mes', fr: 'Ce mois-ci jusqu\'à présent', de: 'Diesen Monat bisher', ja: '今月のこれまでの合計', zh: '本月至今', it: 'Questo mese finora');
  String get howMuchFoodPrompt => _t('How much did I spend on food this month?', ne: 'मैले यस महिना खानामा कति खर्च गरें?', es: '¿Cuánto gasté en comida este mes?', fr: 'Combien ai-je dépensé en nourriture ce mois-ci ?', de: 'Wie viel habe ich diesen Monat für Essen ausgegeben?', ja: '今月食費にいくら使った？', zh: '我本月在吃喝上花了多少钱？', it: 'Quanto ho speso per il cibo questo mese?');
  String get canIAffordTitle => _t('Can I afford a 300 purchase?', ne: 'के म यो सामान किन्न सक्छु?', es: '¿Puedo permitirme una compra de 300?', fr: 'Puis-je me permettre un achat de 300 ?', de: 'Kann ich mir einen Einkauf von 300 leisten?', ja: '300の買い物をしても大丈夫ですか？', zh: '我能承担得起300的消费支出吗？', it: 'Posso permettermi un acquisto di 300?');
  String get basedOnForecastSubtitle => _t('Based on your forecast', ne: 'वित्तीय प्रक्षेपणको आधारमा', es: 'Según tu pronóstico', fr: 'Selon vos prévisions', de: 'Basiert auf Ihrer Prognose', ja: '収支予測に基づきます', zh: '基于您的现金流预测', it: 'In base alle tue previsioni');
  String get canIAffordPrompt => _t('Can I afford a 300 purchase?', ne: 'के म ३०० को सामान किन्न सक्छु?', es: '¿Puedo permitirme una compra de 300?', fr: 'Puis-je me permettre un achat de 300 ?', de: 'Kann ich mir einen Kauf von 300 leisten?', ja: '300の大きな買い物をしても家計は大丈夫？', zh: '以目前的资金情况我能买300的物品吗？', it: 'Posso permettermi una spesa di 300?');
  String get whatNextTitle => _t('What would you like to do next?', ne: 'अब के गर्न चाहनुहुन्छ?', es: '¿Qué deseas hacer ahora?', fr: 'Que souhaitez-vous faire ensuite ?', de: 'Was möchten Sie als Nächstes tun?', ja: '次に何をしますか？', zh: '接下来想做什么？', it: 'Cosa vorresti fare dopo?');
  String get startFresh => _t('Start fresh', ne: 'नयाँ सुरु', es: 'Empezar de nuevo', fr: 'Recommencer', de: 'Neu beginnen', ja: '新しく始める', zh: '重新开始', it: 'Ricomincia');
  String get scanBillTooltip => _t('Scan bill or receipt', ne: 'बिल वा रसिद स्क्यान गर्नुहोस्', es: 'Escanear factura o recibo', fr: 'Scanner le ticket ou la facture', de: 'Rechnung oder Quittung scannen', ja: 'レシートや領収書をスキャン', zh: '扫描账单或消费小票', it: 'Scansiona ricevuta o fattura');
  String get askOrTypeNotesHint => _t('Ask, or type bill notes...', ne: 'सोध्नुहोस् वा बिलको विवरण...', es: 'Pregunta o escribe notas...', fr: 'Posez une question ou tapez des notes...', de: 'Fragen oder Notizen eingeben...', ja: '質問やレシートのメモを入力...', zh: '提问或输入账目备注...', it: 'Chiedi o scrivi note...');
  String get needsYourOk => _t('Needs your OK', ne: 'पुष्टि आवश्यक', es: 'Requiere tu confirmación', fr: 'Confirmation requise', de: 'Bestätigung erforderlich', ja: '確認が必要です', zh: '等待您确认', it: 'Richiede la tua conferma');
  String get merchantOrNoteLabel => _t('Merchant / Note', ne: 'पसल / कैफियत', es: 'Comercio / Nota', fr: 'Commerçant / Note', de: 'Händler / Notiz', ja: '店舗名 / メモ', zh: '商户名 / 备注', it: 'Commerciante / Nota');
  String get confirmAction => _t('Confirm', ne: 'पुष्टि गर्नुहोस्', es: 'Confirmar', fr: 'Confirmer', de: 'Bestätigen', ja: '確認・実行', zh: '确认执行', it: 'Conferma');
  String get openInFullAddForm => _t('Open in full add form', ne: 'पूर्ण फारममा खोल्नुहोस्', es: 'Abrir en formulario completo', fr: 'Ouvrir le formulaire complet', de: 'Im vollständigen Formular öffnen', ja: '詳細な入力フォームで開く', zh: '在完整表单中打开', it: 'Apri nel modulo completo');

  // Welcome & Currency Onboarding
  String get welcomePitch => _t(
        'Your money and\nyour shifts, in one\nplace.',
        ne: 'तपाईंको पैसा र\nसिफ्टहरू, एकै\nठाउँमा।',
        es: 'Tu dinero y\ntus turnos, en un\nsolo lugar.',
        fr: 'Votre argent et\nvos quarts, en un\nseul endroit.',
        de: 'Ihr Geld und\nIhre Schichten an\neinem Ort.',
        ja: 'お金とシフトを\nひとつの場所に。',
        zh: '一站管理\n您的财务与班次。',
      );
  String get offlinePitch => _t(
        'Works offline. Your data stays on your phone.',
        ne: 'अफलाइन चल्छ। तपाईंको डाटा फोनमै सुरक्षित रहन्छ।',
        es: 'Funciona sin conexión. Tus datos se quedan en tu teléfono.',
        fr: 'Fonctionne hors ligne. Vos données restent sur votre téléphone.',
        de: 'Funktioniert offline. Ihre Daten bleiben auf Ihrem Telefon.',
        ja: 'オフライン対応。データは端末内に安全に保存されます。',
        zh: '支持离线。所有数据本地安全存储。',
      );
  String get getStarted => _t('Get started', ne: 'सुरु गर्नुहोस्', es: 'Comenzar', fr: 'Commencer', de: 'Loslegen', ja: 'はじめる', zh: '立即开始');
  String get whichCurrencyQuestion => _t(
        'Which currency do you\nuse?',
        ne: 'तपाईं कुन मुद्रा\nप्रयोग गर्नुहुन्छ?',
        es: '¿Qué moneda\nutilizas?',
        fr: 'Quelle devise\nutilisez-vous?',
        de: 'Welche Währung\nnutzen Sie?',
        ja: '使用する通貨を\n選択してください',
        zh: '请选择您的\n常用货币',
      );
  String get addSecondLater => _t(
        'You can add a second one later.',
        ne: 'पछि अर्को मुद्रा पनि थप्न सक्नुहुन्छ।',
        es: 'Puedes añadir otra más tarde.',
        fr: 'Vous pourrez en ajouter une autre plus tard.',
        de: 'Sie können später eine weitere hinzufügen.',
        ja: '後から別の通貨を追加することも可能です。',
        zh: '之后可随时添加其他货币。',
      );
  String get finishSetup => _t('Finish setup', ne: 'सेटअप पूरा गर्नुहोस्', es: 'Finalizar configuración', fr: 'Terminer la configuration', de: 'Einrichtung abschließen', ja: '設定を完了する', zh: '完成设置');
  String get manage => _t('Manage', ne: 'व्यवस्थापन', es: 'Gestionar', fr: 'Gérer', de: 'Verwalten', ja: '管理', zh: '管理');
  String get running => _t('RUNNING', ne: 'सक्रिय', es: 'ACTIVO', fr: 'EN COURS', de: 'LÄUFT', ja: '稼働中', zh: '运行中');

  // Authentication & Legal
  String get continueWithGoogle => _t('Continue with Google', ne: 'Google मार्फत जारी राख्नुहोस्', es: 'Continuar con Google', fr: 'Continuer avec Google', de: 'Mit Google fortfahren', ja: 'Googleで続ける', zh: '通过 Google 继续');
  String get continueWithApple => _t('Continue with Apple', ne: 'Apple मार्फत जारी राख्नुहोस्', es: 'Continuar con Apple', fr: 'Continuer avec Apple', de: 'Mit Apple fortfahren', ja: 'Appleで続ける', zh: '通过 Apple 继续');
  String get continueAsGuest => _t('Continue as Guest (Offline)', ne: 'अतिथि (अफलाइन) को रूपमा जारी राख्नुहोस्', es: 'Continuar como invitado (Offline)', fr: 'Continuer en invité (Hors ligne)', de: 'Als Gast fortfahren (Offline)', ja: 'ゲストとして続ける（オフライン）', zh: '访客体验（离线）');
  String get orDivider => _t('or', ne: 'वा', es: 'o', fr: 'ou', de: 'oder', ja: 'または', zh: '或');
  String get offlineSecurityBadge => _t('100% on-device · Private · Zero ads', ne: '१००% तपाईंको फोनमै · सुरक्षित · कुनै विज्ञापन छैन', es: '100% en dispositivo · Privado · Sin anuncios', fr: '100% sur l\'appareil · Privé · Zéro pub', de: '100% auf dem Gerät · Sicher · Keine Werbung', ja: '完全端末保存 · プライベート · 広告なし', zh: '100% 本地运行 · 隐私保护 · 无广告');
  String get loginPitch => _t('Clarity and control over your financial life.', ne: 'सिफ्ट, आम्दानी र खर्चको स्पष्ट हिसाबकिताब।', es: 'Claridad y control sobre tu vida financiera.', fr: 'Clarté et contrôle sur votre vie financière.', de: 'Klarheit und Kontrolle über Ihre Finanzen.', ja: 'お金とシフトを明確にコントロール。', zh: '掌控收入与支出，财务一目了然。');
  String get privacyPolicy => _t('Privacy Policy', ne: 'गोपनीयता नीति', es: 'Política de Privacidad', fr: 'Politique de confidentialité', de: 'Datenschutzerklärung', ja: 'プライバシーポリシー', zh: '隐私政策');
  String get termsOfService => _t('Terms of Service', ne: 'सेवाका सर्तहरू', es: 'Términos de Servicio', fr: 'Conditions d\'utilisation', de: 'Nutzungsbedingungen', ja: '利用規約', zh: '服务条款');
  String get agreeToTermsPrefix => _t('By continuing, you agree to our ', ne: 'जारी राख्दै तपाईं हाम्रा ', es: 'Al continuar, aceptas nuestros ', fr: 'En continuant, vous acceptez nos ', de: 'Indem Sie fortfahren, stimmen Sie unseren ', ja: '続行することで、利用規約および', zh: '继续操作即表示您同意我们的');
  String get andWord => _t(' and ', ne: ' र ', es: ' y ', fr: ' et ', de: ' und ', ja: 'と', zh: '和');
  String get agreeToTermsSuffix => _t('.', ne: ' स्वीकार गर्नुहुन्छ।', es: '.', fr: '.', de: ' zu.', ja: 'に同意したことになります。', zh: '。');

  String formatNumber(num n) {
    return localizeDigits(n.toString());
  }

  String get lendingBorrowingIous => _t('Lending & Borrowing (IOUs)', ne: 'ऋण र सापटी (IOUs)', es: 'Préstamos y deudas (IOU)', fr: 'Prêts et dettes (reconnaissances)', de: 'Leihen & Schulden (Schuldscheine)', ja: '貸し借り・精算 (IOU)', zh: '借贷与借条 (IOUs)', it: 'Prestiti e debiti (IOU)');
  String get merchantLabel => _t('Merchant', ne: 'पसल', es: 'Comercio', fr: 'Commerçant', de: 'Händler', ja: '店舗', zh: '商户', it: 'Esercente');
  String get jobLabel => _t('Job', ne: 'जागिर', es: 'Empleo', fr: 'Emploi', de: 'Job', ja: '仕事', zh: '工作', it: 'Lavoro');
  String get goalLabel => _t('Goal', ne: 'लक्ष्य', es: 'Meta', fr: 'Objectif', de: 'Ziel', ja: '目標', zh: '目标', it: 'Obiettivo');
  String get freeAiLimitReachedMessage => _t('You have used your 5 free AI queries. Upgrade to Hyprwise Pro for unlimited AI financial intelligence.', ne: 'तपाईंले आजका लागि ५ नि:शुल्क एआई प्रश्नहरू प्रयोग गर्नुभयो। असीमित एआईका लागि हाइपरवाइज प्रो लिनुहोस्।', es: 'Has usado tus 5 consultas gratuitas de IA. Pásate a Hyprwise Pro para IA ilimitada.', fr: 'Vous avez utilisé vos 5 requêtes IA gratuites. Passez à Hyprwise Pro pour une IA illimitée.', de: 'Sie haben Ihre 5 kostenlosen KI-Anfragen aufgebraucht. Upgraden Sie auf Hyprwise Pro für unbegrenzte KI.', ja: '無料のAI利用枠（5回）を使い切りました。無制限に利用するにはHyprwise Proにアップグレードしてください。', zh: '您已使用完5次免费AI提问额度。升级到 Hyprwise Pro 尊享无限制智能分析。', it: 'Hai utilizzato le tue 5 richieste IA gratuite. Passa a Hyprwise Pro per un\'IA illimitata.');
  String get unlimitedAiAssistantDesc => _t('Get instant shift planning, spending analysis, and financial intelligence with zero limits.', ne: 'कुनै पनि सीमा बिना वित्तीय सल्लाह, खर्च विश्लेषण र सिफ्ट योजना प्राप्त गर्नुहोस्।', es: 'Planificación de turnos, análisis de gastos e inteligencia financiera sin límites.', fr: 'Planification de quarts, analyse des dépenses et intelligence financière sans limites.', de: 'Schichtplanung, Ausgabenanalyse und Finanzintelligenz ohne Einschränkungen.', ja: 'シフト計画、支出分析、財務インサイトを制限なしで利用できます。', zh: '尊享排班规划、支出分析与财务智能分析，无任何次数限制。', it: 'Pianificazione dei turni, analisi delle spese e intelligenza finanziaria senza limiti.');
  String get assistantIntroSubtitle => _t('Ask about your money, or tell me to do something.', ne: 'आफ्नो वित्तीय स्थितिबारे सोध्नुहोस्, वा केही गर्न निर्देशन दिनुहोस्।', es: 'Pregunta sobre tu dinero o pídeme realizar alguna acción.', fr: 'Posez des questions sur vos finances ou demandez-moi d\'effectuer une action.', de: 'Fragen Sie nach Ihrem Geld oder geben Sie mir eine Anweisung.', ja: 'お金について質問するか、実行したい操作を指示してください。', zh: '询问您的财务状况，或直接下达记账与排班指令。', it: 'Chiedi informazioni sul tuo denaro o dimmi cosa fare.');
  String get addAccount => _t('Add Account', ne: 'खाता थप्नुहोस्', es: 'Añadir Cuenta', fr: 'Ajouter un compte', de: 'Konto hinzufügen', ja: '口座を追加', zh: '添加账户', it: 'Aggiungi conto');
  String get addTransaction => _t('Add Transaction', ne: 'कारोबार थप्नुहोस्', es: 'Añadir Transacción', fr: 'Ajouter une transaction', de: 'Transaktion hinzufügen', ja: '取引を追加', zh: '记一笔', it: 'Aggiungi transazione');
  String get moveMoneyToGoal => _t('Move money to a goal', ne: 'लक्ष्यमा रकम सार्नुहोस्', es: 'Mover dinero a una meta', fr: 'Transférer vers un objectif', de: 'Geld auf ein Ziel überweisen', ja: '目標に資金を移動', zh: '向目标存入资金', it: 'Sposta denaro su un obiettivo');

  // Analytics tabs
  String get analyticsTabOverview => _t('Overview', ne: 'सारांश', es: 'Resumen', fr: 'Aperçu', de: 'Übersicht', ja: '概要', zh: '概览', it: 'Panoramica');
  String get analyticsTabExpenses => _t('Expenses', ne: 'खर्चहरू', es: 'Gastos', fr: 'Dépenses', de: 'Ausgaben', ja: '支出', zh: '支出', it: 'Spese');
  String get analyticsTabLend => _t('Lend', ne: 'सापटी दिएको', es: 'Prestado', fr: 'Prêts', de: 'Verleihen', ja: '貸出', zh: '借出', it: 'Prestiti');
  String get analyticsTabBorrow => _t('Borrow', ne: 'सापटी लिएको', es: 'Pedido', fr: 'Emprunts', de: 'Borgen', ja: '借入', zh: '借入', it: 'Debiti');
  String get analyticsTabShiftsWork => _t('Shifts & Work', ne: 'सिफ्ट र काम', es: 'Turnos y trabajo', fr: 'Quarts et travail', de: 'Schichten & Arbeit', ja: 'シフトと勤務', zh: '排班与工作', it: 'Turni e lavoro');
  String get analyticsTrend => _t('Trend', ne: 'प्रवृत्ति', es: 'Tendencia', fr: 'Tendance', de: 'Verlauf', ja: '推移', zh: '趋势', it: 'Andamento');
  String get analyticsByCategory => _t('By category', ne: 'श्रेणी अनुसार', es: 'Por categoría', fr: 'Par catégorie', de: 'Nach Kategorie', ja: 'カテゴリ別', zh: '按类别', it: 'Per categoria');
  String get analyticsByPerson => _t('By person', ne: 'व्यक्ति अनुसार', es: 'Por persona', fr: 'Par personne', de: 'Nach Person', ja: '相手別', zh: '按对象', it: 'Per persona');
  String get analyticsTopItems => _t('Top items', ne: 'शीर्ष वस्तुहरू', es: 'Principales', fr: 'Principaux', de: 'Top-Einträge', ja: '上位項目', zh: '热门项目', it: 'Principali');
  String get analyticsTotal => _t('Total', ne: 'जम्मा', es: 'Total', fr: 'Total', de: 'Gesamt', ja: '合計', zh: '总计', it: 'Totale');
  String get analyticsAverage => _t('Average', ne: 'औसत', es: 'Promedio', fr: 'Moyenne', de: 'Durchschnitt', ja: '平均', zh: '平均', it: 'Media');
  String get analyticsTransactionsCount => _t('Transactions', ne: 'कारोबार', es: 'Transacciones', fr: 'Transactions', de: 'Transaktionen', ja: '取引数', zh: '交易数', it: 'Transazioni');
  String get analyticsEntriesCount => _t('Entries', ne: 'प्रविष्टि', es: 'Registros', fr: 'Entrées', de: 'Einträge', ja: '件数', zh: '条目', it: 'Voci');
  String get analyticsOutstanding => _t('Outstanding', ne: 'बाँकी', es: 'Pendiente', fr: 'En cours', de: 'Offen', ja: '未精算', zh: '未结清', it: 'In sospeso');
  String get analyticsSettled => _t('Settled', ne: 'फर्छ्यौट', es: 'Saldado', fr: 'Réglé', de: 'Beglichen', ja: '精算済み', zh: '已结清', it: 'Saldato');
  String get analyticsNoEntriesInPeriod => _t('Nothing recorded in this period', ne: 'यो अवधिमा केही दर्ता छैन', es: 'Nada registrado en este periodo', fr: 'Rien d\'enregistré sur cette période', de: 'Nichts in diesem Zeitraum erfasst', ja: 'この期間の記録はありません', zh: '此期间暂无记录', it: 'Nessun dato in questo periodo');
  String get analyticsNoShiftsInPeriod => _t('No completed shifts in this period', ne: 'यो अवधिमा सम्पन्न सिफ्ट छैन', es: 'Sin turnos completados en este periodo', fr: 'Aucun quart terminé sur cette période', de: 'Keine abgeschlossenen Schichten in diesem Zeitraum', ja: 'この期間に完了したシフトはありません', zh: '此期间没有已完成的班次', it: 'Nessun turno completato in questo periodo');
  String get analyticsTotalHours => _t('Total hours', ne: 'कुल घण्टा', es: 'Horas totales', fr: 'Heures totales', de: 'Gesamtstunden', ja: '合計時間', zh: '总工时', it: 'Ore totali');
  String get analyticsEarnings => _t('Earnings', ne: 'कमाइ', es: 'Ganancias', fr: 'Revenus', de: 'Verdienst', ja: '収入額', zh: '收入', it: 'Guadagni');
  String get analyticsOvertimeHours => _t('Overtime hours', ne: 'ओभरटाइम घण्टा', es: 'Horas extras', fr: 'Heures sup', de: 'Überstunden', ja: '残業時間', zh: '加班时长', it: 'Ore di straordinario');
  String get analyticsBreakTime => _t('Break time', ne: 'विश्राम समय', es: 'Tiempo de descanso', fr: 'Temps de pause', de: 'Pausenzeit', ja: '休憩時間', zh: '休息时间', it: 'Tempo di pausa');
  String get analyticsAvgShiftLength => _t('Avg shift length', ne: 'औसत सिफ्ट अवधि', es: 'Duración media del turno', fr: 'Durée moyenne du quart', de: 'Ø Schichtlänge', ja: '平均シフト時間', zh: '平均班次时长', it: 'Durata media turno');
  String get analyticsShiftsCount => _t('Shifts', ne: 'सिफ्टहरू', es: 'Turnos', fr: 'Quarts', de: 'Schichten', ja: 'シフト数', zh: '班次', it: 'Turni');
  String get analyticsEarningsByJob => _t('Earnings by job', ne: 'जागिर अनुसार कमाइ', es: 'Ganancias por empleo', fr: 'Revenus par emploi', de: 'Verdienst pro Job', ja: '仕事別の収入', zh: '按工作统计收入', it: 'Guadagni per lavoro');
  String get analyticsWeeklyBreakdown => _t('Weekly breakdown', ne: 'साप्ताहिक विवरण', es: 'Desglose semanal', fr: 'Détail hebdomadaire', de: 'Wochenübersicht', ja: '週別内訳', zh: '每周明细', it: 'Dettaglio settimanale');
  String get analyticsHoursChip => _t('Hours', ne: 'घण्टा', es: 'Horas', fr: 'Heures', de: 'Stunden', ja: '時間', zh: '工时', it: 'Ore');
  String get hourAbbr => _t('h', ne: 'घ', es: 'h', fr: 'h', de: 'Std', ja: '時間', zh: '小时', it: 'h');
  String get minuteAbbr => _t('m', ne: 'मि', es: 'min', fr: 'min', de: 'Min', ja: '分', zh: '分钟', it: 'min');

  // Hypr AI & home insight widgets
  String get hyprAi => _t('Hypr AI', ne: 'Hypr AI', es: 'Hypr AI', fr: 'Hypr AI', de: 'Hypr AI', ja: 'Hypr AI', zh: 'Hypr AI', it: 'Hypr AI');
  String get thisWeekTitle => _t('This week', ne: 'यो हप्ता', es: 'Esta semana', fr: 'Cette semaine', de: 'Diese Woche', ja: '今週', zh: '本周', it: 'Questa settimana');
  String get incomeVsSpend => _t('Income vs spend', ne: 'आम्दानी बनाम खर्च', es: 'Ingresos vs gastos', fr: 'Revenus vs dépenses', de: 'Einnahmen vs. Ausgaben', ja: '収入と支出', zh: '收入与支出', it: 'Entrate vs spese');
  String get savingsRateTitle => _t('Savings rate', ne: 'बचत दर', es: 'Tasa de ahorro', fr: 'Taux d\'épargne', de: 'Sparquote', ja: '貯蓄率', zh: '储蓄率', it: 'Tasso di risparmio');
  String get ofIncomeKept => _t('of income kept this month', ne: 'यो महिना आम्दानीबाट जोगाइएको', es: 'del ingreso ahorrado este mes', fr: 'du revenu conservé ce mois-ci', de: 'des Einkommens diesen Monat gespart', ja: '今月の収入のうち残した割合', zh: '本月收入结余比例', it: 'del reddito risparmiato questo mese');
  String get topSpendingTitle => _t('Top spending', ne: 'सबैभन्दा बढी खर्च', es: 'Mayor gasto', fr: 'Plus grosse dépense', de: 'Höchste Ausgaben', ja: '最大の支出', zh: '最大支出', it: 'Spesa maggiore');
  String get noSpendingYet => _t('No spending yet this month', ne: 'यो महिना अहिलेसम्म खर्च छैन', es: 'Aún sin gastos este mes', fr: 'Aucune dépense ce mois-ci', de: 'Diesen Monat noch keine Ausgaben', ja: '今月の支出はまだありません', zh: '本月暂无支出', it: 'Nessuna spesa questo mese');
  String get billsDueSoonTitle => _t('Bills due soon', ne: 'छिट्टै तिर्नुपर्ने बिल', es: 'Facturas próximas', fr: 'Factures à venir', de: 'Bald fällige Rechnungen', ja: 'まもなく支払い期日', zh: '即将到期账单', it: 'Bollette in scadenza');
  String get noBillsDueSoon => _t('Nothing due in the next 7 days', ne: 'आगामी ७ दिनमा केही बाँकी छैन', es: 'Nada vence en 7 días', fr: 'Rien à payer sous 7 jours', de: 'Nichts fällig in 7 Tagen', ja: '7日以内の支払いはありません', zh: '未来7天无到期项目', it: 'Niente in scadenza nei prossimi 7 giorni');
  String get spendingBreakdown => _t('Spending breakdown', ne: 'खर्चको विवरण', es: 'Desglose de gastos', fr: 'Répartition des dépenses', de: 'Ausgabenaufteilung', ja: '支出の内訳', zh: '支出明细', it: 'Ripartizione delle spese');
  String get last7Days => _t('Last 7 days', ne: 'पछिल्लो ७ दिन', es: 'Últimos 7 días', fr: '7 derniers jours', de: 'Letzte 7 Tage', ja: '過去7日間', zh: '最近7天', it: 'Ultimi 7 giorni');
  String get askHyprAiHint => _t('Ask Hypr AI', ne: 'Hypr AI सँग सोध्नुहोस्', es: 'Pregunta a Hypr AI', fr: 'Demander à Hypr AI', de: 'Hypr AI fragen', ja: 'Hypr AIに質問', zh: '询问 Hypr AI', it: 'Chiedi a Hypr AI');
  String get otherCategory => _t('Other', ne: 'अन्य', es: 'Otros', fr: 'Autres', de: 'Sonstige', ja: 'その他', zh: '其他', it: 'Altro');

  // Reminder ruleset & planner strings
  String get shiftLabel => _t('Shift', ne: 'सिफ्ट', es: 'Turno', fr: 'Quart', de: 'Schicht', ja: 'シフト', zh: '班次', it: 'Turno');
  String reminderShiftTitle(String job) => _t('Upcoming shift · $job', ne: 'आगामी सिफ्ट · $job', es: 'Próximo turno · $job', fr: 'Quart à venir · $job', de: 'Kommende Schicht · $job', ja: '次のシフト · $job', zh: '即将开始的班次 · $job', it: 'Prossimo turno · $job');
  String reminderShiftBody(String offset, String time) => _t('$offset (starts at $time)', ne: '$offset ($time मा सुरु)', es: '$offset (empieza a las $time)', fr: '$offset (début à $time)', de: '$offset (Beginn um $time)', ja: '$offset ($time 開始)', zh: '$offset ($time 开始)', it: '$offset (inizia alle $time)');
  String reminderOffsetLabel(int minutes) {
    if (minutes <= 0) {
      return _t('Starting now', ne: 'अहिले सुरु हुँदैछ', es: 'Empieza ahora', fr: 'Commence maintenant', de: 'Beginnt jetzt', ja: 'まもなく開始', zh: '现在开始', it: 'Inizia ora');
    }
    if (minutes % 1440 == 0) {
      final d = minutes ~/ 1440;
      return _t('${d}d before', ne: '$d दिन अघि', es: '${d}d antes', fr: '${d}j avant', de: '${d}T vorher', ja: '$d日前', zh: '提前$d天', it: '${d}g prima');
    }
    if (minutes % 60 == 0) {
      final h = minutes ~/ 60;
      return _t('${h}h before', ne: '$h घण्टा अघि', es: '${h}h antes', fr: '${h}h avant', de: '${h}h vorher', ja: '$h時間前', zh: '提前$h小时', it: '${h}h prima');
    }
    return _t('${minutes}m before', ne: '$minutes मिनेट अघि', es: '${minutes}min antes', fr: '${minutes}min avant', de: '${minutes}Min vorher', ja: '$minutes分前', zh: '提前$minutes分钟', it: '${minutes}min prima');
  }
  String reminderBillTitle(String name) => _t('Bill reminder · $name', ne: 'बिल रिमाइन्डर · $name', es: 'Recordatorio de factura · $name', fr: 'Rappel de facture · $name', de: 'Rechnungserinnerung · $name', ja: '請求リマインダー · $name', zh: '账单提醒 · $name', it: 'Promemoria bolletta · $name');
  String reminderDebtTitle(String person) => _t('Settlement due · $person', ne: 'भुक्तानी मिति · $person', es: 'Vencimiento · $person', fr: 'Échéance · $person', de: 'Fälligkeit · $person', ja: '精算期日 · $person', zh: '借贷到期 · $person', it: 'Scadenza · $person');
  String reminderDueBody(String amount, String date) => _t('$amount due on $date', ne: '$date मा $amount तिर्नुपर्ने', es: '$amount vence el $date', fr: '$amount dû le $date', de: '$amount fällig am $date', ja: '$date に $amount 期日', zh: '$date 到期 $amount', it: '$amount in scadenza il $date');
  String get reminderCustomDefault => _t('Hyprwise Reminder', ne: 'हाइपरवाइज रिमाइन्डर', es: 'Recordatorio Hyprwise', fr: 'Rappel Hyprwise', de: 'Hyprwise-Erinnerung', ja: 'Hyprwise リマインダー', zh: 'Hyprwise 提醒', it: 'Promemoria Hyprwise');
  String get reminderCustomBody => _t('Tap to review your finances and schedule.', ne: 'आफ्नो हरहिसाब र तालिका हेर्न ट्याप गर्नुहोस्।', es: 'Toca para revisar tus finanzas y horario.', fr: 'Appuyez pour vérifier vos finances et votre planning.', de: 'Tippen Sie, um Finanzen und Schichtplan zu prüfen.', ja: 'タップして収支とシフトを確認しましょう。', zh: '点击查看您的财务与排班安排。', it: 'Tocca per controllare finanze e turni.');
  String get reminderRulesSection => _t('Reminder Ruleset', ne: 'रिमाइन्डर नियमहरू', es: 'Reglas de recordatorio', fr: 'Règles de rappel', de: 'Erinnerungsregeln', ja: 'リマインダールール', zh: '提醒规则集', it: 'Regole di promemoria');
  String get reminderRulesSubtitle => _t('Create flexible rules for shifts, bills, debts, or custom check-ins.', ne: 'सिफ्ट, बिल, सापटी वा कस्टम रिमाइन्डरका लागि लचिलो नियम बनाउनुहोस्।', es: 'Crea reglas flexibles para turnos, facturas, deudas o avisos.', fr: 'Créez des règles flexibles pour quarts, factures, dettes ou rappels.', de: 'Erstellen Sie flexible Regeln für Schichten, Rechnungen, Schulden oder eigene Erinnerungen.', ja: 'シフト・請求・貸借・カスタム通知の柔軟なルールを設定できます。', zh: '为排班、账单、借贷或自定义事项创建灵活提醒规则。', it: 'Crea regole flessibili per turni, bollette, debiti o promemoria.');
  String get addReminderRule => _t('Add Reminder Rule', ne: 'नयाँ नियम थप्नुहोस्', es: 'Añadir regla', fr: 'Ajouter une règle', de: 'Regel hinzufügen', ja: 'ルールを追加', zh: '添加提醒规则', it: 'Aggiungi regola');
  String get editReminderRule => _t('Edit Reminder Rule', ne: 'नियम सम्पादन गर्नुहोस्', es: 'Editar regla', fr: 'Modifier la règle', de: 'Regel bearbeiten', ja: 'ルールを編集', zh: '编辑提醒规则', it: 'Modifica regola');
  String get reminderTypeLabel => _t('Rule Type', ne: 'रिमाइन्डर प्रकार', es: 'Tipo de regla', fr: 'Type de règle', de: 'Regeltyp', ja: 'ルール種別', zh: '规则类型', it: 'Tipo di regola');
  String get reminderTimingLabel => _t('Notify Me', ne: 'जानकारी समय', es: 'Notificarme', fr: 'Me notifier', de: 'Benachrichtigen', ja: '通知タイミング', zh: '提醒时机', it: 'Avvisami');
  String get reminderTimeOfDayLabel => _t('Time of Day', ne: 'दिनको समय', es: 'Hora del día', fr: 'Heure du jour', de: 'Tageszeit', ja: '通知時刻', zh: '提醒时间', it: 'Ora del giorno');
  String get reminderRepeatDaysLabel => _t('Active Days (empty = every day)', ne: 'सक्रिय बारहरू (खाली = हरेक दिन)', es: 'Días activos (vacío = todos)', fr: 'Jours actifs (vide = tous)', de: 'Aktive Tage (leer = täglich)', ja: '対象曜日（未選択＝毎日）', zh: '重复星期（留空为每天）', it: 'Giorni attivi (vuoto = tutti)');
  String get everyDay => _t('Every day', ne: 'हरेक दिन', es: 'Todos los días', fr: 'Tous les jours', de: 'Jeden Tag', ja: '毎日', zh: '每天', it: 'Ogni giorno');
  String get customMinutesBefore => _t('Custom minutes before', ne: 'कस्टम मिनेट अघि', es: 'Minutos personalizados antes', fr: 'Minutes personnalisées avant', de: 'Eigene Minuten vorher', ja: 'カスタム分数前', zh: '自定义提前分钟', it: 'Minuti personalizzati prima');

  // Shift completion log & custom break / long shift alert strings
  String get shiftLogTitle => _t('Shift Completion Log', ne: 'सिफ्ट सम्पन्न विवरण', es: 'Registro de turno completado', fr: 'Journal de fin de quart', de: 'Schichtabschluss-Protokoll', ja: 'シフト完了ログ', zh: '班次完成日志', it: 'Riepilogo fine turno');
  String get shiftTimelineTitle => _t('Shift Timeline', ne: 'सिफ्ट समयरेखा', es: 'Línea de tiempo del turno', fr: 'Chronologie du quart', de: 'Schicht-Zeitachse', ja: 'シフトタイムライン', zh: '班次时间轴', it: 'Cronologia del turno');
  String get totalClockTime => _t('Total clock time', ne: 'कुल समय', es: 'Tiempo total', fr: 'Temps total', de: 'Gesamtzeit', ja: '総拘束時間', zh: '总打卡时长', it: 'Tempo totale');
  String get netWorkedTime => _t('Net worked', ne: 'खुद काम गरेको', es: 'Tiempo trabajado', fr: 'Temps travaillé', de: 'Arbeitszeit netto', ja: '実働時間', zh: '净工作时长', it: 'Ore lavorate nette');
  String get regularPayLabel => _t('Regular pay', ne: 'नियमित कमाइ', es: 'Pago regular', fr: 'Salaire normal', de: 'Regulärer Lohn', ja: '通常給', zh: '常规薪资', it: 'Paga ordinaria');
  String get overtimePayLabel => _t('Overtime pay', ne: 'ओभरटाइम कमाइ', es: 'Pago horas extra', fr: 'Heures supplémentaires', de: 'Überstundenlohn', ja: '残業代', zh: '加班薪资', it: 'Straordinario');
  String get clockedInEvent => _t('Clocked In', ne: 'काम सुरु (Clock In)', es: 'Entrada', fr: 'Début de quart', de: 'Eingestempelt', ja: '出勤 (Clock In)', zh: '上班打卡', it: 'Entrata');
  String get clockedOutEvent => _t('Clocked Out', ne: 'काम समाप्त (Clock Out)', es: 'Salida', fr: 'Fin de quart', de: 'Ausgestempelt', ja: '退勤 (Clock Out)', zh: '下班打卡', it: 'Uscita');
  String get breakSegmentLabel => _t('Break taken', ne: 'विश्राम लिइएको', es: 'Descanso tomado', fr: 'Pause prise', de: 'Pause', ja: '休憩', zh: '休息时段', it: 'Pausa effettuata');
  String get overtimeReachedEvent => _t('Overtime rate active', ne: 'ओभरटाइम दर लागू', es: 'Tarifa extra activa', fr: 'Tarif heures sup actif', de: 'Überstundensatz aktiv', ja: '残業レート適用', zh: '进入加班费率', it: 'Tariffa straordinario attiva');
  String get customBreakMinutesLabel => _t('Custom break (minutes)', ne: 'कस्टम विश्राम (मिनेट)', es: 'Descanso personalizado (min)', fr: 'Pause personnalisée (min)', de: 'Eigene Pause (Minuten)', ja: 'カスタム休憩（分）', zh: '自定义休息（分钟）', it: 'Pausa personalizzata (min)');
  String get defaultBreakDurationLabel => _t('Default break duration', ne: 'डिफल्ट विश्राम अवधि', es: 'Descanso predeterminado', fr: 'Durée de pause par défaut', de: 'Standard-Pausendauer', ja: '標準の休憩時間', zh: '默认休息时长', it: 'Durata pausa predefinita');
  String get longShiftNotificationLabel => _t('Long-shift notification', ne: 'लामो सिफ्ट सूचना', es: 'Aviso de turno largo', fr: 'Alerte de long quart', de: 'Langschicht-Benachrichtigung', ja: '長時間シフト通知', zh: '长班次提醒', it: 'Avviso turno lungo');
  String get longShiftNotificationSubtitle => _t('Choose when to be notified during a running shift', ne: 'काम चलिरहँदा कति घण्टापछि सूचित गर्ने छान्नुहोस्', es: 'Elige cuándo recibir aviso durante un turno activo', fr: 'Choisissez quand être notifié pendant un quart', de: 'Wählen Sie, wann Sie während einer Schicht erinnert werden', ja: 'シフト開始から何時間後に通知するか選択', zh: '选择班次进行多久后发送提醒通知', it: 'Scegli dopo quante ore ricevere un avviso');
  String notifyAfterHours(int hours) => _t('After ${hours}h', ne: '$hours घण्टा पछि', es: 'Tras ${hours}h', fr: 'Après ${hours}h', de: 'Nach ${hours}h', ja: '$hours時間後', zh: '$hours小时后', it: 'Dopo ${hours}h');
  String get customHoursLabel => _t('Custom hours', ne: 'कस्टम घण्टा', es: 'Horas personalizadas', fr: 'Heures personnalisées', de: 'Eigene Stunden', ja: 'カスタム時間', zh: '自定义小时', it: 'Ore personalizzate');
  String get customOption => _t('Custom', ne: 'कस्टम', es: 'Personalizado', fr: 'Personnalisé', de: 'Eigene', ja: 'カスタム', zh: '自定义', it: 'Personalizzato');
  String get offOption => _t('Off', ne: 'बन्द', es: 'Desactivado', fr: 'Désactivé', de: 'Aus', ja: 'オフ', zh: '关闭', it: 'Off');
  String get title => _t('Title', ne: 'शीर्षक', es: 'Título', fr: 'Titre', de: 'Titel', ja: 'タイトル', zh: '标题', it: 'Titolo');
  String get add => _t('Add', ne: 'थप्नुहोस्', es: 'Añadir', fr: 'Ajouter', de: 'Hinzufügen', ja: '追加', zh: '添加', it: 'Aggiungi');
  String get statusCompleted => _t('Completed', ne: 'सम्पन्न', es: 'Completado', fr: 'Terminé', de: 'Abgeschlossen', ja: '完了', zh: '已完成', it: 'Completato');
  String longShiftAlertTitle(String job) => _t('Still working at $job?', ne: '$job मा अझै काम गर्दै हुनुहुन्छ?', es: '¿Sigues trabajando en $job?', fr: 'Toujours en service chez $job ?', de: 'Noch bei $job im Dienst?', ja: '$job でまだ勤務中ですか？', zh: '还在 $job 工作吗？', it: 'Stai ancora lavorando da $job?');
  String longShiftAlertBody(String duration) => _t('You have been clocked in for $duration. Tap to review or clock out.', ne: 'तपाईंले $duration काम गरिसक्नुभयो। समाप्त गर्न ट्याप गर्नुहोस्।', es: 'Llevas $duration en turno. Toca para revisar o salir.', fr: 'Vous êtes en service depuis $duration. Appuyez pour terminer.', de: 'Sie sind seit $duration eingestempelt. Tippen zum Prüfen oder Ausstempeln.', ja: '出勤から $duration 経過しました。タップして確認または退勤。', zh: '您已连续打卡 $duration，点击查看或下班打卡。', it: 'Sei in turno da $duration. Tocca per controllare o uscire.');

  // Built-in Category, Account & Currency Localization
  String categoryLabel(String keyOrLabel, [String? fallback]) {
    final norm = keyOrLabel.trim().toLowerCase().replaceAll(' ', '_');
    switch (norm) {
      case 'salary':
        return _t('Salary', ne: 'तलब', es: 'Salario', fr: 'Salaire', de: 'Gehalt', ja: '給与', zh: '工资', it: 'Stipendio');
      case 'shift_pay':
      case 'shift':
        return _t('Shift pay', ne: 'सिफ्ट कमाइ', es: 'Pago de turno', fr: 'Paie de quart', de: 'Schichtlohn', ja: 'シフト給', zh: '班次薪资', it: 'Paga turno');
      case 'business':
        return _t('Business', ne: 'व्यवसाय', es: 'Negocio', fr: 'Entreprise', de: 'Geschäft', ja: 'ビジネス', zh: '生意/副业', it: 'Attività');
      case 'interest':
        return _t('Interest', ne: 'ब्याज', es: 'Intereses', fr: 'Intérêts', de: 'Zinsen', ja: '利息', zh: '利息', it: 'Interessi');
      case 'borrowing':
      case 'borrowed':
        return _t('Borrowing', ne: 'सापटी लिएको', es: 'Préstamo recibido', fr: 'Emprunt', de: 'Geliehen', ja: '借入', zh: '借入', it: 'Prestito ricevuto');
      case 'debt_repayment':
        return _t('Debt Repayment', ne: 'ऋण फिर्ता', es: 'Pago de deuda', fr: 'Remboursement', de: 'Schuldenrückzahlung', ja: '返済', zh: '债务偿还', it: 'Rimborso debito');
      case 'gift_received':
      case 'gift':
        return _t('Gift received', ne: 'उपहार प्राप्त', es: 'Regalo recibido', fr: 'Cadeau reçu', de: 'Geschenk erhalten', ja: 'ギフト', zh: '收到礼金', it: 'Regalo ricevuto');
      case 'other_income':
        return _t('Other income', ne: 'अन्य आम्दानी', es: 'Otros ingresos', fr: 'Autre revenu', de: 'Sonstige Einnahmen', ja: 'その他収入', zh: '其他收入', it: 'Altre entrate');
      case 'groceries':
        return _t('Groceries', ne: 'किराना तथा खाद्यान्न', es: 'Supermercado', fr: 'Courses', de: 'Lebensmittel', ja: '食料品', zh: '买菜/杂货', it: 'Spesa alimentare');
      case 'eating_out':
      case 'dining':
      case 'food':
        return _t('Eating out', ne: 'बाहिरको खाना / खाजा', es: 'Comer fuera', fr: 'Restaurant', de: 'Auswärts essen', ja: '外食', zh: '餐饮外食', it: 'Ristorante');
      case 'entertainment':
        return _t('Entertainment', ne: 'मनोरञ्जन', es: 'Entretenimiento', fr: 'Divertissement', de: 'Unterhaltung', ja: '娯楽', zh: '休闲娱乐', it: 'Intrattenimento');
      case 'transport':
        return _t('Transport', ne: 'यातायात', es: 'Transporte', fr: 'Transport', de: 'Transport', ja: '交通費', zh: '交通出行', it: 'Trasporti');
      case 'bills':
      case 'utilities':
        return _t('Bills', ne: 'बिल तथा महसुल', es: 'Facturas', fr: 'Factures', de: 'Rechnungen', ja: '請求・光熱費', zh: '生活账单', it: 'Bollette');
      case 'lending':
      case 'lent':
        return _t('Lending', ne: 'सापटी दिएको', es: 'Dinero prestado', fr: 'Prêt accordé', de: 'Verliehen', ja: '貸出', zh: '借出', it: 'Prestito concesso');
      case 'other_expense':
      case 'other':
        return _t('Other expense', ne: 'अन्य खर्च', es: 'Otros gastos', fr: 'Autre dépense', de: 'Sonstige Ausgaben', ja: 'その他支出', zh: '其他支出', it: 'Altre spese');
      case 'shopping':
        return _t('Shopping', ne: 'किनमेल', es: 'Compras', fr: 'Shopping', de: 'Einkaufen', ja: '買い物', zh: '购物', it: 'Shopping');
      case 'housing':
      case 'rent':
        return _t('Housing', ne: 'आवास / भाडा', es: 'Vivienda', fr: 'Logement', de: 'Wohnen', ja: '住居・家賃', zh: '住房/房租', it: 'Casa / Affitto');
      case 'health':
        return _t('Health', ne: 'स्वास्थ्य', es: 'Salud', fr: 'Santé', de: 'Gesundheit', ja: '医療・健康', zh: '医疗健康', it: 'Salute');
      case 'transfer':
        return transfer;
      case 'goal':
        return goalLabel;
      case 'general':
        return _t('General', ne: 'सामान्य', es: 'General', fr: 'Général', de: 'Allgemein', ja: '一般', zh: '常规', it: 'Generale');
      default:
        return fallback ?? keyOrLabel;
    }
  }

  String accountDisplayName(String rawName) {
    final norm = rawName.trim().toLowerCase();
    switch (norm) {
      case 'everyday':
      case 'everyday account':
        return everyday;
      case 'savings':
      case 'savings account':
        return savings;
      case 'cash':
      case 'cash wallet':
        return cash;
      default:
        return rawName;
    }
  }

  String currencyName(String code, String fallback) {
    switch (code.toUpperCase()) {
      case 'AUD':
        return _t('Australian dollar', ne: 'अस्ट्रेलियन डलर', es: 'Dólar australiano', fr: 'Dollar australien', de: 'Australischer Dollar', ja: 'オーストラリア・ドル', zh: '澳大利亚元', it: 'Dollaro australiano');
      case 'NPR':
        return _t('Nepali rupee', ne: 'नेपाली रुपैयाँ', es: 'Rupia nepalí', fr: 'Roupie népalaise', de: 'Nepalesische Rupie', ja: 'ネパール・ルピー', zh: '尼泊尔卢比', it: 'Rupia nepalese');
      case 'USD':
        return _t('US dollar', ne: 'अमेरिकी डलर', es: 'Dólar estadounidense', fr: 'Dollar américain', de: 'US-Dollar', ja: '米ドル', zh: '美元', it: 'Dollaro statunitense');
      case 'INR':
        return _t('Indian rupee', ne: 'भारतीय रुपैयाँ', es: 'Rupia india', fr: 'Roupie indienne', de: 'Indische Rupie', ja: 'インド・ルピー', zh: '印度卢比', it: 'Rupia indiana');
      case 'EUR':
        return _t('Euro', ne: 'युरो', es: 'Euro', fr: 'Euro', de: 'Euro', ja: 'ユーロ', zh: '欧元', it: 'Euro');
      case 'GBP':
        return _t('British pound', ne: 'बेलायती पाउन्ड', es: 'Libra esterlina', fr: 'Livre sterling', de: 'Britisches Pfund', ja: '英ポンド', zh: '英镑', it: 'Sterlina britannica');
      case 'JPY':
        return _t('Japanese yen', ne: 'जापानी येन', es: 'Yen japonés', fr: 'Yen japonais', de: 'Japanischer Yen', ja: '日本円', zh: '日元', it: 'Yen giapponese');
      case 'CAD':
        return _t('Canadian dollar', ne: 'क्यानेडियन डलर', es: 'Dólar canadiense', fr: 'Dollar canadien', de: 'Kanadischer Dollar', ja: 'カナダ・ドル', zh: '加拿大元', it: 'Dollaro canadese');
      case 'CNY':
        return _t('Chinese yuan', ne: 'चिनियाँ युआन', es: 'Yuan chino', fr: 'Yuan chinois', de: 'Chinesischer Yuan', ja: '中国人民元', zh: '人民币', it: 'Yuan cinese');
      case 'CHF':
        return _t('Swiss franc', ne: 'स्विस फ्र्याङ्क', es: 'Franco suizo', fr: 'Franc suisse', de: 'Schweizer Franken', ja: 'スイス・フラン', zh: '瑞士法郎', it: 'Franco svizzero');
      case 'HKD':
        return _t('Hong Kong dollar', ne: 'हङकङ डलर', es: 'Dólar de Hong Kong', fr: 'Dollar de Hong Kong', de: 'Hongkong-Dollar', ja: '香港ドル', zh: '港元', it: 'Dollaro di Hong Kong');
      case 'SGD':
        return _t('Singapore dollar', ne: 'सिंगापुर डलर', es: 'Dólar de Singapur', fr: 'Dollar de Singapour', de: 'Singapur-Dollar', ja: 'シンガポール・ドル', zh: '新加坡元', it: 'Dollaro di Singapore');
      default:
        return fallback;
    }
  }

  String formatHourLabel(int hour) {
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final numStr = formatNumber(h12);
    if (hour < 12) {
      return _t('$numStr AM', ne: '$numStr बिहान', es: '$numStr AM', fr: '${formatNumber(hour)}h', de: '${formatNumber(hour)} Uhr', ja: '午前$numStr時', zh: '上午$numStr点', it: '${formatNumber(hour)}:00');
    } else {
      return _t('$numStr PM', ne: '$numStr दिउँसो', es: '$numStr PM', fr: '${formatNumber(hour)}h', de: '${formatNumber(hour)} Uhr', ja: '午後$numStr時', zh: '下午$numStr点', it: '${formatNumber(hour)}:00');
    }
  }

  // Analytics & Filter Period Labels
  String get filterThisMonth => _t('This Month', ne: 'यो महिना', es: 'Este mes', fr: 'Ce mois-ci', de: 'Dieser Monat', ja: '今月', zh: '本月', it: 'Questo mese');
  String get filterThisWeek => _t('This Week', ne: 'यो हप्ता', es: 'Esta semana', fr: 'Cette semaine', de: 'Diese Woche', ja: '今週', zh: '本周', it: 'Questa settimana');
  String get filterLast30Days => _t('Last 30 Days', ne: 'पछिल्लो ३० दिन', es: 'Últimos 30 días', fr: '30 derniers jours', de: 'Letzte 30 Tage', ja: '過去30日間', zh: '最近30天', it: 'Ultimi 30 giorni');
  String get filterThisYear => _t('This Year', ne: 'यो वर्ष', es: 'Este año', fr: 'Cette année', de: 'Dieses Jahr', ja: '今年', zh: '今年', it: 'Quest\'anno');
  String get filterCustomRange => _t('Custom Range', ne: 'कस्टम अवधि', es: 'Rango personalizado', fr: 'Période personnalisée', de: 'Eigener Zeitraum', ja: '期間を指定', zh: '自定义范围', it: 'Periodo personalizzato');
  String get filter3Months => _t('3 months', ne: '३ महिना', es: '3 meses', fr: '3 mois', de: '3 Monate', ja: '3ヶ月', zh: '3个月', it: '3 mesi');
  String get filterYear => _t('Year', ne: 'वर्ष', es: 'Año', fr: 'Année', de: 'Jahr', ja: '年', zh: '年', it: 'Anno');
  String transactionsRecordedCount(int count) {
    final c = formatNumber(count);
    return _t(
      '$c ${count == 1 ? 'transaction' : 'transactions'} recorded',
      ne: '$c कारोबार दर्ता गरिएको छ',
      es: '$c ${count == 1 ? 'transacción registrada' : 'transacciones registradas'}',
      fr: '$c ${count == 1 ? 'transaction enregistrée' : 'transactions enregistrées'}',
      de: '$c ${count == 1 ? 'Transaktion erfasst' : 'Transaktionen erfasst'}',
      ja: '$c 件の取引を記録',
      zh: '已记录 $c 笔交易',
      it: '$c ${count == 1 ? 'transazione registrata' : 'transazioni registrate'}',
    );
  }
  String txCountShort(int count) {
    final c = formatNumber(count);
    return _t(
      '$c ${count == 1 ? 'tx' : 'txs'}',
      ne: '$c कारोबार',
      es: '$c ${count == 1 ? 'mov.' : 'movs.'}',
      fr: '$c ${count == 1 ? 'op.' : 'ops.'}',
      de: '$c ${count == 1 ? 'Buchung' : 'Buchungen'}',
      ja: '$c 件',
      zh: '$c 笔',
      it: '$c ${count == 1 ? 'op.' : 'ops.'}',
    );
  }
  String weekShortLabel(int weekIndex) {
    final w = formatNumber(weekIndex);
    return _t('W$w', ne: 'हप्ता $w', es: 'S$w', fr: 'S$w', de: 'W$w', ja: '第$w週', zh: '第$w周', it: 'S$w');
  }

  // Money & Transactions Screen
  String get expenses => _t('Expenses', ne: 'खर्चहरू', es: 'Gastos', fr: 'Dépenses', de: 'Ausgaben', ja: '支出', zh: '支出', it: 'Spese');
  String get spending => _t('Spending', ne: 'खर्च', es: 'Gastos', fr: 'Dépenses', de: 'Ausgaben', ja: '支出', zh: '支出', it: 'Spesa');
  String get periodLabel => _t('Period', ne: 'अवधि', es: 'Período', fr: 'Période', de: 'Zeitraum', ja: '期間', zh: '周期', it: 'Periodo');
  String get total => _t('Total', ne: 'जम्मा', es: 'Total', fr: 'Total', de: 'Gesamt', ja: '合計', zh: '总计', it: 'Totale');
  String get otherOption => _t('Other', ne: 'अन्य', es: 'Otro', fr: 'Autre', de: 'Sonstiges', ja: 'その他', zh: '其他', it: 'Altro');
  String get note => _t('Note', ne: 'नोट', es: 'Nota', fr: 'Note', de: 'Notiz', ja: 'メモ', zh: '备注', it: 'Nota');
  String get optional => _t('Optional', ne: 'वैकल्पिक', es: 'Opcional', fr: 'Optionnel', de: 'Optional', ja: '任意', zh: '选填', it: 'Opzionale');
  String convertForeignAmountIntoBase(String curr) => _t('Convert foreign amount into $curr', ne: 'विदेशी रकमलाई $curr मा रूपान्तरण गर्नुहोस्', es: 'Convertir importe extranjero a $curr', fr: 'Convertir le montant étranger en $curr', de: 'Fremdwährung in $curr umrechnen', ja: '外貨金額を $curr に換算', zh: '将外币金额换算为 $curr', it: 'Converti importo estero in $curr');
  String get liveInstitutionalRates => _t('Live institutional benchmark rates', ne: 'प्रत्यक्ष विनिमय दरहरू', es: 'Tasas de cambio en tiempo real', fr: 'Taux de change en temps réel', de: 'Live-Wechselkurse', ja: 'リアルタイム為替レート', zh: '实时基准汇率', it: 'Tassi di cambio in tempo reale');
  String get billTagLabel => _t('Bill', ne: 'बिल', es: 'Factura', fr: 'Facture', de: 'Rechnung', ja: '請求書', zh: '账单', it: 'Bolletta');
  String get searchTransactionsHint => _t('Search notes, merchants, categories...', ne: 'नोट, पसल वा श्रेणी खोज्नुहोस्...', es: 'Buscar notas, comercios, categorías...', fr: 'Rechercher notes, commerçants, catégories...', de: 'Notizen, Händler, Kategorien suchen...', ja: 'メモ、店舗、カテゴリを検索...', zh: '搜索备注、商户、类别...', it: 'Cerca note, esercenti, categorie...');
  String transactionsFoundCount(int count) {
    final c = formatNumber(count);
    return _t(
      '$c ${count == 1 ? 'transaction' : 'transactions'} found',
      ne: '$c कारोबार फेला पर्‍यो',
      es: '$c ${count == 1 ? 'transacción encontrada' : 'transacciones encontradas'}',
      fr: '$c ${count == 1 ? 'transaction trouvée' : 'transactions trouvées'}',
      de: '$c ${count == 1 ? 'Transaktion gefunden' : 'Transaktionen gefunden'}',
      ja: '$c 件の取引が見つかりました',
      zh: '找到 $c 笔交易',
      it: '$c ${count == 1 ? 'transazione trovata' : 'transazioni trovate'}',
    );
  }
  String get clearFilters => _t('Clear filters', ne: 'फिल्टर हटाउनुहोस्', es: 'Limpiar filtros', fr: 'Effacer les filtres', de: 'Filter zurücksetzen', ja: 'フィルターをクリア', zh: '清除筛选', it: 'Cancella filtri');
  String get noMatchingTransactions => _t('No matching transactions', ne: 'कुनै मिल्दो कारोबार भेटिएन', es: 'Sin transacciones coincidentes', fr: 'Aucune transaction correspondante', de: 'Keine passenden Transaktionen', ja: '一致する取引がありません', zh: '未找到匹配的交易', it: 'Nessuna transazione corrispondente');
  String get tryAdjustingSearchOrFilters => _t('Try adjusting your search or category filters.', ne: 'आफ्नो खोज वा श्रेणी फिल्टर परिवर्तन गरी हेर्नुहोस्।', es: 'Prueba a ajustar tu búsqueda o filtros.', fr: 'Essayez de modifier votre recherche ou vos filtres.', de: 'Passen Sie Ihre Suche oder Kategorie-Filter an.', ja: '検索条件やカテゴリフィルターを変更してみてください。', zh: '请尝试调整搜索词或类别筛选条件。', it: 'Prova a modificare la ricerca o i filtri.');
  String get tapAddToRecordFirstTransaction => _t('Tap + to record your first income or expense.', ne: 'आफ्नो पहिलो आम्दानी वा खर्च दर्ता गर्न + थिच्नुहोस्।', es: 'Toca + para registrar tu primer ingreso o gasto.', fr: 'Appuyez sur + pour enregistrer votre première opération.', de: 'Tippen Sie auf +, um Ihre erste Buchung zu erfassen.', ja: '＋をタップして最初の収支を記録しましょう。', zh: '点击 + 记录您的第一笔收入或支出。', it: 'Tocca + per registrare la tua prima operazione.');
  String get whereQuestion => _t('Where?', ne: 'कहाँ?', es: '¿Dónde?', fr: 'Où ?', de: 'Wo?', ja: 'どこで？', zh: '在哪里？', it: 'Dove?');
  String get newLabel => _t('New', ne: 'नयाँ', es: 'Nuevo', fr: 'Nouveau', de: 'Neu', ja: '新規', zh: '新增', it: 'Nuovo');
  String get addCustomExpenseCategory => _t('Add Custom Expense Category', ne: 'नयाँ खर्च श्रेणी थप्नुहोस्', es: 'Añadir categoría de gasto', fr: 'Ajouter une catégorie de dépense', de: 'Eigene Ausgabenkategorie', ja: 'カスタム支出カテゴリを追加', zh: '添加自定义支出类别', it: 'Aggiungi categoria di spesa');
  String get addCustomIncomeCategory => _t('Add Custom Income Category', ne: 'नयाँ आम्दानी श्रेणी थप्नुहोस्', es: 'Añadir categoría de ingreso', fr: 'Ajouter une catégorie de revenu', de: 'Eigene Einnahmenkategorie', ja: 'カスタム収入カテゴリを追加', zh: '添加自定义收入类别', it: 'Aggiungi categoria di entrata');
  String get categoryNameLabel => _t('Category name', ne: 'श्रेणीको नाम', es: 'Nombre de la categoría', fr: 'Nom de la catégorie', de: 'Kategoriename', ja: 'カテゴリ名', zh: '类别名称', it: 'Nome categoria');
  String get addCategoryButton => _t('Add Category', ne: 'श्रेणी थप्नुहोस्', es: 'Añadir categoría', fr: 'Ajouter la catégorie', de: 'Kategorie hinzufügen', ja: 'カテゴリを追加', zh: '添加类别', it: 'Aggiungi categoria');
  String get multiCurrencyProTitle => _t('Multi-Currency is a Pro Feature', ne: 'बहु-मुद्रा प्रो सुविधा हो', es: 'Multimoneda es una función Pro', fr: 'Le multi-devises est une fonction Pro', de: 'Multi-Währung ist eine Pro-Funktion', ja: '複数通貨はPro機能です', zh: '多币种是 Pro 专属功能', it: 'Multi-valuta è una funzione Pro');
  String get multiCurrencyProMessage => _t(
        'Recording transactions in foreign currencies with live exchange rates requires Hyprwise Pro.',
        ne: 'विदेशी मुद्रामा प्रत्यक्ष विनिमय दरसहित कारोबार दर्ता गर्न हाइपरवाइज प्रो आवश्यक पर्दछ।',
        es: 'Registrar transacciones en moneda extranjera con tasas en vivo requiere Hyprwise Pro.',
        fr: 'L\'enregistrement en devises étrangères avec taux en direct nécessite Hyprwise Pro.',
        de: 'Transaktionen in Fremdwährungen mit Live-Kursen erfordern Hyprwise Pro.',
        ja: '外貨でのリアルタイム換算記録にはHyprwise Proが必要です。',
        zh: '使用实时汇率记录外币交易需要升级至 Hyprwise Pro。',
        it: 'Registrare transazioni in valuta estera con tassi live richiede Hyprwise Pro.',
      );

  // Calendar Screen
  String itemsScheduledCount(int count) {
    final c = formatNumber(count);
    return _t(
      '$c ${count == 1 ? 'item' : 'items'} scheduled',
      ne: '$c कार्य तालिकाबद्ध',
      es: '$c ${count == 1 ? 'elemento programado' : 'elementos programados'}',
      fr: '$c ${count == 1 ? 'élément prévu' : 'éléments prévus'}',
      de: '$c ${count == 1 ? 'Eintrag geplant' : 'Einträge geplant'}',
      ja: '$c 件の予定',
      zh: '$c 项日程安排',
      it: '$c ${count == 1 ? 'elemento in programma' : 'elementi in programma'}',
    );
  }
  String hoursDurationLabel(String hours) => _t('$hours hours duration', ne: '$hours घण्टा अवधि', es: '$hours horas de duración', fr: 'Durée de $hours heures', de: '$hours Stunden Dauer', ja: '所要時間 $hours 時間', zh: '时长 $hours 小时', it: 'Durata $hours ore');
  String amountWithValue(String formattedAmount) => _t('Amount: $formattedAmount', ne: 'रकम: $formattedAmount', es: 'Importe: $formattedAmount', fr: 'Montant : $formattedAmount', de: 'Betrag: $formattedAmount', ja: '金額: $formattedAmount', zh: '金额：$formattedAmount', it: 'Importo: $formattedAmount');
  String get recurringBillDue => _t('Recurring bill due', ne: 'नियमित बिल तिर्ने मिति', es: 'Vencimiento de factura recurrente', fr: 'Facture récurrente due', de: 'Wiederkehrende Rechnung fällig', ja: '定期請求の期日', zh: '定期账单到期', it: 'Scadenza bolletta ricorrente');
  String get goalContributionPlanned => _t('Goal contribution planned', ne: 'लक्ष्य बचत योजना', es: 'Aporte a meta planificado', fr: 'Contribution à l\'objectif prévue', de: 'Geplanter Sparbeitrag', ja: '目標への積立予定', zh: '计划目标存入', it: 'Contributo obiettivo pianificato');
  String get scheduledShiftSubtitle => _t('Scheduled shift', ne: 'तालिकाबद्ध सिफ्ट', es: 'Turno programado', fr: 'Quart planifié', de: 'Geplante Schicht', ja: '予定シフト', zh: '计划班次', it: 'Turno programmato');
  String jobShiftTitle(String jobName) => _t('$jobName shift', ne: '$jobName सिफ्ट', es: 'Turno de $jobName', fr: 'Quart $jobName', de: '$jobName-Schicht', ja: '$jobName シフト', zh: '$jobName 班次', it: 'Turno $jobName');

  // Work & Shift Rate Slider
  String get activeBadge => _t('Active', ne: 'सक्रिय', es: 'Activo', fr: 'Actif', de: 'Aktiv', ja: '稼働中', zh: '进行中', it: 'Attivo');
  String get hrsUnit => _t('hrs', ne: 'घण्टा', es: 'h', fr: 'h', de: 'Std.', ja: '時間', zh: '小时', it: 'ore');
  String get perHourSuffix => _t('/ hr', ne: '/ घण्टा', es: '/ h', fr: '/ h', de: '/ Std.', ja: '/ 時間', zh: '/ 小时', it: '/ ora');
  String get regularRateShort => _t('reg', ne: 'नियमित', es: 'reg', fr: 'norm', de: 'Reg', ja: '通常', zh: '常规', it: 'ord');
  String get overtimeShort => _t('OT', ne: 'ओभरटाइम', es: 'Extra', fr: 'HS', de: 'ÜS', ja: '残業', zh: '加班', it: 'Str');
  String get avgShort => _t('avg', ne: 'औसत', es: 'prom', fr: 'moy', de: 'Ø', ja: '平均', zh: '平均', it: 'med');
  String regularHoursSummary(String hours) => _t('Regular: $hours', ne: 'नियमित: $hours', es: 'Regular: $hours', fr: 'Normal : $hours', de: 'Regulär: $hours', ja: '通常: $hours', zh: '常规：$hours', it: 'Ordinario: $hours');
  String overtimeSummary(String mult, String afterHours) => _t('OT ($mult): after $afterHours', ne: 'ओभरटाइम ($mult): $afterHours पछि', es: 'Extra ($mult): tras $afterHours', fr: 'HS ($mult) : après $afterHours', de: 'ÜS ($mult): nach $afterHours', ja: '残業 ($mult): $afterHours 以降', zh: '加班 ($mult)：$afterHours 后', it: 'Straord. ($mult): dopo $afterHours');

  // Export & Backup Dialogs
  String get csvFormatTitle => _t('CSV Spreadsheet (.csv)', ne: 'CSV स्प्रेडसिट (.csv)', es: 'Hoja de cálculo CSV (.csv)', fr: 'Feuille de calcul CSV (.csv)', de: 'CSV-Tabelle (.csv)', ja: 'CSVスプレッドシート (.csv)', zh: 'CSV 电子表格 (.csv)', it: 'Foglio di calcolo CSV (.csv)');
  String get csvFormatDesc => _t('Transactions and work shifts in tabular format, compatible with Excel and Google Sheets.', ne: 'Excel र Google Sheets मा खुल्ने कारोबार र सिफ्टहरूको तालिका।', es: 'Transacciones y turnos en formato tabular para Excel y Google Sheets.', fr: 'Transactions et quarts au format tabulaire pour Excel et Google Sheets.', de: 'Transaktionen und Schichten im Tabellenformat für Excel und Google Sheets.', ja: 'ExcelやGoogleスプレッドシートに対応した表形式データ。', zh: '兼容 Excel 与 Google 表格的交易和排班记录。', it: 'Transazioni e turni in formato tabellare per Excel e Fogli Google.');
  String get jsonFormatTitle => _t('Full System Backup (.json)', ne: 'पूर्ण प्रणाली ब्याकअप (.json)', es: 'Copia completa del sistema (.json)', fr: 'Sauvegarde complète (.json)', de: 'Vollständiges System-Backup (.json)', ja: '完全システムバックアップ (.json)', zh: '完整系统备份 (.json)', it: 'Backup completo di sistema (.json)');
  String get jsonFormatDesc => _t('Complete database backup including accounts, shifts, jobs, goals, and exchange rates.', ne: 'खाता, सिफ्ट, काम, लक्ष्य र विनिमय दरसहितको पूर्ण ब्याकअप।', es: 'Copia completa de cuentas, turnos, empleos, metas y tasas.', fr: 'Sauvegarde complète incluant comptes, quarts, emplois et objectifs.', de: 'Komplettes Datenbank-Backup inkl. Konten, Schichten, Jobs und Zielen.', ja: '口座、シフト、仕事、目標を含む完全なバックアップデータ。', zh: '包含账户、排班、工作、目标和汇率的完整数据库备份。', it: 'Backup completo inclusi conti, turni, lavori e obiettivi.');
  String get saveToDownloadsTitle => _t('Save to Downloads', ne: 'डाउनलोड फोल्डरमा सुरक्षित गर्नुहोस्', es: 'Guardar en Descargas', fr: 'Enregistrer dans Téléchargements', de: 'In Downloads speichern', ja: 'ダウンロードに保存', zh: '保存到下载目录', it: 'Salva in Download');
  String get saveToDownloadsDesc => _t('Saves directly to your device Downloads folder for easy file access.', ne: 'तपाईंको फोनको Downloads फोल्डरमा सिधै सेभ हुन्छ।', es: 'Se guarda directamente en la carpeta Descargas de tu dispositivo.', fr: 'Enregistre directement dans le dossier Téléchargements de l\'appareil.', de: 'Speichert direkt im Downloads-Ordner Ihres Geräts.', ja: '端末のダウンロードフォルダに直接保存します。', zh: '直接保存到您设备的下载文件夹中。', it: 'Salva direttamente nella cartella Download del dispositivo.');
  String get shareToAppsTitle => _t('Share to App', ne: 'अन्य एपमा सेयर गर्नुहोस्', es: 'Compartir en aplicación', fr: 'Partager vers une application', de: 'An App teilen', ja: '他のアプリで共有', zh: '分享到应用', it: 'Condividi con app');
  String get shareToAppsDesc => _t('Send via WhatsApp, Email, or Save to Files.', ne: 'WhatsApp, इमेल वा फाइलमा सुरक्षित गर्नुहोस्।', hi: 'WhatsApp, ईमेल या फ़ाइल में सुरक्षित करें।', es: 'Enviar por WhatsApp, correo o Guardar en Archivos.', fr: 'Envoyer via WhatsApp, e-mail ou Fichiers.', de: 'Über WhatsApp, E-Mail senden oder in Dateien speichern.', ja: 'WhatsAppやメール、ファイルアプリへ共有・保存します。', zh: '通过 WhatsApp、邮件发送或保存到本地文件。', it: 'Invia tramite WhatsApp, Email o Salva su File.');
  String get exportFinancialData => _t('Export Financial Data', ne: 'वित्तीय डाटा निर्यात गर्नुहोस्', es: 'Exportar datos financieros', fr: 'Exporter les données financières', de: 'Finanzdaten exportieren', ja: '財務データのエクスポート', zh: '导出财务数据', it: 'Esporta dati finanziari');
  String get chooseExportFormatSub => _t('Choose the format and where you would like to place the export.', ne: 'निर्यात गर्ने ढाँचा र सुरक्षित गर्ने स्थान छान्नुहोस्।', es: 'Elige el formato y dónde deseas guardar la exportación.', fr: 'Choisissez le format et la destination de l\'exportation.', de: 'Wählen Sie das Format und das Ziel für den Export.', ja: '出力形式と保存先を選択してください。', zh: '选择导出的文件格式与保存位置。', it: 'Scegli il formato e la destinazione dell\'esportazione.');
  String get chooseFormatLabel => _t('1. Choose Format', ne: '१. ढाँचा छान्नुहोस्', es: '1. Elegir formato', fr: '1. Choisir le format', de: '1. Format wählen', ja: '1. 形式を選択', zh: '1. 选择格式', it: '1. Scegli formato');
  String get deliveryMethodLabel => _t('2. Choose Destination', ne: '२. माध्यम छान्नुहोस्', es: '2. Elegir destino', fr: '2. Choisir la destination', de: '2. Ziel wählen', ja: '2. 保存先を選択', zh: '2. 选择导出方式', it: '2. Scegli destinazione');
  String get exportNowButton => _t('Export Now', ne: 'अहिले निर्यात गर्नुहोस्', es: 'Exportar ahora', fr: 'Exporter maintenant', de: 'Jetzt exportieren', ja: '今すぐエクスポート', zh: '立即导出', it: 'Esporta ora');
  String get exportCompleteTitle => _t('Export Complete', ne: 'निर्यात सम्पन्न भयो', es: 'Exportación completada', fr: 'Exportation terminée', de: 'Export abgeschlossen', ja: 'エクスポート完了', zh: '导出完成', it: 'Esportazione completata');
  String exportCompleteMsg(String kb) => _t('Your data was exported successfully ($kb KB).', ne: 'तपाईंको डाटा सफलतापूर्वक निर्यात गरियो ($kb KB)।', es: 'Tus datos se exportaron correctamente ($kb KB).', fr: 'Vos données ont été exportées avec succès ($kb Ko).', de: 'Ihre Daten wurden erfolgreich exportiert ($kb KB).', ja: 'データが正常にエクスポートされました ($kb KB)。', zh: '您的数据已成功导出 ($kb KB)。', it: 'I tuoi dati sono stati esportati con successo ($kb KB).');
  String get fileLocationLabel => _t('File location:', ne: 'फाइल रहेको स्थान:', es: 'Ubicación del archivo:', fr: 'Emplacement du fichier :', de: 'Dateispeicherort:', ja: '保存先:', zh: '文件位置：', it: 'Posizione file:');
  String get copyPathButton => _t('Copy path', ne: 'पाथ कपी गर्नुहोस्', es: 'Copiar ruta', fr: 'Copier le chemin', de: 'Pfad kopieren', ja: 'パスをコピー', zh: '复制路径', it: 'Copia percorso');
  String get pathCopiedToast => _t('Path copied to clipboard', ne: 'फाइल पाथ कपी गरियो', es: 'Ruta copiada al portapapeles', fr: 'Chemin copié dans le presse-papiers', de: 'Pfad in die Zwischenablage kopiert', ja: 'パスをコピーしました', zh: '路径已复制到剪贴板', it: 'Percorso copiato negli appunti');
  String get shareFileButton => _t('Share file', ne: 'फाइल सेयर गर्नुहोस्', es: 'Compartir archivo', fr: 'Partager le fichier', de: 'Datei teilen', ja: 'ファイルを共有', zh: '分享文件', it: 'Condividi file');

  // Wizard Scaffold & Pro Dialogs
  String get discardTitle => _t('Discard this?', ne: 'यो रद्द गर्ने हो?', es: '¿Descartar esto?', fr: 'Abandonner ?', de: 'Verwerfen?', ja: '破棄しますか？', zh: '要放弃吗？', it: 'Scartare le modifiche?');
  String get discardMessage => _t('What you entered will be lost.', ne: 'तपाईंले भर्नुभएको विवरण हट्नेछ।', es: 'Lo que ingresaste se perderá.', fr: 'Ce que vous avez saisi sera perdu.', de: 'Ihre Eingaben gehen verloren.', ja: '入力した内容は失われます。', zh: '您输入的内容将会丢失。', it: 'I dati inseriti andranno persi.');
  String get discardAction => _t('Discard', ne: 'रद्द गर्नुहोस्', es: 'Descartar', fr: 'Abandonner', de: 'Verwerfen', ja: '破棄する', zh: '放弃', it: 'Scarta');
  String get keepEditing => _t('Keep editing', ne: 'सम्पादन जारी राख्नुहोस्', es: 'Seguir editando', fr: 'Continuer la saisie', de: 'Weiter bearbeiten', ja: '編集を続ける', zh: '继续编辑', it: 'Continua a modificare');
  String get exploreProPlans => _t('Explore Pro Plans', ne: 'प्रो योजनाहरू हेर्नुहोस्', es: 'Explorar planes Pro', fr: 'Découvrir les offres Pro', de: 'Pro-Pläne entdecken', ja: 'Proプランを見る', zh: '查看 Pro 计划', it: 'Esplora i piani Pro');
  String get maybeLater => _t('Maybe later', ne: 'पछि गरौँला', es: 'Quizás más tarde', fr: 'Peut-être plus tard', de: 'Vielleicht später', ja: 'あとで', zh: '以后再说', it: 'Forse più tardi');
  String get proPerkMultiCurrency => _t('Unlimited Multi-Currency Tracking & Live Rates', ne: 'असीमित बहु-मुद्रा ट्र्याकिङ र प्रत्यक्ष विनिमय दर', es: 'Seguimiento multimoneda ilimitado y tasas en vivo', fr: 'Suivi multi-devises illimité et taux en direct', de: 'Unbegrenztes Multi-Währungs-Tracking & Live-Kurse', ja: '無制限の複数通貨管理とリアルタイム為替レート', zh: '无限制多币种追踪与实时汇率', it: 'Tracciamento multi-valuta illimitato e tassi live');
  String get proPerkAiAssistant => _t('Hypr AI Financial Assistant & Smart Insights', ne: 'Hypr AI वित्तीय सहायक र स्मार्ट विश्लेषण', es: 'Asistente financiero Hypr AI e ideas inteligentes', fr: 'Assistant financier Hypr AI et analyses intelligentes', de: 'Hypr AI Finanzassistent & smarte Analysen', ja: 'Hypr AI アシスタント＆スマート分析', zh: 'Hypr AI 财务助手与智能洞察', it: 'Assistente finanziario Hypr AI e analisi smart');
  String get proPerkCloudBackup => _t('Encrypted Cloud Backup & PDF/Excel Reports', ne: 'सुरक्षित क्लाउड ब्याकअप र PDF/Excel रिपोर्टहरू', es: 'Copia en la nube cifrada e informes PDF/Excel', fr: 'Sauvegarde cloud chiffrée et rapports PDF/Excel', de: 'Verschlüsseltes Cloud-Backup & PDF/Excel-Berichte', ja: '暗号化クラウドバックアップ＆PDF/Excelレポート', zh: '加密云备份与 PDF/Excel 报表导出', it: 'Backup cloud crittografato e report PDF/Excel');

  // Settings & Auth Guard
  String get accountAndDataDeleted => _t('Account and data deleted', ne: 'खाता र डाटा हटाइयो', es: 'Cuenta y datos eliminados', fr: 'Compte et données supprimés', de: 'Konto und Daten gelöscht', ja: 'アカウントとデータを削除しました', zh: '账户及数据已删除', it: 'Account e dati eliminati');
  String get appVersionTagline => _t('v0.1.0 (preview) · personal finance & shift planner', ne: 'v०.१.० (पूर्वावलोकन) · व्यक्तिगत वित्त र सिफ्ट योजनाकार', es: 'v0.1.0 (preview) · finanzas personales y turnos', fr: 'v0.1.0 (aperçu) · finances personnelles et quarts', de: 'v0.1.0 (Vorschau) · Finanzen & Schichtplaner', ja: 'v0.1.0 (プレビュー) · 家計簿＆シフト管理', zh: 'v0.1.0 (预览版) · 个人财务与排班助手', it: 'v0.1.0 (anteprima) · finanze personali e turni');
  String get proUnlockedSubtitle => _t('Cloud sync & Hypr AI unlocked', ne: 'क्लाउड सिंक र Hypr AI सक्रिय छ', es: 'Sincronización en la nube y Hypr AI desbloqueados', fr: 'Sync cloud et Hypr AI débloqués', de: 'Cloud-Sync & Hypr AI freigeschaltet', ja: 'クラウド同期＆Hypr AI 利用可能', zh: '云同步与 Hypr AI 已解锁', it: 'Sync cloud e Hypr AI sbloccati');
  String get proUpgradeSubtitle => _t('Cloud sync, Hypr AI, multi-currency & PDF export', ne: 'क्लाउड सिंक, Hypr AI, बहु-मुद्रा र PDF निर्यात', es: 'Nube, Hypr AI, multimoneda y exportación PDF', fr: 'Cloud, Hypr AI, multi-devises et export PDF', de: 'Cloud-Sync, Hypr AI, Multi-Währung & PDF-Export', ja: 'クラウド同期・Hypr AI・複数通貨・PDF出力', zh: '云同步、Hypr AI、多币种与 PDF 导出', it: 'Cloud, Hypr AI, multi-valuta ed esportazione PDF');
  String get cloudAccount => _t('Cloud Account', ne: 'क्लाउड खाता', es: 'Cuenta en la nube', fr: 'Compte Cloud', de: 'Cloud-Konto', ja: 'クラウドアカウント', zh: '云端账户', it: 'Account Cloud');
  String get signInToSyncSubtitle => _t('Sign in to synchronize backups & unlock Pro across devices', ne: 'ब्याकअप सिंक गर्न र सबै डिभाइसमा प्रो चलाउन साइन इन गर्नुहोस्', es: 'Inicia sesión para sincronizar copias y activar Pro', fr: 'Connectez-vous pour synchroniser vos sauvegardes et Pro', de: 'Anmelden, um Backups & Pro geräteübergreifend zu nutzen', ja: 'サインインしてバックアップとProを端末間で同期', zh: '登录以同步云备份并在多设备间解锁 Pro', it: 'Accedi per sincronizzare i backup e sbloccare Pro');
  String get signedInWithGoogle => _t('Signed in with Google', ne: 'Google बाट साइन इन गरिएको', es: 'Conectado con Google', fr: 'Connecté avec Google', de: 'Mit Google angemeldet', ja: 'Googleでサインイン中', zh: '已通过 Google 登录', it: 'Accesso effettuato con Google');
  String get signedInWithApple => _t('Signed in with Apple', ne: 'Apple बाट साइन इन गरिएको', es: 'Conectado con Apple', fr: 'Connecté avec Apple', de: 'Mit Apple angemeldet', ja: 'Appleでサインイン中', zh: '已通过 Apple 登录', it: 'Accesso effettuato con Apple');
  String get signInToLinkProTitle => _t('Sign In to Link Data & Purchase Pro', ne: 'डाटा लिंक गर्न र प्रो खरिद गर्न साइन इन गर्नुहोस्', es: 'Inicia sesión para vincular datos y comprar Pro', fr: 'Connectez-vous pour lier vos données et acheter Pro', de: 'Anmelden, um Daten zu verknüpfen & Pro zu kaufen', ja: 'サインインしてデータを連携＆Proを購入', zh: '登录以绑定数据并购买 Pro', it: 'Accedi per collegare i dati e acquistare Pro');
  String get signInToLinkProDesc => _t(
        'To protect your subscription across devices and securely bind your local records to your cloud account, please sign in before upgrading to Hyprwise Pro.',
        ne: 'तपाईंको सदस्यता सुरक्षित राख्न र फोनको डाटालाई क्लाउड खातामा जोड्न कृपया हाइपरवाइज प्रो लिनुअघि साइन इन गर्नुहोस्।',
        es: 'Para proteger tu suscripción entre dispositivos y vincular tus datos locales, inicia sesión antes de actualizar a Hyprwise Pro.',
        fr: 'Pour protéger votre abonnement sur tous vos appareils, veuillez vous connecter avant de passer à Hyprwise Pro.',
        de: 'Um Ihr Abo geräteübergreifend zu schützen, melden Sie sich bitte vor dem Upgrade auf Hyprwise Pro an.',
        ja: '複数の端末でサブスクリプションを保護しデータを安全に連携するため、アップグレード前にサインインしてください。',
        zh: '为了跨设备保护您的订阅并将本地记录安全绑定到云账户，请在升级 Hyprwise Pro 前登录。',
        it: 'Per proteggere il tuo abbonamento su tutti i dispositivi, accedi prima di passare a Hyprwise Pro.',
      );

  // Advice Engine Alerts
  String alertGoalMayFallShort(String goalName) => _t('$goalName may fall short', ne: '$goalName लक्ष्य अपूरो हुन सक्छ', es: '$goalName podría quedarse corto', fr: '$goalName risque d\'être insuffisant', de: '$goalName könnte verfehlt werden', ja: '$goalName が目標に届かない可能性', zh: '$goalName 可能无法按期达成', it: '$goalName potrebbe non essere raggiunto');
  String alertGoalProjectedMsg(String projected, String target, String date) => _t('Projected $projected against a $target target by $date', ne: '$date सम्म $target लक्ष्यको तुलनामा अनुमानित $projected', es: 'Proyectado $projected frente a $target para el $date', fr: 'Projeté $projected sur un objectif de $target d\'ici le $date', de: 'Prognose $projected bei $target Ziel bis $date', ja: '$date までに目標 $target に対し予測 $projected', zh: '预计到 $date 为 $projected（目标 $target）', it: 'Previsti $projected su un obiettivo di $target entro il $date');
  String get alertBalanceNegativeTitle => _t('Projected balance goes negative', ne: 'अनुमानित मौज्दात ऋणात्मक हुँदैछ', es: 'El saldo proyectado se vuelve negativo', fr: 'Le solde projeté devient négatif', de: 'Prognostizierter Kontostand wird negativ', ja: '予測残高がマイナスになります', zh: '预计余额将变为负数', it: 'Il saldo previsto diventa negativo');
  String alertBalanceNegativeMsg(String date) => _t('At the current pace you run out around $date', ne: 'हालको गतिमा $date तिर रकम अपुग हुन सक्छ', es: 'Al ritmo actual te quedarás sin fondos hacia el $date', fr: 'Au rythme actuel, vous serez à découvert vers le $date', de: 'Beim aktuellen Tempo reicht das Guthaben bis ca. $date', ja: '現在のペースでは $date 頃に資金が不足します', zh: '按目前的速度，预计在 $date 左右余额耗尽', it: 'Al ritmo attuale finirai i fondi intorno al $date');
  String alertBillDueTitle(String billName, String date) => _t('$billName due $date', ne: '$billName तिर्ने मिति $date', es: '$billName vence el $date', fr: '$billName dû le $date', de: '$billName fällig am $date', ja: '$billName の支払期日 $date', zh: '$billName 将于 $date 到期', it: '$billName in scadenza il $date');
  String alertBillLeavesBalanceMsg(String amount, String remaining) => _t('$amount leaves your account on $remaining', ne: '$amount तिरेपछि खातामा $remaining बाँकी रहनेछ', es: '$amount deja tu cuenta en $remaining', fr: '$amount laisse votre compte à $remaining', de: '$amount lässt $remaining auf Ihrem Konto', ja: '$amount の支払い後、残高は $remaining になります', zh: '支付 $amount 后账户剩余 $remaining', it: '$amount lascia il conto a $remaining');

  // Transactions & Work Details
  String get overtime => _t('Overtime', ne: 'ओभरटाइम', hi: 'ओवरटाइम', es: 'Horas extras', fr: 'Heures supplémentaires', de: 'Überstunden', ja: '残業', zh: '加班', it: 'Straordinario');
  String get typeLabel => _t('Type', ne: 'प्रकार', hi: 'प्रकार', es: 'Tipo', fr: 'Type', de: 'Typ', ja: '種類', zh: '类型', it: 'Tipo');
  String get amount => _t('Amount', ne: 'रकम', hi: 'राशि', es: 'Importe', fr: 'Montant', de: 'Betrag', ja: '金額', zh: '金额', it: 'Importo');
  String get noteOptional => _t('Note (Optional)', ne: 'कैफियत (वैकल्पिक)', hi: 'नोट (वैकल्पिक)', es: 'Nota (Opcional)', fr: 'Note (Optionnel)', de: 'Notiz (Optional)', ja: 'メモ (任意)', zh: '备注 (可选)', it: 'Nota (Facoltativa)');
  String get deleteTransactionTitle => _t('Delete Transaction?', ne: 'कारोबार मेटाउने?', hi: 'लेनदेन हटाएं?', es: '¿Eliminar transacción?', fr: 'Supprimer la transaction ?', de: 'Transaktion löschen?', ja: '取引を削除しますか？', zh: '删除交易？', it: 'Eliminare transazione?');
  String get deleteTransactionSubtitle => _t(
        'This transaction will be permanently removed from your account balance.',
        ne: 'यो कारोबार तपाईंको खाता ब्यालेन्सबाट स्थायी रूपमा हटाइनेछ।',
        hi: 'यह लेनदेन आपके खाते से स्थायी रूप से हटा दिया जाएगा।',
        es: 'Esta transacción se eliminará de forma permanente de su saldo.',
        fr: 'Cette transaction sera définitivement supprimée de votre solde.',
        de: 'Diese Transaktion wird dauerhaft aus Ihrem Kontostand gelöscht.',
        ja: 'この取引は口座残高から完全に削除されます。',
        zh: '此交易记录将从您的账户余额中永久删除。',
        it: 'Questa transazione verrà rimossa definitivamente dal saldo del tuo conto.',
      );

  // Redesigned Home Hero
  String get spendable => _t('Spendable', ne: 'खर्चयोग्य', hi: 'खर्च योग्य', es: 'Gastable', fr: 'Disponible', de: 'Verfügbar', ja: '利用可能', zh: '可用余额', it: 'Spendibile');
  String get reserved => _t('Reserved', ne: 'सुरक्षित/बचत', hi: 'सुरक्षित', es: 'Reservado', fr: 'Réservé', de: 'Reserviert', ja: '確保済み', zh: '已预留', it: 'Riservato');
  String get allAccounts => _t('All accounts', ne: 'सबै खाताहरू', hi: 'सभी खाते', es: 'Todas las cuentas', fr: 'Tous les comptes', de: 'Alle Konten', ja: 'すべての口座', zh: '全部账户', it: 'Tutti i conti');
  String get everydayAndCash => _t('Everyday and cash', ne: 'दैनिक तथा नगद', hi: 'दैनिक और नकद', es: 'Diario y efectivo', fr: 'Courant et espèces', de: 'Giro und Bargeld', ja: '日常口座と現金', zh: '日常账户与现金', it: 'Conto e contanti');
  String get savingsAndGoals => _t('Savings, goals', ne: 'बचत, लक्ष्यहरू', hi: 'बचत, लक्ष्य', es: 'Ahorros, metas', fr: 'Épargne, objectifs', de: 'Sparen, Ziele', ja: '貯蓄・目標', zh: '储蓄与目标', it: 'Risparmi, obiettivi');
  String get balanceOutlook => _t('Balance outlook', ne: 'ब्यालेन्स प्रक्षेपण', hi: 'बैलेंस दृष्टिकोण', es: 'Perspectiva de saldo', fr: 'Évolution du solde', de: 'Saldo-Ausblick', ja: '残高の見通し', zh: '余额走势', it: 'Andamento saldo');
  String get outlook => _t('Outlook', ne: 'प्रक्षेपण', hi: 'दृष्टिकोण', es: 'Perspectiva', fr: 'Perspectives', de: 'Ausblick', ja: '見通し', zh: '走势', it: 'Prospettiva');
  String get thisMonth => _t('This month', ne: 'यो महिना', hi: 'इस महीने', es: 'Este mes', fr: 'Ce mois-ci', de: 'Diesen Monat', ja: '今月', zh: '本月', it: 'Questo mese');
  String get thisMonthSoFar => _t('This month so far', ne: 'यो महिना हालसम्म', hi: 'इस महीने अब तक', es: 'Este mes hasta ahora', fr: 'Ce mois-ci jusqu\'à présent', de: 'Diesen Monat bisher', ja: '今月の状況', zh: '本月至今', it: 'Questo mese finora');
  String get forecastLabel => _t('forecast', ne: 'पूर्वानुमान', hi: 'पूर्वानुमान', es: 'pronóstico', fr: 'prévision', de: 'Prognose', ja: '予測', zh: '预测', it: 'previsione');
  String inDays(int n) => _t('in $n days', ne: '$n दिनमा', hi: '$n दिनों में', es: 'en $n días', fr: 'dans $n jours', de: 'in $n Tagen', ja: '$n日後', zh: '$n天内', it: 'in $n giorni');
  String get rangeLabel => _t('range', ne: 'दायरा', hi: 'दायरा', es: 'rango', fr: 'fourchette', de: 'Spanne', ja: '範囲', zh: '区间', it: 'intervallo');
  String get inWord => _t('In', ne: 'आम्दानी', hi: 'आवक', es: 'Entradas', fr: 'Entrées', de: 'Einnahmen', ja: '収入', zh: '流入', it: 'Entrate');
  String get outWord => _t('Out', ne: 'खर्च', hi: 'जावक', es: 'Salidas', fr: 'Sorties', de: 'Ausgaben', ja: '支出', zh: '流出', it: 'Uscite');
  String activeWithCount(int n) => _t('$n active', ne: '$n सक्रिय', hi: '$n सक्रिय', es: '$n activo(s)', fr: '$n actif(s)', de: '$n aktiv', ja: '$n件 有効', zh: '$n条进行中', it: '$n attivo/i');
  String get lentLabel => _t('Lent', ne: 'दिएको', hi: 'दिया', es: 'Prestado', fr: 'Prêté', de: 'Verliehen', ja: '貸出', zh: '借出', it: 'Prestato');
  String get borrowedLabel => _t('Borrowed', ne: 'लिएको', hi: 'लिया', es: 'Tomado', fr: 'Emprunté', de: 'Geliehen', ja: '借入', zh: '借入', it: 'Preso in prestito');
  String get viewAll => _t('View all', ne: 'सबै हेर्नुहोस्', hi: 'सभी देखें', es: 'Ver todo', fr: 'Voir tout', de: 'Alle ansehen', ja: 'すべて表示', zh: '查看全部', it: 'Vedi tutto');
  String get addTransactionsToSeeOutlook => _t(
        'Add transactions to see your outlook',
        ne: 'प्रक्षेपण हेर्न कारोबार थप्नुहोस्',
        hi: 'दृष्टिकोण देखने के लिए लेनदेन जोड़ें',
        es: 'Añade transacciones para ver tu perspectiva',
        fr: 'Ajoutez des transactions pour voir l\'évolution',
        de: 'Transaktionen hinzufügen, um Ausblick zu sehen',
        ja: '見通しを表示するには取引を追加してください',
        zh: '添加交易记录以查看收支走势',
        it: 'Aggiungi transazioni per vedere l\'andamento',
      );
  String percentOfNet(String pct) => _t('$pct% of net', ne: 'कुलको $pct%', hi: 'कुल का $pct%', es: '$pct% del neto', fr: '$pct% du net', de: '$pct% des Netto', ja: '全体の $pct%', zh: '占净额 $pct%', it: '$pct% del netto');
  String get net => _t('Net', ne: 'खुद', hi: 'शुद्ध', es: 'Neto', fr: 'Net', de: 'Netto', ja: '純額', zh: '净额', it: 'Netto');
  String get betterMoneyBrighterDays => _t('Better money. Brighter days.', ne: 'राम्रो धन। उज्ज्वल दिनहरू।', hi: 'बेहतर धन। उज्ज्वल दिन।', es: 'Mejor dinero. Días más brillantes.', fr: 'Un meilleur argent. Des jours meilleurs.', de: 'Besseres Geld. Hellere Tage.', ja: 'より良いお金。明るい未来。', zh: '明智理财，美好未来。', it: 'Soldi migliori. Giorni più luminosi.');
  String get spendingOverview => _t('Spending overview', ne: 'खर्च अवलोकन', hi: 'खर्च अवलोकन', es: 'Resumen de gastos', fr: 'Aperçu des dépenses', de: 'Ausgabenübersicht', ja: '支出の概要', zh: '支出概览', it: 'Panoramica spese');
  String get spent => _t('spent', ne: 'खर्च भयो', hi: 'खर्च हुआ', es: 'gastado', fr: 'dépensé', de: 'ausgegeben', ja: '支出', zh: '已支出', it: 'speso');
  String get more => _t('More', ne: 'थप', hi: 'अधिक', es: 'Más', fr: 'Plus', de: 'Mehr', ja: 'その他', zh: '更多', it: 'Altro');
  String get smallStepsToBigGoals => _t('Small steps to big goals.', ne: 'ठूला लक्ष्यका लागि साना पाइलाहरू।', hi: 'बड़े लक्ष्यों के लिए छोटे कदम।', es: 'Pequeños pasos para grandes metas.', fr: 'De petits pas vers de grands objectifs.', de: 'Kleine Schritte zu großen Zielen.', ja: '大きな目標へ、小さな一歩。', zh: '不积跬步，无以至千里。', it: 'Piccoli passi verso grandi obiettivi.');
  String get trackYourSpendingSaveMore => _t('Track your spending, save more, live better.', ne: 'खर्च ट्र्याक गर्नुहोस्, धेरै बचत गर्नुहोस्, राम्रो जीवन बिताउनुहोस्।', hi: 'खर्च ट्रैक करें, अधिक बचत करें, बेहतर जीवन जिएं।', es: 'Controla tus gastos, ahorra más, vive mejor.', fr: 'Suivez vos dépenses, épargnez plus, vivez mieux.', de: 'Ausgaben erfassen, mehr sparen, besser leben.', ja: '支出を把握し、賢く貯めて、より良い暮らしを。', zh: '追踪每一笔支出，积少成多，享受生活。', it: 'Monitora le spese, risparmia di più, vivi meglio.');
  String dueInDays(int n) => _t('Due in $n days', ne: '$n दिनमा बाँकी', hi: '$n दिनों में देय', es: 'Vence en $n días', fr: 'Échéance dans $n jours', de: 'Fällig in $n Tagen', ja: '$n日後に期日', zh: '$n天后到期', it: 'Scade tra $n giorni');
  String get dueToday => _t('Due today', ne: 'आज तिर्नुपर्ने', hi: 'आज देय', es: 'Vence hoy', fr: 'Échéance aujourd\'hui', de: 'Heute fällig', ja: '本日期日', zh: '今日到期', it: 'Scade oggi');
  String get overdue => _t('Overdue', ne: 'म्याद नाघेको', hi: 'अतिदेय', es: 'Vencido', fr: 'En retard', de: 'Überfällig', ja: '期限超過', zh: '已逾期', it: 'Scaduto');
  String accountsCount(int n) => _t('$n accounts', ne: '$n खाताहरू', hi: '$n खाते', es: '$n cuentas', fr: '$n comptes', de: '$n Konten', ja: '$n件の口座', zh: '$n个账户', it: '$n conti');
  String percentLiquid(int pct) => _t('$pct% liquid', ne: '$pct% तरल', hi: '$pct% तरल', es: '$pct% líquido', fr: '$pct% liquide', de: '$pct% liquide', ja: '$pct% 流動性', zh: '$pct% 流动资金', it: '$pct% liquido');
  String get quickActions => _t('Quick Actions', ne: 'द्रुत कार्यहरू', hi: 'त्वरित क्रियाएँ', es: 'Acciones Rápidas', fr: 'Actions Rapides', de: 'Schnellaktionen', ja: 'クイック操作', zh: '快捷操作', it: 'Azioni rapide');
  String get financialAi => _t('Financial AI', ne: 'वित्तीय एआई', hi: 'वित्तीय एआई', es: 'IA Financiera', fr: 'IA Financière', de: 'Finanz-KI', ja: 'AIアシスタント', zh: 'AI 财务顾问', it: 'IA Finanziaria');
}

extension AppStringsExtension on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
