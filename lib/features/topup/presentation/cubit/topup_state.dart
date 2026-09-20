import 'package:equatable/equatable.dart';
import '../../domain/entities/topup_entities.dart';

enum TopUpStep { amount, instructions, details, pendingReview }

enum ProofUploadStatus { idle, selected, uploading, uploaded, failed }

class TopUpState extends Equatable {
  final TopUpStep currentStep;
  final bool isLoadingConfig;
  final PaymentConfig paymentConfig;
  final List<PaymentMethod> paymentMethods;
  final PaymentMethod? selectedMethod;
  final int amount;
  final int availableBalance;

  // Frozen backend request
  final String? createdRequestId;
  final String? createdPublicId;
  final double expectedAmountEgp;
  final String? receivingPhone;

  // Proof submission fields
  final String senderPhone;
  final String paymentReference;
  final DateTime? transferredAt;
  final List<int>? proofBytes;
  final String? proofExtension;
  final String? proofFileName;
  final ProofUploadStatus proofStatus;

  final bool isSubmitting;
  final bool isSuccess;
  final String? submittedPublicId;
  final String? errorMessage;
  final bool isResubmit;
  final String? rejectionReason;

  const TopUpState({
    this.currentStep = TopUpStep.amount,
    this.isLoadingConfig = false,
    this.paymentConfig = const PaymentConfig(),
    this.paymentMethods = const [],
    this.selectedMethod,
    this.amount = 0,
    this.availableBalance = 0,
    this.createdRequestId,
    this.createdPublicId,
    this.expectedAmountEgp = 0,
    this.receivingPhone,
    this.senderPhone = '',
    this.paymentReference = '',
    this.transferredAt,
    this.proofBytes,
    this.proofExtension,
    this.proofFileName,
    this.proofStatus = ProofUploadStatus.idle,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.submittedPublicId,
    this.errorMessage,
    this.isResubmit = false,
    this.rejectionReason,
  });

  bool get isAmountValid => amount >= paymentConfig.minimumTopupPoints;

  bool get isSenderPhoneValid {
    final clean = senderPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final normalized = (clean.length == 12 && clean.startsWith('201'))
        ? '01${clean.substring(3)}'
        : clean;
    return RegExp(r'^01[0125][0-9]{8}$').hasMatch(normalized);
  }

  bool get isProofValid => proofBytes != null && proofBytes!.isNotEmpty;

  bool get canProceedFromAmount => isAmountValid && !isSubmitting;

  bool get canSubmitDetails {
    if (isResubmit) {
      return isSenderPhoneValid &&
          isProofValid &&
          !isSubmitting &&
          createdRequestId != null;
    }
    return isSenderPhoneValid && isProofValid && !isSubmitting;
  }

  String get effectiveReceivingNumber {
    if (receivingPhone != null && receivingPhone!.isNotEmpty) {
      return receivingPhone!;
    }
    if (selectedMethod != null &&
        selectedMethod!.accountIdentifier.isNotEmpty) {
      return selectedMethod!.accountIdentifier;
    }
    return paymentConfig.mobileCashReceiverNumber;
  }

  TopUpState copyWith({
    TopUpStep? currentStep,
    bool? isLoadingConfig,
    PaymentConfig? paymentConfig,
    List<PaymentMethod>? paymentMethods,
    PaymentMethod? Function()? selectedMethod,
    int? amount,
    int? availableBalance,
    String? Function()? createdRequestId,
    String? Function()? createdPublicId,
    double? expectedAmountEgp,
    String? Function()? receivingPhone,
    String? senderPhone,
    String? paymentReference,
    DateTime? Function()? transferredAt,
    List<int>? Function()? proofBytes,
    String? Function()? proofExtension,
    String? Function()? proofFileName,
    ProofUploadStatus? proofStatus,
    bool? isSubmitting,
    bool? isSuccess,
    String? Function()? submittedPublicId,
    String? Function()? errorMessage,
    bool? isResubmit,
    String? Function()? rejectionReason,
  }) {
    return TopUpState(
      currentStep: currentStep ?? this.currentStep,
      isLoadingConfig: isLoadingConfig ?? this.isLoadingConfig,
      paymentConfig: paymentConfig ?? this.paymentConfig,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedMethod: selectedMethod != null
          ? selectedMethod()
          : this.selectedMethod,
      amount: amount ?? this.amount,
      availableBalance: availableBalance ?? this.availableBalance,
      createdRequestId: createdRequestId != null
          ? createdRequestId()
          : this.createdRequestId,
      createdPublicId: createdPublicId != null
          ? createdPublicId()
          : this.createdPublicId,
      expectedAmountEgp: expectedAmountEgp ?? this.expectedAmountEgp,
      receivingPhone: receivingPhone != null
          ? receivingPhone()
          : this.receivingPhone,
      senderPhone: senderPhone ?? this.senderPhone,
      paymentReference: paymentReference ?? this.paymentReference,
      transferredAt: transferredAt != null
          ? transferredAt()
          : this.transferredAt,
      proofBytes: proofBytes != null ? proofBytes() : this.proofBytes,
      proofExtension: proofExtension != null
          ? proofExtension()
          : this.proofExtension,
      proofFileName: proofFileName != null
          ? proofFileName()
          : this.proofFileName,
      proofStatus: proofStatus ?? this.proofStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      submittedPublicId: submittedPublicId != null
          ? submittedPublicId()
          : this.submittedPublicId,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isResubmit: isResubmit ?? this.isResubmit,
      rejectionReason: rejectionReason != null
          ? rejectionReason()
          : this.rejectionReason,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    isLoadingConfig,
    paymentConfig,
    paymentMethods,
    selectedMethod,
    amount,
    availableBalance,
    createdRequestId,
    createdPublicId,
    expectedAmountEgp,
    receivingPhone,
    senderPhone,
    paymentReference,
    transferredAt,
    proofBytes,
    proofExtension,
    proofFileName,
    proofStatus,
    isSubmitting,
    isSuccess,
    submittedPublicId,
    errorMessage,
    isResubmit,
    rejectionReason,
  ];
}
