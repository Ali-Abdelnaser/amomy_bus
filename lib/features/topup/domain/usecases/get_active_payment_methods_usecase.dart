import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/topup_entities.dart';
import '../repositories/topup_repository.dart';

@lazySingleton
class GetActivePaymentMethodsUseCase {
  final TopUpRepository _repository;

  const GetActivePaymentMethodsUseCase(this._repository);

  ResultFuture<List<PaymentMethod>> call() {
    return _repository.getActivePaymentMethods();
  }
}
