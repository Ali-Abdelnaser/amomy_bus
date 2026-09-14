import 'package:injectable/injectable.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  HomeRepositoryImpl(this._remoteDataSource);

  @override
  ResultFuture<HomeSummary> getHomeSummary() async {
    try {
      final summary = await _remoteDataSource.getHomeSummary();
      return Success(summary);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<List<Announcement>> getActiveAnnouncements() async {
    try {
      final announcements = await _remoteDataSource.getActiveAnnouncements();
      return Success(announcements);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }
}
