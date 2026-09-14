import 'dart:convert';
import 'package:amomy_bus/core/theme/app_text_styles.dart';
import 'package:amomy_bus/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) return null;
      final key = utf8.decode(message.buffer.asUint8List());
      if (key == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage(<String, Object?>{
          'google_fonts/Tajawal-Bold.ttf': <Object?>['google_fonts/Tajawal-Bold.ttf'],
          'google_fonts/Tajawal-Medium.ttf': <Object?>['google_fonts/Tajawal-Medium.ttf'],
          'google_fonts/Tajawal-Regular.ttf': <Object?>['google_fonts/Tajawal-Regular.ttf'],
          'google_fonts/OpenSans-Bold.ttf': <Object?>['google_fonts/OpenSans-Bold.ttf'],
          'google_fonts/OpenSans-SemiBold.ttf': <Object?>['google_fonts/OpenSans-SemiBold.ttf'],
          'google_fonts/OpenSans-Medium.ttf': <Object?>['google_fonts/OpenSans-Medium.ttf'],
          'google_fonts/OpenSans-Regular.ttf': <Object?>['google_fonts/OpenSans-Regular.ttf'],
        });
      }
      if (key == 'AssetManifest.json') {
        return ByteData.sublistView(
          utf8.encode(jsonEncode(<String, dynamic>{})),
        );
      }
      if (key == 'FontManifest.json') {
        return ByteData.sublistView(
          utf8.encode(jsonEncode(<dynamic>[])),
        );
      }
      return ByteData(0).buffer.asByteData();
    });
  });

  test('AppTextStyles raw styles have valid weights', () {
    expect(AppTextStyles.rawDisplayLarge.fontWeight, FontWeight.w700);
    expect(AppTextStyles.rawHeadlineSmall.fontWeight, FontWeight.w700);
    expect(AppTextStyles.rawTitleMedium.fontWeight, FontWeight.w700);
    expect(AppTextStyles.rawBodyMedium.fontWeight, FontWeight.w400);
    expect(AppTextStyles.rawLabelLarge.fontWeight, FontWeight.w700);
    expect(AppTextStyles.rawLabelSmall.fontWeight, FontWeight.w500);
  });

  test('AppTextStyles.localized applies correct font family and maps w600 for Arabic', () {
    final arStyle = AppTextStyles.localized(
      const TextStyle(fontWeight: FontWeight.w600),
      locale: const Locale('ar'),
    );
    expect(arStyle.fontFamily, contains('Tajawal'));
    expect(arStyle.fontWeight, FontWeight.w700);

    final enStyle = AppTextStyles.localized(
      const TextStyle(fontWeight: FontWeight.w600),
      locale: const Locale('en'),
    );
    expect(enStyle.fontFamily, contains('OpenSans'));
    expect(enStyle.fontWeight, FontWeight.w600);
  });

  test('AppTextStyleExtension fluent methods work correctly', () {
    const base = TextStyle(fontSize: 14);
    final bold = base.bold(locale: const Locale('ar'));
    expect(bold.fontWeight, FontWeight.w700);
    expect(bold.fontFamily, contains('Tajawal'));

    final semiBoldAr = base.semiBold(locale: const Locale('ar'));
    expect(semiBoldAr.fontWeight, FontWeight.w700);

    final semiBoldEn = base.semiBold(locale: const Locale('en'));
    expect(semiBoldEn.fontWeight, FontWeight.w600);

    final medium = base.medium(locale: const Locale('ar'));
    expect(medium.fontWeight, FontWeight.w500);

    final regular = base.regular(locale: const Locale('ar'));
    expect(regular.fontWeight, FontWeight.w400);
  });

  test('AppTheme generates complete localized TextThemes', () {
    final arTheme = AppTheme.getTheme(const Locale('ar'));
    expect(arTheme.textTheme.bodyMedium?.fontFamily, contains('Tajawal'));
    expect(arTheme.textTheme.titleMedium?.fontFamily, contains('Tajawal'));
    expect(arTheme.textTheme.headlineSmall?.fontFamily, contains('Tajawal'));

    final enTheme = AppTheme.getTheme(const Locale('en'));
    expect(enTheme.textTheme.bodyMedium?.fontFamily, contains('OpenSans'));
    expect(enTheme.textTheme.titleMedium?.fontFamily, contains('OpenSans'));
  });
}
