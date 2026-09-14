import '../../../../core/typedefs/typedefs.dart';
import '../entities/announcement.dart';
import '../entities/home_summary.dart';

abstract class HomeRepository {
  ResultFuture<HomeSummary> getHomeSummary();
  ResultFuture<List<Announcement>> getActiveAnnouncements();
}
