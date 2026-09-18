import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/wallet_preview.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class EmailVerificationRequired extends AuthState {
  final String email;
  final String? infoMessage;

  const EmailVerificationRequired({
    required this.email,
    this.infoMessage,
  });

  @override
  List<Object?> get props => [email, infoMessage];
}

final class ProfileCompletionRequired extends AuthState {
  final AppUser user;

  const ProfileCompletionRequired(this.user);

  @override
  List<Object?> get props => [user];
}

final class Authenticated extends AuthState {
  final AppUser user;
  final WalletPreview? wallet;

  const Authenticated({
    required this.user,
    this.wallet,
  });

  bool get isProfileComplete => user.isProfileComplete;
  double get profileCompletionPercentage => user.profileCompletionPercentage;
  int get profileCompletionPercent => user.profileCompletionPercent;
  List<String> get missingProfileFields => user.missingProfileFields;

  @override
  List<Object?> get props => [user, wallet];
}

final class ProfileSaving extends Authenticated {
  const ProfileSaving({
    required super.user,
    super.wallet,
  });
}

final class ProfileSaveFailure extends Authenticated {
  final Failure failure;

  const ProfileSaveFailure({
    required super.user,
    required this.failure,
    super.wallet,
  });

  @override
  List<Object?> get props => [user, wallet, failure];
}

final class AuthFailureState extends AuthState {
  final Failure failure;

  const AuthFailureState(this.failure);

  @override
  List<Object?> get props => [failure];
}

final class PasswordResetEmailSent extends AuthState {
  final String email;

  const PasswordResetEmailSent(this.email);

  @override
  List<Object?> get props => [email];
}

final class PasswordUpdatedSuccessfully extends AuthState {
  const PasswordUpdatedSuccessfully();
}

enum AccessBlockedType {
  deviceBlocked,
  temporaryBan,
  permanentBan,
}

final class AccessBlockedState extends AuthState {
  final AccessBlockedType type;
  final DateTime? bannedUntil;
  final String? customMessage;

  const AccessBlockedState({
    required this.type,
    this.bannedUntil,
    this.customMessage,
  });

  @override
  List<Object?> get props => [type, bannedUntil, customMessage];
}

