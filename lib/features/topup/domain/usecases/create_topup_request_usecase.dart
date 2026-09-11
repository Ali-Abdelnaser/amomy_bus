import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../repositories/topup_repository.dart';

@lazySingleton
class CreateTopUpRequestUseCase {
  final TopUpRepository _repository;

  const CreateTopUpRequestUseCase(this._repository);

  ResultFuture<String> call({
    required int amount,
    required String paymentMethodCode,
    required String paymentReference,
  }) {
    return _repository.createTopUpRequest(
      amount: amount,
      paymentMethodCode: paymentMethodCode,
      paymentReference: paymentReference,
    );
  }
}
