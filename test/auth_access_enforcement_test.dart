import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/services/device_identity_service.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';
import 'package:amomy_bus/features/auth/domain/entities/user_access_status.dart';
import 'package:amomy_bus/features/auth/domain/entities/wallet_preview.dart';
import 'package:amomy_bus/features/auth/domain/repositories/auth_repository.dart';
import 'package:amomy_bus/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/get_wallet_preview_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_event.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';

class MockDeviceIdentityService implements DeviceIdentityService {
  String deviceId = 'test-device-uuid-123';

  @override
  Future<String> getDeviceIdentifier() async => deviceId;
}

class MockAuthRepository implements AuthRepository {
  DeviceAccessResult deviceAccessResult = const DeviceAccessResult(
    allowed: true,
    isBlocked: false,
  );
  UserAccessStatus accessStatusResult = const UserAccessStatus(
    allowed: true,
    accountStatus: 'active',
  );

  bool registerInstallationCalled = false;
  String? registeredDeviceId;
  String? registeredPlatform;

  final List<String> recordedEvents = [];

  @override
  ResultFuture<DeviceAccessResult> checkDeviceAccess({
    required String deviceIdentifier,
  }) async {
    return Success(deviceAccessResult);
  }

  @override
  ResultFuture<void> registerUserInstallation({
    required String deviceIdentifier,
    required String platform,
    String? deviceName,
    String? appVersion,
  }) async {
    registerInstallationCalled = true;
    registeredDeviceId = deviceIdentifier;
    registeredPlatform = platform;
    return const Success(null);
  }

  @override
  ResultFuture<UserAccessStatus> getMyAccessStatus({
    required String deviceIdentifier,
  }) async {
    return Success(accessStatusResult);
  }

  @override
  ResultFuture<void> recordUserActivity({
    required String eventType,
    required String deviceIdentifier,
    Map<String, dynamic>? metadata,
  }) async {
    recordedEvents.add(eventType);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGetCurrentUserUseCase implements GetCurrentUserUseCase {
  AppUser? userToReturn;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Future<Result<AppUser?>> call() async => Success(userToReturn);

  @override
  Stream<AppUser?> get userStream => _controller.stream;
}

class FakeSignInWithEmailUseCase implements SignInWithEmailUseCase {
  AppUser? userToReturn;
  Failure? failureToReturn;

  @override
  Future<Result<AppUser>> call({
    required String email,
    required String password,
  }) async {
    if (failureToReturn != null) return Error(failureToReturn!);
    return Success(userToReturn!);
  }
}

class FakeSignUpWithEmailUseCase implements SignUpWithEmailUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVerifyOtpUseCase implements VerifyOtpUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeResendOtpUseCase implements ResendOtpUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSignInWithGoogleUseCase implements SignInWithGoogleUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCompleteProfileUseCase implements CompleteProfileUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSendPasswordResetUseCase implements SendPasswordResetUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUpdatePasswordUseCase implements UpdatePasswordUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGetWalletPreviewUseCase implements GetWalletPreviewUseCase {
  @override
  Future<Result<WalletPreview?>> call(String userId) async =>
      const Success(null);
}

class FakeSignOutUseCase implements SignOutUseCase {
  bool called = false;
  @override
  Future<Result<void>> call() async {
    called = true;
    return const Success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDeviceIdentityService mockIdentityService;
  late MockAuthRepository mockAuthRepo;
  late FakeGetCurrentUserUseCase mockGetCurrentUser;
  late FakeSignInWithEmailUseCase mockSignIn;
  late FakeSignOutUseCase mockSignOut;
  late AuthBloc authBloc;

  final testUser = AppUser(
    id: 'usr-1',
    email: 'passenger@example.com',
    fullName: 'Passenger One',
    phone: '01011112222',
    gender: 'male',
    dateOfBirth: DateTime(2000, 1, 1),
    isEmailVerified: true,
    roles: const [],
  );

  setUp(() {
    mockIdentityService = MockDeviceIdentityService();
    mockAuthRepo = MockAuthRepository();
    mockGetCurrentUser = FakeGetCurrentUserUseCase();
    mockSignIn = FakeSignInWithEmailUseCase();
    mockSignOut = FakeSignOutUseCase();

    authBloc = AuthBloc(
      getCurrentUserUseCase: mockGetCurrentUser,
      signInWithEmailUseCase: mockSignIn,
      signUpWithEmailUseCase: FakeSignUpWithEmailUseCase(),
      verifyOtpUseCase: FakeVerifyOtpUseCase(),
      resendOtpUseCase: FakeResendOtpUseCase(),
      signInWithGoogleUseCase: FakeSignInWithGoogleUseCase(),
      completeProfileUseCase: FakeCompleteProfileUseCase(),
      sendPasswordResetUseCase: FakeSendPasswordResetUseCase(),
      updatePasswordUseCase: FakeUpdatePasswordUseCase(),
      getWalletPreviewUseCase: FakeGetWalletPreviewUseCase(),
      deviceIdentityService: mockIdentityService,
      authRepository: mockAuthRepo,
      signOutUseCase: mockSignOut,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('Passenger Access Enforcement Tests', () {
    test(
      'Pre-auth device check blocks blocked device before loading user session',
      () async {
        mockAuthRepo.deviceAccessResult = const DeviceAccessResult(
          allowed: false,
          isBlocked: true,
        );
        mockGetCurrentUser.userToReturn = testUser;

        final states = <AuthState>[];
        final sub = authBloc.stream.listen(states.add);

        authBloc.add(const AuthCheckRequested());
        await Future.delayed(const Duration(milliseconds: 50));

        expect(
          states.any(
            (s) =>
                s is AccessBlockedState &&
                s.type == AccessBlockedType.deviceBlocked,
          ),
          isTrue,
        );
        expect(states.any((s) => s is Authenticated), isFalse);
        await sub.cancel();
      },
    );

    test(
      'Allowed device with active user session authenticates, registers installation and records session_start',
      () async {
        mockAuthRepo.deviceAccessResult = const DeviceAccessResult(
          allowed: true,
          isBlocked: false,
        );
        mockAuthRepo.accessStatusResult = const UserAccessStatus(
          allowed: true,
          accountStatus: 'active',
        );
        mockGetCurrentUser.userToReturn = testUser;

        final states = <AuthState>[];
        final sub = authBloc.stream.listen(states.add);

        authBloc.add(const AuthCheckRequested());
        await Future.delayed(const Duration(milliseconds: 50));

        expect(states.last is Authenticated, isTrue);
        expect(mockAuthRepo.registerInstallationCalled, isTrue);
        expect(mockAuthRepo.registeredDeviceId, 'test-device-uuid-123');
        expect(mockAuthRepo.recordedEvents.contains('session_start'), isTrue);
        await sub.cancel();
      },
    );

    test(
      'Temporary ban blocks authenticated user session and returns bannedUntil timestamp',
      () async {
        final banDate = DateTime(2026, 10, 15);
        mockAuthRepo.deviceAccessResult = const DeviceAccessResult(
          allowed: true,
          isBlocked: false,
        );
        mockAuthRepo.accessStatusResult = UserAccessStatus(
          allowed: false,
          accountStatus: 'temporary_ban',
          bannedUntil: banDate,
        );
        mockGetCurrentUser.userToReturn = testUser;

        final states = <AuthState>[];
        final sub = authBloc.stream.listen(states.add);

        authBloc.add(const AuthCheckRequested());
        await Future.delayed(const Duration(milliseconds: 50));

        final blockedState = states.whereType<AccessBlockedState>().firstOrNull;
        expect(blockedState, isNotNull);
        expect(blockedState!.type, AccessBlockedType.temporaryBan);
        expect(blockedState.bannedUntil, banDate);
        expect(states.any((s) => s is Authenticated), isFalse);
        await sub.cancel();
      },
    );

    test('Permanent ban blocks authenticated user session', () async {
      mockAuthRepo.deviceAccessResult = const DeviceAccessResult(
        allowed: true,
        isBlocked: false,
      );
      mockAuthRepo.accessStatusResult = const UserAccessStatus(
        allowed: false,
        accountStatus: 'permanent_ban',
      );
      mockGetCurrentUser.userToReturn = testUser;

      final states = <AuthState>[];
      final sub = authBloc.stream.listen(states.add);

      authBloc.add(const AuthCheckRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      final blockedState = states.whereType<AccessBlockedState>().firstOrNull;
      expect(blockedState, isNotNull);
      expect(blockedState!.type, AccessBlockedType.permanentBan);
      expect(states.any((s) => s is Authenticated), isFalse);
      await sub.cancel();
    });

    test('Successful login checks access and records login_success', () async {
      mockAuthRepo.deviceAccessResult = const DeviceAccessResult(
        allowed: true,
        isBlocked: false,
      );
      mockAuthRepo.accessStatusResult = const UserAccessStatus(
        allowed: true,
        accountStatus: 'active',
      );
      mockSignIn.userToReturn = testUser;

      final states = <AuthState>[];
      final sub = authBloc.stream.listen(states.add);

      authBloc.add(
        const SignInWithEmailRequested(
          email: 'passenger@example.com',
          password: 'Password123!',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.last is Authenticated, isTrue);
      expect(mockAuthRepo.recordedEvents.contains('login_success'), isTrue);
      await sub.cancel();
    });

    test(
      'App resume event re-checks access status and records app_open when active',
      () async {
        mockAuthRepo.deviceAccessResult = const DeviceAccessResult(
          allowed: true,
          isBlocked: false,
        );
        mockAuthRepo.accessStatusResult = const UserAccessStatus(
          allowed: true,
          accountStatus: 'active',
        );
        mockGetCurrentUser.userToReturn = testUser;

        authBloc.add(const AuthCheckRequested());
        await Future.delayed(const Duration(milliseconds: 50));
        expect(authBloc.state is Authenticated, isTrue);

        // Trigger app resume
        authBloc.add(const AppResumedRequested());
        await Future.delayed(const Duration(milliseconds: 50));

        expect(mockAuthRepo.recordedEvents.contains('app_open'), isTrue);
        expect(authBloc.state is Authenticated, isTrue);

        // Now simulate ban while app was backgrounded
        mockAuthRepo.accessStatusResult = const UserAccessStatus(
          allowed: false,
          accountStatus: 'permanent_ban',
        );
        authBloc.add(const AppResumedRequested());
        await Future.delayed(const Duration(milliseconds: 50));

        expect(authBloc.state is AccessBlockedState, isTrue);
        expect(
          (authBloc.state as AccessBlockedState).type,
          AccessBlockedType.permanentBan,
        );
      },
    );

    test('SignOut records logout event with device identifier', () async {
      mockGetCurrentUser.userToReturn = testUser;
      authBloc.add(const AuthCheckRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      authBloc.add(const SignOutRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockAuthRepo.recordedEvents.contains('logout'), isTrue);
      expect(mockSignOut.called, isTrue);
      expect(authBloc.state is Unauthenticated, isTrue);
    });
  });
}
