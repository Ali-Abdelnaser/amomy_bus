import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_init_status.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

class SplashLoading extends SplashState {
  const SplashLoading();
}

class SplashLoaded extends SplashState {
  final AppInitStatus status;

  const SplashLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

class SplashError extends SplashState {
  final Failure failure;

  const SplashError(this.failure);

  @override
  List<Object?> get props => [failure];
}
