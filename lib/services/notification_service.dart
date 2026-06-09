import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts();
  final Map<int, DateTime> _scheduledTasks = {};

  bool get _isWeb => kIsWeb;

  Future<void> initialize() async {
    if (_isWeb) return;

    tz_data.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@android:drawable/ic_menu_info_details');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(initSettings);
    await _requestPermissions();
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.45);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool speakOnNotify = false,
  }) async {
    if (_isWeb) return;

    await _ensurePermissions();

    const androidDetails = AndroidNotificationDetails(
      'todo_reminders',
      'Todo Reminders',
      channelDescription: 'Notifications for todo task reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      actions: [
        AndroidNotificationAction('yes', 'Yes, Done', showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction('no', 'Not Yet', showsUserInterface: true, cancelNotification: false),
      ],
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final location = tz.local;
    final tzDate = tz.TZDateTime.from(scheduledDate, location);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '$id|notification',
    );

    if (speakOnNotify) {
      await speakText('$title: $body');
    }

    _scheduledTasks[id] = scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    if (_isWeb) return;
    await _plugin.cancel(id);
    _scheduledTasks.remove(id);
  }

  Future<void> cancelAll() async {
    if (_isWeb) return;
    await _plugin.cancelAll();
    _scheduledTasks.clear();
  }

  Future<void> _requestPermissions() async {
    if (_isWeb) return;
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
  }

  Future<void> _ensurePermissions() async {
    if (_isWeb) return;
    final android = await Permission.notification.request();
    if (android.isGranted) return;
  }

  Future<void> speakText(String text) async {
    if (_isWeb) return;
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    if (_isWeb) return;
    await _tts.stop();
  }

  Map<int, DateTime> get scheduledTasks => Map.unmodifiable(_scheduledTasks);
}
