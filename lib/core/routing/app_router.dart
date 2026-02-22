import 'package:claudy/app/shell/app_shell.dart';
import 'package:claudy/core/routing/app_routes.dart';
import 'package:claudy/features/map/ui/map_page.dart';
import 'package:claudy/features/search/ui/search_page.dart';
import 'package:claudy/features/settings/ui/settings_page.dart';
import 'package:claudy/features/settings/ui/theme_editor_page.dart';
import 'package:claudy/features/weather/ui/weather_home_page.dart';
import 'package:claudy/features/weather/ui/weather_details_page.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const WeatherHomePage(),
          ),
          GoRoute(
            path: AppRoutes.map,
            builder: (context, state) => const MapPage(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.settingsTheme,
            builder: (context, state) => const ThemeEditorPage(),
          ),
          GoRoute(
            path: AppRoutes.details,
            builder: (context, state) => const WeatherDetailsPage(),
          ),
        ],
      ),
    ],
  );
}
