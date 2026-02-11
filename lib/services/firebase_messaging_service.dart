import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truebpm/firebase_options.dart';
import 'package:truebpm/services/device_token_service.dart';
import 'package:truebpm/navigation/navigation_service.dart';
import 'package:truebpm/screens/main_tab_screens/main_tab_screen.dart';

final _logger = Logger();

/// Background message handler - phải là top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _logger.i('Handling a background message: ${message.messageId}');
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() => _instance;

  FirebaseMessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Flutter Local Notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel', // id - phải khớp với AndroidManifest.xml
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  /// FCM Token
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Flag: app được mở từ terminated state qua notification tap
  /// Dùng để navigate đến Notify tab sau khi app build xong
  static bool _pendingNotifyTabNavigation = false;
  static bool get pendingNotifyTabNavigation => _pendingNotifyTabNavigation;
  static void clearPendingNotifyTabNavigation() {
    _pendingNotifyTabNavigation = false;
  }

  /// Khởi tạo Firebase Messaging
  Future<void> initialize() async {
    try {
      // Đăng ký background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Yêu cầu quyền notification
      await _requestPermissions();

      // Khởi tạo local notifications
      await _initLocalNotifications();

      // Tạo Android notification channel
      await _createNotificationChannel();

      // Lấy FCM token (skip trên iOS Simulator vì không hỗ trợ APNs)
      if (!Platform.isIOS || !kDebugMode || await _isRealDevice()) {
        await _getToken();
      } else {
        _logger.w('Skipping FCM token on iOS Simulator (APNs not supported)');
      }

      // Lắng nghe token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _logger.i('FCM Token refreshed: $newToken');
        _saveRefreshedTokenToServer();
      });

      // Lắng nghe foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Cho phép hiển thị notification khi app ở foreground (iOS)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Lắng nghe khi user tap notification (app đang ở background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Kiểm tra initial message (app được mở từ terminated state qua notification)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _logger.i(
            'App opened from terminated state via notification: ${initialMessage.messageId}');
        // Set flag → MainTabScreen sẽ check flag này để navigate sang Notify tab
        _pendingNotifyTabNavigation = true;
      }

      _logger.i('Firebase Messaging initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Error initializing Firebase Messaging: $e\n$stackTrace');
    }
  }

  /// Yêu cầu quyền notification
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _logger.i(
        'Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      _logger.i('User granted provisional notification permission');
    } else {
      _logger.w('User denied notification permission');
    }
  }

  /// Khởi tạo Flutter Local Notifications
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _logger.i('Local notification tapped: ${response.payload}');
        // Tap local notification (foreground) → navigate đến Notify tab
        _navigateToNotifyTab();
      },
    );
  }

  /// Kiểm tra có phải real device không
  Future<bool> _isRealDevice() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        return apnsToken != null;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Tạo Android notification channel
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  /// Lấy FCM token
  Future<void> _getToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          _logger.w('APNs token is null - running on simulator or APNs not configured');
          return;
        }
      }
      _fcmToken = await _messaging.getToken();
      _logger.i('FCM Token: $_fcmToken');
    } catch (e) {
      _logger.e('Error getting FCM token: $e');
    }
  }

  /// Xử lý message khi app ở foreground → hiển thị local notification
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Foreground message received:');
    _logger.i('  Title: ${message.notification?.title}');
    _logger.i('  Body: ${message.notification?.body}');
    _logger.i('  Data: ${message.data}');

    // Lấy title/body từ notification field hoặc fallback từ data field
    final String? title = message.notification?.title ?? message.data['title'];
    final String? body = message.notification?.body ?? message.data['body'] ?? message.data['content'];

    if (title == null && body == null) {
      _logger.w('⚠️ No title/body in FCM message → skip showing notification');
      return;
    }

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      title ?? '',
      body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Xử lý khi user tap push notification (app đang ở background)
  /// → navigate đến Notify tab
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('🔔 Notification tapped (background):');
    _logger.i('  Title: ${message.notification?.title}');
    _logger.i('  Data: ${message.data}');

    _navigateToNotifyTab();
  }

  /// Navigate đến Notify tab (tab index 4) trong MainTabScreen
  void _navigateToNotifyTab() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainTabScreen(initialTabIndex: 4),
        ),
        (route) => false,
      );
    } else {
      _logger.w('⚠️ No context available for navigation to Notify tab');
    }
  }

  /// Subscribe vào topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      _logger.i('Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe khỏi topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      _logger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Gửi token mới lên server khi token refresh (ngầm, fire-and-forget).
  void _saveRefreshedTokenToServer() {
    SharedPreferences.getInstance().then((prefs) {
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr != null) {
        try {
          final userMap = jsonDecode(userJsonStr);
          final userId = userMap['id']?.toString();
          if (userId != null && userId.isNotEmpty) {
            DeviceTokenService.instance.saveDeviceToken(userId: userId);
          }
        } catch (_) {}
      }
    }).catchError((_) {
      // Ignore - chạy ngầm
    });
  }
}
