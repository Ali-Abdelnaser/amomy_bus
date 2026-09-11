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
    final availableBalance = (json['cached_available_balance'] as num?)?.toInt();
    final heldBalance = (json['cached_held_balance'] as num?)?.toInt();
    final cashPoints = (json['cash_points'] as num?)?.toInt() ?? availableBalance ?? 0;
    final subscriptionPoints = (json['subscription_points'] as num?)?.toInt() ?? 0;
    final heldPoints = (json['held_points'] as num?)?.toInt() ?? heldBalance ?? 0;

    return WalletPreviewModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      cashPoints: cashPoints,
      subscriptionPoints: subscriptionPoints,
      heldPoints: heldPoints,
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
