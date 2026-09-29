import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/app_update/data/models/app_update_info_model.dart';

void main() {
  group('AppUpdateInfoModel', () {
    test('parses when update is not available', () {
      final json = {
        'enabled': false,
        'force_update': false,
        'update_available': false,
      };

      final model = AppUpdateInfoModel.fromJson(json);

      expect(model.updateAvailable, isFalse);
      expect(model.forceUpdate, isFalse);
      expect(model.latestVersion, isNull);
      expect(model.storeUrl, isNull);
      expect(model.message, isNull);
    });

    test('parses optional update with all fields', () {
      final json = {
        'update_available': true,
        'force_update': false,
        'latest_version': '1.2.0',
        'latest_build': 15,
        'store_url': 'https://play.google.com/store/apps/details?id=com.amomy.passenger',
        'message': 'Bug fixes and performance improvements.',
      };

      final model = AppUpdateInfoModel.fromJson(json);

      expect(model.updateAvailable, isTrue);
      expect(model.forceUpdate, isFalse);
      expect(model.latestVersion, equals('1.2.0'));
      expect(model.latestBuild, equals(15));
      expect(
        model.storeUrl,
        equals('https://play.google.com/store/apps/details?id=com.amomy.passenger'),
      );
      expect(model.message, equals('Bug fixes and performance improvements.'));
    });

    test('parses force update with alternative field names', () {
      final json = {
        'is_update_available': true,
        'is_force_update': true,
        'version': '2.0.0',
        'build_number': '25',
        'url': 'https://apps.apple.com/app/amomy/id123456789',
        'release_notes': 'Critical security update required.',
      };

      final model = AppUpdateInfoModel.fromJson(json);

      expect(model.updateAvailable, isTrue);
      expect(model.forceUpdate, isTrue);
      expect(model.latestVersion, equals('2.0.0'));
      expect(model.latestBuild, equals(25));
      expect(
        model.storeUrl,
        equals('https://apps.apple.com/app/amomy/id123456789'),
      );
      expect(model.message, equals('Critical security update required.'));
    });

    test('handles null and invalid types safely', () {
      final json = <String, dynamic>{};

      final model = AppUpdateInfoModel.fromJson(json);

      expect(model.updateAvailable, isFalse);
      expect(model.forceUpdate, isFalse);
      expect(model.latestVersion, isNull);
      expect(model.storeUrl, isNull);
    });
  });
}
