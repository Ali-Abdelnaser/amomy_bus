import 'dart:io';
import 'package:amomy_bus/core/assets/app_assets.dart';
import 'package:amomy_bus/core/theme/app_colors.dart';
import 'package:amomy_bus/core/widgets/amomy_bus_icon.dart';
import 'package:amomy_bus/core/widgets/amomy_bus_loading.dart';
import 'package:amomy_bus/core/widgets/app_empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transportation Assets Integrity Tests', () {
    test('All organized illustration and animation assets exist on disk', () {
      final assets = [
        AppAssets.busSvg,
        AppAssets.busLoadingGif,
        AppAssets.busServiceIllustration,
        AppAssets.emptyNoRoutes,
        AppAssets.emptyNoTripsToday,
        AppAssets.bookingSuccess,
        AppAssets.emptyUpcomingTrip,
        AppAssets.tripHistoryEmpty,
        AppAssets.trackingPlaceholder,
      ];

      for (final assetPath in assets) {
        final file = File(assetPath);
        expect(file.existsSync(), isTrue, reason: 'Asset missing: $assetPath');
        expect(file.lengthSync(), greaterThan(0), reason: 'Asset empty: $assetPath');
      }
    });

    test('Old vague filenames no longer exist in root assets', () {
      final oldFilenames = [
        'assets/city bus-rafiki.png',
        'assets/Bus Stop-rafiki.png',
        'assets/double decker bus-rafiki.png',
        'assets/city bus-pana.png',
        'assets/city bus-cuate.png',
        'assets/city bus-amico.png',
        'assets/city bus-bro.png',
      ];

      for (final oldPath in oldFilenames) {
        expect(File(oldPath).existsSync(), isFalse, reason: 'Old asset should have been moved: $oldPath');
      }
    });
  });

  group('AmomyBusIcon Widget Tests', () {
    testWidgets('renders AmomyBusIcon with specified size and custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AmomyBusIcon(
                size: 36,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(AmomyBusIcon);
      expect(iconFinder, findsOneWidget);

      final customPaintFinder = find.descendant(
        of: iconFinder,
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: iconFinder, matching: find.byType(SizedBox)),
      );
      expect(sizedBox.width, 36);
      expect(sizedBox.height, closeTo(36 / AmomyBusIcon.aspectRatio, 0.1));
    });

    testWidgets('renders AmomyBusIcon with explicit width, height and opacity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AmomyBusIcon(
                width: 140,
                height: 100,
                opacity: 0.85,
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(AmomyBusIcon);
      expect(iconFinder, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: iconFinder, matching: find.byType(SizedBox)),
      );
      expect(sizedBox.width, 140);
      expect(sizedBox.height, 100);

      final opacityWidget = tester.widget<Opacity>(
        find.descendant(of: iconFinder, matching: find.byType(Opacity)),
      );
      expect(opacityWidget.opacity, 0.85);
    });
  });

  group('AmomyBusLoading Widget Tests', () {
    testWidgets('renders AmomyBusLoading medium with optional message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmomyBusLoading.medium(
              message: 'Loading trips...',
            ),
          ),
        ),
      );

      expect(find.byType(AmomyBusLoading), findsOneWidget);
      expect(find.text('Loading trips...'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.width, 80);
      expect(imageWidget.height, 60);
    });

    testWidgets('renders AmomyBusLoading small and large sizes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AmomyBusLoading.small(),
                AmomyBusLoading.large(),
              ],
            ),
          ),
        ),
      );

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.length, 2);
      expect(images[0].width, 48);
      expect(images[0].height, 36);
      expect(images[1].width, 120);
      expect(images[1].height, 90);
    });
  });

  group('AppEmptyView with Illustration Tests', () {
    testWidgets('renders AppEmptyView with illustrationPath', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyView(
              illustrationPath: AppAssets.emptyUpcomingTrip,
              message: 'No upcoming trip found',
            ),
          ),
        ),
      );

      expect(find.text('No upcoming trip found'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      final img = tester.widget<Image>(find.byType(Image));
      expect(img.height, 140.0);
    });
  });
}
