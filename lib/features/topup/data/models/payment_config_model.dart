import '../../domain/entities/topup_entities.dart';

class PaymentConfigModel extends PaymentConfig {
  const PaymentConfigModel({
    super.mobileCashEnabled = true,
    super.mobileCashReceiverNumber = '01000000000',
    super.egpPerPoint = 1.0,
    super.minimumTopupPoints = 200,
  });

  factory PaymentConfigModel.fromJson(Map<String, dynamic> json) {
    return PaymentConfigModel(
      mobileCashEnabled: json['mobile_cash_enabled'] as bool? ?? true,
      mobileCashReceiverNumber: json['mobile_cash_receiver_number'] as String? ?? '01000000000',
      egpPerPoint: (json['egp_per_point'] as num?)?.toDouble() ?? 1.0,
      minimumTopupPoints: (json['minimum_topup_points'] as num?)?.toInt() ?? 200,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile_cash_enabled': mobileCashEnabled,
      'mobile_cash_receiver_number': mobileCashReceiverNumber,
      'egp_per_point': egpPerPoint,
      'minimum_topup_points': minimumTopupPoints,
    };
  }
}
