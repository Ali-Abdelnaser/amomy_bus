import '../../../../core/typedefs/typedefs.dart';
import '../entities/referral_entities.dart';
import '../repositories/referral_repository.dart';

class GetMyReferralDashboardUseCase {
  final ReferralRepository _repository;

  const GetMyReferralDashboardUseCase(this._repository);

  ResultFuture<ReferralDashboard> call() =>
      _repository.getMyReferralDashboard();
}

class PreviewReferralCodeUseCase {
  final ReferralRepository _repository;

  const PreviewReferralCodeUseCase(this._repository);

  ResultFuture<ReferralCodePreview> call(String code) =>
      _repository.previewReferralCode(code);
}

class BindReferralCodeUseCase {
  final ReferralRepository _repository;

  const BindReferralCodeUseCase(this._repository);

  ResultFuture<BindReferralResult> call({
    required String code,
    required String source,
  }) =>
      _repository.bindReferralCode(code: code, source: source);
}
