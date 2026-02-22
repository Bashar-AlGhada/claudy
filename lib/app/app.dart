import 'package:claudy/core/i18n/app_translations.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/i18n/locale_provider.dart';
import 'package:claudy/core/routing/app_router.dart';
import 'package:claudy/core/theme/theme_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class App extends StatelessWidget {
  const App({super.key, this.overrides = const []});

  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(overrides: overrides, child: const _AppView());
  }
}

class _AppView extends ConsumerWidget {
  const _AppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Locale>>(localeProvider, (_, next) {
      final value = next.valueOrNull;
      if (value == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.updateLocale(value);
      });
    });

    final locale = ref.watch(localeProvider);
    final theme = ref.watch(themeProvider);

    if (locale.isLoading || theme.isLoading) {
      return const GetMaterialApp(
        home: SizedBox.shrink(),
      );
    }

    final selectedLocale = locale.valueOrNull ?? const Locale('en');

    return GetMaterialApp.router(
      title: LocaleKeys.appTitle.tr,
      debugShowCheckedModeBanner: false,
      locale: selectedLocale,
      fallbackLocale: const Locale('en'),
      translations: AppTranslations(),
      theme: theme.valueOrNull?.materialThemeData,
      routerDelegate: AppRouter.router.routerDelegate,
      routeInformationParser: AppRouter.router.routeInformationParser,
      routeInformationProvider: AppRouter.router.routeInformationProvider,
    );
  }
}
