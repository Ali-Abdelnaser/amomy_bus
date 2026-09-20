import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'secure_storage_service.dart';

abstract class DeviceIdentityService {
  /// Returns a stable opaque device identifier.
  /// Android: Prefers Settings.Secure.ANDROID_ID (stable across Clear Data & normal reinstalls).
  /// iOS: Uses Keychain-backed persisted app-scoped identifier.
  /// Fallback: Cryptographically-seeded UUID stored in secure storage.
  Future<String> getDeviceIdentifier();
}

@LazySingleton(as: DeviceIdentityService)
class DeviceIdentityServiceImpl implements DeviceIdentityService {
  static const String _storageKey = 'amomy_device_identifier';
  static const MethodChannel _platformChannel = MethodChannel(
    'com.aliabdelnaser.amomy/device_identity',
  );

  final SecureStorageService _secureStorage;
  final MethodChannel _channel;

  DeviceIdentityServiceImpl(this._secureStorage, [MethodChannel? channel])
    : _channel = channel ?? _platformChannel;

  @override
  Future<String> getDeviceIdentifier() async {
    // 1. Android: Primary stable source is OS-provided Android ID
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidId = await _channel.invokeMethod<String>('getAndroidId');
        if (androidId != null &&
            androidId.trim().isNotEmpty &&
            androidId.trim() != '9774d56d682e549c') {
          // '9774d56d682e549c' is a known Android emulator bug bugId in older OS versions
          final trimmed = androidId.trim();
          // Also persist as backup
          try {
            await _secureStorage.write(_storageKey, trimmed);
          } catch (_) {}
          return trimmed;
        }
      } catch (_) {
        // Fallback to secure storage if channel fails
      }
    }

    // 2. iOS / Generic: Read from Keychain / Secure Storage
    try {
      final existing = await _secureStorage.read(_storageKey);
      if (existing != null && existing.trim().isNotEmpty) {
        return existing.trim();
      }

      final generated = _generateOpaqueIdentifier();
      await _secureStorage.write(_storageKey, generated);
      return generated;
    } catch (_) {
      // 3. Last-resort fallback: generate in-memory pseudorandom token
      return _generateOpaqueIdentifier();
    }
  }

  /// Generates a cryptographically-seeded UUID v4 format string
  String _generateOpaqueIdentifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // Set version to 4 (0100)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122 (10xx)
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
