import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileRemoteDataSource {
  Future<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  });

  Future<void> removeAvatar({required String userId, String? currentAvatarUrl});

  Future<void> deleteAccount({required String confirmationEmail});

  Future<void> deleteAppleAccount({
    required String confirmationEmail,
    required String authorizationCode,
  });

  bool get isAppleUser;
}


class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient? _customClient;

  ProfileRemoteDataSourceImpl({SupabaseClient? supabaseClient})
    : _customClient = supabaseClient;

  SupabaseClient get _supabase => _customClient ?? Supabase.instance.client;

  @override
  Future<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  }) async {
    final validExt = fileExtension.toLowerCase().replaceAll('.', '');
    final contentType = switch (validExt) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final filename =
        'avatar_${DateTime.now().millisecondsSinceEpoch}.$validExt';
    final storagePath = '$userId/$filename';

    // 1. Upload compressed binary to user-isolated folder in public 'avatars' bucket
    await _supabase.storage
        .from('avatars')
        .uploadBinary(
          storagePath,
          Uint8List.fromList(imageBytes),
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    // 2. Obtain permanent public URL
    final publicUrl = _supabase.storage
        .from('avatars')
        .getPublicUrl(storagePath);

    // 3. Persist authoritative URL to public.profiles table
    await _supabase
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', userId);

    // 4. Clean up any previous avatar files for this user to maintain storage hygiene
    try {
      final existingFiles = await _supabase.storage
          .from('avatars')
          .list(path: userId);
      final oldFiles = existingFiles
          .where((f) => f.name != filename)
          .map((f) => '$userId/${f.name}')
          .toList();
      if (oldFiles.isNotEmpty) {
        await _supabase.storage.from('avatars').remove(oldFiles);
      }
    } catch (_) {
      // Non-critical background cleanup failure
    }

    return publicUrl;
  }

  @override
  Future<void> removeAvatar({
    required String userId,
    String? currentAvatarUrl,
  }) async {
    // 1. Nullify avatar_url on user's profile row
    await _supabase
        .from('profiles')
        .update({'avatar_url': null})
        .eq('id', userId);

    // 2. Remove all existing avatar files from user's storage directory
    try {
      final existingFiles = await _supabase.storage
          .from('avatars')
          .list(path: userId);
      if (existingFiles.isNotEmpty) {
        await _supabase.storage
            .from('avatars')
            .remove(existingFiles.map((f) => '$userId/${f.name}').toList());
      }
    } catch (_) {
      // Non-critical background cleanup failure
    }
  }

  @override
  bool get isAppleUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    final appMetadata = user.appMetadata;
    final provider = appMetadata['provider']?.toString().toLowerCase();
    if (provider == 'apple') return true;
    final providers = appMetadata['providers'];
    if (providers is List &&
        providers.any((p) => p.toString().toLowerCase() == 'apple')) {
      return true;
    }
    final identities = user.identities;
    if (identities != null &&
        identities.any((id) => id.provider.toLowerCase() == 'apple')) {
      return true;
    }
    return false;
  }

  @override
  Future<void> deleteAccount({required String confirmationEmail}) async {
    await _supabase.rpc(
      'delete_my_account',
      params: {'p_confirmation_email': confirmationEmail},
    );
  }

  @override
  Future<void> deleteAppleAccount({
    required String confirmationEmail,
    required String authorizationCode,
  }) async {
    final response = await _supabase.functions.invoke(
      'apple-delete-account',
      body: {
        'confirmation_email': confirmationEmail,
        'authorization_code': authorizationCode,
      },
    );

    final rawData = response.data;
    if (response.status != 200 ||
        (rawData is Map &&
            (rawData['error'] != null || rawData['success'] == false))) {
      String? errorMessage;
      if (rawData is Map) {
        errorMessage = rawData['error']?.toString() ??
            rawData['message']?.toString();
      } else if (rawData is String && rawData.isNotEmpty) {
        errorMessage = rawData;
      }
      throw FunctionException(
        status: response.status,
        details: rawData,
        reasonPhrase: errorMessage ??
            'Failed to delete Apple account (${response.status})',
      );
    }
  }
}

