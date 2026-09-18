import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/wallet/domain/entities/point_transaction.dart';
import 'package:amomy_bus/features/wallet/domain/entities/wallet_history_event.dart';
import 'package:amomy_bus/features/wallet/domain/entities/wallet_summary.dart';
import 'package:amomy_bus/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:amomy_bus/features/wallet/domain/usecases/get_wallet_history_usecase.dart';
import 'package:amomy_bus/features/wallet/domain/usecases/get_wallet_summary_usecase.dart';
import 'package:amomy_bus/features/wallet/domain/usecases/get_wallet_transactions_usecase.dart';
import 'package:amomy_bus/features/topup/domain/entities/topup_entities.dart';
import 'package:amomy_bus/features/topup/domain/repositories/topup_repository.dart';
import 'package:amomy_bus/features/topup/domain/usecases/get_my_topup_requests_usecase.dart';
import 'package:amomy_bus/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:amomy_bus/features/wallet/presentation/cubit/wallet_state.dart';

class MockWalletRepository implements WalletRepository {
  StreamController<int>? balanceController;
  StreamController<PointTransaction>? transactionController;

  @override
  ResultFuture<WalletSummary> getWalletSummary(String userId) async {
    return const Success(
      WalletSummary(
        totalAvailablePoints: 100,
        cashPoints: 100,
        subscriptionPoints: 0,
      ),
    );
  }

  List<PointTransaction> mockTransactions = const [];
  WalletHistoryPage mockHistoryPage = const WalletHistoryPage.empty();

  @override
  ResultFuture<List<PointTransaction>> getTransactions(
    String userId, {
    int limit = 20,
  }) async {
    return Success(mockTransactions);
  }

  @override
  ResultFuture<WalletHistoryPage> getWalletHistory({
    int limit = 20,
    String? beforeCreatedAt,
    String? beforeEventId,
  }) async {
    return Success(mockHistoryPage);
  }

  @override
  Stream<int> subscribeToWalletBalance(String userId) {
    balanceController ??= StreamController<int>.broadcast();
    return balanceController!.stream;
  }

  @override
  Stream<PointTransaction> subscribeToPointTransactions(String userId) {
    transactionController ??= StreamController<PointTransaction>.broadcast();
    return transactionController!.stream;
  }
}

class MockTopUpRepository implements TopUpRepository {
  StreamController<void>? topUpController;

  @override
  ResultFuture<PaymentConfig> getPaymentConfig() async =>
      const Success(PaymentConfig(minimumTopupPoints: 200, egpPerPoint: 1.0));

  @override
  ResultFuture<List<PaymentMethod>> getActivePaymentMethods() async =>
      const Success([]);

  @override
  ResultFuture<TopUpCreatedResponse> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    String? paymentReference,
  }) async => throw UnimplementedError();

  @override
  ResultFuture<String> submitTopUpPaymentProof({
    required String requestId,
    required String senderPhone,
    String? transferReference,
    DateTime? transferredAt,
    required List<int> fileBytes,
    required String fileExtension,
  }) async => const Success('path');

  @override
  ResultFuture<String> uploadTopUpProof({
    required String requestId,
    required List<int> fileBytes,
    required String fileExtension,
  }) async => const Success('path');

  @override
  ResultFuture<TopUpCreatedResponse> submitNewTopUpRequest({
    required int amount,
    required String paymentMethod,
    required String senderPhone,
    String? transferReference,
    DateTime? transferredAt,
    required List<int> fileBytes,
    required String fileExtension,
  }) async => throw UnimplementedError();

  @override
  ResultFuture<List<TopUpRequest>> getMyTopUpRequests() async =>
      const Success([]);

  @override
  Stream<void> subscribeToTopUpUpdates() {
    topUpController ??= StreamController<void>.broadcast();
    return topUpController!.stream;
  }
}

void main() {
  late MockWalletRepository walletRepo;
  late MockTopUpRepository topUpRepo;
  late GetWalletSummaryUseCase getWalletSummaryUseCase;
  late GetWalletTransactionsUseCase getWalletTransactionsUseCase;
  late GetMyTopUpRequestsUseCase getMyTopUpRequestsUseCase;
  late WalletCubit cubit;

  setUp(() {
    walletRepo = MockWalletRepository();
    topUpRepo = MockTopUpRepository();
    getWalletSummaryUseCase = GetWalletSummaryUseCase(walletRepo);
    getWalletTransactionsUseCase = GetWalletTransactionsUseCase(walletRepo);
    getMyTopUpRequestsUseCase = GetMyTopUpRequestsUseCase(topUpRepo);
    final getWalletHistoryUseCase = GetWalletHistoryUseCase(walletRepo);

    cubit = WalletCubit(
      getWalletSummaryUseCase,
      getWalletTransactionsUseCase,
      walletRepo,
      getMyTopUpRequestsUseCase,
      getWalletHistoryUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test(
    'WalletCubit loads summary and handles real-time balance stream events',
    () async {
      await cubit.loadWalletSummary('user-123');
      expect(cubit.state.status, WalletStatus.loaded);
      expect(cubit.state.summary.totalAvailablePoints, 100);

      // Emit balance update
      walletRepo.balanceController?.add(250);
      await pumpEventQueue();

      expect(cubit.state.summary.totalAvailablePoints, 250);
    },
  );

  test(
    'WalletCubit gracefully handles stream error on topup_requests without crashing or throwing',
    () async {
      await cubit.loadWalletSummary('user-123');
      expect(cubit.state.status, WalletStatus.loaded);

      // Emit error simulating RealtimeSubscribeException / channelError on topup stream
      topUpRepo.topUpController?.addError(
        Exception('Unable to subscribe to changes with given parameters'),
      );
      await pumpEventQueue();

      // Cubit remains in loaded status and does NOT bubble uncaught exception
      expect(cubit.state.status, WalletStatus.loaded);
    },
  );

  test(
    'WalletCubit gracefully handles stream error on wallets without crashing or throwing',
    () async {
      await cubit.loadWalletSummary('user-123');
      expect(cubit.state.status, WalletStatus.loaded);

      // Emit error simulating RealtimeSubscribeException on wallet balance stream
      walletRepo.balanceController?.addError(
        Exception('Realtime channel error'),
      );
      await pumpEventQueue();

      // Cubit remains loaded and functional
      expect(cubit.state.status, WalletStatus.loaded);
      expect(cubit.state.summary.totalAvailablePoints, 100);
    },
  );

  test(
    'RealtimeSubscribeException does NOT escape to global bootstrap zone',
    () async {
      await cubit.loadWalletSummary('user-123');

      Object? uncaughtError;
      await runZonedGuarded(
        () async {
          // Inject channelError on both streams simultaneously
          walletRepo.balanceController?.addError(Exception('channelError'));
          topUpRepo.topUpController?.addError(Exception('channelError'));
          await pumpEventQueue();
        },
        (error, stack) {
          uncaughtError = error;
        },
      );

      // Neither error must escape
      expect(uncaughtError, isNull);
      expect(cubit.state.status, WalletStatus.loaded);
    },
  );

  test(
    'Wallet state is preserved after stream failure — last loaded data remains',
    () async {
      await cubit.loadWalletSummary('user-123');
      expect(cubit.state.summary.totalAvailablePoints, 100);

      // Update balance via realtime
      walletRepo.balanceController?.add(300);
      await pumpEventQueue();
      expect(cubit.state.summary.totalAvailablePoints, 300);

      // Now a channel error fires
      walletRepo.balanceController?.addError(Exception('channelError'));
      await pumpEventQueue();

      // Last balance (300) must be preserved
      expect(cubit.state.summary.totalAvailablePoints, 300);
      expect(cubit.state.status, WalletStatus.loaded);
    },
  );

  test(
    'Subscriptions are cancelled on cubit close — no late events processed',
    () async {
      await cubit.loadWalletSummary('user-123');
      expect(cubit.state.summary.totalAvailablePoints, 100);

      await cubit.close();

      // Emit after close
      expect(() => walletRepo.balanceController?.add(999), returnsNormally);
      await pumpEventQueue();

      // Balance unchanged at last known value
      expect(cubit.state.summary.totalAvailablePoints, 100);
    },
  );

  test(
    'WalletCubit treats point_transactions realtime event as invalidation and refreshes history',
    () async {
      final transaction = PointTransaction(
        id: 'tx-1',
        userId: 'user-123',
        walletId: 'wallet-1',
        transactionType: PointTransactionType.credit,
        amount: 50,
        referenceType: 'topup',
        createdAt: DateTime(2026, 9, 15, 12),
      );

      final event = WalletHistoryEvent(
        eventId: 'evt-1',
        semanticType: WalletSemanticType.pointsTopup,
        signedAmount: 50,
        createdAt: DateTime(2026, 9, 15, 12),
      );

      walletRepo.mockTransactions = [transaction];
      walletRepo.mockHistoryPage = WalletHistoryPage(
        events: [event],
        hasMore: false,
      );

      await cubit.loadWalletSummary('user-123');
      expect(cubit.state.historyEvents.length, 1);
      expect(cubit.state.historyEvents.first.eventId, 'evt-1');

      // Trigger realtime invalidation twice
      walletRepo.transactionController?.add(transaction);
      walletRepo.transactionController?.add(transaction);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await pumpEventQueue();

      // De-duplicated and stable by eventId
      expect(cubit.state.historyEvents.length, 1);
      expect(cubit.state.historyEvents.first.eventId, 'evt-1');
    },
  );
}
