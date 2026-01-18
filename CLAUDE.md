# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Nudge** is a Flutter app (iOS, Android, Web) that provides periodic audio reminders inspired by classic Casio digital watches. Features configurable intervals (1 min to 1 hour) with time-aligned beeps that work even when the app is closed.

## Commands

```bash
# Install dependencies
flutter pub get

# Run on connected device/simulator
flutter run

# Run on specific platform
flutter run -d chrome          # Web
flutter run -d ios             # iOS Simulator
flutter run -d android         # Android Emulator

# Analyze code
flutter analyze

# Run tests
flutter test

# Build for release
flutter build apk              # Android
flutter build ios              # iOS
flutter build web              # Web
```

## Architecture

### State Management: Riverpod 3.x

The app uses `flutter_riverpod` with the Notifier pattern. Key providers in `lib/providers/`:

- `sharedPreferencesProvider` - Overridden at app startup in `main.dart`
- `beepEnabledProvider` - Controls the beep toggle and schedules notifications
- `beepIntervalProvider` - Configurable interval (1min, 5min, 15min, 30min, 1hr)
- `audioChannelProvider` - Android-only audio channel selection (alarm vs media)

### Background Notifications

Uses `flutter_local_notifications` to schedule beeps that work when the app is closed:

- `lib/services/notification_service.dart` - Handles notification scheduling
- Schedules up to 64 notifications at a time (iOS limit)
- Custom beep sound configured per platform
- Reschedules on boot (Android) via `ScheduledNotificationBootReceiver`

### Interval Alignment

Beeps are aligned to clock time (e.g., 15-minute interval beeps at :00, :15, :30, :45). The `BeepInterval.nextAlignedTime()` method calculates the next aligned time from any given moment.

### Audio Playback

- **In-app testing**: Uses `audioplayers` package
- **Background**: Uses notification sound (platform-specific)
- On Android, the notification channel uses alarm priority to bypass silent mode

### Persistence

`shared_preferences` for storing toggle states and settings.

## Key Files

- `lib/main.dart` - App entry point, notification init, HomeScreen UI
- `lib/providers/beep_provider.dart` - State management and business logic
- `lib/services/notification_service.dart` - Background notification scheduling
- `assets/beep.mp3` - In-app test sound
- `android/app/src/main/res/raw/beep.mp3` - Android notification sound
- `ios/Runner/Sounds/beep.aiff` - iOS notification sound

## Platform-Specific Notes

### Android
- Audio channel selector available (Alarm/Media)
- Notifications play even in silent mode (alarm channel)
- Requires permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`
- Package: `ch.jacem.nudge`

### iOS
- Custom notification sound (beep.aiff)
- Limited to 64 pending notifications (auto-reschedules when app opens)
- Bundle ID: `ch.jacem.nudge`

### Web
- No background support (notifications not available)
- Falls back to in-app timer (only works while tab is active)

## Future Development

Planned features (when implementing, add new providers following existing patterns):
- Smart reminders and scheduling
- Todo list with auto-generated tasks
