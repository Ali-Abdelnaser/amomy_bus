import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_role.dart';
import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.phone,
    super.gender,
    super.dateOfBirth,
    super.avatarUrl,
    super.roles = const [AppRole.passenger],
    super.isEmailVerified = false,
  });

  factory AppUserModel.fromSupabase({
    required User user,
    Map<String, dynamic>? profileData,
    List<String>? roleStrings,
  }) {
    final meta = user.userMetadata ?? {};

    final fullName = (profileData?['full_name'] as String?)?.trim().isNotEmpty == true
        ? profileData!['full_name'] as String
        : (meta['full_name'] as String?) ??
            (meta['name'] as String?) ??
            user.email?.split('@').first ??
            '';

    final phone = (profileData?['phone'] as String?) ??
        (meta['phone'] as String?) ??
        user.phone;

    final gender = (profileData?['gender'] as String?) ??
        (meta['gender'] as String?);

    DateTime? dob;
    final dobRaw = profileData?['date_of_birth'] ?? meta['date_of_birth'];
    if (dobRaw is String && dobRaw.isNotEmpty) {
      dob = DateTime.tryParse(dobRaw);
    } else if (dobRaw is DateTime) {
      dob = dobRaw;
    }

    final avatarUrl = (profileData?['avatar_url'] as String?) ??
        (meta['avatar_url'] as String?);

    final parsedRoles = roleStrings != null && roleStrings.isNotEmpty
        ? roleStrings.map(AppRole.fromString).toList()
        : [AppRole.passenger];

    // Supabase sets emailConfirmedAt when email is verified
    final isEmailVerified = user.emailConfirmedAt != null;

    return AppUserModel(
      id: user.id,
      email: user.email ?? '',
      fullName: fullName,
      phone: phone,
      gender: gender,
      dateOfBirth: dob,
      avatarUrl: avatarUrl,
      roles: parsedRoles,
      isEmailVerified: isEmailVerified,
    );
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName,
      phone: phone,
      gender: gender,
      dateOfBirth: dateOfBirth,
      avatarUrl: avatarUrl,
      roles: roles,
      isEmailVerified: isEmailVerified,
    );
  }
}
