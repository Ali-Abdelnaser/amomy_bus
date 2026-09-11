import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/wallet_preview.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class GetWalletPreviewUseCase {
  final AuthRepository _repository;

  const GetWalletPreviewUseCase(this._repository);

  ResultFuture<WalletPreview?> call(String userId) {
    return _repository.getWalletPreview(userId);
  }
}
