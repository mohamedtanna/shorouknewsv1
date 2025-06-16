import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// Wrapper around Firebase Messaging functionality used in the app.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initializes Firebase and Firebase Messaging.
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      NotificationSettings settings = await _messaging.requestPermission();
      debugPrint('Firebase Messaging permission status: ${settings.authorizationStatus}');

      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      FirebaseMessaging.onMessage.listen(_handleMessage);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Error initializing FirebaseService: $e');
    }
  }

  /// Subscribes the device to a list of FCM topics.
  Future<void> subscribeToTopics(List<String> topics) async {
    for (final topic in topics) {
      try {
        await _messaging.subscribeToTopic(topic);
      } catch (e) {
        debugPrint('Failed to subscribe to $topic: $e');
      }
    }
    await _saveSubscribedTopicsToLocal(topics);
  }

  /// Unsubscribes the device from the specified FCM topics.
  Future<void> unsubscribeFromTopics(List<String> topics) async {
    for (final topic in topics) {
      try {
        await _messaging.unsubscribeFromTopic(topic);
      } catch (e) {
        debugPrint('Failed to unsubscribe from $topic: $e');
      }
    }
    await _saveSubscribedTopicsToLocal([]);
  }

  Future<List<String>> getSubscribedTopicsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('user_subscribed_fcm_topics') ?? [];
  }

  Future<void> _saveSubscribedTopicsToLocal(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_subscribed_fcm_topics', topics);
  }

  Future<void> logAnalyticsEvent(String name, {Map<String, Object?>? parameters}) async {
    debugPrint('Analytics event: $name, params: $parameters');
  }

  Future<void> logAnalyticsScreenView(String screenName) async {
    debugPrint('Analytics screen view: $screenName');
  }

  Future<void> announceUserForVersionTracking() async {
    debugPrint('announceUserForVersionTracking called');
  }

  Future<String?> refreshToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Handles foreground messages by showing a local notification.
  Future<void> _handleMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    if (notification != null) {
      await NotificationService().showNotification(
        title: notification.title ?? 'إشعار جديد',
        body: notification.body ?? '',
        imageUrl: notification.android?.imageUrl ?? notification.apple?.imageUrl,
        data: data,
        isBreakingNews: data['type'] == 'breaking',
      );
    }
  }
}

/// Top level background message handler used by Firebase Messaging.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notification = message.notification;
  final data = message.data;
  if (notification != null) {
    await NotificationService().showNotification(
      title: notification.title ?? 'إشعار جديد',
      body: notification.body ?? '',
      imageUrl: notification.android?.imageUrl ?? notification.apple?.imageUrl,
      data: data,
      isBreakingNews: data['type'] == 'breaking',
    );
  }
}
