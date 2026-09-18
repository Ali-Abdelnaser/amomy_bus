import 'package:equatable/equatable.dart';
import '../../domain/entities/app_user.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class SignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

final class SignUpWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String? phone;
  final String? gender;
  final DateTime? dateOfBirth;

  const SignUpWithEmailRequested({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
    this.gender,
    this.dateOfBirth,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        fullName,
        phone,
        gender,
        dateOfBirth,
      ];
}

final class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String token;

  const VerifyOtpRequested({
    required this.email,
    required this.token,
  });

  @override
  List<Object?> get props => [email, token];
}

final class ResendOtpRequested extends AuthEvent {
  final String email;

  const ResendOtpRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

final class SignInWithGoogleRequested extends AuthEvent {
  final String? webClientId;

  const SignInWithGoogleRequested({this.webClientId});

  @override
  List<Object?> get props => [webClientId];
}

final class CompleteProfileRequested extends AuthEvent {
  final String fullName;
  final String phone;
  final String gender;
  final DateTime dateOfBirth;

  const CompleteProfileRequested({
    required this.fullName,
    required this.phone,
    required this.gender,
    required this.dateOfBirth,
  });

  @override
  List<Object?> get props => [fullName, phone, gender, dateOfBirth];
}

final class SendPasswordResetRequested extends AuthEvent {
  final String email;

  const SendPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

final class UpdatePasswordRequested extends AuthEvent {
  final String newPassword;

  const UpdatePasswordRequested({required this.newPassword});

  @override
  List<Object?> get props => [newPassword];
}

final class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

final class AuthUserChangedInternal extends AuthEvent {
  final AppUser? user;

  const AuthUserChangedInternal(this.user);

  @override
  List<Object?> get props => [user];
}

final class AppResumedRequested extends AuthEvent {
  const AppResumedRequested();
}

