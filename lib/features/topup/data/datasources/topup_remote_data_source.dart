import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/topup_entities.dart';
import '../models/payment_config_model.dart';
import '../models/payment_method_model.dart';
import '../models/topup_request_model.dart';

abstract class TopUpRemoteDataSource {
  Future<PaymentConfigModel> getPaymentConfig();

  Future<List<PaymentMethodModel>> getActivePaymentMethods();

  Future<TopUpCreatedResponse> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    String? paymentReference,
  });

  Future<String> submitTopUpPaymentProof({
    required String requestId,
    required String senderPhone,
    String? transferReference,
    DateTime? transferredAt,
    required List<int> fileBytes,
    required String fileExtension,
  });

  Future<String> uploadTopUpProof({
    required String requestId,
    required List<int> fileBytes,
    required String fileExtension,
  });

  Future<List<TopUpRequestModel>> getMyTopUpRequests();

  Stream<void> subscribeToTopUpUpdates();
}

@LazySingleton(as: TopUpRemoteDataSource)
class TopUpRemoteDataSourceImpl implements TopUpRemoteDataSource {
  final SupabaseClient _supabase;

  TopUpRemoteDataSourceImpl(this._supabase);

  @override
  Future<PaymentConfigModel> getPaymentConfig() async {
    final response = await _supabase.rpc('get_payment_config');
    if (response is Map) {
      return PaymentConfigModel.fromJson(Map<String, dynamic>.from(response));
    }
    return const PaymentConfigModel();
  }

  @override
  Future<List<PaymentMethodModel>> getActivePaymentMethods() async {
    final response = await _supabase.rpc('get_active_payment_methods');
    if (response is List) {
      return response
          .map(
            (item) => PaymentMethodModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<TopUpCreatedResponse> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    String? paymentReference,
  }) async {
    final response = await _supabase.rpc(
      'create_topup_request',
      params: {
        'p_requested_amount': amount,
        'p_payment_method': paymentMethodCode,
        'p_payment_reference': paymentReference,
        'p_screenshot_path': null,
      },
    );

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      return TopUpCreatedResponse(
        requestId: map['request_id'] as String,
        publicId: map['public_id'] as String? ?? 'AMY-TOPUP',
        requestedPoints: (map['requested_points'] as num?)?.toInt() ?? amount,
        expectedAmountEgp:
            (map['expected_amount_egp'] as num?)?.toDouble() ??
            amount.toDouble(),
        receivingPhone: map['receiving_phone'] as String? ?? '01014045363',
        conversionRate: (map['conversion_rate'] as num?)?.toDouble() ?? 1.0,
        status: TopUpStatus.fromString(map['status'] as String?),
      );
    }
    throw const FormatException(
      'Failed to obtain top-up request details from backend.',
    );
  }

  @override
  Future<String> submitTopUpPaymentProof({
    required String requestId,
    required String senderPhone,
    String? transferReference,
    DateTime? transferredAt,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Not authenticated');
    }

    final cleanExt = fileExtension.replaceAll('.', '').toLowerCase();
    final validExt = switch (cleanExt) {
      'png' => 'png',
      'webp' => 'webp',
      'heic' => 'heic',
      _ => 'jpg',
    };

    final contentType = switch (validExt) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };

    final filename = 'proof_${DateTime.now().millisecondsSinceEpoch}.$validExt';
    final storagePath = '$userId/$requestId/$filename';

    // 1. Upload bytes directly to private bucket 'payment-proofs'
    await _supabase.storage
        .from('payment-proofs')
        .uploadBinary(
          storagePath,
          Uint8List.fromList(fileBytes),
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    // 2. Submit payment proof to top-up request via server-validated RPC
    await _supabase.rpc(
      'submit_topup_payment_proof',
      params: {
        'p_request_id': requestId,
        'p_sender_phone': senderPhone,
        'p_transfer_reference': transferReference,
        'p_transferred_at': (transferredAt ?? DateTime.now()).toIso8601String(),
        'p_screenshot_path': storagePath,
      },
    );

    return storagePath;
  }

  @override
  Future<String> uploadTopUpProof({
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
  Future<List<TopUpRequestModel>> getMyTopUpRequests() async {
    final response = await _supabase.rpc('get_my_topup_requests');
    if (response is List) {
      return response
          .map(
            (item) => TopUpRequestModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }
    return [];
  }

  @override
  Stream<void> subscribeToTopUpUpdates() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const Stream.empty();
    }

    return _supabase
        .from('topup_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((_) {})
        .handleError((_) {});
  }
}
