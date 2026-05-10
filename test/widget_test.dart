import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/main.dart';
import 'package:nudge/providers/beep_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolgee/tolgee.dart';

void main() {
  setUpAll(() async {
    await Tolgee.init();
  });

  testWidgets('App renders correctly in disabled state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const NudgeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nudge'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('Interval selection works', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const NudgeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Select the 5 minute interval
    await tester.tap(find.text('Every 5 minutes'));
    await tester.pump();

    // Verify selection persisted
    final savedInterval = prefs.getInt('beep_interval');
    expect(savedInterval, BeepInterval.every5Minutes.index);
  });
}
