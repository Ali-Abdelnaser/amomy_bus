import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/check_app_status_usecase.dart';
import 'splash_event.dart';
import 'splash_state.dart';

@injectable
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final CheckAppStatusUseCase _checkAppStatusUseCase;

  SplashBloc(this._checkAppStatusUseCase) : super(const SplashInitial()) {
    on<SplashCheckRequested>(_onSplashCheckRequested);
  }

  Future<void> _onSplashCheckRequested(
    SplashCheckRequested event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());

    final result = await _checkAppStatusUseCase();

    result.fold(
      onError: (failure) => emit(SplashError(failure)),
      onSuccess: (status) => emit(SplashLoaded(status)),
    );
  }
}
