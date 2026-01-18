import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/main.dart';
import 'package:nudge/providers/beep_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App renders correctly in disabled state', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const NudgeApp(),
      ),
    );

    // Verify initial state shows disabled
    expect(find.text('Disabled'), findsOneWidget);
    expect(find.text('Nudge'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // Verify interval chips are shown
    expect(find.text('1 min'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('1 hour'), findsOneWidget);
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

    // Tap on 5 min interval
    await tester.tap(find.text('5 min'));
    await tester.pump();

    // Verify selection persisted
    final savedInterval = prefs.getInt('beep_interval');
    expect(savedInterval, BeepInterval.every5Minutes.index);
  });
}
