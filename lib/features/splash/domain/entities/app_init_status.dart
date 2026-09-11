import 'package:equatable/equatable.dart';

class AppInitStatus extends Equatable {
  final bool isAuthenticated;
  final bool isOnboardingCompleted;

  const AppInitStatus({
    required this.isAuthenticated,
    required this.isOnboardingCompleted,
  });

  @override
  List<Object?> get props => [isAuthenticated, isOnboardingCompleted];
}
