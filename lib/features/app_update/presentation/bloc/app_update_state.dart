import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_update_info.dart';

abstract class AppUpdateState extends Equatable {
  const AppUpdateState();

  @override
  List<Object?> get props => [];
}

class AppUpdateInitial extends AppUpdateState {
  const AppUpdateInitial();
}

class AppUpdateChecking extends AppUpdateState {
  const AppUpdateChecking();
}

class AppUpdateAvailableState extends AppUpdateState {
  final AppUpdateInfo updateInfo;

  const AppUpdateAvailableState(this.updateInfo);

  @override
  List<Object?> get props => [updateInfo];
}

class AppUpdateNotAvailableState extends AppUpdateState {
  const AppUpdateNotAvailableState();
}

class AppUpdateFailureState extends AppUpdateState {
  final Failure failure;

  const AppUpdateFailureState(this.failure);

  @override
  List<Object?> get props => [failure];
}
