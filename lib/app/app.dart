import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../l10n/app_localizations.dart';
import '../core/config/app_config.dart';
import '../core/localization/app_locale_controller.dart';
import '../core/localization/localization_helpers.dart';
import '../core/theme/app_theme.dart';
import 'di/injection.dart';
import 'router/app_router.dart';

class AmomyApp extends StatelessWidget {
  const AmomyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>(),
      child: ListenableBuilder(
        listenable: AppLocaleController.instance,
        builder: (context, _) {
          final locale = AppLocaleController.instance.locale;
          return MaterialApp.router(
            title: AppConfig.instance.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(locale),
            darkTheme: AppTheme.getTheme(locale),
            themeMode: ThemeMode.system,
            routerConfig: appRouter.router,
            locale: locale,
            builder: DevicePreview.appBuilder,
            supportedLocales: LocalizationHelper.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          );
        },
      ),
    );
  }
}
