import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/l10n/app_strings.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_button.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// Shows the app Privacy Policy in an accessible modal dialog.
void showAppPrivacyPolicyDialog(BuildContext context) {
  final tr = context.strings;
  final theme = Theme.of(context);

  final content = tr.t(
    '1. Local-First Privacy\nHyprwise is built on a local-first philosophy. Your financial logs, bank accounts, shifts, debts, and budgets reside securely on your device inside an encrypted SQLite database.\n\n2. Cloud Backup & Sync\nWhen Hyprwise Cloud Sync is enabled, your data is transferred securely over TLS and used strictly to synchronize between your authorized devices.\n\n3. Zero Data Sales\nWe never sell, rent, or monetize your personal financial transactions, hourly wages, or logs to advertisers or data brokers.\n\n4. Gemini AI Assistance\nQueries to the financial assistant are processed securely via the Google Gemini API. Sensitive personal identifiers are omitted.\n\n5. Complete Data Ownership\nYou retain full ownership of your records. You may export a complete JSON archive or permanently erase all data at any time from Settings.',
    ne: '१. स्थानीय-पहिलो गोपनीयता\nहाइपरवाइज स्थानीय-पहिलो वास्तुकलामा आधारित छ। तपाईंका खाता, कारोबार, कामको सिफ्ट र वित्तीय योजनाहरू तपाईंको आफ्नै यन्त्रमै सुरक्षित इन्क्रिप्टेड SQLite डाटाबेसमा रहन्छन्।\n\n२. क्लाउड ब्याकअप र सिंक\nहाइपरवाइज क्लाउड सिंक सक्षम गर्दा, तपाईंको डाटा सुरक्षित इन्क्रिप्सनमार्फत प्रसारण हुन्छ र केवल तपाईंका यन्त्रहरूबीच सिंक गर्न प्रयोग गरिन्छ।\n\n३. कुनै विज्ञापन वा डाटा बिक्री छैन\nहामी तपाईंको वित्तीय रेकर्ड वा प्रयोग विवरण कुनै पनि विज्ञापनदाता वा तेस्रो पक्षलाई बेच्दैनौं।\n\n४. जेमिनी एआई सहायक\nवित्तीय सहायकसँग गरिने कुराकानीहरू Google Gemini API मार्फत सुरक्षित रूपमा विश्लेषण गरिन्छ।\n\n५. डाटा नियन्त्रण\nतपाईंले जुनसुकै बेला सेटिङ्सबाट आफ्नो सम्पूर्ण डाटा JSON ढाँचामा निर्यात गर्न वा स्थायी रूपमा मेटाउन सक्नुहुन्छ।',
    hi: '१. स्थानीय-प्रथम गोपनीयता\nहाइपरवाइज स्थानीय-प्रथम दर्शन पर निर्मित है। आपके वित्तीय लेनदेन, खाते, पारियां (शिफ्ट) और ऋण आपके फोन में एन्क्रिप्टेड SQLite डेटाबेस में सुरक्षित रहते हैं।\n\n२. क्लाउड बैकअप और सिंक\nहाइपरवाइज क्लाउड सिंक के माध्यम से आपका डेटा पूरी तरह एन्क्रिप्टेड रूप में केवल आपके अधिकृत उपकरणों के बीच सिंक होता है।\n\n३. शून्य डेटा मुद्रीकरण\nहम आपके वित्तीय रिकॉर्ड या व्यक्तिगत डेटा को किसी भी विज्ञापनदाता या तीसरे पक्ष को कभी नहीं बेचते हैं।\n\n४. जेमिनी एआई सहायक\nएआई वित्तीय सहायक के प्रश्न Google Gemini API के माध्यम से सुरक्षित रूप से प्रोसेस किए जाते हैं।\n\n५. पूर्ण डेटा स्वामित्व\nआप अपने डेटा के पूर्ण मालिक हैं। आप कभी भी सेटिंग्स से पूरा डेटा निर्यात या स्थायी रूप से हटा सकते हैं।',
    es: '1. Privacidad Local Primero\nHyprwise está diseñado con filosofía local primero. Tus registros, cuentas, turnos y deudas se almacenan de forma segura y encriptada en tu dispositivo.\n\n2. Copia y Sincronización en la Nube\nCon Hyprwise Cloud Sync, tus datos se transmiten de forma segura por TLS exclusivamente entre tus dispositivos autorizados.\n\n3. Cero Venta de Datos\nNunca vendemos ni monetizamos tus transacciones financieras ni salarios a terceros o anunciantes.\n\n4. Asistente Gemini AI\nLas consultas al asistente se procesan de forma segura mediante la API de Google Gemini sin exponer identificadores sensibles.\n\n5. Propiedad Total de Datos\nConservas la propiedad total de tus registros y puedes exportarlos o eliminarlos en cualquier momento desde Ajustes.',
    fr: '1. Confidentialité locale d\'abord\nHyprwise repose sur une architecture locale sécurisée. Vos comptes, transactions et quarts de travail restent cryptés sur votre appareil.\n\n2. Sauvegarde et Synchronisation Cloud\nAvec Hyprwise Cloud Sync, vos données sont synchronisées de manière chiffrée uniquement entre vos appareils autorisés.\n\n3. Aucune vente de données\nNous ne vendons ni ne louons jamais vos données financières à des annonceurs.\n\n4. Assistant IA Gemini\nLes requêtes sont traitées de manière sécurisée via l\'API Google Gemini sans identifiants personnels sensibles.\n\n5. Propriété complète des données\nVous pouvez exporter ou supprimer vos données à tout moment depuis les Paramètres.',
    de: '1. Datenschutz nach dem Local-First-Prinzip\nHyprwise speichert alle Konten, Schichten und Transaktionen verschlüsselt auf Ihrem Gerät.\n\n2. Cloud-Synchronisierung\nHyprwise Cloud Sync überträgt Ihre Daten verschlüsselt nur zwischen Ihren autorisierten Geräten.\n\n3. Kein Datenverkauf\nWir verkaufen oder vermieten Ihre Finanzdaten niemals an Werbetreibende.\n\n4. Gemini AI-Assistent\nAbfragen werden sicher über die Google Gemini API verarbeitet.\n\n5. Volle Datenkontrolle\nSie können Ihre Daten jederzeit exportieren oder vollständig löschen.',
    ja: '1. ローカルファーストのプライバシー\nHyprwiseは暗号化された端末内データベースで動作し、財務記録やシフト履歴は外部に無断共有されません。\n\n2. クラウド同期\nHyprwise Cloud Syncを有効化した場合のみ、TLS暗号化を介して安全にご自身の端末間で同期されます。\n\n3. データの販売・広告利用ゼロ\nユーザーの給与記録や支出履歴を広告主や第三者に販売することは一切ありません。\n\n4. Gemini AI アシスタント\nAIアシスタント機能はGoogle Gemini APIを介して安全に処理されます。\n\n5. 完全なデータ所有権\n設定からいつでもJSON形式で全データをエクスポートまたは完全消去できます。',
    zh: '1. 本地优先与隐私安全\nHyprwise 采用本地优先架构，所有账户、班次与交易记录均加密保存在您的设备本地。\n\n2. 云端安全同步\n启用 Hyprwise 云端同步后，数据将通过安全加密通道在您的授权设备之间同步。\n\n3. 绝不出售用户数据\n我们绝不会将您的财务数据、时薪或账单信息出售给广告商或第三方。\n\n4. Gemini AI 智能助手\nAI 助理查询通过 Google Gemini API 安全进行，不泄露个人敏感标识。\n\n5. 完整数据掌控权\n您拥有数据的完全所有权，可随时在设置中导出完整 JSON 备份或彻底删除数据。',
    it: '1. Privacy Locale\nHyprwise protegge i tuoi dati finanziari, turni e conti salvandoli sul tuo dispositivo in un database SQLite crittografato.\n\n2. Sincronizzazione Cloud\nHyprwise Cloud Sync sincronizza i tuoi dati in modo sicuro e protetto esclusivamente tra i tuoi dispositivi autorizzati.\n\n3. Nessuna vendita di dati\nNon vendiamo né monetizziamo mai le tue transazioni o buste paga a inserzionisti.\n\n4. Assistente IA Gemini\nLe richieste sono elaborate in sicurezza tramite le API Google Gemini.\n\n5. Pieno controllo dei dati\nPuoi esportare o cancellare definitivamente i tuoi dati in qualsiasi momento dalle Impostazioni.',
  );

  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xxl),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(HugeIcons.strokeRoundedShield02, size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    tr.privacyPolicy,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              tr.t('Got it', ne: 'बुझें', hi: 'समझ गया', es: 'Entendido', fr: 'Compris', de: 'Verstanden', ja: '了解', zh: '知道了', it: 'Ho capito'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shows the app Terms of Service in an accessible modal dialog.
void showAppTermsDialog(BuildContext context) {
  final tr = context.strings;
  final theme = Theme.of(context);

  final content = tr.t(
    '1. Informational Purposes Only\nHyprwise provides personal finance, shift tracking, and budgeting organization. It does not provide certified financial, tax, or legal advice.\n\n2. Device Security & Access\nYou are responsible for safeguarding your device passcode, biometric authentication, and cloud account credentials.\n\n3. Subscriptions & Billing\nHyprwise Pro subscriptions are billed and managed securely via RevenueCat through Google Play or Apple App Store. Subscriptions renew automatically unless cancelled in your store account at least 24 hours prior to renewal.\n\n4. Data Responsibility\nWhile Hyprwise provides local database backups and export options, you are encouraged to periodically export backups to prevent data loss in case of hardware replacement.\n\n5. Limitation of Liability\nHyprwise is provided "as is" without warranty of any kind. Developers are not liable for decisions made based on projections, forecasts, or exchange rate calculations.',
    ne: '१. वित्तीय वा कानुनी सल्लाह होइन\nहाइपरवाइज व्यक्तिगत वित्तीय ट्र्याकिङ, सिफ्ट र ऋण व्यवस्थापनका लागि मात्र हो। यो कुनै प्रमाणित वित्तीय वा कर परामर्शदाताको विकल्प होइन।\n\n२. खाता तथा सुरक्षा\nतपाईं आफ्नो यन्त्रको बायोमेट्रिक लक वा पिन कोड सुरक्षित राख्न आफैं जिम्मेवार हुनुहुन्छ।\n\n३. सदस्यता (RevenueCat)\nहाइपरवाइज प्रो सदस्यताहरू गुगल प्ले वा एप्पल एप स्टोरमार्फत व्यवस्थापन गरिन्छ।\n\n४. डाटा स्वामित्व र ब्याकअप\nतपाईंले प्रविष्ट गर्नुभएको सबै डाटामा तपाईंको पूर्ण अधिकार छ। यन्त्र बिग्रिएमा डाटा सुरक्षित राख्न समय-समयमा ब्याकअप लिन सुझाव दिइन्छ।\n\n५. दायित्वको सीमा\nहाइपरवाइज "जस्तो छ त्यस्तै" आधारमा उपलब्ध गराइएको छ। विदेशी विनिमय दरको उतारचढाव वा अनुमानबाट हुने कुनै नोक्सानीका लागि हामी जिम्मेवार हुनेछैनौं।',
    hi: '१. केवल सूचनात्मक उद्देश्य\nहाइपरवाइज व्यक्तिगत वित्त, कार्य पारी (शिफ्ट) और बजट प्रबंधन के लिए है। यह किसी प्रमाणित वित्तीय या कर सलाहकार का विकल्प नहीं है।\n\n२. उपकरण सुरक्षा\nआप अपने फोन के पिन कोड, बायोमेट्रिक सुरक्षा और क्रेडेंशियल्स की सुरक्षा के लिए स्वयं जिम्मेदार हैं।\n\n३. सदस्यता और बिलिंग\nहाइपरवाइज प्रो सदस्यता Google Play या Apple App Store के माध्यम से प्रबंधित की जाती है।\n\n४. बैकअप जिम्मेदारी\nडेटा सुरक्षित रखने के लिए समय-समय पर स्थानीय बैकअप निर्यात करने की सलाह दी जाती है।\n\n५. दायित्व की सीमा\nहाइपरवाइज बिना किसी वारंटी के उपलब्ध कराया गया है।',
    es: '1. Solo Fines Informativos\nHyprwise organiza finanzas personales y turnos de trabajo. No constituye asesoramiento financiero o legal certificado.\n\n2. Seguridad del Dispositivo\nEres responsable de proteger el acceso a tu dispositivo y credenciales.\n\n3. Suscripciones y Facturación\nLas suscripciones Hyprwise Pro se gestionan a través de Google Play o Apple App Store vía RevenueCat.\n\n4. Responsabilidad de Copias de Seguridad\nRecomendamos exportar copias de respaldo periódicamente para evitar pérdidas en caso de cambio de terminal.\n\n5. Limitación de Responsabilidad\nHyprwise se proporciona "tal cual" sin garantías explícitas.',
    fr: '1. À titre informatif uniquement\nHyprwise organise vos finances personnelles et quarts de travail. Il ne remplace pas un conseiller fiscal ou juridique.\n\n2. Sécurité de l\'appareil\nVous êtes responsable de la sécurité de votre appareil et de vos mots de passe.\n\n3. Abonnements\nHyprwise Pro est géré de manière sécurisée via RevenueCat sur Google Play ou Apple App Store.\n\n4. Sauvegardes\nNous vous encourageons à exporter régulièrement des sauvegardes locales.\n\n5. Limitation de responsabilité\nHyprwise est fourni « tel quel » sans garantie.',
    de: '1. Nur zu Informationszwecken\nHyprwise dient der Organisation Ihrer persönlichen Finanzen und Schichten. Keine Steuer- oder Rechtsberatung.\n\n2. Gerätesicherheit\nSie sind für den Schutz Ihrer Gerätezugangsdaten verantwortlich.\n\n3. Abonnements\nHyprwise Pro-Abonnements werden sicher über Google Play oder Apple App Store abgewickelt.\n\n4. Datensicherung\nRegelmäßige lokale Backups werden empfohlen.\n\n5. Haftungsbeschränkung\nHyprwise wird "wie besehen" bereitgestellt.',
    ja: '1. 情報提供のみを目的とします\nHyprwiseは個人の家計およびシフト管理ツールであり、公認の税務または法的助言を提供するものではありません。\n\n2. 端末と認証情報の管理\n端末のパスコードおよび生体認証の管理はユーザー自身の責任で行ってください。\n\n3. サブスクリプション管理\nHyprwise Proの定期購入はGoogle PlayまたはApple App Storeを通じて安全に管理されます。\n\n4. バックアップの推奨\n端末故障や機種変更に備え、定期的なバックアップエクスポートを推奨します。\n\n5. 免責事項\n本アプリは現状有姿で提供され、将来予測や為替計算に基づく損失について一切の責任を負いません。',
    zh: '1. 仅供信息参考\nHyprwise 为个人财务与排班记录工具，不构成认证财务、税务或法律建议。\n\n2. 设备安全与访问权限\n用户须自行妥善保管设备锁屏密码及账户凭据。\n\n3. 订阅与账单管理\nHyprwise Pro 订阅通过 Google Play 或 Apple App Store 安全结算与续订。\n\n4. 数据备份建议\n建议定期导出本地备份，以防设备损坏或更换时数据丢失。\n\n5. 免责声明\n本应用按“现状”提供，开发者对基于预测或汇率计算作出的决策不承担法律责任。',
    it: '1. Solo a scopo informativo\nHyprwise gestisce finanze e turni personali, senza sostituire consulenze legali o fiscali certificate.\n\n2. Sicurezza del dispositivo\nSei responsabile della custodia del codice di accesso e dei dati biometrici del tuo dispositivo.\n\n3. Abbonamenti\nGli abbonamenti Hyprwise Pro sono gestiti tramite RevenueCat su Google Play o App Store.\n\n4. Backup\nSi raccomanda di esportare periodicamente i dati per prevenire perdite accidentali.\n\n5. Limitazione di responsabilità\nHyprwise è fornito "così com\'è" senza garanzie.',
  );

  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xxl),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(HugeIcons.strokeRoundedNote01, size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    tr.termsOfService,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              tr.t('Got it', ne: 'बुझें', hi: 'समझ गया', es: 'Entendido', fr: 'Compris', de: 'Verstanden', ja: '了解', zh: '知道了', it: 'Ho capito'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
