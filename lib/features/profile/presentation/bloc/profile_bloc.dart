import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(const ProfileInitial()) {
    on<ProfileAvatarUploadRequested>(_onAvatarUploadRequested);
    on<ProfileAvatarRemoveRequested>(_onAvatarRemoveRequested);
    on<ProfileDeleteAccountRequested>(_onDeleteAccountRequested);
    on<ProfileResetState>((event, emit) => emit(const ProfileInitial()));
  }

  Future<void> _onAvatarUploadRequested(
    ProfileAvatarUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileAvatarLoading(isRemoving: false));

    final result = await repository.uploadAvatar(
      userId: event.userId,
      imageBytes: event.imageBytes,
      fileExtension: event.fileExtension,
    );

    result.fold(
      onError: (failure) =>
          emit(ProfileAvatarFailure(message: failure.message)),
      onSuccess: (url) =>
          emit(ProfileAvatarSuccess(avatarUrl: url, isRemoved: false)),
    );
  }

  Future<void> _onAvatarRemoveRequested(
    ProfileAvatarRemoveRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileAvatarLoading(isRemoving: true));

    final result = await repository.removeAvatar(
      userId: event.userId,
      currentAvatarUrl: event.currentAvatarUrl,
    );

    result.fold(
      onError: (failure) =>
          emit(ProfileAvatarFailure(message: failure.message)),
      onSuccess: (_) =>
          emit(const ProfileAvatarSuccess(avatarUrl: null, isRemoved: true)),
    );
  }

  Future<void> _onDeleteAccountRequested(
    ProfileDeleteAccountRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileDeleteAccountLoading());

    final code = event.authorizationCode;
    final result = (code != null && code.isNotEmpty)
        ? await repository.deleteAppleAccount(
            confirmationEmail: event.confirmationEmail,
            authorizationCode: code,
          )
        : await repository.deleteAccount(
            confirmationEmail: event.confirmationEmail,
          );

    result.fold(
      onError: (failure) =>
          emit(ProfileDeleteAccountFailure(message: failure.message)),
      onSuccess: (_) =>
          emit(const ProfileDeleteAccountSuccess()),
    );
  }
}

