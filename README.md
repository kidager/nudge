# <img src="assets/icon.svg" width="32" height="32" alt="Nudge icon"> Nudge

[![Version](https://img.shields.io/github/v/release/kidager/nudge?label=version)](https://github.com/kidager/nudge/releases)

A minimalist Flutter app that sends periodic audio reminders — inspired by the classic Casio digital watch hourly chime. Stay mindful of time passing without constantly checking your phone.

**[Try the Web App →](https://kidager.github.io/nudge/)**

## Features

- **Configurable intervals** — Choose from 1 min, 5 min, 15 min, 30 min, or 1 hour
- **Time-aligned beeps** — Reminders sync to the clock (e.g., 15-min interval beeps at :00, :15, :30, :45)
- **Background notifications** — Works even when the app is closed (iOS & Android)
- **Android audio channels** — Choose between Alarm (bypasses silent mode) or Media channel
- **Cross-platform** — iOS, Android, and Web support
- **Material 3 design** — Clean, modern UI with light/dark theme support

## Screenshots

<!-- Add your screenshots here -->
<!--
| Light Mode | Dark Mode |
|------------|-----------|
| ![Light](screenshots/light.png) | ![Dark](screenshots/dark.png) |
-->

*Screenshots coming soon*

## Installation

### Prerequisites

- Flutter SDK ^3.10.7
- Xcode (for iOS)
- Android Studio (for Android)

### Setup

```bash
# Clone the repository
git clone https://github.com/kidager/nudge.git
cd nudge

# Install dependencies
flutter pub get

# Run on your device
flutter run
```

### Platform-specific builds

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

## How It Works

Nudge uses local notifications to deliver beeps even when the app is in the background:

1. When enabled, the app schedules up to 64 notifications (iOS limit) at calculated times
2. Beeps are aligned to clock time — a 15-minute interval will beep at :00, :15, :30, :45
3. Notifications automatically reschedule when you open the app
4. On Android, boot receivers ensure notifications persist after device restart

## Tech Stack

- **Flutter** — Cross-platform framework
- **Riverpod** — State management
- **flutter_local_notifications** — Background notifications
- **audioplayers** — In-app sound playback
- **shared_preferences** — Persistence
- **[Tolgee](https://tolgee.io)** — Localization platform

## Localization

Nudge is translated using [Tolgee](https://app.tolgee.io/projects/27166). Currently supported languages:

- English
- French
- Arabic (with RTL support)

Translations are bundled with the app in `lib/tolgee/`. To contribute translations, visit the [Tolgee project](https://app.tolgee.io/projects/27166).

## Permissions

### Android
- `POST_NOTIFICATIONS` — Display notification beeps
- `SCHEDULE_EXACT_ALARM` — Precise timing for reminders
- `RECEIVE_BOOT_COMPLETED` — Reschedule after device restart

### iOS
- Notification permission required for background beeps

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## Third-Party Dependencies

This project uses the following open-source packages:

| Package | License |
|---------|---------|
| [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | MIT |
| [audioplayers](https://pub.dev/packages/audioplayers) | MIT |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | BSD-3-Clause |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | BSD-3-Clause |
| [timezone](https://pub.dev/packages/timezone) | BSD-2-Clause |
| [flutter_timezone](https://pub.dev/packages/flutter_timezone) | MIT |
| [cupertino_icons](https://pub.dev/packages/cupertino_icons) | MIT |
| [tolgee](https://pub.dev/packages/tolgee) | MIT |
| [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | BSD-3-Clause |

## License

This project is released into the public domain under [The Unlicense](UNLICENSE).

You are free to copy, modify, publish, use, compile, sell, or distribute this software for any purpose, commercial or non-commercial, without any restrictions.

---

Built with [Claude Code](https://claude.ai/code)
