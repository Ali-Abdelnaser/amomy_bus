import '../../../../core/error/failures.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({ProfileRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? ProfileRemoteDataSourceImpl();

  @override
  ResultFuture<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  }) async {
    try {
      final url = await _remoteDataSource.uploadAvatar(
        userId: userId,
        imageBytes: imageBytes,
        fileExtension: fileExtension,
      );
      return Success(url);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> removeAvatar({
    required String userId,
    String? currentAvatarUrl,
  }) async {
    try {
      await _remoteDataSource.removeAvatar(
        userId: userId,
        currentAvatarUrl: currentAvatarUrl,
      );
      return const Success(null);
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }
}
