import '../../domain/entities/topup_entities.dart';

class TopUpRequestModel extends TopUpRequest {
  const TopUpRequestModel({
    required super.id,
    super.publicId,
    required super.userId,
    required super.requestedAmount,
    super.expectedAmountEgp = 0,
    super.conversionRate = 1.0,
    super.receivingPhone,
    required super.paymentMethodCode,
    super.paymentReference,
    super.senderPhone,
    super.transferredAt,
    super.submittedAt,
    super.screenshotPath,
    required super.status,
    super.rejectionReason,
    super.resubmissionCount = 0,
    required super.createdAt,
    super.updatedAt,
    super.paymentMethodNameAr,
    super.paymentMethodNameEn,
    super.paymentMethodIconKey,
  });

  factory TopUpRequestModel.fromJson(Map<String, dynamic> json) {
    return TopUpRequestModel(
      id: json['id'] as String,
      publicId: json['public_id'] as String?,
      userId: json['user_id'] as String? ?? '',
      requestedAmount: (json['requested_amount'] as num?)?.toInt() ?? 0,
      expectedAmountEgp:
          (json['expected_amount_egp'] as num?)?.toDouble() ??
          ((json['requested_amount'] as num?)?.toDouble() ?? 0.0),
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 1.0,
      receivingPhone: json['receiving_phone'] as String?,
      paymentMethodCode: json['payment_method'] as String? ?? '',
      paymentReference: json['payment_reference'] as String?,
      senderPhone: json['sender_phone'] as String?,
      transferredAt: json['transferred_at'] != null
          ? DateTime.parse(json['transferred_at'] as String)
          : null,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      screenshotPath: json['screenshot_path'] as String?,
      status: TopUpStatus.fromString(json['status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      resubmissionCount: (json['resubmission_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      paymentMethodNameAr: json['payment_method_name_ar'] as String?,
      paymentMethodNameEn: json['payment_method_name_en'] as String?,
      paymentMethodIconKey: json['payment_method_icon_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'public_id': publicId,
      'user_id': userId,
      'requested_amount': requestedAmount,
      'expected_amount_egp': expectedAmountEgp,
      'conversion_rate': conversionRate,
      'receiving_phone': receivingPhone,
      'payment_method': paymentMethodCode,
      'payment_reference': paymentReference,
      'sender_phone': senderPhone,
      'transferred_at': transferredAt?.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'screenshot_path': screenshotPath,
      'status': status.dbValue,
      'rejection_reason': rejectionReason,
      'resubmission_count': resubmissionCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'payment_method_name_ar': paymentMethodNameAr,
      'payment_method_name_en': paymentMethodNameEn,
      'payment_method_icon_key': paymentMethodIconKey,
    };
  }
}
