import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_method_model.dart';
import '../models/topup_request_model.dart';

abstract class TopUpRemoteDataSource {
  Future<List<PaymentMethodModel>> getActivePaymentMethods();

  Future<String> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    required String paymentReference,
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
  Future<List<PaymentMethodModel>> getActivePaymentMethods() async {
    final response = await _supabase.rpc('get_active_payment_methods');
    if (response is List) {
      return response
          .map((item) => PaymentMethodModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  @override
  Future<String> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    required String paymentReference,
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

    if (response is Map && response['request_id'] != null) {
      return response['request_id'] as String;
    }
    throw const FormatException('Failed to obtain top-up request ID from backend.');
  }

  @override
  Future<String> uploadTopUpProof({
    required String requestId,
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
    await _supabase.storage.from('payment-proofs').uploadBinary(
          storagePath,
          Uint8List.fromList(fileBytes),
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    // 2. Attach payment proof to top-up request via hardened RPC
    await _supabase.rpc(
      'attach_topup_payment_proof',
      params: {
        'p_request_id': requestId,
        'p_screenshot_path': storagePath,
      },
    );

    return storagePath;
  }

  @override
  Future<List<TopUpRequestModel>> getMyTopUpRequests() async {
    final response = await _supabase.rpc('get_my_topup_requests');
    if (response is List) {
      return response
          .map((item) => TopUpRequestModel.fromJson(Map<String, dynamic>.from(item as Map)))
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
        .map((_) {});
  }
}
