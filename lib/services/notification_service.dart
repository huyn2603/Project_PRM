import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_intent.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const channelId = 'finance_alerts';
  static const _channel = AndroidNotificationChannel(
    channelId,
    'Cảnh báo tài chính',
    description: 'Thanh toán, công nợ, quỹ dự phòng và rủi ro dự án',
    importance: Importance.high,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _intentController = StreamController<NotificationIntent>.broadcast();
  final _firestore = FirebaseFirestore.instance;

  Stream<NotificationIntent> get intents => _intentController.stream;

  NotificationIntent? _pendingIntent;
  String? _currentUserId;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  bool get _supportsFcm =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  bool get _supportsLocalNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> initialize() async {
    if (_initialized || !_supportsFcm) return;
    _initialized = true;

    if (_supportsLocalNotifications) {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_finance'),
        iOS: IOSInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _localNotifications.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      final launchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      final payload = launchDetails?.notificationResponse?.payload;
      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          payload != null) {
        _queueOrEmit(_intentFromPayload(payload));
      }
    }

    FirebaseMessaging.onMessage.listen((message) {
      if (kIsWeb) {
        // On web, Firebase delivers a service-worker notification click back
        // to the page through onMessage rather than onMessageOpenedApp.
        _queueOrEmit(NotificationIntent.fromData(message.data));
        return;
      }
      unawaited(_showForegroundNotification(message));
    });
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _queueOrEmit(NotificationIntent.fromData(message.data)),
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _queueOrEmit(NotificationIntent.fromData(initialMessage.data));
    }
  }

  Future<void> registerUser(String userId) async {
    if (!_supportsFcm) return;
    _currentUserId = userId;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    try {
      const webVapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb && webVapidKey.isNotEmpty ? webVapidKey : null,
      );
      if (token != null) await _saveToken(userId, token);
    } catch (error) {
      debugPrint('Không thể lấy FCM token: $error');
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final uid = _currentUserId;
      if (uid != null) await _saveToken(uid, token);
    });
  }

  Future<void> unregisterUser(String userId) async {
    final token = _currentToken;
    _currentUserId = null;
    _currentToken = null;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    if (token == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(_tokenDocumentId(token))
          .delete();
    } catch (error) {
      debugPrint('Không thể xóa FCM token: $error');
    }
  }

  NotificationIntent? takePendingIntent() {
    final value = _pendingIntent;
    _pendingIntent = null;
    return value;
  }

  Future<void> markAsRead(String userId, String? notificationId) async {
    if (notificationId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'readAt': FieldValue.serverTimestamp()});
    } catch (_) {
      // Notification gửi trực tiếp từ console có thể không có bản ghi Firestore.
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    _currentToken = token;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(_tokenDocumentId(token))
        .set({
      'token': token,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _tokenDocumentId(String token) =>
      base64Url.encode(utf8.encode(token)).replaceAll('=', '');

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_supportsLocalNotifications || message.notification == null) return;
    final notification = message.notification!;
    await _localNotifications.show(
      id: message.messageId?.hashCode ?? message.hashCode,
      title: notification.title ?? 'FreelanceFlow',
      body: notification.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Cảnh báo tài chính',
          channelDescription:
              'Thanh toán, công nợ, quỹ dự phòng và rủi ro dự án',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_finance',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) _queueOrEmit(_intentFromPayload(payload));
  }

  NotificationIntent _intentFromPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return NotificationIntent.fromData(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Payload không hợp lệ sẽ quay về trang Tổng quan.
    }
    return NotificationIntent.fromData(const {'type': 'general'});
  }

  void _queueOrEmit(NotificationIntent intent) {
    if (_currentUserId == null) {
      _pendingIntent = intent;
      return;
    }
    _intentController.add(intent);
  }
}
