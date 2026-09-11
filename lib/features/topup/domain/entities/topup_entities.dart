import 'package:equatable/equatable.dart';

enum TopUpStatus {
  pending,
  approved,
  rejected;

  static TopUpStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return TopUpStatus.approved;
      case 'rejected':
        return TopUpStatus.rejected;
      case 'pending':
      default:
        return TopUpStatus.pending;
    }
  }

  String get dbValue => name;
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

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;
  String localizedInstructions(bool isArabic) => isArabic ? instructionsAr : instructionsEn;

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

class TopUpRequest extends Equatable {
  final String id;
  final String userId;
  final int requestedAmount;
  final String paymentMethodCode;
  final String? paymentReference;
  final String? screenshotPath;
  final TopUpStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? paymentMethodNameAr;
  final String? paymentMethodNameEn;
  final String? paymentMethodIconKey;

  const TopUpRequest({
    required this.id,
    required this.userId,
    required this.requestedAmount,
    required this.paymentMethodCode,
    this.paymentReference,
    this.screenshotPath,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.paymentMethodNameAr,
    this.paymentMethodNameEn,
    this.paymentMethodIconKey,
  });

  String getLocalizedMethodName(bool isArabic) {
    if (isArabic && paymentMethodNameAr != null && paymentMethodNameAr!.isNotEmpty) {
      return paymentMethodNameAr!;
    }
    if (!isArabic && paymentMethodNameEn != null && paymentMethodNameEn!.isNotEmpty) {
      return paymentMethodNameEn!;
    }
    return paymentMethodCode;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        requestedAmount,
        paymentMethodCode,
        paymentReference,
        screenshotPath,
        status,
        rejectionReason,
        createdAt,
        updatedAt,
        paymentMethodNameAr,
        paymentMethodNameEn,
        paymentMethodIconKey,
      ];
}
