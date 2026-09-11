import '../../domain/entities/wallet_preview.dart';

class WalletPreviewModel extends WalletPreview {
  const WalletPreviewModel({
    required super.id,
    required super.userId,
    required super.cashPoints,
    required super.subscriptionPoints,
    super.heldPoints = 0,
  });

  factory WalletPreviewModel.fromJson(Map<String, dynamic> json) {
    return WalletPreviewModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      cashPoints: (json['cash_points'] as num?)?.toInt() ?? 0,
      subscriptionPoints: (json['subscription_points'] as num?)?.toInt() ?? 0,
      heldPoints: (json['held_points'] as num?)?.toInt() ?? 0,
    );
  }

  WalletPreview toEntity() {
    return WalletPreview(
      id: id,
      userId: userId,
      cashPoints: cashPoints,
      subscriptionPoints: subscriptionPoints,
      heldPoints: heldPoints,
    );
  }
}
