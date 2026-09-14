import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/topup/domain/entities/topup_entities.dart';
import 'package:amomy_bus/features/topup/domain/repositories/topup_repository.dart';
import 'package:amomy_bus/features/topup/domain/usecases/get_my_topup_requests_usecase.dart';
import 'package:amomy_bus/features/topup/presentation/cubit/topup_history_cubit.dart';
import 'package:amomy_bus/features/topup/presentation/cubit/topup_history_state.dart';

class FakeHistoryRepository implements TopUpRepository {
  List<TopUpRequest> requests = [];
  Failure? failure;

  @override
  ResultFuture<PaymentConfig> getPaymentConfig() async => const Success(PaymentConfig());

  @override
  ResultFuture<List<PaymentMethod>> getActivePaymentMethods() async => const Success([]);

  @override
  ResultFuture<TopUpCreatedResponse> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    String? paymentReference,
  }) async =>
      const Success(TopUpCreatedResponse(
        requestId: 'req-1',
        publicId: 'AMY-123456',
        requestedPoints: 300,
        expectedAmountEgp: 300,
        receivingPhone: '01000000000',
        conversionRate: 1.0,
        status: TopUpStatus.awaitingPayment,
      ));

  @override
  ResultFuture<String> submitTopUpPaymentProof({
    required String requestId,
    required String senderPhone,
    String? transferReference,
    DateTime? transferredAt,
    required List<int> fileBytes,
    required String fileExtension,
  }) async =>
      const Success('path/proof.jpg');

  @override
  ResultFuture<String> uploadTopUpProof({
    required String requestId,
    required List<int> fileBytes,
    required String fileExtension,
  }) async =>
      const Success('path');

  @override
  ResultFuture<List<TopUpRequest>> getMyTopUpRequests() async {
    if (failure != null) return Error(failure!);
    return Success(requests);
  }

  @override
  Stream<void> subscribeToTopUpUpdates() => const Stream.empty();
}

void main() {
  late FakeHistoryRepository repository;
  late GetMyTopUpRequestsUseCase getMyTopUpRequestsUseCase;
  late TopUpHistoryCubit cubit;

  final testPendingReq = TopUpRequest(
    id: 'req-1',
    userId: 'u-1',
    requestedAmount: 300,
    paymentMethodCode: 'VODAFONE_CASH',
    status: TopUpStatus.pending,
    createdAt: DateTime.now(),
  );

  final testApprovedReq = TopUpRequest(
    id: 'req-1',
    userId: 'u-1',
    requestedAmount: 300,
    paymentMethodCode: 'VODAFONE_CASH',
    status: TopUpStatus.approved,
    createdAt: DateTime.now(),
  );

  final testRejectedReq = TopUpRequest(
    id: 'req-2',
    userId: 'u-1',
    requestedAmount: 200,
    paymentMethodCode: 'ORANGE_CASH',
    status: TopUpStatus.rejected,
    rejectionReason: 'Invalid reference',
    createdAt: DateTime.now(),
  );

  setUp(() {
    repository = FakeHistoryRepository();
    getMyTopUpRequestsUseCase = GetMyTopUpRequestsUseCase(repository);
    cubit = TopUpHistoryCubit(getMyTopUpRequestsUseCase);
  });

  tearDown(() {
    cubit.close();
  });

  group('TopUpHistoryCubit', () {
    test('initial state has empty requests and initial status', () {
      expect(cubit.state.status, equals(TopUpHistoryStatus.initial));
      expect(cubit.state.requests, isEmpty);
    });

    test('loadRequests successfully updates state with user requests', () async {
      repository.requests = [testPendingReq, testRejectedReq];
      await cubit.loadRequests();

      expect(cubit.state.status, equals(TopUpHistoryStatus.success));
      expect(cubit.state.requests.length, equals(2));
      expect(cubit.state.requests.first.status, equals(TopUpStatus.pending));
    });

    test('loadRequests handles failure gracefully', () async {
      repository.failure = const ServerFailure(message: 'Database error');
      await cubit.loadRequests();

      expect(cubit.state.status, equals(TopUpHistoryStatus.failure));
      expect(cubit.state.errorMessage, equals('Database error'));
    });

    test('onApprovedTopUpDetected fires when a pending request becomes approved', () async {
      bool callbackFired = false;
      cubit.onApprovedTopUpDetected = () {
        callbackFired = true;
      };

      // 1. Initially user has a pending request
      repository.requests = [testPendingReq];
      await cubit.loadRequests();
      expect(callbackFired, isFalse);

      // 2. Refresh occurs and now it is approved
      repository.requests = [testApprovedReq];
      await cubit.loadRequests();
      expect(callbackFired, isTrue);
    });
  });
}
