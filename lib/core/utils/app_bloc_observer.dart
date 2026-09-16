import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    // Suppressed generic event logs temporarily for [IOS_PUSH_DIAG] investigation
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // Suppressed generic verbose BLoC state/user dumping temporarily for [IOS_PUSH_DIAG] investigation
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      developer.log(
        'onError: ${bloc.runtimeType}',
        error: error,
        stackTrace: stackTrace,
        name: 'BLOC',
      );
    }
    super.onError(bloc, error, stackTrace);
  }
}
