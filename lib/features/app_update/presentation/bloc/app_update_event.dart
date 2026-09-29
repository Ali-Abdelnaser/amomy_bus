import 'package:equatable/equatable.dart';

abstract class AppUpdateEvent extends Equatable {
  const AppUpdateEvent();

  @override
  List<Object?> get props => [];
}

class CheckAppUpdateRequested extends AppUpdateEvent {
  const CheckAppUpdateRequested();
}

class AppUpdateDismissed extends AppUpdateEvent {
  const AppUpdateDismissed();
}
