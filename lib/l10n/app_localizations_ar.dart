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
  String get didntReceiveCode => 'لم تستلم الرمز؟';

  @override
  String get wrongEmailPrompt => 'البريد الإلكتروني غير صحيح؟';

  @override
  String get changeEmailAction => 'تغيير البريد';

  @override
  String get otpInvalid => 'رمز التحقق غير صحيح.';

  @override
  String get otpExpired => 'انتهت صلاحية هذا الرمز. يرجى طلب رمز جديد.';

  @override
  String get otpRateLimited => 'يرجى الانتظار قليلاً قبل طلب رمز جديد.';

  @override
  String get otpNetworkError =>
      'تعذر التحقق من الرمز. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get selectDateTitle => 'تحديد التاريخ';

  @override
  String get confirmDate => 'تأكيد التاريخ';

  @override
  String get dayColumnLabel => 'اليوم';

  @override
  String get monthColumnLabel => 'الشهر';

  @override
  String get yearColumnLabel => 'السنة';

  @override
  String get completeProfileTitle => 'استكمال البيانات';

  @override
  String get completeProfileSubtitle =>
      'يرجى استكمال البيانات المطلوبة لإنهاء تسجيل حسابك';

  @override
  String get saveAndContinue => 'حفظ ومتابعة';

  @override
  String get profileUpdateFailed => 'تعذر حفظ التعديلات. حاول مرة أخرى.';

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

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navMyTrips => 'رحلاتي';

  @override
  String get navWallet => 'المحفظة';

  @override
  String get navProfile => 'حسابي';

  @override
  String get greetingMorning => 'صباح الخير،';

  @override
  String get greetingAfternoon => 'مساء الخير،';

  @override
  String get greetingEvening => 'مساء الخير،';

  @override
  String get pointsBalance => 'رصيد النقاط';

  @override
  String get pointsUnit => 'نقطة';

  @override
  String get addPoints => 'شحن النقاط';

  @override
  String get walletDetails => 'التفاصيل';

  @override
  String get cashPointsPrefix => 'نقدية';

  @override
  String get subscriptionPointsPrefix => 'اشتراك';

  @override
  String get bookRideTitle => 'احجز رحلتك';

  @override
  String get bookRideSubtitle => 'اختار المعاد والمقعد المناسب ليك.';

  @override
  String get bookNow => 'احجز الآن';

  @override
  String get upcomingTrip => 'رحلتك القادمة';

  @override
  String get noUpcomingTrip => 'مفيش رحلة محجوزة حاليًا';

  @override
  String get bookTripCta => 'احجز رحلة';

  @override
  String get quickActions => 'خدمات سريعة';

  @override
  String get actionAddPoints => 'شحن نقاط';

  @override
  String get actionMyTrips => 'رحلاتي';

  @override
  String get actionSubscriptions => 'الاشتراكات';

  @override
  String get actionSupport => 'الدعم';

  @override
  String get support => 'الدعم';

  @override
  String get upcomingTab => 'القادمة';

  @override
  String get historyTab => 'السابقة';

  @override
  String get noTripsFound => 'لا توجد رحلات حتى الآن';

  @override
  String get noTripsSubtitle => 'عند حجز رحلة جديدة ستظهر بياناتها هنا مباشرة.';

  @override
  String get transactions => 'سجل المعاملات';

  @override
  String get noTransactions => 'لا توجد معاملات بعد';

  @override
  String get noTransactionsSubtitle => 'ستظهر تفاصيل ومعاملات نقاطك هنا.';

  @override
  String get personalInfo => 'البيانات الشخصية';

  @override
  String get language => 'اللغة';

  @override
  String get aboutAmomy => 'عن AMOMY';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get termsAndConditions => 'الشروط والأحكام';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get signOutConfirmMessage =>
      'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get featureUnderDevelopment => 'هذه الميزة قيد التطوير';

  @override
  String get bookingComingSoonDesc =>
      'حجز الرحلات واختيار المقاعد قيد التطوير وسيكون متاحًا قريبًا.';

  @override
  String get subscriptionsComingSoonDesc =>
      'باقات واشتراكات AMOMY ستكون متاحة قريبًا.';

  @override
  String get supportDialogTitle => 'خدمة عملاء AMOMY';

  @override
  String get supportDialogDesc =>
      'فريق الدعم متواجد على مدار الساعة لمساعدتك في رحلاتك وحسابك.';

  @override
  String get quickBooking => 'حجز سريع ومباشر';

  @override
  String get directionOutbound => 'ذهاب';

  @override
  String get directionReturn => 'عودة';

  @override
  String get selectDirection => 'اختر اتجاه الرحلة';

  @override
  String get selectDate => 'اختر تاريخ الرحلة';

  @override
  String get selectTime => 'اختر موعد الرحلة';

  @override
  String get selectSeat => 'اختر المقعد';

  @override
  String get reviewBooking => 'مراجعة تفاصيل الحجز';

  @override
  String get confirmBooking => 'تأكيد الحجز';

  @override
  String seatsAvailableCount(int count) {
    return '$count مقعد متاح';
  }

  @override
  String get seatStatusAvailable => 'متاح';

  @override
  String get seatStatusHeld => 'محجوز مؤقتًا';

  @override
  String get seatStatusBooked => 'محجوز';

  @override
  String get seatStatusSelected => 'مقعدك المختار';

  @override
  String get driverFront => 'المقدمة / السائق';

  @override
  String holdCountdown(String time) {
    return 'ينتهي حجز المقعد المؤقت خلال $time';
  }

  @override
  String get holdExpiredNotice =>
      'انتهت مدة الحجز المؤقت للمقعد. يُرجى اختياره مرة أخرى.';

  @override
  String get seatUnavailableNotice =>
      'هذا المقعد لم يعد متاحًا. يُرجى اختيار مقعد آخر.';

  @override
  String get insufficientPointsNotice =>
      'رصيد النقاط غير كافٍ. يُرجى شحن رصيدك للمتابعة.';

  @override
  String get bookingSuccessTitle => 'تم تأكيد الحجز بنجاح!';

  @override
  String get bookingSuccessSubtitle =>
      'تم حجز مقعدك بنجاح وجاهز لرحلتك القادمة.';

  @override
  String get qrTicketInstruction =>
      'قم بإبراز رمز الـ QR هذا للمسؤول أو الماسح الضوئي عند صعود الحافلة.';

  @override
  String get viewMyTrips => 'عرض رحلاتي';

  @override
  String get mitFadalaStopName => 'ميت فضالة';

  @override
  String departureBusAtFirstStop(Object stopName) {
    return 'موعد الباص في $stopName';
  }

  @override
  String get firstStopLabel => 'أول نقطة انطلاق';

  @override
  String get tripDetailsDirection => 'اتجاه الرحلة';

  @override
  String get tripDetailsDate => 'تاريخ الرحلة';

  @override
  String get tripDetailsTime => 'موعد التحرك';

  @override
  String get tripDetailsSeat => 'رقم المقعد';

  @override
  String get tripDetailsFare => 'تكلفة الرحلة';

  @override
  String get tripDetailsRoute => 'خط السير';

  @override
  String get tripStatusScheduled => 'مجدولة';

  @override
  String get tripStatusBoarding => 'صعود الركاب';

  @override
  String get tripStatusDeparted => 'انطلقت';

  @override
  String get tripStatusCompleted => 'مكتملة';

  @override
  String get tripStatusCancelled => 'ملغاة';

  @override
  String get bookingStatusConfirmed => 'مؤكد';

  @override
  String get bookingStatusCancelled => 'ملغي';

  @override
  String get pointsBalanceAvailable => 'النقاط المتاحة';

  @override
  String get completeProfileToBook =>
      'يُرجى إكمال بيانات ملفك الشخصي لتتمكن من حجز الرحلات.';

  @override
  String get topUpAmountTitle => 'المبلغ';

  @override
  String get topUpAmountHint => 'أدخل المبلغ بالجنيه المصري';

  @override
  String get topUpPointsRatio => '1 جنيه ≈ 1 نقطة';

  @override
  String get topUpSelectMethod => 'اختر طريقة الدفع';

  @override
  String get topUpInstructions => 'تعليمات التحويل';

  @override
  String get topUpRecipientAccount => 'رقم الحساب / المحفظة المستلمة';

  @override
  String get topUpCopyAccount => 'نسخ الرقم';

  @override
  String get topUpCopiedToast => 'تم نسخ الرقم إلى الحافظة';

  @override
  String get topUpTransactionReference => 'رقم العملية / مرجع التحويل';

  @override
  String get topUpTransactionReferenceHint =>
      'أدخل رقم العملية أو مرجع التحويل';

  @override
  String get topUpTransactionReferenceHelper =>
      'أدخل مرجع التحويل لمساعدتنا في تأكيد دفعك بسرعة.';

  @override
  String get topUpPaymentProof => 'صورة إيصال التحويل';

  @override
  String get topUpUploadScreenshot => 'إرفاق صورة الإيصال';

  @override
  String get topUpChangeScreenshot => 'تغيير الصورة';

  @override
  String get topUpReviewTitle => 'مراجعة طلب الشحن';

  @override
  String get topUpExpectedPoints => 'النقاط النقدية المتوقعة';

  @override
  String get topUpSubmitButton => 'إرسال طلب الشحن';

  @override
  String get topUpSubmitting => 'جارٍ الإرسال...';

  @override
  String get topUpPendingSuccessTitle => 'تم إرسال طلب الشحن';

  @override
  String get topUpPendingSuccessDesc =>
      'طلبك قيد المراجعة.\nسيتم إضافة النقاط إلى محفظتك بعد الموافقة.';

  @override
  String get topUpBackToWallet => 'العودة إلى المحفظة';

  @override
  String get topUpManualNotice =>
      'ملاحظة: يتم شحن النقاط بمراجعة يدوية وليس عبر بوابة دفع إلكترونية فورية.';

  @override
  String get topUpHistoryTitle => 'طلبات الشحن';

  @override
  String get topUpStatusPending => 'قيد المراجعة';

  @override
  String get topUpStatusApproved => 'تمت الموافقة';

  @override
  String get topUpStatusRejected => 'مرفوض';

  @override
  String get topUpRejectionReason => 'سبب الرفض';

  @override
  String get topUpEmptyHistory => 'لا توجد طلبات شحن سابقة.';

  @override
  String get topUpErrorInvalidAmount => 'يرجى إدخال مبلغ صحيح أكبر من الصفر.';

  @override
  String get topUpErrorSelectMethod => 'يرجى اختيار طريقة الدفع.';

  @override
  String get topUpErrorEnterReference =>
      'يرجى إدخال رقم العملية / مرجع التحويل.';

  @override
  String get topUpErrorAttachProof => 'يرجى إرفاق صورة إيصال التحويل.';

  @override
  String get topUpErrorDuplicateRef =>
      'يوجد طلب شحن نشط أو معتمد مسبقاً بنفس رقم العملية.';

  @override
  String get topUpErrorUploadFailed =>
      'فشل رفع صورة الإيصال. يرجى المحاولة مرة أخرى.';

  @override
  String get topUpErrorNotFound => 'لم يتم العثور على طلب الشحن.';

  @override
  String get topUpErrorAlreadyReviewed => 'تمت مراجعة هذا الطلب بالفعل.';

  @override
  String get continueAction => 'المتابعة';

  @override
  String get backAction => 'رجوع';

  @override
  String get announcements => 'الإعلانات';

  @override
  String get announcementBadge => 'تنبيه';

  @override
  String get offerBadge => 'عرض';

  @override
  String get viewTicket => 'عرض التذكرة';

  @override
  String get yourActivity => 'نشاطك';

  @override
  String get tripsThisMonth => 'رحلات هذا الشهر';

  @override
  String get completedTrips => 'رحلات مكتملة';

  @override
  String get pointsSpentThisMonth => 'نقاط مصروفة هذا الشهر';

  @override
  String get missedTrips => 'رحلات فائتة';

  @override
  String get noMissedTripsMessage => 'لا توجد رحلات فائتة هذا الشهر.';

  @override
  String get allTime => 'إجمالي';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get selectBoardingStop => 'اختر نقطة الركوب';

  @override
  String get boardingStop => 'نقطة الركوب';

  @override
  String get noStopsAvailable => 'لا توجد نقاط ركوب متاحة حالياً';

  @override
  String get chooseSeatAgain => 'اختيار مقعد مرة أخرى';

  @override
  String get holdExpiredMessage =>
      'انتهت مدة حجز المقعد. يرجى اختيار المقعد مرة أخرى.';

  @override
  String seatHeldFor(String time) {
    return 'المقعد محجوز لك لمدة $time';
  }

  @override
  String get bookingSummaryTitle => 'ملخص الحجز';

  @override
  String get totalFare => 'الإجمالي';

  @override
  String get availableBalanceLabel => 'الرصيد المتاح';

  @override
  String get afterBookingLabel => 'بعد الحجز';

  @override
  String notEnoughPointsDeficit(int deficit) {
    return 'رصيد النقاط غير كافٍ. تحتاج إلى $deficit نقطة إضافية لإتمام هذا الحجز.';
  }

  @override
  String get reviewTicketNotice => 'يمكنك عرض تذكرتك لاحقًا من رحلاتي.';

  @override
  String get fromStop => 'من';

  @override
  String get toStop => 'إلى';

  @override
  String get departureTimeTitle => 'ميعاد الرحلة';

  @override
  String get departureSelected => 'تم الاختيار';

  @override
  String get departureSelectedTrip => 'الرحلة المختارة';

  @override
  String get departureAvailable => 'متاح';

  @override
  String get departureFullyBooked => 'مكتمل';

  @override
  String get departureAvailableNow => 'متاح الآن';

  @override
  String get fewSeatsLeft => 'مقاعد محدودة';

  @override
  String get alreadyBookedTrip => 'لقد قمت بحجز هذه الرحلة بالفعل.';

  @override
  String seatNumberSelected(String seatNumber) {
    return 'تم اختيار مقعد $seatNumber';
  }

  @override
  String get noMoreAvailableTrips => 'انتهت رحلات اليوم';

  @override
  String get recentTransactions => 'آخر المعاملات';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get noTransactionsTitle => 'لا توجد معاملات بعد';

  @override
  String get cardTravelBalance => 'رصيد رحلاتك';

  @override
  String get amomyWallet => 'محفظة عمومي';

  @override
  String get txTypeTrip => 'رحلة';

  @override
  String get txTypeTopUp => 'شحن نقاط';

  @override
  String get txTypeRefund => 'استرداد حجز';

  @override
  String get txTypeBonus => 'مكافأة';

  @override
  String get txTypeGift => 'هدية';

  @override
  String get txTypeAdjustment => 'تعديل رصيد';

  @override
  String get ptsUnit => 'نقطة';

  @override
  String get howManyPointsToAdd => 'كم عدد النقاط التي ترغب في شحنها؟';

  @override
  String get minTopupNotice => 'الحد الأدنى للشحن هو 200 نقطة.';

  @override
  String get customAmount => 'مبلغ مخصص';

  @override
  String pointsEquivalentEgp(String points, String egp) {
    return '$points نقطة = $egp ج.م';
  }

  @override
  String get mobileCash => 'محفظة كاش (فودافون كاش / أورنج كاش)';

  @override
  String get transferAmount => 'مبلغ التحويل';

  @override
  String get transferTo => 'تحويل إلى';

  @override
  String get copyNumber => 'نسخ';

  @override
  String get numberCopied => 'تم نسخ الرقم إلى الحافظة';

  @override
  String get instructionStep1 =>
      '١. افتح تطبيق محفظتك الإلكترونية (أنا فودافون، أورنج كاش...).';

  @override
  String get instructionStep2 => '٢. قم بتحويل المبلغ المحدد أعلاه بدقة.';

  @override
  String get instructionStep3 =>
      '٣. احتفظ برسالة تأكيد التحويل أو لقطة شاشة للإيصال.';

  @override
  String get instructionStep4 =>
      '٤. عُد هنا وأرسل بيانات التحويل لتأكيد الشحن.';

  @override
  String get iveTransferredCta => 'لقد قمت بالتحويل';

  @override
  String get senderPhoneLabel => 'رقم الهاتف المُرسل منه';

  @override
  String get senderPhoneHint => '01XXXXXXXXX';

  @override
  String get senderPhoneInvalid =>
      'يرجى إدخال رقم محمول مصري صحيح (01XXXXXXXXX)';

  @override
  String get transferReferenceLabel => 'رقم العملية أو المرجع';

  @override
  String get transferReferenceOptional => 'اختياري إذا لم يتوفر برقم الإيصال';

  @override
  String get transferDateTimeLabel => 'تاريخ ووقت التحويل';

  @override
  String get paymentScreenshotLabel => 'صورة إيصال التحويل';

  @override
  String get tapToUploadScreenshot => 'اضغط لإرفاق لقطة شاشة للإيصال';

  @override
  String get screenshotAttached => 'تم إرفاق الإيصال بنجاح';

  @override
  String get submitDetailsAction => 'إرسال بيانات التحويل';

  @override
  String get paymentSubmittedTitle => 'تم إرسال بيانات الدفع';

  @override
  String get paymentUnderReviewSubtitle =>
      'طلب الشحن قيد المراجعة حالياً من قبل الإدارة.';

  @override
  String get statusPendingReview => 'قيد المراجعة';

  @override
  String get statusAwaitingPayment => 'بانتظار التحويل';

  @override
  String get statusApproved => 'تمت الموافقة';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get requestIdLabel => 'رقم الطلب';

  @override
  String get backToWalletCta => 'العودة للمحفظة';

  @override
  String get stepPoints => 'النقاط';

  @override
  String get stepPayment => 'طريقة الدفع';

  @override
  String get stepConfirm => 'التأكيد';

  @override
  String get vodafoneCash => 'فودافون كاش';

  @override
  String get instapay => 'إنستاباي';

  @override
  String get choosePaymentMethod => 'اختر طريقة الدفع';

  @override
  String get instapayAccount => 'حساب إنستاباي';

  @override
  String get txTypePointsAdjustment => 'تعديل نقاط';

  @override
  String get pendingPoints => 'نقاط قيد المراجعة';

  @override
  String get paymentCouldNotBeVerified => 'تعذر التحقق من الدفع';

  @override
  String get resubmit => 'إعادة التقديم';

  @override
  String get resubmitPaymentTitle => 'إعادة تقديم الدفع';

  @override
  String get resubmitForReview => 'إعادة التقديم للمراجعة';

  @override
  String get paymentResubmittedTitle => 'تمت إعادة تقديم الدفع';

  @override
  String get submittedOn => 'قُدم في';

  @override
  String get viewAllPendingTopUps => 'عرض جميع النقاط المعلقة';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get allNotifications => 'كل الإشعارات';

  @override
  String get serviceUpdatesTitle => 'تحديثات الخدمة والإشعارات العامة';

  @override
  String get serviceUpdatesDesc => 'إعلانات وتحديثات مهمة تخص خدمة عمومي.';

  @override
  String get bookingUpdatesTitle => 'تحديثات الحجز';

  @override
  String get bookingUpdatesDesc => 'تأكيد الحجز والإلغاء وتغيير المقعد.';

  @override
  String get walletUpdatesTitle => 'المحفظة والشحن';

  @override
  String get walletUpdatesDesc => 'حالة طلبات الشحن وحركات النقاط.';

  @override
  String get tripUpdatesTitle => 'الرحلات وتتبع الأتوبيس';

  @override
  String get tripUpdatesDesc =>
      'تحديثات الرحلة وتنبيه اقتراب الأتوبيس من محطتك.';

  @override
  String get notificationsDisabledOs => 'الإشعارات متوقفة من إعدادات الجهاز.';

  @override
  String get openDeviceSettings => 'فتح إعدادات الجهاز';

  @override
  String get todayHeader => 'اليوم';

  @override
  String get earlierHeader => 'السابق';

  @override
  String get markAllAsRead => 'تحديد الكل كمقروء';

  @override
  String get noNotifications => 'لا توجد إشعارات حالياً';

  @override
  String get profileAccountSection => 'الحساب';

  @override
  String get profilePreferencesSection => 'التفضيلات';

  @override
  String get profileHelpSupportSection => 'المساعدة والدعم';

  @override
  String get profileAboutLegalSection => 'حول التطبيق والقانونية';

  @override
  String get supportCenter => 'مركز الدعم';

  @override
  String get aboutAmomyApp => 'عن تطبيق عمومي';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromPhotos => 'اختيار من الصور';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get avatarUpdatedSuccess => 'تم تحديث الصورة الشخصية بنجاح';

  @override
  String get avatarRemovedSuccess => 'تم إزالة الصورة الشخصية بنجاح';

  @override
  String get avatarUpdateFailed => 'فشل تحديث الصورة الشخصية';

  @override
  String get avatarRemoveFailed => 'فشل إزالة الصورة الشخصية';

  @override
  String get supportHeroTitle => 'كيف يمكننا مساعدتك؟';

  @override
  String get supportHeroSubtitle =>
      'فريقنا متواجد لمساعدتك في كل ما يخص رحلاتك وحسابك.';

  @override
  String get emailSupport => 'البريد الإلكتروني للدعم';

  @override
  String get callUs => 'اتصل بنا';

  @override
  String get whatsApp => 'واتساب';

  @override
  String get workingHours => 'ساعات العمل';

  @override
  String get frequentlyAskedQuestions => 'الأسئلة الشائعة';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get faqQuestion1 => 'كيف يمكنني حجز مقعد في الأتوبيس؟';

  @override
  String get faqAnswer1 =>
      'اختر محطة الركوب ومحطة النزول، ثم حدد موعد الرحلة واختر مقعدك المفضل مباشرة من خريطة الأتوبيس.';

  @override
  String get faqQuestion2 => 'كيف يعمل رصيد النقاط في المحفظة؟';

  @override
  String get faqAnswer2 =>
      'تعتمد المحفظة على النقاط بحيث ١ نقطة = ١ جنيه مصري. يمكنك شحن رصيدك بسهولة عبر فودافون كاش أو إنستاباي.';

  @override
  String get faqQuestion3 => 'كيف أصعد إلى الأتوبيس؟';

  @override
  String get faqAnswer3 =>
      'أظهر تذكرة QR الرقمية الخاصة بك من التطبيق للمشرف أو السائق عند الصعود.';

  @override
  String get aboutAppDescription =>
      'تطبيق عمومي باص هو منصة نقل ذكية تتيح للركاب تجربة تنقل يومية مريحة وموثوقة في مصر.';

  @override
  String get aboutFeature1 => 'استعراض الرحلات والمواعيد المجدولة';

  @override
  String get aboutFeature2 => 'حجز المقاعد المتاحة في الوقت الفعلي';

  @override
  String get aboutFeature3 => 'إدارة الحجوزات وسجل الرحلات';

  @override
  String get aboutFeature4 => 'الدفع السهل عبر محفظة النقاط';

  @override
  String get aboutFeature5 => 'تذاكر رقمية برمز QR لركوب أسرع';

  @override
  String get aboutFeature6 => 'استلام إشعارات بالرحلات والخدمات أولاً بأول';

  @override
  String get aboutFeature7 => 'تتبع الأتوبيسات المدعومة أثناء الخدمة';

  @override
  String get developerSection => 'المطور';

  @override
  String get developerNameLabel => 'المطور';

  @override
  String get developerEmailLabel => 'البريد الإلكتروني';

  @override
  String get developerWebsiteLabel => 'الموقع الإلكتروني';

  @override
  String get developerLinkedInLabel => 'لينكد إن';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get allRightsReserved => 'جميع الحقوق محفوظة.';

  @override
  String get privacyPolicyUrl => 'https://amomy.com/privacy-policy';

  @override
  String get termsAndConditionsUrl => 'https://amomy.com/terms-and-conditions';
}
