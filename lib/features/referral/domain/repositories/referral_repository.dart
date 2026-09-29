import '../../../../core/typedefs/typedefs.dart';
import '../entities/referral_entities.dart';

abstract class ReferralRepository {
  /// Fetches the authenticated passenger's complete referral dashboard.
  ResultFuture<ReferralDashboard> getMyReferralDashboard();

  /// Previews an inviter's referral code before user confirms binding.
  ResultFuture<ReferralCodePreview> previewReferralCode(String code);

  /// Binds the current user to a referral code with the specified source.
  /// [source] must be one of: `'manual_code'`, `'deep_link'`, `'qr'`.
  ResultFuture<BindReferralResult> bindReferralCode({
    required String code,
    required String source,
  });

  /// Subscribes to changes in referral_settings.
  Stream<void> subscribeToReferralSettingsUpdates();

  /// Subscribes to changes in referral_settings, referrals, referral_rewards, referral_qualified_trips.
  Stream<void> subscribeToReferralDashboardUpdates();
}
