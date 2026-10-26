import 'package:dompetektif/app/app_lock_gate.dart';
import 'package:dompetektif/app/app_router.dart';
import 'package:dompetektif/core/config/app_config.dart';
import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:dompetektif/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

class DompetektifApp extends StatefulWidget {
  const DompetektifApp({super.key});

  @override
  State<DompetektifApp> createState() => _DompetektifAppState();
}

class _DompetektifAppState extends State<DompetektifApp> {
  late final GoRouter _router = createRouter(getIt<AuthBloc>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: getIt<SettingsBloc>()),
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<SyncBloc>.value(value: getIt<SyncBloc>()),
      ],
      child: BlocBuilder<SettingsBloc, AppSettings>(
        builder: (context, settings) {
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: switch (settings.themeMode) {
              AppThemeMode.system => ThemeMode.system,
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
            },
            locale: Locale(settings.localeCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            scrollBehavior: const _CaseScrollBehavior(),
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.3,
                  ),
                ),
                child: AppLockGate(child: child ?? const SizedBox.shrink()),
              );
            },
          );
        },
      ),
    );
  }
}

class _CaseScrollBehavior extends MaterialScrollBehavior {
  const _CaseScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
