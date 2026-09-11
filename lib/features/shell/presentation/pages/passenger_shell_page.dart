import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import '../widgets/nav_svg_icon.dart';

class PassengerShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const PassengerShellPage({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final navItems = [
      FloatingNavItem(
        svgType: NavSvgType.home,
        label: l10n.navHome,
      ),
      FloatingNavItem(
        svgType: NavSvgType.trip,
        label: l10n.navMyTrips,
      ),
      FloatingNavItem(
        svgType: NavSvgType.wallet,
        label: l10n.navWallet,
      ),
      FloatingNavItem(
        svgType: NavSvgType.profile,
        label: l10n.navProfile,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: FloatingBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onItemSelected: _onTap,
        items: navItems,
      ),
    );
  }
}
