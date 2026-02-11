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
import 'package:truebpm/services/pending_notification_action.dart';
import 'package:truebpm/navigation/navigation_service.dart';
import 'package:truebpm/navigation/notification_navigation_service.dart';
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
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleLocalNotificationTap(response.payload!);
        }
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
      // Encode data thành JSON string để truyền qua payload
      final payloadJson = jsonEncode(message.data);

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
        payload: payloadJson,
      );
    }
  }

  /// Xử lý khi user tap push notification (app từ background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('🔔 Notification tapped:');
    _logger.i('  Title: ${message.notification?.title}');
    _logger.i('  Data: ${message.data}');

    _navigateFromFcmData(message.data);
  }

  /// Xử lý khi user tap local notification (foreground)
  void _handleLocalNotificationTap(String payload) {
    _logger.i('🔔 Local notification tapped, payload: $payload');

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromFcmData(data.map((k, v) => MapEntry(k, v.toString())));
    } catch (e) {
      _logger.e('Error parsing local notification payload: $e');
    }
  }

  /// Logic chung: parse FCM data → navigate hoặc save pending action
  Future<void> _navigateFromFcmData(Map<String, dynamic> data) async {
    try {
      final targetUrl = data['targetUrl'] as String?;
      final notificationType = data['notificationType'] as String?;

      // Parse recordId từ notificationIds (JSON string chứa recordId)
      String? recordId;
      final notificationIdsStr = data['notificationIds'] as String?;
      if (notificationIdsStr != null && notificationIdsStr.isNotEmpty) {
        try {
          final idsData = jsonDecode(notificationIdsStr);
          if (idsData is Map<String, dynamic>) {
            recordId = idsData['recordId']?.toString();
          }
        } catch (_) {
          _logger.w('⚠️ Cannot parse notificationIds: $notificationIdsStr');
        }
      }

      // Parse moduleCode từ targetUrl (giống NotificationItem.targetModuleCode)
      String? moduleCode;
      if (targetUrl != null && targetUrl.isNotEmpty) {
        moduleCode = _parseModuleCodeFromUrl(targetUrl);
      }

      _logger.i('📋 FCM data parsed: moduleCode=$moduleCode, recordId=$recordId, type=$notificationType, targetUrl=$targetUrl');

      // Kiểm tra user đã login chưa
      final isLoggedIn = await _isUserLoggedIn();

      if (notificationType == 'STATUS_CHANGE' && moduleCode != null && recordId != null) {
        // STATUS_CHANGE → navigate đến detail (giống onTap item trong list)
        final isTaskList = targetUrl?.contains('task-list') == true;

        if (isLoggedIn) {
          _logger.i('🚀 STATUS_CHANGE → navigate directly to detail');
          final context = NavigationService.navigatorKey.currentContext;
          if (context != null) {
            await NotificationNavigationService.navigateDirectly(
              context,
              moduleCode: moduleCode,
              recordId: recordId,
              fromTaskScreen: isTaskList,
            );
          } else {
            _logger.w('⚠️ No context available for navigation');
          }
        } else {
          _logger.i('📌 User NOT logged in → save pending action');
          await PendingNotificationAction.save(
            moduleCode: moduleCode,
            recordId: recordId,
            targetUrl: targetUrl ?? '',
            notificationType: 'STATUS_CHANGE',
          );
        }
      } else if (notificationType == 'INFORMATION') {
        // INFORMATION → navigate đến Notify tab để user xem popup từ list
        if (isLoggedIn) {
          _logger.i('📋 INFORMATION → navigate to Notify tab');
          _navigateToNotifyTab();
        } else {
          _logger.i('📌 User NOT logged in → save pending action (INFORMATION)');
          await PendingNotificationAction.save(
            moduleCode: '',
            recordId: '',
            targetUrl: targetUrl ?? '',
            notificationType: 'INFORMATION',
          );
        }
      } else {
        _logger.i('ℹ️ Skip navigation: type=$notificationType, moduleCode=$moduleCode, recordId=$recordId');
      }
    } catch (e, stack) {
      _logger.e('Error handling FCM navigation: $e\n$stack');
    }
  }

  /// Parse module code từ targetUrl
  /// e.g. ".../e-leave-page?code=ELEAVE-10125" → "ELEAVE"
  /// e.g. ".../task-list?code=ELEAVE-10133" → "ELEAVE"
  String? _parseModuleCodeFromUrl(String url) {
    const pageToModuleCode = {
      'e-leave-page': 'ELEAVE',
      'quotation-page': 'QUTATI',
      'ot-registration-page': 'OVTIME',
      'car-booking-page': 'CARBKG',
      'travel-request-page': 'TRAREQ',
      'travel-claim-page': 'TRACLA',
      'product-page': 'PRD',
      'customer-page': 'CTM',
      'weekly-report-page': 'WKLRPT',
      'opportunities-page': 'OPP',
      'project-management-page': 'PRJMGT',
    };

    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final page = segments.last;

        // Direct page mapping
        if (pageToModuleCode.containsKey(page)) {
          return pageToModuleCode[page];
        }

        // task-list: extract module code từ query param 'code'
        // e.g. "task-list?code=ELEAVE-10133" → "ELEAVE"
        if (page == 'task-list') {
          final code = uri.queryParameters['code'];
          if (code != null && code.contains('-')) {
            return code.split('-').first;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Navigate đến Notify tab (tab index 4) trong MainTabScreen
  void _navigateToNotifyTab() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MainTabScreen(initialTabIndex: 4),
        ),
      );
    } else {
      _logger.w('⚠️ No context available for navigation to Notify tab');
    }
  }

  /// Kiểm tra user đã login chưa bằng cách check user_info trong SharedPreferences
  Future<bool> _isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfo = prefs.getString('user_info');
      return userInfo != null && userInfo.isNotEmpty;
    } catch (_) {
      return false;
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
