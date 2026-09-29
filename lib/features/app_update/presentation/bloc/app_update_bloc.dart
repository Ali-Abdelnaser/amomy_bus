import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/check_app_update_usecase.dart';
import 'app_update_event.dart';
import 'app_update_state.dart';

@injectable
class AppUpdateBloc extends Bloc<AppUpdateEvent, AppUpdateState> {
  final CheckAppUpdateUseCase _checkAppUpdateUseCase;
  bool _hasCheckedThisSession = false;

  AppUpdateBloc(this._checkAppUpdateUseCase) : super(const AppUpdateInitial()) {
    on<CheckAppUpdateRequested>(_onCheckAppUpdateRequested);
    on<AppUpdateDismissed>(_onAppUpdateDismissed);
  }

  bool get hasCheckedThisSession => _hasCheckedThisSession;

  Future<void> _onCheckAppUpdateRequested(
    CheckAppUpdateRequested event,
    Emitter<AppUpdateState> emit,
  ) async {
    if (_hasCheckedThisSession) return;
    _hasCheckedThisSession = true;

    emit(const AppUpdateChecking());

    try {
      final result = await _checkAppUpdateUseCase();

      result.fold(
        onError: (failure) {
          emit(AppUpdateFailureState(failure));
        },
        onSuccess: (info) {
          if (info.updateAvailable) {
            emit(AppUpdateAvailableState(info));
          } else {
            emit(const AppUpdateNotAvailableState());
          }
        },
      );
    } catch (e) {
      // Safe guard against unexpected runtime issues
      emit(const AppUpdateNotAvailableState());
    }
  }

  void _onAppUpdateDismissed(
    AppUpdateDismissed event,
    Emitter<AppUpdateState> emit,
  ) {
    emit(const AppUpdateNotAvailableState());
  }
}
