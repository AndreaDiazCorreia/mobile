import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mostro_mobile/core/app_routes.dart';
import 'package:mostro_mobile/core/app_theme.dart';
import 'package:mostro_mobile/core/deep_link_handler.dart';
import 'package:mostro_mobile/features/auth/providers/auth_notifier_provider.dart';
import 'package:mostro_mobile/generated/l10n.dart';
import 'package:mostro_mobile/features/auth/notifiers/auth_state.dart';
import 'package:mostro_mobile/services/lifecycle_manager.dart';
import 'package:mostro_mobile/shared/providers/app_init_provider.dart';
import 'package:mostro_mobile/features/settings/settings_provider.dart';
import 'package:mostro_mobile/shared/notifiers/locale_notifier.dart';
import 'package:mostro_mobile/features/walkthrough/providers/first_run_provider.dart';

class MostroApp extends ConsumerStatefulWidget {
  const MostroApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  ConsumerState<MostroApp> createState() => _MostroAppState();
}

class _MostroAppState extends ConsumerState<MostroApp> {
  GoRouter? _router;
  bool _deepLinksInitialized = false;

  @override
  void initState() {
    super.initState();
    ref.read(lifecycleManagerProvider);
  }

  @override
  void dispose() {
    // Deep link handler disposal is handled automatically by Riverpod
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initAsyncValue = ref.watch(appInitializerProvider);

    return initAsyncValue.when(
      data: (_) {
        // Initialize first run provider
        ref.watch(firstRunProvider);

        ref.listen<AuthState>(authNotifierProvider, (previous, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            if (state is AuthAuthenticated ||
                state is AuthRegistrationSuccess) {
              context.go('/');
            } else if (state is AuthUnregistered ||
                state is AuthUnauthenticated) {
              context.go('/');
            }
          });
        });

        // Watch both system locale and settings for changes
        final systemLocale = ref.watch(systemLocaleProvider);
        final settings = ref.watch(settingsProvider);

        // Initialize router if not already done
        _router ??= createRouter(ref);

        // Initialize deep links after router is created
        if (!_deepLinksInitialized && _router != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              final deepLinkHandler = ref.read(deepLinkHandlerProvider);
              deepLinkHandler.initialize(_router!);
              _deepLinksInitialized = true;
            } catch (e, stackTrace) {
              // Log the error but don't set _deepLinksInitialized to true
              // This allows retries on subsequent builds
              debugPrint('Failed to initialize deep links: $e');
              debugPrint('Stack trace: $stackTrace');
            }
          });
        }

        return MaterialApp.router(
          title: 'Mostro',
          theme: AppTheme.theme,
          darkTheme: AppTheme.theme,
          routerConfig: _router!,
          // Use language override from settings if available, otherwise let callback handle detection
          locale: settings.selectedLanguage != null
              ? Locale(settings.selectedLanguage!)
              : systemLocale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            // Use the current system locale from our provider
            final deviceLocale = locale ?? systemLocale;

            // Check for Spanish language code (es) - includes es_AR, es_ES, etc.
            if (deviceLocale.languageCode == 'es') {
              return const Locale('es');
            }

            // Check for exact match with any supported locale
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == deviceLocale.languageCode) {
                return supportedLocale;
              }
            }

            // If no match found, return Spanish as fallback
            return const Locale('es');
          },
        );
      },
      loading: () => MaterialApp(
        theme: AppTheme.theme,
        darkTheme: AppTheme.theme,
        home: Scaffold(
          backgroundColor: AppTheme.dark1,
          body: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Initialization Error: $err')),
        ),
      ),
    );
  }
}
