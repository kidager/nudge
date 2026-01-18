import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolgee/tolgee.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

const _kBeepEnabledKey = 'beep_enabled';
const _kAudioChannelKey = 'audio_channel';
const _kBeepIntervalKey = 'beep_interval';
const _kLanguageKey = 'language';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

// ============================================================================
// Beep Interval
// ============================================================================

enum BeepInterval {
  everyMinute(Duration(minutes: 1), 'Every minute'),
  every5Minutes(Duration(minutes: 5), 'Every 5 minutes'),
  every15Minutes(Duration(minutes: 15), 'Every 15 minutes'),
  every30Minutes(Duration(minutes: 30), 'Every 30 minutes'),
  everyHour(Duration(hours: 1), 'Every hour');

  const BeepInterval(this.duration, this.label);

  final Duration duration;
  final String label;

  /// Calculate the next aligned time for this interval.
  /// E.g., for 15 minutes at 10:07, returns 10:15.
  DateTime nextAlignedTime(DateTime from) {
    final minutes = from.minute;
    final seconds = from.second;
    final intervalMinutes = duration.inMinutes;

    if (intervalMinutes >= 60) {
      // Hourly: next hour at :00
      return DateTime(from.year, from.month, from.day, from.hour + 1);
    }

    // Find next multiple of interval
    final currentSlot = minutes ~/ intervalMinutes;
    final nextSlotMinute = (currentSlot + 1) * intervalMinutes;

    if (nextSlotMinute >= 60) {
      // Rolls over to next hour
      return DateTime(from.year, from.month, from.day, from.hour + 1);
    }

    final next = DateTime(
        from.year, from.month, from.day, from.hour, nextSlotMinute);
    // If we're exactly on the mark, go to the next interval
    if (minutes == nextSlotMinute - intervalMinutes && seconds == 0) {
      return next;
    }
    return next;
  }
}

final beepIntervalProvider =
    NotifierProvider<BeepIntervalNotifier, BeepInterval>(
        BeepIntervalNotifier.new);

class BeepIntervalNotifier extends Notifier<BeepInterval> {
  @override
  BeepInterval build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final index =
        prefs.getInt(_kBeepIntervalKey) ?? BeepInterval.everyHour.index;
    return BeepInterval.values[index];
  }

  Future<void> setInterval(BeepInterval interval) async {
    await SettingsService.instance.setInt(_kBeepIntervalKey, interval.index);
    state = interval;
  }
}

// ============================================================================
// Audio Channel (Android only)
// ============================================================================

enum AudioChannelType {
  media,
  alarm,
  notification,
  ring,
}

extension AudioChannelTypeX on AudioChannelType {
  String get label {
    switch (this) {
      case AudioChannelType.media:
        return 'Media';
      case AudioChannelType.alarm:
        return 'Alarm (ignores silent mode)';
      case AudioChannelType.notification:
        return 'Notification';
      case AudioChannelType.ring:
        return 'Ring';
    }
  }

  AudioContextAndroid toAndroidContext() {
    switch (this) {
      case AudioChannelType.media:
        return AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        );
      case AudioChannelType.alarm:
        return AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        );
      case AudioChannelType.notification:
        return AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        );
      case AudioChannelType.ring:
        return AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notificationRingtone,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        );
    }
  }
}

final audioChannelProvider =
    NotifierProvider<AudioChannelNotifier, AudioChannelType>(
        AudioChannelNotifier.new);

class AudioChannelNotifier extends Notifier<AudioChannelType> {
  @override
  AudioChannelType build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final index =
        prefs.getInt(_kAudioChannelKey) ?? AudioChannelType.alarm.index;
    return AudioChannelType.values[index];
  }

  Future<void> setChannel(AudioChannelType channel) async {
    await SettingsService.instance.setInt(_kAudioChannelKey, channel.index);
    state = channel;
  }
}

// ============================================================================
// Language Selection
// ============================================================================

enum AppLanguage {
  system('System', null),
  english('English', 'en'),
  french('Français', 'fr'),
  arabic('العربية', 'ar');

  const AppLanguage(this.label, this.code);

  final String label;
  final String? code; // null means system default
}

final languageProvider =
    NotifierProvider<LanguageNotifier, AppLanguage>(LanguageNotifier.new);

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final index = prefs.getInt(_kLanguageKey) ?? AppLanguage.system.index;
    final language = AppLanguage.values[index];

    // Set initial Tolgee locale
    _updateTolgeeLocale(language);

    return language;
  }

  Future<void> setLanguage(AppLanguage language) async {
    await SettingsService.instance.setInt(_kLanguageKey, language.index);
    await _updateTolgeeLocale(language);
    state = language;
  }

  Future<void> _updateTolgeeLocale(AppLanguage language) async {
    final Locale targetLocale;

    if (language.code != null) {
      // User selected a specific language
      targetLocale = Locale(language.code!);
    } else {
      // System mode - use device locale, fallback to English
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final supportedCodes = ['en', 'fr', 'ar'];
      if (supportedCodes.contains(deviceLocale.languageCode)) {
        targetLocale = Locale(deviceLocale.languageCode);
      } else {
        targetLocale = const Locale('en');
      }
    }

    await Tolgee.setCurrentLocale(targetLocale);
  }
}

// ============================================================================
// Beep Controller
// ============================================================================

final beepEnabledProvider =
    NotifierProvider<BeepEnabledNotifier, bool>(BeepEnabledNotifier.new);

class BeepEnabledNotifier extends Notifier<bool> {
  DateTime? _nextBeepTime;
  late final AudioPlayer _audioPlayer;
  bool _permissionsGranted = false;

  @override
  bool build() {
    _audioPlayer = AudioPlayer();
    _configureAudioContext();

    // Check permission status on startup
    _checkPermissionStatus();

    final prefs = ref.watch(sharedPreferencesProvider);
    final enabled = prefs.getBool(_kBeepEnabledKey) ?? false;

    // Re-schedule notifications when interval changes
    ref.listen(beepIntervalProvider, (_, _) {
      if (state) {
        _scheduleNotifications();
      }
    });

    ref.listen(audioChannelProvider, (_, _) {
      _configureAudioContext();
      // Reschedule notifications with new channel
      if (state) {
        _scheduleNotifications();
      }
    });

    ref.onDispose(() {
      _audioPlayer.dispose();
    });

    if (enabled) {
      _scheduleNotifications();
    }

    return enabled;
  }

  Future<void> _checkPermissionStatus() async {
    if (kIsWeb) return;
    _permissionsGranted =
        await NotificationService.instance.arePermissionsGranted();
  }

  void _configureAudioContext() {
    if (!kIsWeb && Platform.isAndroid) {
      final channel = ref.read(audioChannelProvider);
      _audioPlayer.setAudioContext(
        AudioContext(android: channel.toAndroidContext()),
      );
    }
  }

  Future<bool> requestPermissions() async {
    _permissionsGranted =
        await NotificationService.instance.requestPermissions();
    return _permissionsGranted;
  }

  bool get needsPermissions => !_permissionsGranted && !kIsWeb;

  Future<void> toggle({bool permissionExplained = false}) async {
    final newValue = !state;

    if (newValue && !_permissionsGranted) {
      if (!permissionExplained && !kIsWeb) {
        // UI should show explanation dialog first
        return;
      }
      _permissionsGranted = await requestPermissions();
      if (!_permissionsGranted && !kIsWeb) {
        // Can't enable without permissions on mobile
        return;
      }
    }

    await SettingsService.instance.setBool(_kBeepEnabledKey, newValue);

    if (newValue) {
      await _scheduleNotifications();
    } else {
      await NotificationService.instance.cancelAllNotifications();
      _nextBeepTime = null;
    }

    state = newValue;
  }

  Future<void> _scheduleNotifications() async {
    final interval = ref.read(beepIntervalProvider);
    final audioChannel = ref.read(audioChannelProvider);
    final now = DateTime.now();
    _nextBeepTime = interval.nextAlignedTime(now);

    // Map AudioChannelType to NotificationAudioChannel
    final notificationChannel = audioChannel == AudioChannelType.alarm
        ? NotificationAudioChannel.alarm
        : NotificationAudioChannel.media;

    // Schedule notifications (works in background)
    await NotificationService.instance.scheduleBeepNotifications(
      interval: interval.duration,
      startFrom: _nextBeepTime!,
      audioChannel: notificationChannel,
    );
  }

  Future<void> testBeep() async {
    await _audioPlayer.play(AssetSource('beep.mp3'));
  }

  Duration get timeUntilNextBeep {
    if (_nextBeepTime == null) {
      final interval = ref.read(beepIntervalProvider);
      return interval
          .nextAlignedTime(DateTime.now())
          .difference(DateTime.now());
    }
    final remaining = _nextBeepTime!.difference(DateTime.now());
    if (remaining.isNegative) {
      // Recalculate next beep time
      final interval = ref.read(beepIntervalProvider);
      _nextBeepTime = interval.nextAlignedTime(DateTime.now());
      return _nextBeepTime!.difference(DateTime.now());
    }
    return remaining;
  }
}
