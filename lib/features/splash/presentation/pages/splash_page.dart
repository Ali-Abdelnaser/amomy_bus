import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_event.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SplashBloc>()..add(const SplashCheckRequested()),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashLoaded) {
            if (!state.status.isOnboardingCompleted) {
              context.go('/onboarding');
            } else {
              context.read<AuthBloc>().add(const AuthCheckRequested());
            }
          }
        },
        builder: (context, state) {
          if (state is SplashError) {
            return AppErrorView(
              message: state.failure.message,
              onRetry: () =>
                  context.read<SplashBloc>().add(const SplashCheckRequested()),
            );
          }

          // Matches the native iOS LaunchScreen.storyboard exactly:
          // centered AMOMY logo at 78% width on white background.
          // No extra text, version, or spinner — so the transition
          // from native launch → Flutter first frame is seamless.
          return Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final logoSize = (constraints.maxWidth * 0.78).clamp(
                  280.0,
                  420.0,
                );

                return SizedBox.square(
                  dimension: logoSize,
                  child: Image.asset(AppAssets.splash, fit: BoxFit.contain),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
