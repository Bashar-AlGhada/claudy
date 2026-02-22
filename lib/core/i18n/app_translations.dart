import 'package:claudy/core/i18n/i18n_store.dart';
import 'package:get/get.dart';

class AppTranslations extends Translations {
  AppTranslations();

  @override
  Map<String, Map<String, String>> get keys => I18nStore.keys;
}
