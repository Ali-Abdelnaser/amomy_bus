import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/topup_entities.dart';
import '../../domain/usecases/create_topup_request_usecase.dart';
import '../../domain/usecases/get_active_payment_methods_usecase.dart';
import '../../domain/usecases/upload_topup_proof_usecase.dart';
import 'topup_state.dart';

@injectable
class TopUpCubit extends Cubit<TopUpState> {
  final GetActivePaymentMethodsUseCase? _getActivePaymentMethodsUseCase;
  final CreateTopUpRequestUseCase? _createTopUpRequestUseCase;
  final UploadTopUpProofUseCase? _uploadTopUpProofUseCase;

  TopUpCubit(
    GetActivePaymentMethodsUseCase getActivePaymentMethodsUseCase,
    CreateTopUpRequestUseCase createTopUpRequestUseCase,
    UploadTopUpProofUseCase uploadTopUpProofUseCase,
  )   : _getActivePaymentMethodsUseCase = getActivePaymentMethodsUseCase,
        _createTopUpRequestUseCase = createTopUpRequestUseCase,
        _uploadTopUpProofUseCase = uploadTopUpProofUseCase,
        super(const TopUpState());

  TopUpCubit.idle()
      : _getActivePaymentMethodsUseCase = null,
        _createTopUpRequestUseCase = null,
        _uploadTopUpProofUseCase = null,
        super(const TopUpState());

  Future<void> loadPaymentMethods() async {
    if (_getActivePaymentMethodsUseCase == null) return;
    emit(state.copyWith(isLoadingMethods: true, errorMessage: () => null));

    final result = await _getActivePaymentMethodsUseCase();
    result.fold(
      onError: (failure) {
        emit(state.copyWith(
          isLoadingMethods: false,
          errorMessage: () => failure.message,
        ));
      },
      onSuccess: (methods) {
        final initialSelected = methods.isNotEmpty ? methods.first : null;
        emit(state.copyWith(
          isLoadingMethods: false,
          paymentMethods: methods,
          selectedMethod: () => initialSelected,
        ));
      },
    );
  }

  void setAmount(int amount) {
    emit(state.copyWith(
      amount: amount,
      errorMessage: () => null,
    ));
  }

  void selectPaymentMethod(PaymentMethod method) {
    emit(state.copyWith(
      selectedMethod: () => method,
      errorMessage: () => null,
    ));
  }

  void setPaymentReference(String reference) {
    emit(state.copyWith(
      paymentReference: reference.trim(),
      errorMessage: () => null,
    ));
  }

  void setProofImage({
    required List<int> bytes,
    required String extension,
    required String fileName,
  }) {
    emit(state.copyWith(
      proofBytes: () => bytes,
      proofExtension: () => extension,
      proofFileName: () => fileName,
      proofStatus: ProofUploadStatus.selected,
      errorMessage: () => null,
    ));
  }

  void clearProofImage() {
    emit(state.copyWith(
      proofBytes: () => null,
      proofExtension: () => null,
      proofFileName: () => null,
      proofStatus: ProofUploadStatus.idle,
    ));
  }

  void goToStep(TopUpStep step) {
    emit(state.copyWith(
      currentStep: step,
      errorMessage: () => null,
    ));
  }

  void nextStep() {
    switch (state.currentStep) {
      case TopUpStep.amount:
        if (state.canProceedFromAmount) {
          goToStep(TopUpStep.paymentMethod);
        }
        break;
      case TopUpStep.paymentMethod:
        if (state.canProceedFromMethod) {
          goToStep(TopUpStep.transferDetails);
        }
        break;
      case TopUpStep.transferDetails:
        if (state.canProceedFromDetails) {
          goToStep(TopUpStep.review);
        }
        break;
      case TopUpStep.review:
        submitTopUpRequest();
        break;
      case TopUpStep.pendingSuccess:
        break;
    }
  }

  void previousStep() {
    switch (state.currentStep) {
      case TopUpStep.amount:
        break;
      case TopUpStep.paymentMethod:
        goToStep(TopUpStep.amount);
        break;
      case TopUpStep.transferDetails:
        goToStep(TopUpStep.paymentMethod);
        break;
      case TopUpStep.review:
        goToStep(TopUpStep.transferDetails);
        break;
      case TopUpStep.pendingSuccess:
        break;
    }
  }

  Future<void> submitTopUpRequest() async {
    if (!state.canSubmit) return;
    if (_createTopUpRequestUseCase == null || _uploadTopUpProofUseCase == null) return;

    final amount = state.amount;
    final method = state.selectedMethod!;
    final ref = state.paymentReference;
    final proofBytes = state.proofBytes!;
    final proofExt = state.proofExtension ?? 'jpg';

    emit(state.copyWith(
      isSubmitting: true,
      proofStatus: ProofUploadStatus.uploading,
      errorMessage: () => null,
    ));

    // Step 1: Create top-up request to get requestId
    final createResult = await _createTopUpRequestUseCase(
      amount: amount,
      paymentMethodCode: method.code,
      paymentReference: ref,
    );

    await createResult.fold(
      onError: (failure) async {
        emit(state.copyWith(
          isSubmitting: false,
          proofStatus: ProofUploadStatus.failed,
          errorMessage: () => failure.message,
        ));
      },
      onSuccess: (requestId) async {
        // Step 2: Upload screenshot proof to private bucket and attach via hardened RPC
        final uploadResult = await _uploadTopUpProofUseCase(
          requestId: requestId,
          fileBytes: proofBytes,
          fileExtension: proofExt,
        );

        uploadResult.fold(
          onError: (uploadFailure) {
            emit(state.copyWith(
              isSubmitting: false,
              proofStatus: ProofUploadStatus.failed,
              errorMessage: () => uploadFailure.message,
            ));
          },
          onSuccess: (storedPath) {
            emit(state.copyWith(
              isSubmitting: false,
              isSuccess: true,
              proofStatus: ProofUploadStatus.uploaded,
              currentStep: TopUpStep.pendingSuccess,
              submittedRequestId: () => requestId,
            ));
          },
        );
      },
    );
  }
}
