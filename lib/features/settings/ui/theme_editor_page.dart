import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/core/theme/theme_preset.dart';
import 'package:claudy/core/theme/theme_provider.dart';
import 'package:claudy/core/ui/app_layout.dart';
import 'package:claudy/core/ui/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class ThemeEditorPage extends ConsumerWidget {
  const ThemeEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider).asData?.value;
    if (theme == null) {
      return Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.themeTitle.tr)),
        body: SafeArea(
          child: AppConstrained(
            padding: EdgeInsets.zero,
            child: AppEmptyState(
              icon: Icons.palette_outlined,
              title: LocaleKeys.themeTitle.tr,
              body: LocaleKeys.settingsTheme.tr,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.themeTitle.tr)),
      body: SafeArea(
        child: AppConstrained(
          padding: EdgeInsets.zero,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Tokens.space16),
            children: [
              RadioGroup<ThemePresetId>(
                groupValue: theme.presetId,
                onChanged: (id) {
                  if (id == null) return;
                  ref.read(themeProvider.notifier).setPreset(id);
                },
                child: Column(
                  children: [
                    for (final preset in ThemePresets.all)
                      RadioListTile<ThemePresetId>(
                        value: preset.id,
                        title: Text(preset.labelKey.tr),
                        secondary: _ThemeSwatch(color: preset.seed),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Tokens.space8),
      ),
    );
  }
}
