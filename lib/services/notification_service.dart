import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationAudioChannel { alarm, media }

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Alarm channel - bypasses silent mode
  static const _alarmChannelId = 'nudge_alarm_channel';
  static const _alarmChannelName = 'Nudge Beeps (Alarm)';
  static const _alarmChannelDescription = 'Beeps even in silent mode';

  // Media channel - respects volume settings
  static const _mediaChannelId = 'nudge_media_channel';
  static const _mediaChannelName = 'Nudge Beeps (Media)';
  static const _mediaChannelDescription = 'Respects volume settings';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create Android notification channel
    if (!kIsWeb && Platform.isAndroid) {
      await _createAndroidChannel();
    }

    _isInitialized = true;
  }

  Future<void> _createAndroidChannel() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return;

    // Alarm channel - bypasses silent mode, default importance = sound but no heads-up
    const alarmChannel = AndroidNotificationChannel(
      _alarmChannelId,
      _alarmChannelName,
      description: _alarmChannelDescription,
      importance: Importance.defaultImportance, // Sound but no heads-up
      playSound: true,
      sound: RawResourceAndroidNotificationSound('beep'),
      enableVibration: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    // Media channel - respects volume settings, default importance
    const mediaChannel = AndroidNotificationChannel(
      _mediaChannelId,
      _mediaChannelName,
      description: _mediaChannelDescription,
      importance: Importance.defaultImportance, // Sound but no heads-up
      playSound: true,
      sound: RawResourceAndroidNotificationSound('beep'),
      enableVibration: false,
      audioAttributesUsage: AudioAttributesUsage.media,
    );

    await android.createNotificationChannel(alarmChannel);
    await android.createNotificationChannel(mediaChannel);
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap if needed
  }

  Future<bool> arePermissionsGranted() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }

    if (Platform.isIOS) {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final settings = await ios?.checkPermissions();
      return settings?.isEnabled ?? false;
    }

    return false;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }

    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Request notification permission (Android 13+)
      final notificationGranted =
          await android?.requestNotificationsPermission() ?? false;

      // Request exact alarm permission (Android 12+)
      await android?.requestExactAlarmsPermission();

      return notificationGranted;
    }

    return false;
  }

  Future<void> scheduleBeepNotifications({
    required Duration interval,
    required DateTime startFrom,
    int count = 64, // iOS limit
    NotificationAudioChannel audioChannel = NotificationAudioChannel.alarm,
  }) async {
    if (kIsWeb) return; // Notifications not supported on web

    // Cancel existing notifications first
    await cancelAllNotifications();

    // Select channel based on audio preference
    final channelId = audioChannel == NotificationAudioChannel.alarm
        ? _alarmChannelId
        : _mediaChannelId;
    final channelName = audioChannel == NotificationAudioChannel.alarm
        ? _alarmChannelName
        : _mediaChannelName;
    final channelDescription = audioChannel == NotificationAudioChannel.alarm
        ? _alarmChannelDescription
        : _mediaChannelDescription;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance, // Sound but no heads-up
      priority: Priority.defaultPriority, // Sound but no heads-up
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('beep'),
      enableVibration: false,
      autoCancel: true,
      category: AndroidNotificationCategory.alarm,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: true,
      sound: 'beep.aiff',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    // Schedule multiple notifications
    var nextTime = startFrom;
    for (var i = 0; i < count; i++) {
      await _notifications.zonedSchedule(
        i,
        'Nudge',
        _getTimeMessage(nextTime),
        tz.TZDateTime.from(nextTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
      );
      nextTime = nextTime.add(interval);
    }
  }

  String _getTimeMessage(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) return [];
    return await _notifications.pendingNotificationRequests();
  }
}
