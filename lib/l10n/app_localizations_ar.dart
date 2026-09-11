// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'عمومي باص';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get errorOccurred => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get noData => 'لا توجد بيانات متاحة';

  @override
  String get loginTitle => 'مرحباً بعودتك';

  @override
  String get loginSubtitle => 'سجل الدخول للوصول إلى رحلاتك وتذاكرك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get orDivider => 'أو';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get registerNow => 'أنشئ حساباً الآن';

  @override
  String get registerTitle => 'إنشاء حساب جديد';

  @override
  String get registerSubtitle => 'انضم إلى عمومي للتنقل بسهولة وراحة';

  @override
  String get fullName => 'الاسم بالكامل';

  @override
  String get fullNameHint => 'مثال: أحمد محمد';

  @override
  String get phone => 'رقم الهاتف المحمول';

  @override
  String get phoneHint => '01012345678';

  @override
  String get gender => 'النوع';

  @override
  String get selectGender => 'اختر النوع';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get selectDateOfBirth => 'اختر تاريخ الميلاد';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordHint => 'أعد إدخال كلمة المرور';

  @override
  String get createAccount => 'إنشاء الحساب';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get signInNow => 'تسجيل الدخول';

  @override
  String get verifyEmailTitle => 'تأكيد بريدك الإلكتروني';

  @override
  String get verifyEmailSubtitle => 'أرسلنا رمز تأكيد مكون من 6 أرقام إلى';

  @override
  String get enterCode => 'أدخل الرمز لتفعيل حسابك';

  @override
  String get verifyButton => 'تأكيد الرمز';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String resendIn(int seconds) {
    return 'إعادة الإرسال خلال $seconds ثانية';
  }

  @override
  String get changeEmail => 'تغيير البريد / رجوع';

  @override
  String get completeProfileTitle => 'استكمال البيانات';

  @override
  String get completeProfileSubtitle =>
      'يرجى استكمال البيانات المطلوبة لإنهاء تسجيل حسابك';

  @override
  String get saveAndContinue => 'حفظ ومتابعة';

  @override
  String get forgotPasswordTitle => 'استعادة كلمة المرور';

  @override
  String get forgotPasswordSubtitle =>
      'أدخل بريدك الإلكتروني المسجل وسنرسل لك تعليمات استعادة كلمة المرور';

  @override
  String get sendResetInstructions => 'إرسال رابط الاستعادة';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get resetPasswordTitle => 'تعيين كلمة مرور جديدة';

  @override
  String get resetPasswordSubtitle =>
      'اختر كلمة مرور قوية مكونة من 8 أحرف على الأقل';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get passwordUpdatedSuccess =>
      'تم تحديث كلمة المرور بنجاح. يرجى تسجيل الدخول.';

  @override
  String get resetEmailSentSuccess =>
      'تم إرسال تعليمات الاستعادة. يرجى تفقد بريدك الإلكتروني.';

  @override
  String get homePlaceholderTitle => 'الصفحة الرئيسية للراكب';

  @override
  String get authenticatedAs => 'مسجل الدخول باسم';

  @override
  String get activeRoles => 'الأدوار الممنوحة';

  @override
  String get cashPoints => 'نقاط كاش';

  @override
  String get subscriptionPoints => 'نقاط اشتراك';

  @override
  String get totalBalance => 'إجمالي الرصيد';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get validationRequired => 'هذا الحقل مطلوب';

  @override
  String get validationEmailInvalid => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get validationPhoneInvalid =>
      'يرجى إدخال رقم هاتف مصري صحيح (01xxxxxxxxx)';

  @override
  String get validationPasswordLength =>
      'يجب أن تكون كلمة المرور 8 أحرف على الأقل';

  @override
  String get validationPasswordComplexity =>
      'يجب أن تحتوي كلمة المرور على حرف واحد ورقم واحد على الأقل';

  @override
  String get validationPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get validationOtpInvalid =>
      'يرجى إدخال رمز تأكيد صحيح مكون من 6 أرقام';

  @override
  String get skip => 'تخطي';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get languageSwitchLabel => 'EN';

  @override
  String get onboardingBookingTitle => 'احجز رحلتك بسهولة';

  @override
  String get onboardingBookingSubtitle =>
      'اختر معاد الرحلة والمقعد المناسب ليك في ثواني.';

  @override
  String get onboardingTrackingTitle => 'تابع رحلتك لحظة بلحظة';

  @override
  String get onboardingTrackingSubtitle =>
      'اعرف موقع الباص وموعد وصوله وخليك دايمًا على استعداد.';

  @override
  String get onboardingBoardingTitle => 'اركب بسرعة وأمان';

  @override
  String get onboardingBoardingSubtitle =>
      'استخدم الـ QR أو كارتك للصعود بسهولة وتأكيد حضورك.';

  @override
  String get completeProfileReminderTitle => 'أكمل بيانات حسابك';

  @override
  String get completeProfileReminderSubtitle =>
      'أكمل ملفك الشخصي للاستفادة من جميع خدمات AMOMY.';

  @override
  String get completeNow => 'أكمل الآن';

  @override
  String get bookingGuardTitle => 'أكمل بيانات حسابك أولًا';

  @override
  String get bookingGuardSubtitle =>
      'نحتاج رقم الهاتف والنوع وتاريخ الميلاد قبل حجز رحلتك.';

  @override
  String get completeProfileCta => 'إكمال البيانات';

  @override
  String get dismiss => 'إغلاق';
}
