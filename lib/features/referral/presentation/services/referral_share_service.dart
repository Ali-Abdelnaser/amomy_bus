import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Service responsible for invoking the native system share sheet
/// for referral invitations with deep link and fallback plain code.
class ReferralShareService {
  const ReferralShareService._();

  static Future<ShareResult> shareInvite({
    required String code,
    required bool isArabic,
    Rect? sharePositionOrigin,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    final inviteLink = 'amomy://invite?code=$cleanCode';

    final text = isArabic
        ? 'انضم إلى عمومي باص واستمتع برحلات مريحة وآمنة!\n'
          'كود الدعوة الخاص بي: $cleanCode\n'
          'رابط الانضمام المباشر:\n$inviteLink'
        : 'Join AMOMY Bus for comfortable and safe rides!\n'
          'My referral code: $cleanCode\n'
          'Direct invite link:\n$inviteLink';

    final subject = isArabic
        ? 'دعوة للانضمام إلى عمومي باص ($cleanCode)'
        : 'Invite to join AMOMY Bus ($cleanCode)';

    return SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
