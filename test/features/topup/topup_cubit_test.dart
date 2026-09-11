import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/topup/domain/entities/topup_entities.dart';
import 'package:amomy_bus/features/topup/domain/repositories/topup_repository.dart';
import 'package:amomy_bus/features/topup/domain/usecases/create_topup_request_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/get_active_payment_methods_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/upload_topup_proof_usecase.dart';
import 'package:amomy_bus/features/topup/presentation/cubit/topup_cubit.dart';
import 'package:amomy_bus/features/topup/presentation/cubit/topup_state.dart';

class FakeTopUpRepository implements TopUpRepository {
  List<PaymentMethod> methods = [];
  List<TopUpRequest> requests = [];
  String createdRequestId = 'req-123';
  String uploadedProofPath = 'user-1/req-123/proof.jpg';
  Failure? methodsFailure;
  Failure? createFailure;
  Failure? uploadFailure;
  Failure? historyFailure;

  @override
  ResultFuture<List<PaymentMethod>> getActivePaymentMethods() async {
    if (methodsFailure != null) return Error(methodsFailure!);
    return Success(methods);
  }

  @override
  ResultFuture<String> createTopUpRequest({
    required int amount,
    required String paymentMethodCode,
    required String paymentReference,
  }) async {
    if (createFailure != null) return Error(createFailure!);
    return Success(createdRequestId);
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
  ResultFuture<List<TopUpRequest>> getMyTopUpRequests() async {
    if (historyFailure != null) return Error(historyFailure!);
    return Success(requests);
  }

  @override
  Stream<void> subscribeToTopUpUpdates() => const Stream.empty();
}

void main() {
  late FakeTopUpRepository repository;
  late GetActivePaymentMethodsUseCase getActivePaymentMethodsUseCase;
  late CreateTopUpRequestUseCase createTopUpRequestUseCase;
  late UploadTopUpProofUseCase uploadTopUpProofUseCase;
  late TopUpCubit cubit;

  const testMethod = PaymentMethod(
    id: 'pm-1',
    code: 'VODAFONE_CASH',
    nameAr: 'فودافون كاش',
    nameEn: 'Vodafone Cash',
    accountIdentifier: '01000000000',
    instructionsAr: 'قم بالتحويل لرقم فودافون كاش أعلاه',
    instructionsEn: 'Transfer to Vodafone Cash number above',
    iconKey: 'vodafone_cash',
    isActive: true,
    sortOrder: 1,
  );

  setUp(() {
    repository = FakeTopUpRepository()..methods = [testMethod];
    getActivePaymentMethodsUseCase = GetActivePaymentMethodsUseCase(repository);
    createTopUpRequestUseCase = CreateTopUpRequestUseCase(repository);
    uploadTopUpProofUseCase = UploadTopUpProofUseCase(repository);
    cubit = TopUpCubit(
      getActivePaymentMethodsUseCase,
      createTopUpRequestUseCase,
      uploadTopUpProofUseCase,
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

    test('loadPaymentMethods populates methods and selects the first one', () async {
      await cubit.loadPaymentMethods();
      expect(cubit.state.paymentMethods.length, equals(1));
      expect(cubit.state.selectedMethod, equals(testMethod));
      expect(cubit.state.isLoadingMethods, isFalse);
    });

    test('loadPaymentMethods handles failure gracefully', () async {
      repository.methodsFailure = const ServerFailure(message: 'Failed to load');
      await cubit.loadPaymentMethods();
      expect(cubit.state.errorMessage, equals('Failed to load'));
      expect(cubit.state.isLoadingMethods, isFalse);
    });

    test('setAmount validates amount > 0', () {
      cubit.setAmount(0);
      expect(cubit.state.isAmountValid, isFalse);
      expect(cubit.state.canProceedFromAmount, isFalse);

      cubit.setAmount(500);
      expect(cubit.state.amount, equals(500));
      expect(cubit.state.isAmountValid, isTrue);
      expect(cubit.state.canProceedFromAmount, isTrue);
    });

    test('selectPaymentMethod updates selectedMethod', () {
      cubit.selectPaymentMethod(testMethod);
      expect(cubit.state.selectedMethod, equals(testMethod));
      expect(cubit.state.canProceedFromMethod, isTrue);
    });

    test('setPaymentReference trims input', () {
      cubit.setPaymentReference('  REF_12345  ');
      expect(cubit.state.paymentReference, equals('REF_12345'));
      expect(cubit.state.isReferenceValid, isTrue);
    });

    test('setProofImage and clearProofImage manage proof state', () {
      final bytes = [1, 2, 3, 4];
      cubit.setProofImage(bytes: bytes, extension: 'png', fileName: 'receipt.png');
      expect(cubit.state.proofBytes, equals(bytes));
      expect(cubit.state.proofExtension, equals('png'));
      expect(cubit.state.proofFileName, equals('receipt.png'));
      expect(cubit.state.proofStatus, equals(ProofUploadStatus.selected));
      expect(cubit.state.isProofValid, isTrue);

      cubit.clearProofImage();
      expect(cubit.state.proofBytes, isNull);
      expect(cubit.state.proofStatus, equals(ProofUploadStatus.idle));
      expect(cubit.state.isProofValid, isFalse);
    });

    test('nextStep and previousStep navigate flow conditionally', () {
      // Cannot advance if amount is 0
      cubit.nextStep();
      expect(cubit.state.currentStep, equals(TopUpStep.amount));

      // Advance from amount to paymentMethod
      cubit.setAmount(300);
      cubit.nextStep();
      expect(cubit.state.currentStep, equals(TopUpStep.paymentMethod));

      // Advance to transferDetails
      cubit.selectPaymentMethod(testMethod);
      cubit.nextStep();
      expect(cubit.state.currentStep, equals(TopUpStep.transferDetails));

      // Cannot advance without reference and proof
      cubit.nextStep();
      expect(cubit.state.currentStep, equals(TopUpStep.transferDetails));

      // Add reference and proof, then advance to review
      cubit.setPaymentReference('REF999');
      cubit.setProofImage(bytes: [1, 2], extension: 'jpg', fileName: 'p.jpg');
      cubit.nextStep();
      expect(cubit.state.currentStep, equals(TopUpStep.review));

      // Previous step goes back to transferDetails
      cubit.previousStep();
      expect(cubit.state.currentStep, equals(TopUpStep.transferDetails));
    });

    test('submitTopUpRequest creates request and uploads proof successfully', () async {
      cubit.setAmount(500);
      cubit.selectPaymentMethod(testMethod);
      cubit.setPaymentReference('VOD_102030');
      cubit.setProofImage(bytes: [10, 20, 30], extension: 'png', fileName: 'proof.png');
      cubit.goToStep(TopUpStep.review);

      expect(cubit.state.canSubmit, isTrue);

      await cubit.submitTopUpRequest();

      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.currentStep, equals(TopUpStep.pendingSuccess));
      expect(cubit.state.submittedRequestId, equals('req-123'));
      expect(cubit.state.proofStatus, equals(ProofUploadStatus.uploaded));
    });

    test('submitTopUpRequest maps duplicate reference error cleanly', () async {
      repository.createFailure = const DuplicatePaymentReferenceFailure();

      cubit.setAmount(500);
      cubit.selectPaymentMethod(testMethod);
      cubit.setPaymentReference('DUPLICATE_REF');
      cubit.setProofImage(bytes: [10, 20], extension: 'jpg', fileName: 'p.jpg');
      cubit.goToStep(TopUpStep.review);

      await cubit.submitTopUpRequest();

      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.proofStatus, equals(ProofUploadStatus.failed));
      expect(cubit.state.errorMessage, contains('already active or approved'));
    });

    test('submitTopUpRequest handles proof upload failure cleanly', () async {
      repository.uploadFailure = const ProofUploadFailedFailure();

      cubit.setAmount(500);
      cubit.selectPaymentMethod(testMethod);
      cubit.setPaymentReference('REF_VALID');
      cubit.setProofImage(bytes: [10, 20], extension: 'jpg', fileName: 'p.jpg');
      cubit.goToStep(TopUpStep.review);

      await cubit.submitTopUpRequest();

      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.proofStatus, equals(ProofUploadStatus.failed));
      expect(cubit.state.errorMessage, contains('Failed to upload payment proof'));
    });
  });
}
