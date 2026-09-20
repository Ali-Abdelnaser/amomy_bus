import 'package:equatable/equatable.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileAvatarLoading extends ProfileState {
  final bool isRemoving;

  const ProfileAvatarLoading({this.isRemoving = false});

  @override
  List<Object?> get props => [isRemoving];
}

final class ProfileAvatarSuccess extends ProfileState {
  final String? avatarUrl;
  final bool isRemoved;

  const ProfileAvatarSuccess({this.avatarUrl, this.isRemoved = false});

  @override
  List<Object?> get props => [avatarUrl, isRemoved];
}

final class ProfileAvatarFailure extends ProfileState {
  final String message;

  const ProfileAvatarFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
