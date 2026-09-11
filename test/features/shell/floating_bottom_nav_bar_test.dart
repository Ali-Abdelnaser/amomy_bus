import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/core/theme/app_colors.dart';
import 'package:amomy_bus/features/shell/presentation/widgets/floating_bottom_nav_bar.dart';
import 'package:amomy_bus/features/shell/presentation/widgets/nav_svg_icon.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

void main() {
  final englishNavItems = const [
    FloatingNavItem(svgType: NavSvgType.home, label: 'Home'),
    FloatingNavItem(svgType: NavSvgType.trip, label: 'My Trips'),
    FloatingNavItem(svgType: NavSvgType.wallet, label: 'Wallet'),
    FloatingNavItem(svgType: NavSvgType.profile, label: 'Profile'),
  ];

  final arabicNavItems = const [
    FloatingNavItem(svgType: NavSvgType.home, label: 'الرئيسية'),
    FloatingNavItem(svgType: NavSvgType.trip, label: 'رحلاتي'),
    FloatingNavItem(svgType: NavSvgType.wallet, label: 'المحفظة'),
    FloatingNavItem(svgType: NavSvgType.profile, label: 'حسابي'),
  ];

  Widget buildTestableNavBar({
    required int selectedIndex,
    required ValueChanged<int> onItemSelected,
    List<FloatingNavItem>? items,
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
    EdgeInsets padding = const EdgeInsets.only(bottom: 34),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: padding,
        ),
        child: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: FloatingBottomNavBar(
            selectedIndex: selectedIndex,
            onItemSelected: onItemSelected,
            items: items ?? englishNavItems,
          ),
        ),
      ),
    );
  }

  group('FloatingBottomNavBar Redesign Tests', () {
    testWidgets('renders all 4 tabs and initial selected tab as active pill', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        buildTestableNavBar(
          selectedIndex: selected,
          onItemSelected: (idx) => selected = idx,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingBottomNavBar), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('My Trips'), findsWidgets);
      expect(find.text('Wallet'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);

      // Verify all 4 keys exist and are tappable
      for (int i = 0; i < 4; i++) {
        expect(find.byKey(ValueKey('floating_nav_item_$i')), findsOneWidget);
      }
    });

    testWidgets('switching tabs updates active pill and triggers callback', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestableNavBar(
              selectedIndex: selected,
              onItemSelected: (idx) {
                setState(() => selected = idx);
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap Trips (index 1)
      await tester.tap(find.byKey(const ValueKey('floating_nav_item_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(selected, 1);

      // Tap Wallet (index 2)
      await tester.tap(find.byKey(const ValueKey('floating_nav_item_2')));
      await tester.pumpAndSettle();
      expect(selected, 2);

      // Tap Profile (index 3)
      await tester.tap(find.byKey(const ValueKey('floating_nav_item_3')));
      await tester.pumpAndSettle();
      expect(selected, 3);

      // Tap Home back (index 0)
      await tester.tap(find.byKey(const ValueKey('floating_nav_item_0')));
      await tester.pumpAndSettle();
      expect(selected, 0);
    });

    testWidgets('supports rapid tab switching without exceptions or state corruption', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestableNavBar(
              selectedIndex: selected,
              onItemSelected: (idx) => setState(() => selected = idx),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap 1, then immediately 2, then 3 mid-animation
      await tester.tap(find.byKey(const ValueKey('floating_nav_item_1')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const ValueKey('floating_nav_item_2')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const ValueKey('floating_nav_item_3')));
      await tester.pumpAndSettle();

      expect(selected, 3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Arabic RTL seamlessly with localized labels', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        buildTestableNavBar(
          selectedIndex: selected,
          onItemSelected: (idx) => selected = idx,
          items: arabicNavItems,
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الرئيسية'), findsWidgets);
      expect(find.text('رحلاتي'), findsWidgets);
      expect(find.text('المحفظة'), findsWidgets);
      expect(find.text('حسابي'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('floating_nav_item_1')));
      await tester.pumpAndSettle();
      expect(selected, 1);
    });

    testWidgets('fits small screen (320dp width) without overflow', (tester) async {
      await tester.pumpWidget(
        buildTestableNavBar(
          selectedIndex: 0,
          onItemSelected: (_) {},
          size: const Size(320, 600),
          padding: EdgeInsets.zero,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingBottomNavBar), findsOneWidget);
    });

    testWidgets('respects iPhone safe area bottom inset', (tester) async {
      await tester.pumpWidget(
        buildTestableNavBar(
          selectedIndex: 0,
          onItemSelected: (_) {},
          size: const Size(393, 852),
          padding: const EdgeInsets.only(bottom: 34),
        ),
      );
      await tester.pumpAndSettle();

      final paddingFinder = find.byType(Padding).first;
      final paddingWidget = tester.widget<Padding>(paddingFinder);
      // bottom margin should be bottomPadding (34) + 8 = 42
      expect((paddingWidget.padding as EdgeInsets).bottom, 42.0);
    });

    testWidgets('active pill uses AMOMY primary brand color', (tester) async {
      await tester.pumpWidget(
        buildTestableNavBar(
          selectedIndex: 0,
          onItemSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasPrimaryColor = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == AppColors.primary;
      });
      expect(hasPrimaryColor, isTrue);
    });
  });
}
