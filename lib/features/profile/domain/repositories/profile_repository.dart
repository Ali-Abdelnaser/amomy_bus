import '../../../../core/typedefs/typedefs.dart';

abstract class ProfileRepository {
  /// Uploads avatar image bytes to storage, updates public.profiles,
  /// and returns the updated public URL.
  ResultFuture<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  });

  /// Removes avatar from storage and sets avatar_url to null in public.profiles.
  ResultFuture<void> removeAvatar({
    required String userId,
    String? currentAvatarUrl,
  });

  /// Permanently deletes user account via backend RPC delete_my_account.
  ResultFuture<void> deleteAccount({
    required String confirmationEmail,
  });

  /// Permanently deletes Apple-linked account via Edge Function apple-delete-account.
  ResultFuture<void> deleteAppleAccount({
    required String confirmationEmail,
    required String authorizationCode,
  });

  /// Whether current logged-in user is authenticated with Apple
  bool get isAppleUser;
}

