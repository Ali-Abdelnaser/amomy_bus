import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../config/app_config.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (AppConfig.instance.enableLogging) {
      developer.log('onEvent: ${bloc.runtimeType} -> $event', name: 'BLOC');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (AppConfig.instance.enableLogging) {
      developer.log('onChange: ${bloc.runtimeType} -> ${change.currentState} => ${change.nextState}', name: 'BLOC');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    developer.log('onError: ${bloc.runtimeType}', error: error, stackTrace: stackTrace, name: 'BLOC');
    super.onError(bloc, error, stackTrace);
  }
}
