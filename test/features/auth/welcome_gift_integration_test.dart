import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/services/device_identity_service.dart';
import 'package:amomy_bus/core/services/secure_storage_service.dart';
import 'package:amomy_bus/features/wallet/domain/entities/wallet_history_event.dart';
import 'package:amomy_bus/features/wallet/presentation/widgets/wallet_history_event_tile.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _storage = {};

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }
}

void main() {
  group('DeviceIdentityService Tests', () {
    test('generates, persists, and reuses stable device identifier via fallback', () async {
      final storage = FakeSecureStorageService();
      final service = DeviceIdentityServiceImpl(storage);

      final id1 = await service.getDeviceIdentifier();
      expect(id1.isNotEmpty, isTrue);

      // Re-invoking returns exact same identifier from storage
      final id2 = await service.getDeviceIdentifier();
      expect(id2, equals(id1));

      // Simulate app restart with new service instance over same storage
      final newService = DeviceIdentityServiceImpl(storage);
      final id3 = await newService.getDeviceIdentifier();
      expect(id3, equals(id1));
    });

    test('recovers from secure storage read exception gracefully', () async {
      final storage = FakeSecureStorageService();
      final service = DeviceIdentityServiceImpl(storage);

      final id = await service.getDeviceIdentifier();
      expect(id.isNotEmpty, isTrue);
    });
  });

  group('WalletSemanticType Serialization & Presentation Tests', () {
    test('welcome_gift and campaign_gift string conversions', () {
      expect(
        WalletSemanticType.fromString('welcome_gift'),
        equals(WalletSemanticType.welcomeGift),
      );
      expect(
        WalletSemanticType.fromString('campaign_gift'),
        equals(WalletSemanticType.campaignGift),
      );
      expect(WalletSemanticType.welcomeGift.toDbString(), equals('welcome_gift'));
      expect(WalletSemanticType.campaignGift.toDbString(), equals('campaign_gift'));
    });

    testWidgets('renders Welcome Gift and dynamic signed points correctly in EN', (tester) async {
      const event = WalletHistoryEvent(
        eventId: 'evt-welcome-1',
        semanticType: WalletSemanticType.welcomeGift,
        signedAmount: 60,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: WalletHistoryEventTile(event: event),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Gift'), findsOneWidget);
      expect(find.text('+60 PTS'), findsOneWidget);
    });

    testWidgets('renders Welcome Gift with custom backend amount (100) in AR', (tester) async {
      const event = WalletHistoryEvent(
        eventId: 'evt-welcome-2',
        semanticType: WalletSemanticType.welcomeGift,
        signedAmount: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: const Scaffold(
            body: WalletHistoryEventTile(event: event),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('هدية الترحيب'), findsOneWidget);
      expect(find.text('+100 نقطة'), findsOneWidget);
    });

    testWidgets('renders Campaign Gift correctly in EN and AR', (tester) async {
      const event = WalletHistoryEvent(
        eventId: 'evt-campaign-1',
        semanticType: WalletSemanticType.campaignGift,
        signedAmount: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: const Scaffold(
            body: WalletHistoryEventTile(event: event),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('هدية'), findsOneWidget);
      expect(find.text('+50 نقطة'), findsOneWidget);
    });
  });
}
