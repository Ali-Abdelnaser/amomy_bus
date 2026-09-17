import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class ClaimWelcomeGiftUseCase {
  final AuthRepository _repository;

  ClaimWelcomeGiftUseCase(this._repository);

  ResultFuture<bool> call({required String deviceIdentifier}) {
    return _repository.claimActiveWelcomeGift(
      deviceIdentifier: deviceIdentifier,
    );
  }
}
