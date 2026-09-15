import 'package:equatable/equatable.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

final class ProfileAvatarUploadRequested extends ProfileEvent {
  final String userId;
  final List<int> imageBytes;
  final String fileExtension;

  const ProfileAvatarUploadRequested({
    required this.userId,
    required this.imageBytes,
    required this.fileExtension,
  });

  @override
  List<Object?> get props => [userId, imageBytes, fileExtension];
}

final class ProfileAvatarRemoveRequested extends ProfileEvent {
  final String userId;
  final String? currentAvatarUrl;

  const ProfileAvatarRemoveRequested({
    required this.userId,
    this.currentAvatarUrl,
  });

  @override
  List<Object?> get props => [userId, currentAvatarUrl];
}

final class ProfileResetState extends ProfileEvent {
  const ProfileResetState();
}
