import '../../domain/entities/topup_entities.dart';

class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.code,
    required super.nameAr,
    required super.nameEn,
    required super.accountIdentifier,
    required super.instructionsAr,
    required super.instructionsEn,
    super.iconKey,
    required super.isActive,
    required super.sortOrder,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      code: json['code'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      accountIdentifier: json['account_identifier'] as String? ?? '',
      instructionsAr: json['instructions_ar'] as String? ?? '',
      instructionsEn: json['instructions_en'] as String? ?? '',
      iconKey: json['icon_key'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name_ar': nameAr,
      'name_en': nameEn,
      'account_identifier': accountIdentifier,
      'instructions_ar': instructionsAr,
      'instructions_en': instructionsEn,
      'icon_key': iconKey,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}
