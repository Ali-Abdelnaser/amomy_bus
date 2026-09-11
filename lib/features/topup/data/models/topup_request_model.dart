import '../../domain/entities/topup_entities.dart';

class TopUpRequestModel extends TopUpRequest {
  const TopUpRequestModel({
    required super.id,
    required super.userId,
    required super.requestedAmount,
    required super.paymentMethodCode,
    super.paymentReference,
    super.screenshotPath,
    required super.status,
    super.rejectionReason,
    required super.createdAt,
    super.updatedAt,
    super.paymentMethodNameAr,
    super.paymentMethodNameEn,
    super.paymentMethodIconKey,
  });

  factory TopUpRequestModel.fromJson(Map<String, dynamic> json) {
    return TopUpRequestModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      requestedAmount: (json['requested_amount'] as num?)?.toInt() ?? 0,
      paymentMethodCode: json['payment_method'] as String? ?? '',
      paymentReference: json['payment_reference'] as String?,
      screenshotPath: json['screenshot_path'] as String?,
      status: TopUpStatus.fromString(json['status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
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
      'user_id': userId,
      'requested_amount': requestedAmount,
      'payment_method': paymentMethodCode,
      'payment_reference': paymentReference,
      'screenshot_path': screenshotPath,
      'status': status.dbValue,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'payment_method_name_ar': paymentMethodNameAr,
      'payment_method_name_en': paymentMethodNameEn,
      'payment_method_icon_key': paymentMethodIconKey,
    };
  }
}
