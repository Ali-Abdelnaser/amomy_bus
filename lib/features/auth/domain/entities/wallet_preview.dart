import 'package:equatable/equatable.dart';

/// Read-only domain representation of the user's wallet points balance.
///
/// Used exclusively for session validation to verify that the backend trigger
/// successfully initialized the wallet after signup.
class WalletPreview extends Equatable {
  final String id;
  final String userId;
  final int cashPoints;
  final int subscriptionPoints;
  final int heldPoints;

  const WalletPreview({
    required this.id,
    required this.userId,
    required this.cashPoints,
    required this.subscriptionPoints,
    this.heldPoints = 0,
  });

  int get totalPoints => cashPoints + subscriptionPoints;
  int get availablePoints =>
      ((cashPoints + subscriptionPoints) - heldPoints).clamp(0, 1000000);

  @override
  List<Object?> get props => [
    id,
    userId,
    cashPoints,
    subscriptionPoints,
    heldPoints,
  ];
}
