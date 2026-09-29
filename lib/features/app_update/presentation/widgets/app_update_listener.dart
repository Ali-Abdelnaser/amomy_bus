import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../domain/entities/app_update_info.dart';
import '../bloc/app_update_bloc.dart';
import '../bloc/app_update_event.dart';
import '../bloc/app_update_state.dart';
import 'app_update_dialog.dart';

class AppUpdateListener extends StatefulWidget {
  final Widget child;

  const AppUpdateListener({
    super.key,
    required this.child,
  });

  @override
  State<AppUpdateListener> createState() => _AppUpdateListenerState();
}

class _AppUpdateListenerState extends State<AppUpdateListener> {
  bool _hasShownDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppUpdateBloc>().add(const CheckAppUpdateRequested());
      }
    });
  }

  Future<void> _presentUpdateDialog(AppUpdateInfo updateInfo) async {
    if (_hasShownDialog) return;
    _hasShownDialog = true;

    try {
      final router = getIt<AppRouter>().router;
      final deadline = DateTime.now().add(const Duration(milliseconds: 1500));

      // Wait for splash transition to complete so dialog isn't dismissed by context.go
      while (DateTime.now().isBefore(deadline)) {
        if (!mounted) return;
        final loc = router.state.matchedLocation;
        if (loc != RoutePaths.splash) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      // Small pause for the landing page to finish its initial build
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final targetContext = rootNavigatorKey.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await showAppUpdateDialog(
          context: targetContext,
          updateInfo: updateInfo,
        );
      }
    } catch (_) {
      // Must never crash or interrupt app flow
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppUpdateBloc, AppUpdateState>(
      listener: (context, state) {
        if (state is AppUpdateAvailableState) {
          _presentUpdateDialog(state.updateInfo);
        }
      },
      child: widget.child,
    );
  }
}
