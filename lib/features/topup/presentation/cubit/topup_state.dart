import 'package:equatable/equatable.dart';
import '../../domain/entities/topup_entities.dart';

enum TopUpStep {
  amount,
  paymentMethod,
  transferDetails,
  review,
  pendingSuccess,
}

enum ProofUploadStatus {
  idle,
  selected,
  uploading,
  uploaded,
  failed,
}

class TopUpState extends Equatable {
  final TopUpStep currentStep;
  final bool isLoadingMethods;
  final List<PaymentMethod> paymentMethods;
  final PaymentMethod? selectedMethod;
  final int amount;
  final String paymentReference;
  final List<int>? proofBytes;
  final String? proofExtension;
  final String? proofFileName;
  final ProofUploadStatus proofStatus;
  final bool isSubmitting;
  final bool isSuccess;
  final String? submittedRequestId;
  final String? errorMessage;

  const TopUpState({
    this.currentStep = TopUpStep.amount,
    this.isLoadingMethods = false,
    this.paymentMethods = const [],
    this.selectedMethod,
    this.amount = 0,
    this.paymentReference = '',
    this.proofBytes,
    this.proofExtension,
    this.proofFileName,
    this.proofStatus = ProofUploadStatus.idle,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.submittedRequestId,
    this.errorMessage,
  });

  bool get isAmountValid => amount > 0;
  bool get isMethodValid => selectedMethod != null;
  bool get isReferenceValid => paymentReference.trim().isNotEmpty;
  bool get isProofValid => proofBytes != null && proofBytes!.isNotEmpty;

  bool get canProceedFromAmount => isAmountValid;
  bool get canProceedFromMethod => isMethodValid;
  bool get canProceedFromDetails => isReferenceValid && isProofValid;
  bool get canSubmit => isAmountValid && isMethodValid && isReferenceValid && isProofValid && !isSubmitting;

  TopUpState copyWith({
    TopUpStep? currentStep,
    bool? isLoadingMethods,
    List<PaymentMethod>? paymentMethods,
    PaymentMethod? Function()? selectedMethod,
    int? amount,
    String? paymentReference,
    List<int>? Function()? proofBytes,
    String? Function()? proofExtension,
    String? Function()? proofFileName,
    ProofUploadStatus? proofStatus,
    bool? isSubmitting,
    bool? isSuccess,
    String? Function()? submittedRequestId,
    String? Function()? errorMessage,
  }) {
    return TopUpState(
      currentStep: currentStep ?? this.currentStep,
      isLoadingMethods: isLoadingMethods ?? this.isLoadingMethods,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedMethod: selectedMethod != null ? selectedMethod() : this.selectedMethod,
      amount: amount ?? this.amount,
      paymentReference: paymentReference ?? this.paymentReference,
      proofBytes: proofBytes != null ? proofBytes() : this.proofBytes,
      proofExtension: proofExtension != null ? proofExtension() : this.proofExtension,
      proofFileName: proofFileName != null ? proofFileName() : this.proofFileName,
      proofStatus: proofStatus ?? this.proofStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      submittedRequestId: submittedRequestId != null ? submittedRequestId() : this.submittedRequestId,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        isLoadingMethods,
        paymentMethods,
        selectedMethod,
        amount,
        paymentReference,
        proofBytes,
        proofExtension,
        proofFileName,
        proofStatus,
        isSubmitting,
        isSuccess,
        submittedRequestId,
        errorMessage,
      ];
}
