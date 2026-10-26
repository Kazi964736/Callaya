import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'characters.dart';

/// Schedules the fake call as a full-screen "incoming call" notification,
/// so it rings even when the app is closed or the phone is locked.
class CallScheduler {
  CallScheduler._();
  static final instance = CallScheduler._();

  static const _notificationId = 1;
  static const _channelId = 'incoming_calls';

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Called when the user taps the call notification (or it opens full screen).
  void Function(String callerId)? onCallOpened;

  /// Returns the caller id if the app was launched by a call notification.
  Future<String?> init() async {
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final id = response.payload;
        if (id != null) {
          onCallOpened?.call(id);
        }
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      return launch!.notificationResponse?.payload;
    }
    return null;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Asks for notification, exact-alarm and full-screen permissions.
  /// Returns false if notifications were refused.
  Future<bool> requestPermissions() async {
    final android = _android;
    if (android == null) {
      return true;
    }
    final allowed = await android.requestNotificationsPermission() ?? true;
    try {
      await android.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Exact alarm permission request failed: $e');
    }
    try {
      await android.requestFullScreenIntentPermission();
    } catch (e) {
      debugPrint('Full-screen permission request failed: $e');
    }
    return allowed;
  }

  Future<void> schedule(Caller caller, Duration delay) async {
    await cancel();
    final when = tz.TZDateTime.now(tz.UTC).add(delay);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Fake incoming calls',
        channelDescription: 'Rings when your scheduled fake call arrives',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        ongoing: true,
        autoCancel: true,
        timeoutAfter: 45000,
      ),
    );
    Future<void> scheduleWith(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          _notificationId,
          caller.name,
          'Incoming call…',
          when,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: caller.id,
        );
    try {
      await scheduleWith(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      // Exact alarms not allowed on this phone: ring as close to the time as Android permits.
      debugPrint('Exact scheduling failed, falling back to inexact: $e');
      await scheduleWith(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancel() => _plugin.cancel(_notificationId);
}
