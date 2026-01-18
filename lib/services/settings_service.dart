import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings service that persists data across reinstalls.
/// - Android: Uses Auto Backup to Google Drive
/// - iOS: Uses Keychain via flutter_secure_storage
class SettingsService {
  static final SettingsService _instance = SettingsService._();
  static SettingsService get instance => _instance;

  SettingsService._();

  late SharedPreferences _prefs;
  FlutterSecureStorage? _secureStorage;

  // Keys
  static const _kBeepEnabledKey = 'beep_enabled';
  static const _kAudioChannelKey = 'audio_channel';
  static const _kBeepIntervalKey = 'beep_interval';

  static const _allKeys = [
    _kBeepEnabledKey,
    _kAudioChannelKey,
    _kBeepIntervalKey,
  ];

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;

    // iOS: Use Keychain for persistence across reinstalls
    if (!kIsWeb && Platform.isIOS) {
      _secureStorage = const FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

      // Restore from Keychain if SharedPreferences is empty (fresh install)
      await _restoreFromSecureStorage();
    }
  }

  Future<void> _restoreFromSecureStorage() async {
    if (_secureStorage == null) return;

    // Check if this looks like a fresh install (no settings in SharedPreferences)
    final hasSettings = _prefs.containsKey(_kBeepEnabledKey) ||
        _prefs.containsKey(_kAudioChannelKey) ||
        _prefs.containsKey(_kBeepIntervalKey);

    if (hasSettings) return; // Already have settings, don't overwrite

    // Try to restore each key from secure storage
    for (final key in _allKeys) {
      final value = await _secureStorage!.read(key: key);
      if (value != null) {
        // Determine type and restore
        if (value == 'true' || value == 'false') {
          await _prefs.setBool(key, value == 'true');
        } else {
          final intValue = int.tryParse(value);
          if (intValue != null) {
            await _prefs.setInt(key, intValue);
          } else {
            await _prefs.setString(key, value);
          }
        }
      }
    }
  }

  /// Save a boolean value (also backs up to Keychain on iOS)
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
    await _backupToSecureStorage(key, value.toString());
  }

  /// Save an integer value (also backs up to Keychain on iOS)
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
    await _backupToSecureStorage(key, value.toString());
  }

  /// Get a boolean value
  bool? getBool(String key) => _prefs.getBool(key);

  /// Get an integer value
  int? getInt(String key) => _prefs.getInt(key);

  Future<void> _backupToSecureStorage(String key, String value) async {
    if (_secureStorage == null) return;
    try {
      await _secureStorage!.write(key: key, value: value);
    } catch (e) {
      // Ignore errors - this is best effort
      debugPrint('Failed to backup to secure storage: $e');
    }
  }
}
