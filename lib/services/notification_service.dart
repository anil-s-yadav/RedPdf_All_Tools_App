import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Model defining a scheduled reminder time and message.
class ReminderSchedule {
  final int id;
  final int hour;
  final int minute;
  final String title;
  final String body;

  const ReminderSchedule({
    required this.id,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
  });
}

/// Singleton service managing local notifications and daily 10 AM reminders.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'redpdf_daily_reminders';
  static const String _channelName = 'Daily Reminders';
  static const String _channelDescription =
      'Daily reminders to manage, convert, and secure your PDF documents';
  static const String _prefScheduleKey = 'redpdf_notification_schedule_version';
  static const int _scheduleVersion = 1;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Daily 10:00 AM reminder schedule
  static const List<ReminderSchedule> _allSchedules = [
    ReminderSchedule(
      id: 101,
      hour: 10,
      minute: 0,
      title: "REDPDF - All PDF Tools",
      body:
          "Need to convert images to PDF, lock or organize documents? Open RedPdf to get it done quickly!",
    ),
  ];

  /// Initialize notification settings, timezone, and channels.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Timezones
      tz.initializeTimeZones();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      } catch (e) {
        developer.log(
          "Could not detect local timezone: $e",
          name: "NotificationService",
        );
      }

      // 2. Setup initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_notification',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // 3. Create high-importance notification channel for Android
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlatform != null) {
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidPlatform.createNotificationChannel(channel);
      }

      _isInitialized = true;

      // 4. Request permissions & schedule reminders in background
      _requestPermissionsAndSchedule();
    } catch (e, stackTrace) {
      developer.log(
        "Failed to initialize NotificationService: $e",
        name: "NotificationService",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Explicitly request notification permissions (returns true if granted).
  Future<bool> requestPermission() async {
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      developer.log(
        "Error requesting permission: $e",
        name: "NotificationService",
      );
      return false;
    }
  }

  /// Check if notifications are currently enabled on device.
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlatform != null) {
        final enabled = await androidPlatform.areNotificationsEnabled();
        return enabled ?? false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Asynchronously request notification permission and schedule reminders.
  Future<void> _requestPermissionsAndSchedule() async {
    try {
      await requestPermission();
      await scheduleDailyReminders();
    } catch (e) {
      developer.log(
        "Error requesting permission / scheduling reminders: $e",
        name: "NotificationService",
      );
    }
  }

  /// Schedule the daily reminder notification at 10:00 AM.
  /// Optimized with a cache check so we don't unnecessarily reschedule on every single app launch.
  Future<void> scheduleDailyReminders({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentConfigKey = "v${_scheduleVersion}_10am";
      final savedConfig = prefs.getString(_prefScheduleKey);

      if (!force && savedConfig == currentConfigKey) {
        // Already scheduled for this version
        return;
      }

      // Notification details configuration with HIGH importance & priority
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@drawable/ic_notification',
          color: Color(0xFFE53935),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Schedule each configured reminder with inexactAllowWhileIdle
      for (final schedule in _allSchedules) {
        final scheduledDate = _nextInstanceOfTime(
          schedule.hour,
          schedule.minute,
        );

        await _notificationsPlugin.zonedSchedule(
          id: schedule.id,
          title: schedule.title,
          body: schedule.body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      await prefs.setString(_prefScheduleKey, currentConfigKey);
      developer.log(
        "Successfully scheduled daily 10:00 AM reminder notification",
        name: "NotificationService",
      );
    } catch (e, stackTrace) {
      developer.log(
        "Failed to schedule daily reminders: $e",
        name: "NotificationService",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Calculates the next occurrence of [hour]:[minute] in the local timezone.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancels all scheduled reminder notifications.
  Future<void> cancelAllReminders() async {
    try {
      for (final schedule in _allSchedules) {
        await _notificationsPlugin.cancel(id: schedule.id);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefScheduleKey);
    } catch (e) {
      developer.log("Error cancelling reminders: $e");
    }
  }


  /// Returns list of pending notification requests.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print("Notification clicked: ${response.payload}");
    }
  }
}
