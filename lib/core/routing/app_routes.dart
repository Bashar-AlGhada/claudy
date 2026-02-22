class AppRoutes {
  static const home = '/';
  static const map = '/map';
  static const search = '/search';
  static const settings = '/settings';
  static const settingsTheme = '/settings/theme';
  static const details = '/details/:locationId';

  static String detailsFor(String locationId) => '/details/$locationId';
}
