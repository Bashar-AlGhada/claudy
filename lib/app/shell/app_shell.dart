import 'package:claudy/core/routing/app_routes.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/core/ui/floating_nav_bar.dart';
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

    final floatingNavItems = [
      FloatingNavBarItem(
        icon: Icons.cloud_outlined,
        selectedIcon: Icons.cloud,
        label: LocaleKeys.navWeather.tr,
      ),
      FloatingNavBarItem(
        icon: Icons.map_outlined,
        selectedIcon: Icons.map,
        label: LocaleKeys.navMap.tr,
      ),
      FloatingNavBarItem(
        icon: Icons.search,
        label: LocaleKeys.navSearch.tr,
      ),
      FloatingNavBarItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: LocaleKeys.navSettings.tr,
      ),
    ];

    void onSelect(int next) {
      final nextRoute = _indexToRoute(next);
      if (nextRoute != GoRouterState.of(context).uri.toString()) {
        context.go(nextRoute);
      }
    }

    // Bottom padding to prevent content from being hidden behind the nav bar.
    const floatingNavBarTotalHeight = Tokens.floatingNavBarHeight +
        Tokens.floatingNavBarMargin * 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 720;
        if (!useRail) {
          return Scaffold(
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: floatingNavBarTotalHeight,
                  ),
                  child: child,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: FloatingNavBar(
                      items: floatingNavItems,
                      selectedIndex: index,
                      onItemSelected: onSelect,
                    ),
                  ),
                ),
              ],
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
