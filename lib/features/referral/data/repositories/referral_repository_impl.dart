import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/referral_entities.dart';
import '../../domain/repositories/referral_repository.dart';
import '../datasources/referral_remote_data_source.dart';

@LazySingleton(as: ReferralRepository)
class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralRemoteDataSource _remoteDataSource;

  ReferralRepositoryImpl({
    ReferralRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
           remoteDataSource ?? ReferralRemoteDataSourceImpl();

  @override
  ResultFuture<ReferralDashboard> getMyReferralDashboard() async {
    try {
      final dashboard = await _remoteDataSource.getMyReferralDashboard();
      return Success(dashboard);
    } on PostgrestException catch (e) {
      return Error(ServerFailure(message: _localizeDbError(e.message)));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<ReferralCodePreview> previewReferralCode(String code) async {
    try {
      final preview = await _remoteDataSource.previewReferralCode(code);
      return Success(preview);
    } on PostgrestException catch (e) {
      return Error(ServerFailure(message: _localizeDbError(e.message)));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<BindReferralResult> bindReferralCode({
    required String code,
    required String source,
  }) async {
    try {
      final result = await _remoteDataSource.bindReferralCode(
        code: code,
        source: source,
      );
      return Success(result);
    } on PostgrestException catch (e) {
      return Error(ServerFailure(message: _localizeDbError(e.message)));
    } catch (e) {
      return Error(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<void> subscribeToReferralSettingsUpdates() {
    return _remoteDataSource.subscribeToReferralSettingsUpdates();
  }

  @override
  Stream<void> subscribeToReferralDashboardUpdates() {
    return _remoteDataSource.subscribeToReferralDashboardUpdates();
  }

  String _localizeDbError(String rawError) {
    if (rawError.contains('REFERRAL_PROGRAM_DISABLED') ||
        rawError.contains('PROGRAM_DISABLED')) {
      return 'برنامج الدعوات متوقف حالياً';
    }
    if (rawError.contains('ALREADY_REFERRED')) {
      return 'تم ربط حسابك بكود دعوة مسبقاً';
    }
    if (rawError.contains('NOT_ELIGIBLE_ALREADY_TRAVELLED')) {
      return 'أكواد الدعوة متاحة فقط للركاب الجدد قبل إتمام رحلتهم الأولى';
    }
    if (rawError.contains('INVALID_REFERRAL_CODE') ||
        rawError.contains('INVALID_CODE')) {
      return 'كود الدعوة غير صحيح أو غير متاح';
    }
    if (rawError.contains('SELF_INVITE_NOT_ALLOWED') ||
        rawError.contains('SELF_INVITE')) {
      return 'لا يمكنك استخدام كود الدعوة الخاص بك';
    }
    if (rawError.contains('INVITER_UNAVAILABLE')) {
      return 'صاحب كود الدعوة غير متاح حالياً';
    }
    if (rawError.contains('INVITER_MONTHLY_LIMIT_REACHED') ||
        rawError.contains('MONTHLY_LIMIT_REACHED')) {
      return 'وصل صاحب الدعوة للحد الأقصى للدعوات هذا الشهر';
    }
    if (rawError.contains('NOT_AUTHENTICATED')) {
      return 'يرجى تسجيل الدخول أولاً';
    }
    return rawError;
  }
}
