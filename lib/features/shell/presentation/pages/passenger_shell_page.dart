import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
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

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userId = authState is Authenticated ? authState.user.id : '';

        return BlocProvider<WalletCubit>(
          create: (context) => getIt.isRegistered<WalletCubit>()
              ? (getIt<WalletCubit>()..loadWalletSummary(userId))
              : WalletCubit.idle(),
          child: Scaffold(
            extendBody: true,
            body: navigationShell,
            bottomNavigationBar: FloatingBottomNavBar(
              selectedIndex: navigationShell.currentIndex,
              onItemSelected: _onTap,
              items: navItems,
            ),
          ),
        );
      },
    );
  }
}
