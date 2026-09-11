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

  /// First name of the user, falling back to 'Commuter' if empty
  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Commuter';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.first;
  }

  /// Initials derived from the user's full name
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'A';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Required fields for passenger profile completion
  static const List<String> requiredProfileFields = [
    'full_name',
    'email',
    'phone',
    'gender',
    'date_of_birth',
  ];

  /// List of missing required profile field keys
  List<String> get missingProfileFields {
    final missing = <String>[];
    if (fullName.trim().isEmpty) missing.add('full_name');
    if (email.trim().isEmpty) missing.add('email');
    if (phone == null || phone!.trim().isEmpty) missing.add('phone');
    if (gender == null || (gender != 'male' && gender != 'female')) {
      missing.add('gender');
    }
    if (dateOfBirth == null) missing.add('date_of_birth');
    return missing;
  }

  /// Profile is complete when all required fields are present
  bool get isProfileComplete => missingProfileFields.isEmpty;

  /// Profile completion percentage as a double from 0.0 to 1.0
  double get profileCompletionPercentage {
    final completed = requiredProfileFields.length - missingProfileFields.length;
    return completed / requiredProfileFields.length;
  }

  /// Profile completion percentage as an integer from 0 to 100
  int get profileCompletionPercent => (profileCompletionPercentage * 100).round();

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
