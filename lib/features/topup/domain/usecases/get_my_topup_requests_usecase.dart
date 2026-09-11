import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/topup_entities.dart';
import '../repositories/topup_repository.dart';

@lazySingleton
class GetMyTopUpRequestsUseCase {
  final TopUpRepository _repository;

  const GetMyTopUpRequestsUseCase(this._repository);

  ResultFuture<List<TopUpRequest>> call() {
    return _repository.getMyTopUpRequests();
  }

  Stream<void> subscribeToUpdates() {
    return _repository.subscribeToTopUpUpdates();
  }
}
