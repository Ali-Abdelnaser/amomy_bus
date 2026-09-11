import '../../../../core/typedefs/typedefs.dart';
import '../entities/topup_entities.dart';

abstract class TopUpRepository {
  ResultFuture<List<PaymentMethod>> getActivePaymentMethods();

  ResultFuture<String> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    required String paymentReference,
  });

  ResultFuture<String> uploadTopUpProof({
    required String requestId,
    required List<int> fileBytes,
    required String fileExtension,
  });

  ResultFuture<List<TopUpRequest>> getMyTopUpRequests();

  Stream<void> subscribeToTopUpUpdates();
}
