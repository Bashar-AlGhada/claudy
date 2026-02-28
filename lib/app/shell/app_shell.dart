import 'package:claudy/core/routing/app_routes.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.map)) return 1;
    if (location.startsWith(AppRoutes.search)) return 2;
    if (location.startsWith(AppRoutes.settings)) return 3;
    return 0;
  }

  static String _indexToRoute(int index) {
    return switch (index) {
      1 => AppRoutes.map,
      2 => AppRoutes.search,
      3 => AppRoutes.settings,
      _ => AppRoutes.home,
    };
  }

  @override
  Widget build(BuildContext context) {
    final index = _locationToIndex(GoRouterState.of(context).uri.toString());

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.cloud_outlined),
        selectedIcon: const Icon(Icons.cloud),
        label: LocaleKeys.navWeather.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.map_outlined),
        selectedIcon: const Icon(Icons.map),
        label: LocaleKeys.navMap.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.search),
        label: LocaleKeys.navSearch.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: LocaleKeys.navSettings.tr,
      ),
    ];

    void onSelect(int next) {
      final nextRoute = _indexToRoute(next);
      if (nextRoute != GoRouterState.of(context).uri.toString()) {
        context.go(nextRoute);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 720;
        if (!useRail) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: onSelect,
              destinations: destinations,
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: onSelect,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.cloud_outlined),
                      selectedIcon: const Icon(Icons.cloud),
                      label: Text(LocaleKeys.navWeather.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.map_outlined),
                      selectedIcon: const Icon(Icons.map),
                      label: Text(LocaleKeys.navMap.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.search),
                      label: Text(LocaleKeys.navSearch.tr),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: Text(LocaleKeys.navSettings.tr),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}
