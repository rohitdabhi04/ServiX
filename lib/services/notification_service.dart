import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// Background handler — top-level function (FCM requirement)
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // App terminated/background mein bhi notification dikhao
  await NotificationService._showFromRemoteMessage(message);
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // NavigatorKey — notification tap par navigate karne ke liye
  // main.dart mein MaterialApp ko assign karo
  static final navigatorKey = _NavigatorKeyHolder();

  static const String _channelId = 'servix_channel';
  static const String _channelName = 'Servix Notifications';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: 'Booking status updates and alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // ── INIT ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    // 1. Background handler register
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Permission request
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('🔔 FCM Permission: ${settings.authorizationStatus}');

    // 3. Android channel create
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Local notifications init
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTap,
    );

    // 5. Foreground: jab app open ho
    FirebaseMessaging.onMessage.listen((message) {
      print('📩 Foreground FCM: ${message.notification?.title}');
      _showFromRemoteMessage(message);
    });

    // 6. Background → opened (app background mein thi, user ne notification tap ki)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('📲 Notification opened from background: ${message.data}');
      _handleNotificationNavigation(message.data);
    });

    // 7. Terminated → opened (app closed thi)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App opened from terminated via notification');
      // Thoda wait karo jab tak app load ho
      Future.delayed(const Duration(seconds: 2), () {
        _handleNotificationNavigation(initialMessage.data);
      });
    }

    // 8. Token save
    await saveTokenToFirestore();
    _fcm.onTokenRefresh.listen(_saveToken);

    // 9. iOS foreground show
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ── Show local notification from FCM RemoteMessage ─────────────────────────
  static Future<void> _showFromRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Servix';
    final body = notification?.body ?? message.data['body'] ?? '';
    final bookingId = message.data['bookingId'];
    final type = message.data['type'] ?? '';

    await showLocalNotification(
      title: title,
      body: body,
      payload: jsonEncode({'bookingId': bookingId, 'type': type}),
    );
  }

  // ── Show a local notification ──────────────────────────────────────────────
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Booking updates',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ── Notification tap handler ───────────────────────────────────────────────
  @pragma('vm:entry-point')
  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleNotificationNavigation(data);
    } catch (_) {}
  }

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final bookingId = data['bookingId'] as String?;
    final type = data['type'] as String?;
    print('📍 Navigate: bookingId=$bookingId, type=$type');
    // Navigation logic: aap apne app ke routes ke hisaab se customize karo
    // Example: Navigator.pushNamed(context, '/bookingDetail', arguments: bookingId);
  }

  // ── Save FCM token ─────────────────────────────────────────────────────────
  Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await _fcm.getToken();
      if (token != null) await _saveToken(token);
      print('✅ FCM Token saved');
    } catch (e) {
      print('❌ FCM Token save error: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Delete token on logout ─────────────────────────────────────────────────
  Future<void> deleteToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': FieldValue.delete()});
      await _fcm.deleteToken();
    } catch (e) {
      print('❌ Token delete error: $e');
    }
  }

  // ── Send REAL FCM push notification via Firebase Cloud Messaging API ────────
  // Ye method recipient ka fcmToken Firestore se padh ke
  // Firebase HTTP v1 API se actual push notification bhejta hai.
  //
  // ⚠️  IMPORTANT: Production mein ye server-side (Cloud Functions) se karo.
  //     Client-side se sirf testing ke liye use karo.
  //     Agar Firebase Cloud Functions deploy karni ho to functions/index.js dekho.
  static Future<void> sendPushNotification({
    required String recipientUserId,
    required String title,
    required String body,
    String? bookingId,
    String type = 'booking',
  }) async {
    try {
      // 1. Recipient ka FCM token lo
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUserId)
          .get();
      final token = userDoc.data()?['fcmToken'] as String?;

      if (token == null || token.isEmpty) {
        print('⚠️ No FCM token for user: $recipientUserId');
        return;
      }

      // 2. Firestore mein notification record save karo (in-app bell)
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': recipientUserId,
        'title': title,
        'body': body,
        'bookingId': bookingId,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. ✅ REAL PUSH via Firebase Cloud Messaging HTTP v1 API
      // Note: Server key is deprecated. Use Cloud Functions for production.
      // Ye backend Cloud Function call karega jo push bhejega.
      await _triggerPushViaCloudFunction(
        token: token,
        title: title,
        body: body,
        bookingId: bookingId ?? '',
        type: type,
      );
    } catch (e) {
      print('❌ sendPushNotification error: $e');
    }
  }

  // ── Cloud Function call ────────────────────────────────────────────────────
  static Future<void> _triggerPushViaCloudFunction({
    required String token,
    required String title,
    required String body,
    required String bookingId,
    required String type,
  }) async {
    try {
      // Apna Cloud Function URL yahan daalo (deploy karne ke baad milega)
      // Example: https://us-central1-YOUR_PROJECT.cloudfunctions.net/sendPushNotification
      // 🔴 Deploy ke baad apna URL yahan daalo:
      // Firebase Console → Functions → sendPushNotification → URL copy karo
      // Format: https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/sendPushNotification
      const String cloudFunctionUrl =
          'YOUR_CLOUD_FUNCTION_URL_HERE'; // ← Sirf yahan URL replace karo

      if (cloudFunctionUrl == 'YOUR_CLOUD_FUNCTION_URL_HERE') {
        print('⚠️ Cloud Function URL set nahi hai — push nahi jayegi');
        return;
      }

      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          'data': {
            'bookingId': bookingId,
            'type': type,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Push notification sent successfully');
      } else {
        print('❌ Push failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Cloud Function call error: $e');
    }
  }

  // ── Old method — backward compatible (sirf Firestore record) ──────────────
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String? bookingId,
  }) async {
    // Ab real push bhi bhejta hai
    await sendPushNotification(
      recipientUserId: userId,
      title: title,
      body: body,
      bookingId: bookingId,
    );
  }
}

class _NavigatorKeyHolder {
  // Placeholder — apne main.dart mein GlobalKey<NavigatorState> use karo
}