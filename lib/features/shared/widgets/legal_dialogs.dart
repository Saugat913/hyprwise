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
  final isNe = tr.isNepali;

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
                  isNe
                      ? '१. स्थानीय-पहिलो गोपनीयता\nहाइपरवाइज (Hyprwise) स्थानीय-पहिलो (Local-first) वास्तुकलामा आधारित छ। तपाईंका खाता, कारोबार, कामको सिफ्ट र वित्तीय योजनाहरू तपाईंको आफ्नै यन्त्रमै सुरक्षित इन्क्रिप्टेड SQLite डाटाबेसमा रहन्छन्।\n\n२. क्लाउड ब्याकअप र सिंक\nयदि तपाईंले गुगल ड्राइभ वा हाइपरवाइज क्लाउड सिंक सक्षम गर्नुभयो भने, तपाईंको डाटा सुरक्षित इन्क्रिप्सनमार्फत प्रसारण हुन्छ र केवल तपाईंका अधिकृत यन्त्रहरूबीच सिंक गर्न प्रयोग गरिन्छ।\n\n३. कुनै विज्ञापन वा डाटा बिक्री छैन\nहामी तपाईंको वित्तीय रेकर्ड, पहिचान वा प्रयोग विवरण कुनै पनि विज्ञापनदाता वा तेस्रो पक्षलाई बेच्दैनौं।\n\n४. जेमिनी एआई सहायक\nएआई वित्तीय सहायकसँग गरिने कुराकानीहरू व्यक्तिगत विवरणहरू हटाई Google Gemini SDK मार्फत सुरक्षित रूपमा विश्लेषण गरिन्छ।\n\n५. डाटा नियन्त्रण\nतपाईंले जुनसुकै बेला सेटिङ्सबाट आफ्नो सम्पूर्ण डाटा JSON ढाँचामा निर्यात गर्न वा स्थायी रूपमा मेटाउन सक्नुहुन्छ।'
                      : '1. Local-First Privacy\nHyprwise is built on a local-first philosophy. Your financial logs, bank accounts, shifts, debts, and budgets reside securely on your device inside an encrypted SQLite database.\n\n2. Cloud Backup & Sync\nWhen Google Drive Backup or Hyprwise Cloud Sync is enabled, your data is transferred securely over TLS and used strictly to synchronize between your authorized devices.\n\n3. Zero Data Sales\nWe never sell, rent, or monetize your personal financial transactions, hourly wages, or logs to advertisers or data brokers.\n\n4. Gemini AI Assistance\nQueries to the financial assistant are processed securely via the Google Gemini API. Sensitive personal identifiers are omitted.\n\n5. Complete Data Ownership\nYou retain full ownership of your records. You may export a complete JSON archive or permanently erase all data at any time from Settings.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              isNe ? 'बुझें' : 'Got it',
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
  final isNe = tr.isNepali;

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
                  isNe
                      ? '१. वित्तीय वा कानुनी सल्लाह होइन\nहाइपरवाइज व्यक्तिगत वित्तीय ट्र्याकिङ, सिफ्ट र ऋण व्यवस्थापनका लागि मात्र हो। यो कुनै प्रमाणित वित्तीय वा कर परामर्शदाताको विकल्प होइन।\n\n२. खाता तथा सुरक्षा\nतपाईं आफ्नो यन्त्रको बायोमेट्रिक लक वा पिन कोड सुरक्षित राख्न आफैं जिम्मेवार हुनुहुन्छ।\n\n३. सदस्यता (RevenueCat)\nहाइपरवाइज प्रो सदस्यताहरू गुगल प्ले वा एप्पल एप स्टोरमार्फत व्यवस्थापन गरिन्छ। सदस्यता अवधि समाप्त हुनुभन्दा २४ घण्टा अगाडि रद्द नगरेसम्म यो स्वतः नवीकरण हुन्छ।\n\n४. डाटा स्वामित्व र ब्याकअप\nतपाईंले प्रविष्ट गर्नुभएको सबै डाटामा तपाईंको पूर्ण अधिकार छ। यन्त्र हराएको वा बिग्रिएको अवस्थामा डाटा सुरक्षित राख्न समय-समयमा ब्याकअप लिन सुझाव दिइन्छ।\n\n५. दायित्वको सीमा\nहाइपरवाइज "जस्तो छ त्यस्तै" आधारमा उपलब्ध गराइएको छ। म्यानुअल इनपुट वा विदेशी विनिमय दरको उतारचढावबाट हुने कुनै पनि नोक्सानीका लागि हामी जिम्मेवार हुनेछैनौं।'
                      : '1. Informational Purposes Only\nHyprwise provides personal finance, shift tracking, and budgeting organization. It does not provide certified financial, tax, or legal advice.\n\n2. Device Security & Access\nYou are responsible for safeguarding your device passcode, biometric authentication, and cloud account credentials.\n\n3. Subscriptions & Billing\nHyprwise Pro subscriptions are billed and managed securely via RevenueCat through Google Play or Apple App Store. Subscriptions renew automatically unless cancelled in your store account at least 24 hours prior to renewal.\n\n4. Data Responsibility\nWhile Hyprwise provides local database backups and Google Drive export options, you are encouraged to periodically export backups to prevent data loss in case of hardware replacement.\n\n5. Limitation of Liability\nHyprwise is provided "as is" without warranty of any kind. Developers are not liable for decisions made based on projections, forecasts, or exchange rate calculations.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              isNe ? 'बुझें' : 'Got it',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
