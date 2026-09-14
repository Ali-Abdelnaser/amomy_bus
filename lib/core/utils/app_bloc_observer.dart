import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/booking/presentation/cubit/booking_state.dart';
import '../config/app_config.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (kDebugMode && AppConfig.instance.enableLogging) {
      developer.log('onEvent: ${bloc.runtimeType} -> $event', name: 'BLOC');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (!kDebugMode || !AppConfig.instance.enableLogging) return;

    if (change.currentState is BookingState && change.nextState is BookingState) {
      final curr = change.currentState as BookingState;
      final next = change.nextState as BookingState;

      // Suppress countdown-only logs completely
      final isCountdownOnly = curr.currentStep == next.currentStep &&
          curr.status == next.status &&
          curr.selectedSeat == next.selectedSeat &&
          curr.activeHold?.holdId == next.activeHold?.holdId &&
          curr.errorMessage == next.errorMessage &&
          curr.holdSecondsRemaining != next.holdSecondsRemaining;

      if (isCountdownOnly) {
        return;
      }

      final tripId = next.selectedTrip?.tripId;
      final shortTrip = tripId != null
          ? (tripId.length > 8 ? '${tripId.substring(0, 8)}...' : tripId)
          : 'none';

      final errorLine = next.errorMessage != null ? '\nerror: ${next.errorMessage}' : '';
      developer.log(
        '[BLOC][BookingCubit]\n'
        'step: ${curr.currentStep.name} -> ${next.currentStep.name}\n'
        'status: ${curr.status.name} -> ${next.status.name}\n'
        'trip: $shortTrip\n'
        'seat: ${next.selectedSeat?.seatNumber ?? 'none'}\n'
        'holdRemaining: ${next.holdSecondsRemaining}s'
        '$errorLine',
        name: 'BLOC',
      );
      return;
    }

    developer.log(
      'onChange: ${bloc.runtimeType} -> ${change.currentState} => ${change.nextState}',
      name: 'BLOC',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      developer.log('onError: ${bloc.runtimeType}', error: error, stackTrace: stackTrace, name: 'BLOC');
    }
    super.onError(bloc, error, stackTrace);
  }
}
