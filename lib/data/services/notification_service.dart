import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import '../../views/student/assignments/student_assignments_screen.dart';

/// Global navigator key so notification taps can navigate from anywhere.
/// Attached to MaterialApp in main.dart.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _api = ApiService();
  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'assignments_channel',
    'Assignments',
    description: 'Notifications about new assignments',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Call once after Firebase.initializeApp() in main().
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Permission (Android 13+ / iOS)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Local notifications setup (used to display pushes while app is open)
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) => _openAssignments(),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Foreground messages — show as a local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n == null) return;
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // Tap while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Tap that launched the app from terminated state
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Delay until the first frame so the navigator exists
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleMessageTap(initial));
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    if (message.data['type'] == 'new_assignment') {
      _openAssignments();
    }
  }

  void _openAssignments() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
        builder: (_) => const StudentAssignmentsScreen()));
  }

  /// Fetch the device FCM token and register it with the backend.
  /// Call after a successful student login. Also keeps the token fresh.
  Future<void> registerToken(String firebaseUid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _api.registerFcmToken(firebaseUid: firebaseUid, token: token);
      }
      _fcm.onTokenRefresh.listen((newToken) {
        _api
            .registerFcmToken(firebaseUid: firebaseUid, token: newToken)
            .catchError((_) {});
      });
    } catch (_) {
      // Token registration must never block login
    }
  }
}
