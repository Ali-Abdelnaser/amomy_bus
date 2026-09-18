import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/topup/domain/entities/topup_entities.dart';
import 'package:amomy_bus/features/topup/domain/repositories/topup_repository.dart';
import 'package:amomy_bus/features/topup/domain/usecases/create_topup_request_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/get_active_payment_methods_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/get_payment_config_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/submit_topup_proof_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/submit_new_topup_request_usecase.dart';
import 'package:amomy_bus/features/topup/presentation/cubit/topup_cubit.dart';
import 'package:amomy_bus/features/topup/presentation/cubit/topup_state.dart';

class FakeTopUpRepository implements TopUpRepository {
  PaymentConfig config = const PaymentConfig(
    minimumTopupPoints: 200,
    egpPerPoint: 1.0,
  );
  List<PaymentMethod> methods = [];
  List<TopUpRequest> requests = [];
  TopUpCreatedResponse createdResponse = const TopUpCreatedResponse(
    requestId: 'req-123',
    publicId: 'AMY-7K4F92',
    requestedPoints: 500,
    expectedAmountEgp: 500,
    receivingPhone: '01014045363',
    conversionRate: 1.0,
    status: TopUpStatus.awaitingPayment,
  );
  String uploadedProofPath = 'user-1/req-123/proof.jpg';
  Failure? configFailure;
  Failure? methodsFailure;
  Failure? createFailure;
  Failure? uploadFailure;
  Failure? submitNewFailure;
  Failure? historyFailure;

  int createCallCount = 0;
  int submitNewCallCount = 0;
  int submitProofCallCount = 0;

  @override
  ResultFuture<PaymentConfig> getPaymentConfig() async {
    if (configFailure != null) return Error(configFailure!);
    return Success(config);
  }

  @override
  ResultFuture<List<PaymentMethod>> getActivePaymentMethods() async {
    if (methodsFailure != null) return Error(methodsFailure!);
    return Success(methods);
  }

  @override
  ResultFuture<TopUpCreatedResponse> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    String? paymentReference,
  }) async {
    createCallCount++;
    if (createFailure != null) return Error(createFailure!);
    return Success(createdResponse);
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
    submitProofCallCount++;
    if (uploadFailure != null) return Error(uploadFailure!);
    return Success(uploadedProofPath);
  }

  @override
  ResultFuture<String> uploadTopUpProof({
    required String requestId,
    required List<int> fileBytes,
    required String fileExtension,
  }) async {
    if (uploadFailure != null) return Error(uploadFailure!);
    return Success(uploadedProofPath);
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
    submitNewCallCount++;
    if (submitNewFailure != null) return Error(submitNewFailure!);
    return Success(
      TopUpCreatedResponse(
        requestId: 'new-req-999',
        publicId: 'AMY-999',
        requestedPoints: amount,
        expectedAmountEgp: amount.toDouble(),
        receivingPhone: '01014045363',
        conversionRate: 1.0,
        status: TopUpStatus.pending,
      ),
    );
  }

  @override
  ResultFuture<List<TopUpRequest>> getMyTopUpRequests() async {
    if (historyFailure != null) return Error(historyFailure!);
    return Success(requests);
  }

  @override
  Stream<void> subscribeToTopUpUpdates() => const Stream.empty();
}

void main() {
  late FakeTopUpRepository repository;
  late GetPaymentConfigUseCase getPaymentConfigUseCase;
  late GetActivePaymentMethodsUseCase getActivePaymentMethodsUseCase;
  late CreateTopUpRequestUseCase createTopUpRequestUseCase;
  late SubmitTopUpProofUseCase submitTopUpProofUseCase;
  late SubmitNewTopUpRequestUseCase submitNewTopUpRequestUseCase;
  late TopUpCubit cubit;

  const testMethod = PaymentMethod(
    id: 'pm-1',
    code: 'VODAFONE_CASH',
    nameAr: 'فودافون كاش',
    nameEn: 'Vodafone Cash',
    accountIdentifier: '01014045363',
    instructionsAr: 'قم بالتحويل لرقم فودافون كاش أعلاه',
    instructionsEn: 'Transfer to Vodafone Cash number above',
    iconKey: 'vodafone_cash',
    isActive: true,
    sortOrder: 1,
  );

  setUp(() {
    repository = FakeTopUpRepository()..methods = [testMethod];
    getPaymentConfigUseCase = GetPaymentConfigUseCase(repository);
    getActivePaymentMethodsUseCase = GetActivePaymentMethodsUseCase(repository);
    createTopUpRequestUseCase = CreateTopUpRequestUseCase(repository);
    submitTopUpProofUseCase = SubmitTopUpProofUseCase(repository);
    submitNewTopUpRequestUseCase = SubmitNewTopUpRequestUseCase(repository);
    cubit = TopUpCubit(
      getPaymentConfigUseCase,
      getActivePaymentMethodsUseCase,
      createTopUpRequestUseCase,
      submitTopUpProofUseCase,
      submitNewUseCase: submitNewTopUpRequestUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('TopUpCubit', () {
    test('initial state has step amount and default values', () {
      expect(cubit.state.currentStep, equals(TopUpStep.amount));
      expect(cubit.state.amount, equals(0));
      expect(cubit.state.isAmountValid, isFalse);
    });

    test(
      'init populates config, methods, default amount and expected EGP',
      () async {
        await cubit.init(availableBalance: 150);
        expect(cubit.state.availableBalance, equals(150));
        expect(cubit.state.amount, equals(200));
        expect(cubit.state.expectedAmountEgp, equals(200.0));
        expect(cubit.state.paymentMethods.length, equals(1));
        expect(cubit.state.selectedMethod, equals(testMethod));
        expect(cubit.state.isAmountValid, isTrue);
        expect(cubit.state.canProceedFromAmount, isTrue);
      },
    );

    test('enforces minimum 200 points hard rule', () {
      cubit.setAmount(150);
      expect(cubit.state.amount, equals(150));
      expect(cubit.state.isAmountValid, isFalse);
      expect(cubit.state.canProceedFromAmount, isFalse);

      cubit.setAmount(200);
      expect(cubit.state.isAmountValid, isTrue);
      expect(cubit.state.canProceedFromAmount, isTrue);
    });

    test('proceedToInstructions validates min points before advancing', () {
      cubit.setAmount(100);
      cubit.proceedToInstructions();
      expect(cubit.state.currentStep, equals(TopUpStep.amount));
      expect(
        cubit.state.errorMessage,
        contains('Minimum top-up is 200 Points'),
      );

      cubit.setAmount(250);
      cubit.proceedToInstructions();
      expect(cubit.state.currentStep, equals(TopUpStep.instructions));
      expect(cubit.state.errorMessage, isNull);
    });

    test('1. Step 1 does not create request', () {
      cubit.setAmount(500);
      cubit.proceedToInstructions();
      expect(cubit.state.currentStep, equals(TopUpStep.instructions));
      expect(repository.createCallCount, equals(0));
      expect(repository.submitNewCallCount, equals(0));
      expect(cubit.state.createdRequestId, isNull);
    });

    test('2. Step 2 "I Have Transferred" does not create request', () {
      cubit.setAmount(500);
      cubit.selectPaymentMethod(testMethod);
      cubit.proceedToInstructions();

      cubit.confirmTransferAndCreateRequest();

      expect(repository.createCallCount, equals(0));
      expect(repository.submitNewCallCount, equals(0));
      expect(cubit.state.createdRequestId, isNull);
      expect(cubit.state.createdPublicId, isNull);
    });

    test('3. Step 2 only navigates to Step 3 and preserves selected state locally', () {
      cubit.setAmount(500);
      cubit.selectPaymentMethod(testMethod);
      cubit.proceedToInstructions();

      cubit.proceedToDetails();

      expect(cubit.state.currentStep, equals(TopUpStep.details));
      expect(cubit.state.amount, equals(500));
      expect(cubit.state.selectedMethod, equals(testMethod));
      expect(cubit.state.receivingPhone, equals('01014045363'));
      expect(cubit.state.expectedAmountEgp, equals(500.0));
      expect(cubit.state.createdRequestId, isNull);
    });

    test('4. Screenshot upload happens only on final submit', () async {
      cubit.setAmount(500);
      cubit.selectPaymentMethod(testMethod);
      cubit.proceedToInstructions();
      cubit.proceedToDetails();

      cubit.setSenderPhone('01012345678');
      cubit.setProofImage(
        bytes: [1, 2, 3],
        extension: 'jpg',
        fileName: 'proof.jpg',
      );

      // Before submit: no upload or RPC called
      expect(repository.submitNewCallCount, equals(0));
      expect(cubit.state.createdRequestId, isNull);

      // On final submit: upload and RPC called
      await cubit.submitPaymentProof();
      expect(repository.submitNewCallCount, equals(1));
    });

    test('5. submit_new_topup_request called only after upload success', () async {
      cubit.setAmount(500);
      cubit.selectPaymentMethod(testMethod);
      cubit.proceedToInstructions();
      cubit.proceedToDetails();

      cubit.setSenderPhone('01012345678');
      cubit.setPaymentReference('REF_999');
      cubit.setProofImage(
        bytes: [1, 2, 3],
        extension: 'jpg',
        fileName: 'proof.jpg',
      );

      await cubit.submitPaymentProof();

      expect(repository.submitNewCallCount, equals(1));
      expect(repository.createCallCount, equals(0));
      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.createdRequestId, equals('new-req-999'));
      expect(cubit.state.submittedPublicId, equals('AMY-999'));
    });

    test('6. Failed upload creates no request', () async {
      repository.submitNewFailure = const ProofUploadFailedFailure(
        message: 'Storage upload failed',
      );

      cubit.setAmount(500);
      cubit.selectPaymentMethod(testMethod);
      cubit.proceedToInstructions();
      cubit.proceedToDetails();

      cubit.setSenderPhone('01012345678');
      cubit.setProofImage(
        bytes: [1, 2, 3],
        extension: 'jpg',
        fileName: 'proof.jpg',
      );

      await cubit.submitPaymentProof();

      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.proofStatus, equals(ProofUploadStatus.failed));
      expect(cubit.state.errorMessage, contains('Storage upload failed'));
      expect(cubit.state.createdRequestId, isNull);
      expect(cubit.state.currentStep, equals(TopUpStep.details));
      expect(repository.createCallCount, equals(0));
    });

    test('7. Final success returns pending_review', () async {
      cubit.setAmount(500);
      cubit.selectPaymentMethod(testMethod);
      cubit.proceedToInstructions();
      cubit.proceedToDetails();

      cubit.setSenderPhone('01012345678');
      cubit.setProofImage(
        bytes: [1, 2, 3],
        extension: 'jpg',
        fileName: 'proof.jpg',
      );

      await cubit.submitPaymentProof();

      expect(cubit.state.currentStep, equals(TopUpStep.pendingReview));
      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.submittedPublicId, equals('AMY-999'));
    });

    test('8. Back/cancel before final submit creates no request', () {
      cubit.setAmount(500);
      cubit.proceedToInstructions();
      expect(cubit.state.currentStep, equals(TopUpStep.instructions));

      cubit.proceedToDetails();
      expect(cubit.state.currentStep, equals(TopUpStep.details));

      cubit.previousStep();
      expect(cubit.state.currentStep, equals(TopUpStep.instructions));

      cubit.previousStep();
      expect(cubit.state.currentStep, equals(TopUpStep.amount));

      expect(repository.createCallCount, equals(0));
      expect(repository.submitNewCallCount, equals(0));
      expect(cubit.state.createdRequestId, isNull);
    });

    test('9. Existing rejected resubmission still works', () async {
      final rejectedRequest = TopUpRequest(
        id: 'rejected-req-123',
        publicId: 'REQ-REJECTED-001',
        userId: 'u-1',
        requestedAmount: 500,
        expectedAmountEgp: 500,
        paymentMethodCode: 'VODAFONE_CASH',
        receivingPhone: '01014045363',
        senderPhone: '01098765432',
        status: TopUpStatus.rejected,
        rejectionReason: 'Unreadable receipt',
        createdAt: DateTime(2026, 9, 13),
      );

      cubit.initWithResubmit(rejectedRequest);

      expect(cubit.state.isResubmit, isTrue);
      expect(cubit.state.createdRequestId, equals('rejected-req-123'));
      expect(cubit.state.currentStep, equals(TopUpStep.details));

      cubit.setSenderPhone('01012345678');
      cubit.setProofImage(
        bytes: [9, 8, 7],
        extension: 'png',
        fileName: 'new_proof.png',
      );

      expect(cubit.state.canSubmitDetails, isTrue);

      await cubit.submitPaymentProof();

      expect(repository.submitProofCallCount, equals(1));
      expect(repository.submitNewCallCount, equals(0));
      expect(repository.createCallCount, equals(0));
      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.currentStep, equals(TopUpStep.pendingReview));
      expect(cubit.state.submittedPublicId, equals('REQ-REJECTED-001'));
    });

    test('sender phone validation strictly enforces Egyptian format', () {
      cubit.setSenderPhone('12345');
      expect(cubit.state.isSenderPhoneValid, isFalse);

      cubit.setSenderPhone('01012345678');
      expect(cubit.state.isSenderPhoneValid, isTrue);

      cubit.setSenderPhone('201012345678');
      expect(cubit.state.isSenderPhoneValid, isTrue);
    });


    test('previousStep navigates backwards cleanly', () async {
      cubit.setAmount(500);
      cubit.proceedToInstructions();
      expect(cubit.state.currentStep, equals(TopUpStep.instructions));

      cubit.previousStep();
      expect(cubit.state.currentStep, equals(TopUpStep.amount));
    });
  });
}
