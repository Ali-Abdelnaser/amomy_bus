import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/topup_entities.dart';
import '../repositories/topup_repository.dart';

@lazySingleton
class SubmitNewTopUpRequestUseCase {
  final TopUpRepository _repository;

  const SubmitNewTopUpRequestUseCase(this._repository);

  ResultFuture<TopUpCreatedResponse> call({
    required int amount,
    required String paymentMethod,
    required String senderPhone,
    String? transferReference,
    DateTime? transferredAt,
    required List<int> fileBytes,
    required String fileExtension,
  }) {
    return _repository.submitNewTopUpRequest(
      amount: amount,
      paymentMethod: paymentMethod,
      senderPhone: senderPhone,
      transferReference: transferReference,
      transferredAt: transferredAt,
      fileBytes: fileBytes,
      fileExtension: fileExtension,
    );
  }
}
