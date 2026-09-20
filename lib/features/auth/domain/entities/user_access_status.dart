import 'package:equatable/equatable.dart';

class DeviceAccessResult extends Equatable {
  final bool allowed;
  final bool isBlocked;

  const DeviceAccessResult({required this.allowed, this.isBlocked = false});

  factory DeviceAccessResult.fromJson(Map<String, dynamic> json) {
    return DeviceAccessResult(
      allowed: json['allowed'] as bool? ?? true,
      isBlocked: json['is_blocked'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [allowed, isBlocked];
}

class UserAccessStatus extends Equatable {
  final bool allowed;
  final String accountStatus; // 'active', 'temporary_ban', 'permanent_ban'
  final DateTime? bannedUntil;
  final bool deviceBlocked;

  const UserAccessStatus({
    required this.allowed,
    this.accountStatus = 'active',
    this.bannedUntil,
    this.deviceBlocked = false,
  });

  bool get isTemporaryBan => accountStatus == 'temporary_ban';
  bool get isPermanentBan => accountStatus == 'permanent_ban';
  bool get isDeviceBlocked => deviceBlocked;

  factory UserAccessStatus.fromJson(Map<String, dynamic> json) {
    DateTime? banUntil;
    if (json['banned_until'] != null) {
      banUntil = DateTime.tryParse(json['banned_until'].toString());
    }
    return UserAccessStatus(
      allowed: json['allowed'] as bool? ?? true,
      accountStatus: json['account_status'] as String? ?? 'active',
      bannedUntil: banUntil,
      deviceBlocked: json['device_blocked'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    allowed,
    accountStatus,
    bannedUntil,
    deviceBlocked,
  ];
}
