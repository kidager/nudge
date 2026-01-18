import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolgee/tolgee.dart';
import 'providers/beep_provider.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Tolgee localization
  // Use API key for development (in-context editing), static mode for production
  const apiKey = String.fromEnvironment('TOLGEE_API_KEY');
  if (apiKey.isNotEmpty) {
    await Tolgee.init(
      apiKey: apiKey,
      apiUrl: const String.fromEnvironment(
        'TOLGEE_API_URL',
        defaultValue: 'https://app.tolgee.io',
      ),
    );
  } else {
    // Static mode - uses bundled translations from lib/tolgee/
    await Tolgee.init();
  }

  // Initialize notifications (required for background beeps)
  if (!kIsWeb) {
    await NotificationService.instance.initialize();
  }

  final prefs = await SharedPreferences.getInstance();

  // Initialize settings service (handles iOS Keychain backup)
  await SettingsService.instance.initialize(prefs);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const NudgeApp(),
    ),
  );
}

class NudgeApp extends ConsumerWidget {
  const NudgeApp({super.key});

  // Brand colors from icon
  static const _primaryRed = Color(0xFFE64C4C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(languageProvider);

    // Determine locale based on selection
    final locale = appLanguage.code != null ? Locale(appLanguage.code!) : null;

    return MaterialApp(
      title: 'Nudge',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: Tolgee.localizationDelegates,
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
      ],
      locale: locale, // null means follow system
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryRed,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryRed,
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleToggle(
      BuildContext context, BeepEnabledNotifier notifier) async {
    final isEnabled = ref.read(beepEnabledProvider);

    // If turning on, check if we need to show permission explanation
    if (!isEnabled && !kIsWeb) {
      final hasPermission =
          await NotificationService.instance.arePermissionsGranted();

      if (!hasPermission) {
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => TranslationWidget(
            builder: (context, tr) => AlertDialog(
              title: Text(tr('permission_dialog_title')),
              content: Text(tr('permission_dialog_message')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(tr('permission_dialog_cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(tr('permission_dialog_allow')),
                ),
              ],
            ),
          ),
        );

        if (shouldProceed != true) {
          return;
        }
      }
    }

    await notifier.toggle(permissionExplained: true);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(beepEnabledProvider);
    final beepNotifier = ref.read(beepEnabledProvider.notifier);
    final timeUntilNext = beepNotifier.timeUntilNextBeep;
    final beepInterval = ref.watch(beepIntervalProvider);

    return TranslationWidget(
      builder: (context, tr) => Scaffold(
        appBar: AppBar(
          title: Text(tr('app_name')),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          size: 96,
                          color: isEnabled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isEnabled
                              ? tr(_intervalKey(beepInterval))
                              : tr('disabled'),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                        const SizedBox(height: 32),
                        Switch.adaptive(
                          value: isEnabled,
                          onChanged: (_) => _handleToggle(context, beepNotifier),
                        ),
                        if (isEnabled) ...[
                          const SizedBox(height: 48),
                          Text(
                            tr('next_beep_in'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDuration(timeUntilNext),
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontFeatures: [
                                    const FontFeature.tabularFigures()
                                  ],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => beepNotifier.testBeep(),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(tr('test_beep')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _intervalKey(BeepInterval interval) {
    switch (interval) {
      case BeepInterval.everyMinute:
        return 'interval_every_minute';
      case BeepInterval.every5Minutes:
        return 'interval_every_5_minutes';
      case BeepInterval.every15Minutes:
        return 'interval_every_15_minutes';
      case BeepInterval.every30Minutes:
        return 'interval_every_30_minutes';
      case BeepInterval.everyHour:
        return 'interval_every_hour';
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  String _intervalKey(BeepInterval interval) {
    switch (interval) {
      case BeepInterval.everyMinute:
        return 'interval_every_minute';
      case BeepInterval.every5Minutes:
        return 'interval_every_5_minutes';
      case BeepInterval.every15Minutes:
        return 'interval_every_15_minutes';
      case BeepInterval.every30Minutes:
        return 'interval_every_30_minutes';
      case BeepInterval.everyHour:
        return 'interval_every_hour';
    }
  }

  String _languageLabel(AppLanguage lang, String Function(String) tr) {
    if (lang == AppLanguage.system) {
      return tr('language_system');
    }
    return lang.label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioChannel = ref.watch(audioChannelProvider);
    final beepInterval = ref.watch(beepIntervalProvider);
    final beepNotifier = ref.read(beepEnabledProvider.notifier);
    final appLanguage = ref.watch(languageProvider);

    return TranslationWidget(
      builder: (context, tr) => Scaffold(
        appBar: AppBar(
          title: Text(tr('settings')),
        ),
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tr('interval'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            // ignore: deprecated_member_use
            ...BeepInterval.values.map((interval) {
              return RadioListTile<BeepInterval>(
                title: Text(tr(_intervalKey(interval))),
                value: interval,
                // ignore: deprecated_member_use
                groupValue: beepInterval,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    ref.read(beepIntervalProvider.notifier).setInterval(value);
                  }
                },
              );
            }),
            if (_isAndroid) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tr('audio_channel'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              RadioListTile<AudioChannelType>(
                title: Text(tr('audio_channel_alarm')),
                subtitle: Text(tr('audio_channel_alarm_description')),
                value: AudioChannelType.alarm,
                // ignore: deprecated_member_use
                groupValue: audioChannel,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    ref.read(audioChannelProvider.notifier).setChannel(value);
                  }
                },
              ),
              RadioListTile<AudioChannelType>(
                title: Text(tr('audio_channel_media')),
                subtitle: Text(tr('audio_channel_media_description')),
                value: AudioChannelType.media,
                // ignore: deprecated_member_use
                groupValue: audioChannel,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    ref.read(audioChannelProvider.notifier).setChannel(value);
                  }
                },
              ),
            ],
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tr('language'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...AppLanguage.values.map((lang) {
              return RadioListTile<AppLanguage>(
                title: Text(_languageLabel(lang, tr)),
                value: lang,
                // ignore: deprecated_member_use
                groupValue: appLanguage,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    ref.read(languageProvider.notifier).setLanguage(value);
                  }
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: Text(tr('test_beep')),
              onTap: () => beepNotifier.testBeep(),
            ),
          ],
        ),
      ),
    );
  }
}
