import 'package:equatable/equatable.dart';
import 'app_role.dart';

/// Clean domain representation of an authenticated user in Amomy Bus.
///
/// Completely decoupled from Supabase User / GoTrue models.
class AppUser extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? avatarUrl;
  final List<AppRole> roles;
  final bool isEmailVerified;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.avatarUrl,
    this.roles = const [AppRole.passenger],
    this.isEmailVerified = false,
  });

  /// A profile is considered complete when name, phone, gender, and date of birth are all present.
  bool get isProfileComplete {
    final hasName = fullName.trim().isNotEmpty;
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    final hasGender = gender != null && (gender == 'male' || gender == 'female');
    final hasDob = dateOfBirth != null;
    return hasName && hasPhone && hasGender && hasDob;
  }

  bool get hasAdminPrivileges => roles.any((r) => r.isAdmin);
  bool get isPassenger => roles.contains(AppRole.passenger);

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
    String? avatarUrl,
    List<AppRole>? roles,
    bool? isEmailVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roles: roles ?? this.roles,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        phone,
        gender,
        dateOfBirth,
        avatarUrl,
        roles,
        isEmailVerified,
      ];
}
