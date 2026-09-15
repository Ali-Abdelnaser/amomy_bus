import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_scaffold.dart';

/// In-app native Privacy Policy screen grounded in authoritative AMOMY behavior.
///
/// NOTE: Content reflects actual product operations and is suitable for final legal review.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return AppScaffold(
      appBar: AppAppBar(
        title: l10n.privacyPolicy,
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAr ? 'سياسة خصوصية تطبيق عمومي باص' : 'AMOMY Bus Privacy Policy',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapH6,
              Text(
                isAr ? 'آخر تحديث: سبتمبر ٢٠٢٦' : 'Last Updated: September 2026',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapH20,

              _PolicySection(
                title: isAr ? '١. المعلومات التي تقدمها لنا' : '1. Information You Provide',
                content: isAr
                    ? 'عند إنشاء حسابك أو استكماله، نقوم بجمع اسمك الكامل، وعنوان بريدك الإلكتروني، ورقم هاتفك، والنوع (ذكر/أنثى)، وتاريخ ميلادك، وصورة الملف الشخصي الاختيارية. تُستخدم هذه البيانات للتحقق من هوية الراكب وتنظيم المقاعد وضمان أمان الرحلات.'
                    : 'When you create or complete your profile, we collect your full name, email address, mobile phone number, gender, date of birth, and optional profile photo. This information is required for passenger identity verification, seat allocation, and transportation safety.',
              ),

              _PolicySection(
                title: isAr ? '٢. بيانات الحجوزات والتذاكر' : '2. Booking & Ticket Information',
                content: isAr
                    ? 'نقوم بتسجيل الرحلة المحددة، والمقعد المحجوز، ومحطة الركوب، ومحطة الوصول، وحالة الحجز. كما يتم إصدار رمز QR ورقم تعريف رقمي خاص بكل تذكرة لإتمام عملية الصعود والتحقق بواسطة مشرفي الأتوبيس.'
                    : 'We record your selected trip, reserved seat number, boarding stop, destination stop, and booking status. Each confirmed booking generates a digital QR code and boarding identifier for passenger check-in by vehicle staff.',
              ),

              _PolicySection(
                title: isAr ? '٣. محفظة النقاط وإيصالات الشحن' : '3. Points Wallet & Top-Up Proofs',
                content: isAr
                    ? 'تعتمد المعاملات على محفظة النقاط (١ نقطة = ١ جنيه مصري). عند تقديم طلب شحن رصيد، نقوم بمعالجة رقم هاتف المُحوِّل، والرقم المرجعي للتحويل، وتاريخ التحويل، وصورة إيصال التحويل (سكرين شوت) للتحقق المالي من قبل الإدارة.'
                    : 'AMOMY operates a Points wallet (1 Point = 1 EGP). When requesting a wallet top-up, we process your sender phone number, transfer reference code, timestamp, and uploaded payment proof screenshot to verify transaction validity.',
              ),

              _PolicySection(
                title: isAr ? '٤. تتبع الأتوبيسات والموقع الجغرافي' : '4. Bus Tracking & Location Clarification',
                content: isAr
                    ? 'نظام التتبع المباشر المعروض في التطبيق يعتمد كلياً على أجهزة التتبع (GPS) المثبتة في أتوبيسات عمومي وخوادمنا التشغيلية، ولا يقوم التطبيق بتتبع موقع الراكب باستمرار في الخلفية. يتم استخدام موقع جهازك فقط عند فتح الخريطة لتحديد أقرب محطة إليك عند منح الإذن بذلك.'
                    : 'Live bus tracking shown in the passenger app originates from AMOMY onboard hardware and backend telemetry, NOT from continuous background tracking of your phone. Device location is only requested while using the map to highlight your proximity to nearby bus stops.',
              ),

              _PolicySection(
                title: isAr ? '٥. الإشعارات وبيانات الجهاز' : '5. Push Notifications & Device Tokens',
                content: isAr
                    ? 'نقوم بتسجيل رمز إشعار الجهاز (FCM Token) لنرسل لك تحديثات فورية حول حالة حجزك، وتنبيهات اقتراب الأتوبيس من محطتك، والتحديثات التشغيلية. يمكنك التحكم في تفضيلات هذه التنبيهات من قسم الإشعارات داخل التطبيق.'
                    : 'We register your device push notification token (FCM) to deliver operational trip alerts, bus approach notifications, and account updates. You can manage notification categories anytime in Notification Settings.',
              ),

              _PolicySection(
                title: isAr ? '٦. البنية التحتية والشركاء المعتمدون' : '6. Third-Party Infrastructure',
                content: isAr
                    ? 'يعتمد التطبيق على خدمات موثوقة لحفظ وتشغيل البيانات:\n• Supabase: للمصادقة وتخزين البيانات وقواعد البيانات الآمنة.\n• Firebase Cloud Messaging: لإرسال الإشعارات المباشرة.\n• Google Maps: لعرض الخرائط وتحديد مسارات الخطوط.\n• Google Sign-In: للمصادقة السريعة عند اختيارها من قِبل المستخدم.'
                    : 'AMOMY uses established enterprise cloud services to securely handle data:\n• Supabase: user authentication, relational database, and secure file storage.\n• Firebase Cloud Messaging: instant trip and operational push alerts.\n• Google Maps Platform: stop locations and route line visualizations.\n• Google Sign-In: optional streamlined account authentication.',
              ),

              _PolicySection(
                title: isAr ? '٧. أمان البيانات وحقوق المستخدم' : '7. Data Security & Your Rights',
                content: isAr
                    ? 'نحن نطبق معايير أمان صارمة وتشفير كامل لحماية بياناتك من الوصول غير المصرح به. يحق لك في أي وقت تعديل بياناتك الشخصية من خلال شاشة "المعلومات الشخصية" أو طلب حذف حسابك وبياناتك بالتواصل مع مركز الدعم.'
                    : 'We enforce strict Row Level Security (RLS) and encrypted transmissions to protect user data against unauthorized access. You retain the right to edit your personal profile at any time or request account deletion via the Support Center.',
              ),

              _PolicySection(
                title: isAr ? '٨. تحديثات السياسة' : '8. Policy Updates',
                content: isAr
                    ? 'قد نقوم بتحديث هذه السياسة من حين لآخر لمواكبة التحسينات التشغيلية والميزات الجديدة. سيتم إشعار الركاب بأي تغييرات جوهرية عبر التطبيق.'
                    : 'We may periodically update this policy to reflect operational improvements or regulatory requirements. Material changes will be communicated via in-app announcements.',
              ),
              AppSpacing.gapH24,
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({
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
