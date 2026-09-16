import 'package:equatable/equatable.dart';

enum TopUpStatus {
  awaitingPayment,
  pending,
  approved,
  rejected;

  static TopUpStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'awaiting_payment':
        return TopUpStatus.awaitingPayment;
      case 'approved':
        return TopUpStatus.approved;
      case 'rejected':
        return TopUpStatus.rejected;
      case 'pending':
      case 'pending_review':
      default:
        return TopUpStatus.pending;
    }
  }

  String get dbValue {
    switch (this) {
      case TopUpStatus.awaitingPayment:
        return 'awaiting_payment';
      case TopUpStatus.pending:
        return 'pending_review';
      case TopUpStatus.approved:
        return 'approved';
      case TopUpStatus.rejected:
        return 'rejected';
    }
  }
}

class PaymentConfig extends Equatable {
  final bool mobileCashEnabled;
  final String mobileCashReceiverNumber;
  final double egpPerPoint;
  final int minimumTopupPoints;

  const PaymentConfig({
    this.mobileCashEnabled = true,
    this.mobileCashReceiverNumber = '01000000000',
    this.egpPerPoint = 1.0,
    this.minimumTopupPoints = 200,
  });

  int calculateExpectedEgp(int points) => (points * egpPerPoint).round();

  @override
  List<Object?> get props => [
    mobileCashEnabled,
    mobileCashReceiverNumber,
    egpPerPoint,
    minimumTopupPoints,
  ];
}

class PaymentMethod extends Equatable {
  final String id;
  final String code;
  final String nameAr;
  final String nameEn;
  final String accountIdentifier;
  final String instructionsAr;
  final String instructionsEn;
  final String? iconKey;
  final bool isActive;
  final int sortOrder;

  const PaymentMethod({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.accountIdentifier,
    required this.instructionsAr,
    required this.instructionsEn,
    this.iconKey,
    required this.isActive,
    required this.sortOrder,
  });

  String localizedName(bool isArabic) => isArabic
      ? (nameAr.trim().isNotEmpty ? nameAr : nameEn)
      : (nameEn.trim().isNotEmpty ? nameEn : nameAr);
  String localizedInstructions(bool isArabic) => isArabic
      ? (instructionsAr.trim().isNotEmpty ? instructionsAr : instructionsEn)
      : (instructionsEn.trim().isNotEmpty ? instructionsEn : instructionsAr);

  @override
  List<Object?> get props => [
    id,
    code,
    nameAr,
    nameEn,
    accountIdentifier,
    instructionsAr,
    instructionsEn,
    iconKey,
    isActive,
    sortOrder,
  ];
}

class TopUpCreatedResponse extends Equatable {
  final String requestId;
  final String publicId;
  final int requestedPoints;
  final double expectedAmountEgp;
  final String receivingPhone;
  final double conversionRate;
  final TopUpStatus status;

  const TopUpCreatedResponse({
    required this.requestId,
    required this.publicId,
    required this.requestedPoints,
    required this.expectedAmountEgp,
    required this.receivingPhone,
    required this.conversionRate,
    required this.status,
  });

  @override
  List<Object?> get props => [
    requestId,
    publicId,
    requestedPoints,
    expectedAmountEgp,
    receivingPhone,
    conversionRate,
    status,
  ];
}

class TopUpRequest extends Equatable {
  final String id;
  final String? publicId;
  final String userId;
  final int requestedAmount;
  final double expectedAmountEgp;
  final double conversionRate;
  final String? receivingPhone;
  final String paymentMethodCode;
  final String? paymentReference;
  final String? senderPhone;
  final DateTime? transferredAt;
  final DateTime? submittedAt;
  final String? screenshotPath;
  final TopUpStatus status;
  final String? rejectionReason;
  final int resubmissionCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? paymentMethodNameAr;
  final String? paymentMethodNameEn;
  final String? paymentMethodIconKey;

  const TopUpRequest({
    required this.id,
    this.publicId,
    required this.userId,
    required this.requestedAmount,
    this.expectedAmountEgp = 0,
    this.conversionRate = 1.0,
    this.receivingPhone,
    required this.paymentMethodCode,
    this.paymentReference,
    this.senderPhone,
    this.transferredAt,
    this.submittedAt,
    this.screenshotPath,
    required this.status,
    this.rejectionReason,
    this.resubmissionCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.paymentMethodNameAr,
    this.paymentMethodNameEn,
    this.paymentMethodIconKey,
  });

  String get displayReference =>
      publicId != null && publicId!.isNotEmpty ? publicId! : id.substring(0, 8);

  String getLocalizedMethodName(bool isArabic) {
    if (isArabic &&
        paymentMethodNameAr != null &&
        paymentMethodNameAr!.isNotEmpty) {
      return paymentMethodNameAr!;
    }
    if (!isArabic &&
        paymentMethodNameEn != null &&
        paymentMethodNameEn!.isNotEmpty) {
      return paymentMethodNameEn!;
    }
    return paymentMethodCode;
  }

  @override
  List<Object?> get props => [
    id,
    publicId,
    userId,
    requestedAmount,
    expectedAmountEgp,
    conversionRate,
    receivingPhone,
    paymentMethodCode,
    paymentReference,
    senderPhone,
    transferredAt,
    submittedAt,
    screenshotPath,
    status,
    rejectionReason,
    resubmissionCount,
    createdAt,
    updatedAt,
    paymentMethodNameAr,
    paymentMethodNameEn,
    paymentMethodIconKey,
  ];
}
