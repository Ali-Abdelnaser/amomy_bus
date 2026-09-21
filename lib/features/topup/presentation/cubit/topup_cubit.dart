import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../wallet/domain/usecases/get_wallet_summary_usecase.dart';
import '../../domain/entities/topup_entities.dart';
import '../../domain/usecases/create_topup_request_usecase.dart';
import '../../domain/usecases/get_active_payment_methods_usecase.dart';
import '../../domain/usecases/get_payment_config_usecase.dart';
import '../../domain/usecases/submit_new_topup_request_usecase.dart';
import '../../domain/usecases/submit_topup_proof_usecase.dart';
import 'topup_state.dart';

@injectable
class TopUpCubit extends Cubit<TopUpState> {
  final GetPaymentConfigUseCase? _getPaymentConfigUseCase;
  final GetActivePaymentMethodsUseCase? _getActivePaymentMethodsUseCase;
  final SubmitTopUpProofUseCase? _submitTopUpProofUseCase;
  final SubmitNewTopUpRequestUseCase? _submitNewTopUpRequestUseCase;

  TopUpCubit(
    GetPaymentConfigUseCase getPaymentConfigUseCase,
    GetActivePaymentMethodsUseCase getActivePaymentMethodsUseCase,
    CreateTopUpRequestUseCase? createTopUpRequestUseCase,
    SubmitTopUpProofUseCase submitTopUpProofUseCase, {
    SubmitNewTopUpRequestUseCase? submitNewUseCase,
  }) : _getPaymentConfigUseCase = getPaymentConfigUseCase,
       _getActivePaymentMethodsUseCase = getActivePaymentMethodsUseCase,
       _submitTopUpProofUseCase = submitTopUpProofUseCase,
       _submitNewTopUpRequestUseCase = submitNewUseCase,
       super(const TopUpState());

  TopUpCubit.idle()
    : _getPaymentConfigUseCase = null,
      _getActivePaymentMethodsUseCase = null,
      _submitTopUpProofUseCase = null,
      _submitNewTopUpRequestUseCase = null,
      super(const TopUpState());

  SubmitNewTopUpRequestUseCase? get _effectiveSubmitNewTopUpRequestUseCase =>
      _submitNewTopUpRequestUseCase ??
      (getIt.isRegistered<SubmitNewTopUpRequestUseCase>()
          ? getIt<SubmitNewTopUpRequestUseCase>()
          : null);

  void initWithResubmit(TopUpRequest request) {
    emit(
      state.copyWith(
        isResubmit: true,
        currentStep: TopUpStep.details,
        createdRequestId: () => request.id,
        createdPublicId: () => request.publicId,
        amount: request.requestedAmount,
        expectedAmountEgp: request.expectedAmountEgp,
        receivingPhone: () => request.receivingPhone,
        senderPhone: request.senderPhone ?? '',
        paymentReference: request.paymentReference ?? '',
        transferredAt: () => request.transferredAt ?? DateTime.now(),
        rejectionReason: () => request.rejectionReason,
        isLoadingConfig: false,
        errorMessage: () => null,
      ),
    );
  }

  Future<void> init({int availableBalance = 0}) async {
    emit(
      state.copyWith(
        isLoadingConfig: true,
        availableBalance: availableBalance,
        errorMessage: () => null,
        transferredAt: () => DateTime.now(),
      ),
    );

    int balance = availableBalance;
    if (balance <= 0 && getIt.isRegistered<GetWalletSummaryUseCase>()) {
      try {
        final authBloc = getIt.isRegistered<AuthBloc>()
            ? getIt<AuthBloc>()
            : null;
        final currentUserId = authBloc?.state is Authenticated
            ? (authBloc!.state as Authenticated).user.id
            : null;
        if (currentUserId != null && currentUserId.isNotEmpty) {
          final summaryResult = await getIt<GetWalletSummaryUseCase>()(
            currentUserId,
          );
          summaryResult.fold(
            onSuccess: (summary) {
              balance = summary.totalAvailablePoints;
            },
            onError: (_) {},
          );
        }
      } catch (_) {}
    }

    if (_getPaymentConfigUseCase == null ||
        _getActivePaymentMethodsUseCase == null) {
      emit(state.copyWith(isLoadingConfig: false, availableBalance: balance));
      return;
    }

    // Parallel fetch config & methods
    final configFuture = _getPaymentConfigUseCase();
    final methodsFuture = _getActivePaymentMethodsUseCase();

    final configResult = await configFuture;
    final methodsResult = await methodsFuture;

    var config = const PaymentConfig();
    configResult.fold(onSuccess: (c) => config = c, onError: (_) {});

    List<PaymentMethod> methods = const [];
    methodsResult.fold(onSuccess: (m) => methods = m, onError: (_) {});

    if (methods.isEmpty) {
      methods = const [
        PaymentMethod(
          id: 'vodafone_cash_default',
          code: 'VODAFONE_CASH',
          nameAr: 'فودافون كاش',
          nameEn: 'Vodafone Cash',
          accountIdentifier: '01014045363',
          instructionsAr:
              'قم بتحويل المبلغ المطلوب إلى رقم فودافون كاش أعلاه. بعد إتمام التحويل، احتفظ برقم العملية والتقط صورة لإيصال التحويل لإرفاقها.',
          instructionsEn:
              'Transfer the required amount to the Vodafone Cash number above. After completing the transfer, keep the reference number and take a screenshot of the receipt to attach.',
          iconKey: 'vodafone_cash',
          isActive: true,
          sortOrder: 1,
        ),
        PaymentMethod(
          id: 'instapay_default',
          code: 'INSTAPAY',
          nameAr: 'إنستاباي',
          nameEn: 'InstaPay',
          accountIdentifier: '01014045363',
          instructionsAr:
              'قم بالتحويل عبر تطبيق إنستاباي إلى رقم الهاتف أو الحساب أعلاه. بعد إتمام التحويل، احتفظ برقم العملية والتقط صورة لإيصال التحويل لإرفاقها.',
          instructionsEn:
              'Transfer via the InstaPay app to the phone number or username above. After completing the transfer, keep the reference number and take a screenshot of the receipt to attach.',
          iconKey: 'instapay',
          isActive: true,
          sortOrder: 2,
        ),
      ];
    }

    final initialSelected = methods.isNotEmpty ? methods.first : null;
    final defaultAmount = config.minimumTopupPoints > 0
        ? config.minimumTopupPoints
        : 200;

    emit(
      state.copyWith(
        isLoadingConfig: false,
        availableBalance: balance,
        paymentConfig: config,
        paymentMethods: methods,
        selectedMethod: () => initialSelected,
        amount: defaultAmount,
        expectedAmountEgp: config
            .calculateExpectedEgp(defaultAmount)
            .toDouble(),
      ),
    );
  }

  void setAmount(int amount) {
    final expectedEgp = state.paymentConfig
        .calculateExpectedEgp(amount)
        .toDouble();
    emit(
      state.copyWith(
        amount: amount,
        expectedAmountEgp: expectedEgp,
        errorMessage: () => null,
      ),
    );
  }

  void selectPaymentMethod(PaymentMethod method) {
    emit(
      state.copyWith(selectedMethod: () => method, errorMessage: () => null),
    );
  }

  void proceedToInstructions() {
    if (!state.isAmountValid) {
      emit(
        state.copyWith(
          errorMessage: () =>
              'Minimum top-up is ${state.paymentConfig.minimumTopupPoints} Points.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        currentStep: TopUpStep.instructions,
        errorMessage: () => null,
      ),
    );
  }

  void proceedToDetails() {
    final method = state.selectedMethod;
    final receiving = method?.accountIdentifier.isNotEmpty == true
        ? method!.accountIdentifier
        : state.effectiveReceivingNumber;
    final expectedEgp = state.paymentConfig
        .calculateExpectedEgp(state.amount)
        .toDouble();

    emit(
      state.copyWith(
        currentStep: TopUpStep.details,
        expectedAmountEgp: expectedEgp,
        receivingPhone: () => receiving,
        errorMessage: () => null,
      ),
    );
  }

  // Alias for backward compatibility
  void confirmTransferAndCreateRequest() {
    proceedToDetails();
  }

  void setSenderPhone(String phone) {
    emit(state.copyWith(senderPhone: phone.trim(), errorMessage: () => null));
  }

  void setPaymentReference(String reference) {
    emit(
      state.copyWith(
        paymentReference: reference.trim(),
        errorMessage: () => null,
      ),
    );
  }

  void setTransferredAt(DateTime dateTime) {
    emit(
      state.copyWith(transferredAt: () => dateTime, errorMessage: () => null),
    );
  }

  void setProofImage({
    required List<int> bytes,
    required String extension,
    required String fileName,
  }) {
    emit(
      state.copyWith(
        proofBytes: () => bytes,
        proofExtension: () => extension,
        proofFileName: () => fileName,
        proofStatus: ProofUploadStatus.selected,
        errorMessage: () => null,
      ),
    );
  }

  void clearProofImage() {
    emit(
      state.copyWith(
        proofBytes: () => null,
        proofExtension: () => null,
        proofFileName: () => null,
        proofStatus: ProofUploadStatus.idle,
      ),
    );
  }

  void previousStep() {
    switch (state.currentStep) {
      case TopUpStep.amount:
        break;
      case TopUpStep.instructions:
        emit(
          state.copyWith(
            currentStep: TopUpStep.amount,
            errorMessage: () => null,
          ),
        );
        break;
      case TopUpStep.details:
        emit(
          state.copyWith(
            currentStep: TopUpStep.instructions,
            errorMessage: () => null,
          ),
        );
        break;
      case TopUpStep.pendingReview:
        break;
    }
  }

  Future<void> submitPaymentProof() async {
    if (!state.canSubmitDetails) {
      if (!state.isSenderPhoneValid) {
        emit(
          state.copyWith(
            errorMessage: () =>
                'Please enter a valid Egyptian mobile number (01XXXXXXXXX).',
          ),
        );
        return;
      }
      if (!state.isProofValid) {
        emit(
          state.copyWith(errorMessage: () => 'Payment screenshot is required.'),
        );
        return;
      }
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        proofStatus: ProofUploadStatus.uploading,
        errorMessage: () => null,
      ),
    );

    // Flow 1: Existing Rejected / Resubmission flow
    if (state.isResubmit) {
      if (_submitTopUpProofUseCase == null || state.createdRequestId == null) {
        emit(state.copyWith(isSubmitting: false));
        return;
      }

      final result = await _submitTopUpProofUseCase(
        requestId: state.createdRequestId!,
        senderPhone: state.senderPhone,
        transferReference: state.paymentReference.isNotEmpty
            ? state.paymentReference
            : null,
        transferredAt: state.transferredAt ?? DateTime.now(),
        fileBytes: state.proofBytes!,
        fileExtension: state.proofExtension ?? 'jpg',
      );

      result.fold(
        onError: (failure) {
          emit(
            state.copyWith(
              isSubmitting: false,
              proofStatus: ProofUploadStatus.failed,
              errorMessage: () => failure.message,
              errorFailure: () => failure,
            ),
          );
        },
        onSuccess: (path) {
          emit(
            state.copyWith(
              isSubmitting: false,
              isSuccess: true,
              proofStatus: ProofUploadStatus.uploaded,
              currentStep: TopUpStep.pendingReview,
              submittedPublicId: () => state.createdPublicId,
              errorMessage: () => null,
            ),
          );
        },
      );
      return;
    }

    // Flow 2: NEW Top-Up Request Flow (submit_new_topup_request)
    final useCase = _effectiveSubmitNewTopUpRequestUseCase;
    if (useCase == null) {
      emit(
        state.copyWith(
          isSubmitting: false,
          proofStatus: ProofUploadStatus.failed,
          errorMessage: () => 'Top-up service is currently unavailable.',
        ),
      );
      return;
    }

    final methodCode = state.selectedMethod?.code ?? 'VODAFONE_CASH';
    final result = await useCase(
      amount: state.amount,
      paymentMethod: methodCode,
      senderPhone: state.senderPhone,
      transferReference: state.paymentReference.isNotEmpty
          ? state.paymentReference
          : null,
      transferredAt: state.transferredAt ?? DateTime.now(),
      fileBytes: state.proofBytes!,
      fileExtension: state.proofExtension ?? 'jpg',
    );

    result.fold(
      onError: (failure) {
        emit(
          state.copyWith(
            isSubmitting: false,
            proofStatus: ProofUploadStatus.failed,
            errorMessage: () => failure.message,
            errorFailure: () => failure,
          ),
        );
      },
      onSuccess: (created) {
        emit(
          state.copyWith(
            isSubmitting: false,
            isSuccess: true,
            proofStatus: ProofUploadStatus.uploaded,
            currentStep: TopUpStep.pendingReview,
            createdRequestId: () => created.requestId,
            createdPublicId: () => created.publicId,
            submittedPublicId: () => created.publicId,
            errorMessage: () => null,
          ),
        );
      },
    );
  }
}
