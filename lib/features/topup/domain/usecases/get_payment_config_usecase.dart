import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/topup_entities.dart';
import '../repositories/topup_repository.dart';

@lazySingleton
class GetPaymentConfigUseCase {
  final TopUpRepository _repository;

  const GetPaymentConfigUseCase(this._repository);

  ResultFuture<PaymentConfig> call() {
    return _repository.getPaymentConfig();
  }
}
