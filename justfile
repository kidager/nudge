# Nudge - Development Commands

# List all available commands
default:
    @just --list

# Install dependencies
install:
    flutter pub get

# Run the app
run:
    flutter run

# Run the app with Tolgee API (for in-context editing)
run-tolgee:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f .env ]; then
        echo "Error: .env file not found. Copy .env.example to .env and fill in your values."
        exit 1
    fi
    source .env
    flutter run \
        --dart-define=TOLGEE_API_KEY="${TOLGEE_API_KEY}" \
        --dart-define=TOLGEE_API_URL="${TOLGEE_API_URL:-https://app.tolgee.io}"

# Run on web
run-web:
    flutter run -d chrome

# Run on web with Tolgee API
run-web-tolgee:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f .env ]; then
        echo "Error: .env file not found. Copy .env.example to .env and fill in your values."
        exit 1
    fi
    source .env
    flutter run -d chrome \
        --dart-define=TOLGEE_API_KEY="${TOLGEE_API_KEY}" \
        --dart-define=TOLGEE_API_URL="${TOLGEE_API_URL:-https://app.tolgee.io}"

# Analyze code
analyze:
    flutter analyze

# Run tests
test:
    flutter test

# Build release APK
build-apk:
    flutter build apk --release

# Build release AAB (App Bundle)
build-aab:
    flutter build appbundle --release

# Build iOS
build-ios:
    flutter build ios --release --no-codesign

# Build web
build-web:
    flutter build web --release

# ============================================
# Icons Generation
# ============================================

# Generate app icons for all platforms (requires flutter_launcher_icons)
icons:
    @echo "Generating app icons..."
    dart run flutter_launcher_icons

# Generate adaptive icon for Android from source image
# Usage: just generate-icon path/to/icon.png
generate-icon source:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v magick &> /dev/null; then
        echo "Error: ImageMagick is required. Install with: brew install imagemagick"
        exit 1
    fi

    echo "Generating icons from {{ source }}..."

    # Android icons (mipmap)
    magick "{{ source }}" -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    magick "{{ source }}" -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    magick "{{ source }}" -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    magick "{{ source }}" -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    magick "{{ source }}" -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

    # iOS icons
    magick "{{ source }}" -resize 20x20 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
    magick "{{ source }}" -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
    magick "{{ source }}" -resize 60x60 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
    magick "{{ source }}" -resize 29x29 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
    magick "{{ source }}" -resize 58x58 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
    magick "{{ source }}" -resize 87x87 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
    magick "{{ source }}" -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
    magick "{{ source }}" -resize 80x80 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
    magick "{{ source }}" -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
    magick "{{ source }}" -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
    magick "{{ source }}" -resize 180x180 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
    magick "{{ source }}" -resize 76x76 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
    magick "{{ source }}" -resize 152x152 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
    magick "{{ source }}" -resize 167x167 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
    magick "{{ source }}" -resize 1024x1024 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

    # Web icons
    magick "{{ source }}" -resize 192x192 web/icons/Icon-192.png
    magick "{{ source }}" -resize 512x512 web/icons/Icon-512.png
    magick "{{ source }}" -resize 192x192 web/icons/Icon-maskable-192.png
    magick "{{ source }}" -resize 512x512 web/icons/Icon-maskable-512.png
    magick "{{ source }}" -resize 16x16 web/favicon.png

    echo "Icons generated successfully!"

# ============================================
# Screenshots Generation
# ============================================

# Directory for store screenshots
screenshots-dir := "screenshots"

# Create screenshots directory structure
screenshots-init:
    mkdir -p {{ screenshots-dir }}/android/phone
    mkdir -p {{ screenshots-dir }}/android/tablet-7
    mkdir -p {{ screenshots-dir }}/android/tablet-10
    mkdir -p {{ screenshots-dir }}/ios/iphone-6.7
    mkdir -p {{ screenshots-dir }}/ios/iphone-6.5
    mkdir -p {{ screenshots-dir }}/ios/iphone-5.5
    mkdir -p {{ screenshots-dir }}/ios/ipad-12.9
    @echo "Screenshots directories created!"
    @echo ""
    @echo "Required sizes:"
    @echo ""
    @echo "Google Play Store:"
    @echo "  - Phone: 1080x1920 or 1080x2340 (16:9 or 19.5:9)"
    @echo "  - 7\" Tablet: 1200x1920"
    @echo "  - 10\" Tablet: 1800x2560"
    @echo ""
    @echo "App Store:"
    @echo "  - iPhone 6.7\": 1290x2796"
    @echo "  - iPhone 6.5\": 1284x2778 or 1242x2688"
    @echo "  - iPhone 5.5\": 1242x2208"
    @echo "  - iPad 12.9\": 2048x2732"

# Take screenshot on iOS Simulator
# Usage: just screenshot-ios <name>
screenshot-ios name:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p {{ screenshots-dir }}/raw
    xcrun simctl io booted screenshot "{{ screenshots-dir }}/raw/{{ name }}.png"
    echo "Screenshot saved to {{ screenshots-dir }}/raw/{{ name }}.png"

# Take screenshot on Android device (requires adb)
# Install adb: brew install android-platform-tools
# Usage: just screenshot-android <name>
screenshot-android name:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v adb &> /dev/null; then
        echo "Error: adb not found."
        echo "Install with: brew install android-platform-tools"
        exit 1
    fi

    mkdir -p {{ screenshots-dir }}/raw
    adb exec-out screencap -p > "{{ screenshots-dir }}/raw/{{ name }}.png"
    echo "Screenshot saved to {{ screenshots-dir }}/raw/{{ name }}.png"

# Take screenshot using Flutter (works on any connected device)
# Usage: just screenshot <name>
screenshot name:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p {{ screenshots-dir }}/raw

    # Check for iOS Simulator first
    if xcrun simctl list devices booted 2>/dev/null | grep -q "Booted"; then
        echo "Taking screenshot from iOS Simulator..."
        xcrun simctl io booted screenshot "{{ screenshots-dir }}/raw/{{ name }}.png"
        echo "Screenshot saved to {{ screenshots-dir }}/raw/{{ name }}.png"
    # Then check for Android via adb
    elif command -v adb &> /dev/null && adb devices | grep -q "device$"; then
        echo "Taking screenshot from Android device..."
        adb exec-out screencap -p > "{{ screenshots-dir }}/raw/{{ name }}.png"
        echo "Screenshot saved to {{ screenshots-dir }}/raw/{{ name }}.png"
    else
        echo "No device found. Options:"
        echo "  - Start an iOS Simulator"
        echo "  - Connect an Android device (install adb: brew install android-platform-tools)"
        exit 1
    fi

# Resize screenshot for Play Store phone (1080x1920)
resize-android-phone source dest:
    magick "{{ source }}" -resize 1080x1920^ -gravity center -extent 1080x1920 "{{ dest }}"

# Resize screenshot for Play Store 7" tablet (1200x1920)
resize-android-tablet-7 source dest:
    magick "{{ source }}" -resize 1200x1920^ -gravity center -extent 1200x1920 "{{ dest }}"

# Resize screenshot for Play Store 10" tablet (1800x2560)
resize-android-tablet-10 source dest:
    magick "{{ source }}" -resize 1800x2560^ -gravity center -extent 1800x2560 "{{ dest }}"

# Resize screenshot for App Store iPhone 6.7" (1290x2796)
resize-ios-67 source dest:
    magick "{{ source }}" -resize 1290x2796^ -gravity center -extent 1290x2796 "{{ dest }}"

# Resize screenshot for App Store iPhone 6.5" (1284x2778)
resize-ios-65 source dest:
    magick "{{ source }}" -resize 1284x2778^ -gravity center -extent 1284x2778 "{{ dest }}"

# Resize screenshot for App Store iPhone 5.5" (1242x2208)
resize-ios-55 source dest:
    magick "{{ source }}" -resize 1242x2208^ -gravity center -extent 1242x2208 "{{ dest }}"

# Resize screenshot for App Store iPad 12.9" (2048x2732)
resize-ios-ipad source dest:
    magick "{{ source }}" -resize 2048x2732^ -gravity center -extent 2048x2732 "{{ dest }}"

# Generate all store sizes from a single source screenshot
# Usage: just screenshots-generate path/to/screenshot.png screenshot-name
screenshots-generate source name:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v magick &> /dev/null; then
        echo "Error: ImageMagick is required. Install with: brew install imagemagick"
        exit 1
    fi

    echo "Generating store screenshots from {{ source }}..."

    # Ensure directories exist
    just screenshots-init

    # Android
    just resize-android-phone "{{ source }}" "{{ screenshots-dir }}/android/phone/{{ name }}.png"
    just resize-android-tablet-7 "{{ source }}" "{{ screenshots-dir }}/android/tablet-7/{{ name }}.png"
    just resize-android-tablet-10 "{{ source }}" "{{ screenshots-dir }}/android/tablet-10/{{ name }}.png"

    # iOS
    just resize-ios-67 "{{ source }}" "{{ screenshots-dir }}/ios/iphone-6.7/{{ name }}.png"
    just resize-ios-65 "{{ source }}" "{{ screenshots-dir }}/ios/iphone-6.5/{{ name }}.png"
    just resize-ios-55 "{{ source }}" "{{ screenshots-dir }}/ios/iphone-5.5/{{ name }}.png"
    just resize-ios-ipad "{{ source }}" "{{ screenshots-dir }}/ios/ipad-12.9/{{ name }}.png"

    echo ""
    echo "Screenshots generated in {{ screenshots-dir }}/"

# ============================================
# Feature Graphic (Play Store)
# ============================================

# Generate Play Store feature graphic (1024x500)
# Usage: just feature-graphic path/to/source.png
feature-graphic source:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v magick &> /dev/null; then
        echo "Error: ImageMagick is required. Install with: brew install imagemagick"
        exit 1
    fi

    mkdir -p {{ screenshots-dir }}/android
    magick "{{ source }}" -resize 1024x500^ -gravity center -extent 1024x500 "{{ screenshots-dir }}/android/feature-graphic.png"
    echo "Feature graphic saved to {{ screenshots-dir }}/android/feature-graphic.png"

# ============================================
# Tolgee Localization (Docker)
# ============================================

# Pull translations from Tolgee
tolgee-pull:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f .env ]; then
        echo "Error: .env file not found. Copy .env.example to .env and fill in your values."
        exit 1
    fi
    source .env
    docker run --rm \
        -v "$(pwd)/lib/tolgee:/app/output" \
        tolgee/cli \
        pull \
        --api-key "${TOLGEE_API_KEY}" \
        --api-url "${TOLGEE_API_URL:-https://app.tolgee.io}" \
        --project-id "${TOLGEE_PROJECT_ID}" \
        --path /app/output \
        --format JSON_TOLGEE
    echo "Translations pulled to lib/tolgee/"

# Push translations to Tolgee
tolgee-push:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f .env ]; then
        echo "Error: .env file not found. Copy .env.example to .env and fill in your values."
        exit 1
    fi
    source .env
    docker run --rm \
        -v "$(pwd)/lib/tolgee:/app/input" \
        tolgee/cli \
        push \
        --api-key "${TOLGEE_API_KEY}" \
        --api-url "${TOLGEE_API_URL:-https://app.tolgee.io}" \
        --project-id "${TOLGEE_PROJECT_ID}" \
        --files-template '/app/input/{languageTag}.json' \
        --format JSON_TOLGEE \
        --force-mode OVERRIDE
    echo "Translations pushed to Tolgee!"
