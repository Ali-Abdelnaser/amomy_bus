import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_scaffold.dart';

/// In-app native Terms & Conditions screen grounded in AMOMY business rules.
///
/// NOTE FOR LEGAL COUNSEL:
/// This document establishes current operational baselines. Final legal text
/// should receive formal regulatory and corporate counsel sign-off prior to public rollout.
class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return AppScaffold(
      appBar: AppAppBar(
        title: l10n.termsAndConditions,
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAr ? 'الشروط والأحكام لخدمة عمومي باص' : 'AMOMY Bus Terms & Conditions',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapH6,
              Text(
                isAr ? 'تاريخ السريان: سبتمبر ٢٠٢٦' : 'Effective Date: September 2026',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapH20,

              _TermsSection(
                title: isAr ? '١. وصف الخدمة' : '1. Service Description',
                content: isAr
                    ? 'يقدم تطبيق عمومي خدمة نقل ركاب مجدولة عبر خطوط ومسارات محددة. يتيح التطبيق استعراض الرحلات اليومية وحجز المقاعد المتاحة وإدارة التذاكر الرقمية والدفع عبر محفظة النقاط.'
                    : 'AMOMY Bus provides scheduled passenger transportation along designated routes in Egypt. The app enables passengers to view available schedules, reserve seats in real time, manage digital boarding passes, and pay using Points.',
              ),

              _TermsSection(
                title: isAr ? '٢. متطلبات الحساب وأهليته' : '2. Account Registration & Eligibility',
                content: isAr
                    ? 'يلتزم الراكب بتقديم معلومات صحيحة ودقيقة تشمل الاسم الكامل، ورقم الهاتف، والنوع، وتاريخ الميلاد. يُشترط استكمال الملف الشخصي قبل حجز أي رحلة لضمان التحقق التشغيلي والتنظيم.'
                    : 'Passengers must provide accurate account information, including full legal name, active mobile number, gender, and date of birth. Profile completion is mandatory prior to confirming any trip reservation.',
              ),

              _TermsSection(
                title: isAr ? '٣. حجز المقاعد وتوافرها المباشر' : '3. Seat Reservations & Temporary Holds',
                content: isAr
                    ? 'يتم عرض المقاعد المتاحة في الوقت الفعلي. عند اختيار مقعد، يتم حجزه مؤقتاً لفترة محددة لإتاحة الفرصة لإتمام التأكيد. إذا انتهت فترة التثبيت المؤقت دون إتمام الحجز، يُتاح المقعد مجدداً للركاب الآخرين.'
                    : 'Seat availability is updated in real time. Selected seats are placed on temporary hold to allow confirmation. If the hold window expires before confirmation, seats are released back to the general pool.',
              ),

              _TermsSection(
                title: isAr ? '٤. محفظة النقاط والشحن والاسترداد' : '4. Points Wallet, Top-Ups & Refunds',
                content: isAr
                    ? 'تعتمد المعاملات المالية داخل التطبيق على محفظة النقاط، حيث تعادل كل نقطة واحدة جنيهاً مصرياً واحداً (١ نقطة = ١ جنيه). تتم عمليات الشحن عبر الطرق المعتمدة (فودافون كاش أو إنستاباي) وتخضع لمراجعة وتأكيد الإدارة. في حالة إلغاء الحجز وفقاً للقواعد التشغيلية، تُعاد التكلفة إلى رصيد محفظة النقاط الخاصة بالراكب.'
                    : 'Fares are charged in Points, where 1 Point = 1 EGP for accounting. Wallet top-ups via supported gateways (e.g. Vodafone Cash, InstaPay) are credited upon administrative verification of payment proofs. Eligible cancellations are refunded directly as Points to your wallet balance.',
              ),

              _TermsSection(
                title: isAr ? '٥. التذاكر الرقمية والصعود (QR / NFC)' : '5. Digital Boarding Passes & Check-In',
                content: isAr
                    ? 'يُصدر التطبيق تذكرة رقمية برمز QR لكل حجز مؤكد. يجب على الراكب إبراز رمز QR أو استخدام وسيلة التحقق المعتمدة (QR/NFC) عند الصعود للمشرف أو السائق لإثبات صحة الحجز.'
                    : 'A digital boarding ticket with a scannable QR code is generated for each booking. Passengers must present their QR code or designated identifier to vehicle staff during boarding for attendance validation.',
              ),

              _TermsSection(
                title: isAr ? '٦. تتبع الأتوبيس والالتزام بالمواعيد' : '6. Bus Tracking & Schedule Availability',
                content: isAr
                    ? 'تتبع الأتوبيس متاح فقط خلال أوقات تشغيل الرحلات المدعومة. على الركاب التواجد في محطة الركوب المحددة قبل موعد وصول الأتوبيس المتوقع بعدة دقائق لتفادي فوات موعد الرحلة.'
                    : 'Live bus tracking is provided during active service periods of supported trips. Passengers are advised to arrive at their designated boarding stop a few minutes prior to the scheduled arrival time.',
              ),

              _TermsSection(
                title: isAr ? '٧. سلوك الركاب وقواعد السلامة' : '7. Passenger Conduct & Safety',
                content: isAr
                    ? 'يلتزم الركاب بالحفاظ على النظام والسلامة العامة داخل الحافلات، والجلوس في المقعد المحجوز، واتباع توجيهات طاقم التشغيل. يحق لإدارة عمومي تعليق خدمة أي راكب يخالف قواعد السلامة.'
                    : 'Passengers must adhere to transportation safety standards, occupy their allocated seats, and follow staff instructions. AMOMY reserves the right to suspend accounts that violate passenger safety or conduct guidelines.',
              ),

              _TermsSection(
                title: isAr ? '٨. الأعطال والظروف التشغيلية الطارئة' : '8. Operational Disruptions & Changes',
                content: isAr
                    ? 'في حالات الأعطال الفنية أو الأحوال الجوية أو الظروف المرورية الطارئة، تبذل إدارة عمومي أقصى جهد لتوفير حافلات بديلة أو إعادة جدولة الرحلات أو استرداد نقاط الحجز للركاب المتأثرين وفق الإجراءات المتبعة.'
                    : 'In the event of unforeseen mechanical issues, adverse weather, or severe traffic disruptions, AMOMY operations will endeavor to provide replacement transport, reschedule trips, or refund fare points according to standard operating procedures.',
              ),

              _TermsSection(
                title: isAr ? '٩. التعديلات والتواصل' : '9. Modifications & Support Inquiries',
                content: isAr
                    ? 'تحتفظ إدارة عمومي بالحق في تعديل هذه الشروط عند الضرورة التشغيلية. لأي استفسارات أو شكاوى بخصوص الشروط أو الحجوزات، يرجى التواصل عبر مركز الدعم المتاح داخل التطبيق.'
                    : 'AMOMY reserves the right to update these terms to reflect operational updates. For inquiries or questions regarding these terms, please contact our Support Center within the app.',
              ),
              AppSpacing.gapH24,
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapH8,
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
