import '../../../../core/typedefs/typedefs.dart';
import '../entities/topup_entities.dart';

abstract class TopUpRepository {
  ResultFuture<PaymentConfig> getPaymentConfig();

  ResultFuture<List<PaymentMethod>> getActivePaymentMethods();

  ResultFuture<TopUpCreatedResponse> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    String? paymentReference,
  });

  ResultFuture<String> submitTopUpPaymentProof({
    required String requestId,
    required String senderPhone,
    String? transferReference,
    DateTime? transferredAt,
    required List<int> fileBytes,
    required String fileExtension,
  });

  ResultFuture<String> uploadTopUpProof({
    required String requestId,
    required List<int> fileBytes,
    required String fileExtension,
  });

  ResultFuture<List<TopUpRequest>> getMyTopUpRequests();

  Stream<void> subscribeToTopUpUpdates();
}
