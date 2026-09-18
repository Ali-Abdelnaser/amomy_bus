import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/topup_entities.dart';
import '../../domain/repositories/topup_repository.dart';
import '../datasources/topup_remote_data_source.dart';

@LazySingleton(as: TopUpRepository)
class TopUpRepositoryImpl implements TopUpRepository {
  final TopUpRemoteDataSource _remoteDataSource;

  TopUpRepositoryImpl(this._remoteDataSource);

  @override
  ResultFuture<PaymentConfig> getPaymentConfig() async {
    try {
      final config = await _remoteDataSource.getPaymentConfig();
      return Success(config);
    } on SocketException catch (_) {
      return const Error(NetworkFailure());
    } on PostgrestException catch (e) {
      return Error(_mapPostgrestError(e));
    } catch (e) {
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<List<PaymentMethod>> getActivePaymentMethods() async {
    try {
      final methods = await _remoteDataSource.getActivePaymentMethods();
      return Success(methods);
    } on SocketException catch (_) {
      return const Error(NetworkFailure());
    } on PostgrestException catch (e) {
      return Error(_mapPostgrestError(e));
    } catch (e) {
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<TopUpCreatedResponse> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    String? paymentReference,
  }) async {
    try {
      if (amount < 200) {
        return const Error(
          ServerFailure(message: 'Minimum top-up is 200 Points.'),
        );
      }
      final created = await _remoteDataSource.createTopUpRequest(
        amount: amount,
        paymentMethodCode: paymentMethodCode,
        paymentReference: paymentReference,
      );
      return Success(created);
    } on SocketException catch (_) {
      return const Error(NetworkFailure());
    } on PostgrestException catch (e) {
      return Error(_mapPostgrestError(e));
    } catch (e) {
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<String> submitTopUpPaymentProof({
    required String requestId,
    required String senderPhone,
    String? transferReference,
    DateTime? transferredAt,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    try {
      final storedPath = await _remoteDataSource.submitTopUpPaymentProof(
        requestId: requestId,
        senderPhone: senderPhone,
        transferReference: transferReference,
        transferredAt: transferredAt,
        fileBytes: fileBytes,
        fileExtension: fileExtension,
      );
      return Success(storedPath);
    } on SocketException catch (_) {
      return const Error(NetworkFailure());
    } on StorageException catch (e) {
      return Error(ProofUploadFailedFailure(message: e.message));
    } on PostgrestException catch (e) {
      return Error(_mapPostgrestError(e));
    } catch (e) {
      return Error(ProofUploadFailedFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<String> uploadTopUpProof({
    required String requestId,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    return submitTopUpPaymentProof(
      requestId: requestId,
      senderPhone: '01014045363',
      fileBytes: fileBytes,
      fileExtension: fileExtension,
    );
  }

  @override
  ResultFuture<TopUpCreatedResponse> submitNewTopUpRequest({
    required int amount,
    required String paymentMethod,
    required String senderPhone,
    String? transferReference,
    DateTime? transferredAt,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    try {
      if (amount < 200) {
        return const Error(
          ServerFailure(message: 'Minimum top-up is 200 Points.'),
        );
      }
      final created = await _remoteDataSource.submitNewTopUpRequest(
        amount: amount,
        paymentMethod: paymentMethod,
        senderPhone: senderPhone,
        transferReference: transferReference,
        transferredAt: transferredAt,
        fileBytes: fileBytes,
        fileExtension: fileExtension,
      );
      return Success(created);
    } on SocketException catch (_) {
      return const Error(NetworkFailure());
    } on StorageException catch (e) {
      return Error(ProofUploadFailedFailure(message: e.message));
    } on PostgrestException catch (e) {
      return Error(_mapPostgrestError(e));
    } catch (e) {
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<List<TopUpRequest>> getMyTopUpRequests() async {
    try {
      final requests = await _remoteDataSource.getMyTopUpRequests();
      return Success(requests);
    } on SocketException catch (_) {
      return const Error(NetworkFailure());
    } on PostgrestException catch (e) {
      return Error(_mapPostgrestError(e));
    } catch (e) {
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<void> subscribeToTopUpUpdates() {
    return _remoteDataSource.subscribeToTopUpUpdates();
  }

  Failure _mapPostgrestError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('minimum_topup_points') ||
        msg.contains('minimum top-up')) {
      return const ServerFailure(message: 'Minimum top-up is 200 Points.');
    }
    if (msg.contains('invalid_egyptian_phone_number')) {
      return const ServerFailure(
        message: 'Please enter a valid Egyptian mobile number (01XXXXXXXXX).',
      );
    }
    if (msg.contains('already active or approved') ||
        msg.contains('duplicate')) {
      return const DuplicatePaymentReferenceFailure();
    }
    if (msg.contains('greater than zero') || msg.contains('invalid amount')) {
      return const InvalidAmountFailure();
    }
    if (msg.contains('not found')) {
      return const RequestNotFoundFailure();
    }
    if (msg.contains('already') || msg.contains('already reviewed')) {
      return const RequestAlreadyReviewedFailure();
    }
    if (e.code == 'PGRST301' ||
        msg.contains('jwt') ||
        msg.contains('authenticated')) {
      return const AuthenticationFailure();
    }
    return ServerFailure(message: e.message);
  }
}
