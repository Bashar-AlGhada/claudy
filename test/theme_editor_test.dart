import 'package:claudy/features/settings/ui/theme_editor_page.dart';
import 'package:claudy/core/theme/theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Selecting a preset persists theme preset id', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ThemeEditorPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final tiles = tester.widgetList(find.byType(RadioListTile<ThemePresetId>)).toList();
    expect(tiles.length, greaterThan(1));
    final nextPreset = (tiles[1] as RadioListTile<ThemePresetId>).value;
    expect(nextPreset, isNotNull);

    await tester.tap(find.byType(RadioListTile<ThemePresetId>).at(1));
    await tester.pump(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('settings.themePreset');
    expect(saved, nextPreset!.name);
  });
}
