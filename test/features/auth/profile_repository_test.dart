import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:amomy_bus/features/auth/data/models/app_user_model.dart';
import 'package:amomy_bus/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_role.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  AppUserModel? resultUser;
  Object? exceptionToThrow;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<AppUserModel> completeProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return resultUser!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAuthRemoteDataSource fakeRemoteDataSource;
  late AuthRepositoryImpl repository;

  final tModel = AppUserModel(
    id: 'user-123',
    email: 'passenger@amomy.com',
    fullName: 'Ali Abdelnaser',
    phone: '01012345678',
    gender: 'male',
    dateOfBirth: DateTime(1995, 5, 20),
    roles: const [AppRole.passenger],
    isEmailVerified: true,
  );

  setUp(() {
    fakeRemoteDataSource = _FakeAuthRemoteDataSource();
    repository = AuthRepositoryImpl(fakeRemoteDataSource);
  });

  group('AuthRepositoryImpl.completeProfile', () {
    test('returns Success(AppUser) on successful profile update', () async {
      fakeRemoteDataSource.resultUser = tModel;

      final result = await repository.completeProfile(
        userId: 'user-123',
        fullName: 'Ali Abdelnaser',
        phone: '01012345678',
        gender: 'male',
        dateOfBirth: DateTime(1995, 5, 20),
      );

      expect(result, isA<Success<AppUser>>());
      final user = (result as Success<AppUser>).data;
      expect(user.id, equals('user-123'));
      expect(user.fullName, equals('Ali Abdelnaser'));
      expect(user.phone, equals('01012345678'));
    });

    test(
      'returns Error(ValidationFailure) on duplicate phone/email (code 23505)',
      () async {
        fakeRemoteDataSource.exceptionToThrow = const PostgrestException(
          message:
              'duplicate key value violates unique constraint "idx_profiles_phone"',
          code: '23505',
        );

        final result = await repository.completeProfile(
          userId: 'user-123',
          fullName: 'Ali Abdelnaser',
          phone: '01012345678',
          gender: 'male',
          dateOfBirth: DateTime(1995, 5, 20),
        );

        expect(result, isA<Error<AppUser>>());
        final failure = (result as Error<AppUser>).failure;
        expect(failure, isA<ValidationFailure>());
        expect(failure.statusCode, equals(409));
      },
    );

    test(
      'returns Error(ServerFailure) on PostgrestException recursion error (code 42P17)',
      () async {
        fakeRemoteDataSource.exceptionToThrow = const PostgrestException(
          message:
              'infinite recursion detected in policy for relation "profiles"',
          code: '42P17',
        );

        final result = await repository.completeProfile(
          userId: 'user-123',
          fullName: 'Ali Abdelnaser',
          phone: '01012345678',
          gender: 'male',
          dateOfBirth: DateTime(1995, 5, 20),
        );

        expect(result, isA<Error<AppUser>>());
        final failure = (result as Error<AppUser>).failure;
        expect(failure, isA<ServerFailure>());
      },
    );
  });
}
