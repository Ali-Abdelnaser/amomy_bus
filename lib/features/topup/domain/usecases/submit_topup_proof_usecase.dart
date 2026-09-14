import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../repositories/topup_repository.dart';

@lazySingleton
class SubmitTopUpProofUseCase {
  final TopUpRepository _repository;

  const SubmitTopUpProofUseCase(this._repository);

  ResultFuture<String> call({
    required String requestId,
    required String senderPhone,
    String? transferReference,
    DateTime? transferredAt,
    required List<int> fileBytes,
    required String fileExtension,
  }) {
    return _repository.submitTopUpPaymentProof(
      requestId: requestId,
      senderPhone: senderPhone,
      transferReference: transferReference,
      transferredAt: transferredAt,
      fileBytes: fileBytes,
      fileExtension: fileExtension,
    );
  }
}
