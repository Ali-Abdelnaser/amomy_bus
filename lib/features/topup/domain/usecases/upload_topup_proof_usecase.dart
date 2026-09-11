import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../repositories/topup_repository.dart';

@lazySingleton
class UploadTopUpProofUseCase {
  final TopUpRepository _repository;

  const UploadTopUpProofUseCase(this._repository);

  ResultFuture<String> call({
    required String requestId,
    required List<int> fileBytes,
    required String fileExtension,
  }) {
    return _repository.uploadTopUpProof(
      requestId: requestId,
      fileBytes: fileBytes,
      fileExtension: fileExtension,
    );
  }
}
