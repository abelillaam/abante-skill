import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_settings.dart';

/// Handles push notification setup: permission request, FCM token storage
/// (so a notification can be targeted at a specific user from the Firebase
/// Console or a backend), and showing a local notification when a push
/// arrives while the app is in the foreground — FCM doesn't surface a
/// system notification for that case on its own.
class PushNotificationService {
  PushNotificationService._();

  static const _channelId = 'abanteskill_default';

  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    await saveTokenIfSignedIn();
    messaging.onTokenRefresh.listen((_) => saveTokenIfSignedIn());

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  /// Call after a successful login/signup so the freshly signed-in user's
  /// token is attached to their Firestore document (initialize() runs at
  /// app startup, before anyone is signed in, so it can't do this alone).
  static Future<void> saveTokenIfSignedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !AppSettings.notifications) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Token sync isn't critical to app function; ignore failures.
    }
  }

  /// Applies the Profile screen's Notifications toggle: turning it off
  /// detaches this device's push token from the account (so no pushes are
  /// targeted at it) and silences local notifications; turning it back on
  /// re-registers the token.
  static Future<void> setEnabled(bool enabled) async {
    await AppSettings.setNotifications(enabled);
    if (enabled) {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      await saveTokenIfSignedIn();
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'fcmToken': FieldValue.delete()},
          SetOptions(merge: true),
        );
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Local preference already saved; token cleanup is best-effort.
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await showLocalNotification(title: notification.title, body: notification.body);
  }

  /// Shows a local notification immediately — used for in-app events like
  /// hitting the daily goal, as opposed to a server-sent push.
  static Future<void> showLocalNotification({String? title, String? body}) async {
    if (!AppSettings.notifications) return;
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'AbanteSkill Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

/// Must be a top-level function (not a class method): handles a push
/// arriving while the app is fully terminated or backgrounded. No extra
/// work is needed here — the OS shows the notification from the payload
/// automatically whenever the app isn't in the foreground.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
