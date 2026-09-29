import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/app_update/domain/entities/app_update_info.dart';
import 'package:amomy_bus/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:amomy_bus/features/app_update/domain/usecases/check_app_update_usecase.dart';
import 'package:amomy_bus/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:amomy_bus/features/app_update/presentation/bloc/app_update_event.dart';
import 'package:amomy_bus/features/app_update/presentation/bloc/app_update_state.dart';

class FakeAppUpdateRepository implements AppUpdateRepository {
  Result<AppUpdateInfo>? result;

  @override
  ResultFuture<AppUpdateInfo> getAppUpdateStatus() async {
    return result ??
        const Success(
          AppUpdateInfo(
            updateAvailable: false,
            forceUpdate: false,
          ),
        );
  }
}

void main() {
  late FakeAppUpdateRepository fakeRepo;
  late CheckAppUpdateUseCase useCase;
  late AppUpdateBloc bloc;

  setUp(() {
    fakeRepo = FakeAppUpdateRepository();
    useCase = CheckAppUpdateUseCase(fakeRepo);
    bloc = AppUpdateBloc(useCase);
  });

  tearDown(() {
    bloc.close();
  });

  group('AppUpdateBloc', () {
    test('initial state is AppUpdateInitial', () {
      expect(bloc.state, equals(const AppUpdateInitial()));
    });

    test('emits [AppUpdateChecking, AppUpdateNotAvailableState] when update is not available', () async {
      fakeRepo.result = const Success(
        AppUpdateInfo(
          updateAvailable: false,
          forceUpdate: false,
        ),
      );

      final expectedStates = [
        const AppUpdateChecking(),
        const AppUpdateNotAvailableState(),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const CheckAppUpdateRequested());
    });

    test('emits [AppUpdateChecking, AppUpdateAvailableState] when update is available', () async {
      const updateInfo = AppUpdateInfo(
        updateAvailable: true,
        forceUpdate: false,
        latestVersion: '1.2.0',
        latestBuild: 15,
        storeUrl: 'https://store.example.com',
        message: 'A new version is available',
      );

      fakeRepo.result = const Success(updateInfo);

      final expectedStates = [
        const AppUpdateChecking(),
        const AppUpdateAvailableState(updateInfo),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const CheckAppUpdateRequested());
    });

    test('emits [AppUpdateChecking, AppUpdateFailureState] on failure', () async {
      const failure = ServerFailure(message: 'Network connection failed');
      fakeRepo.result = const Error(failure);

      final expectedStates = [
        const AppUpdateChecking(),
        const AppUpdateFailureState(failure),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const CheckAppUpdateRequested());
    });

    test('only checks once per launch session', () async {
      fakeRepo.result = const Success(
        AppUpdateInfo(
          updateAvailable: false,
          forceUpdate: false,
        ),
      );

      bloc.add(const CheckAppUpdateRequested());
      await pumpEventQueue();

      expect(bloc.hasCheckedThisSession, isTrue);

      // Second check should do nothing
      bloc.add(const CheckAppUpdateRequested());
      await pumpEventQueue();

      expect(bloc.state, equals(const AppUpdateNotAvailableState()));
    });
  });
}
