import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truebpm/firebase_options.dart';
import 'package:truebpm/services/device_token_service.dart';

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
        // Gửi token mới lên server (ngầm)
        _saveRefreshedTokenToServer();
      });

      // Lắng nghe foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Lắng nghe khi user tap notification (app đang ở background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Kiểm tra initial message (app được mở từ terminated state qua notification)
      RemoteMessage? initialMessage =
          await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _logger.i(
            'App opened from terminated state via notification: ${initialMessage.messageId}');
        _handleNotificationTap(initialMessage);
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
        // TODO: Xử lý khi user tap notification
      },
    );
  }

  /// Kiểm tra có phải real device không
  Future<bool> _isRealDevice() async {
    try {
      // Trên iOS Simulator, getAPNSToken() sẽ trả về null
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
      // Trên iOS, cần đợi APNs token trước khi lấy FCM token
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          _logger.w('APNs token is null - running on simulator or APNs not configured');
          return;
        }
      }
      _fcmToken = await _messaging.getToken();
      _logger.i('FCM Token: $_fcmToken');
      // TODO: Gửi token lên server backend
    } catch (e) {
      _logger.e('Error getting FCM token: $e');
    }
  }

  /// Xử lý message khi app ở foreground
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Foreground message received:');
    _logger.i('  Title: ${message.notification?.title}');
    _logger.i('  Body: ${message.notification?.body}');
    _logger.i('  Data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Hiển thị local notification khi app đang mở (chỉ Android cần, iOS tự hiển thị)
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Xử lý khi user tap notification
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('Notification tapped:');
    _logger.i('  Title: ${message.notification?.title}');
    _logger.i('  Data: ${message.data}');

    // TODO: Navigate đến screen tương ứng dựa trên message.data
    // Ví dụ:
    // final type = message.data['type'];
    // final id = message.data['id'];
    // NavigationService.navigatorKey.currentState?.pushNamed('/details', arguments: id);
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
  /// Lấy userId từ SharedPreferences (user_info đã lưu sau login).
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
