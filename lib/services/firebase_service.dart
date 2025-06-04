import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'api_service.dart';
import 'notification_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  String? _fcmToken;
  
  // Initialize Firebase services
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      await _requestPermission();
      
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      if (_fcmToken != null) {
        // Create user on server
        await _createUser();
        
        // Get and update subscriptions
        await _getAndUpdateSubscriptions();
      }
      
      // Set up message handlers
      _setupMessageHandlers();
      
      // Setup analytics
      await _setupAnalytics();
      
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('Permission granted: ${settings.authorizationStatus}');
  }

  // Create user on server
  Future<void> _createUser() async {
    if (_fcmToken == null) return;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceType = 'Unknown';
      String deviceModel = 'Unknown';
      int os = 0; // 0: other, 1: Android, 2: iOS
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceType = androidInfo.manufacturer;
        deviceModel = androidInfo.model;
        os = 1;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceType = 'Apple';
        deviceModel = iosInfo.model;
        os = 2;
      }
      
      await _apiService.createUser(
        token: _fcmToken!,
        os: os,
        deviceType: deviceType,
        deviceModel: deviceModel,
      );
    } catch (e) {
      debugPrint('Error creating user: $e');
    }
  }

  // Get and update current subscriptions
  Future<void> _getAndUpdateSubscriptions() async {
    try {
      final subscribedTopics = await getSubscribedTopics();
      
      // Filter out default topics
      final userTopics = subscribedTopics.where((topic) => 
          topic != 'all' && topic != 'android' && topic != 'ios').toList();
      final defaultTopics = subscribedTopics.where((topic) => 
          topic == 'all' || topic == 'android' || topic == 'ios').toList();
      
      // If no user topics but has default topics, subscribe to all sections
      if (userTopics.isEmpty && defaultTopics.isNotEmpty) {
        await _subscribeToAllSections();
      }
    } catch (e) {
      debugPrint('Error updating subscriptions: $e');
    }
  }

  // Subscribe to all sections
  Future<void> _subscribeToAllSections() async {
    try {
      final sections = await _apiService.getSections();
      final sectionIds = sections.map((section) => section.id).toList();
      await subscribeToTopics(sectionIds);
    } catch (e) {
      debugPrint('Error subscribing to all sections: $e');
    }
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      
      // Show local notification
      _notificationService.showNotification(
        title: message.notification?.title ?? 'الشروق',
        body: message.notification?.body ?? '',
        data: message.data,
      );
    });

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked: ${message.messageId}');
      _handleMessageClick(message);
    });

    // Handle notification tap when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state: ${message.messageId}');
        _handleMessageClick(message);
      }
    });
  }

  // Handle message click navigation
  void _handleMessageClick(RemoteMessage message) {
    try {
      final data = message.data;
      final link = data['link'] ?? data['Link'];
      final url = data['url'] ?? data['Url'];
      
      String? navigationPath;
      
      if (link != null && link.isNotEmpty) {
        navigationPath = link;
      } else if (url != null && url.isNotEmpty) {
        navigationPath = url;
      }
      
      if (navigationPath != null) {
        // Navigate to the specified path
        // This should be handled by your router
        debugPrint('Navigate to: $navigationPath');
      }
    } catch (e) {
      debugPrint('Error handling message click: $e');
    }
  }

  // Setup Firebase Analytics
  Future<void> _setupAnalytics() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      
      // Log app open event
      await _analytics.logAppOpen();
      
      // Set user properties
      await _analytics.setUserId(id: _fcmToken);
    } catch (e) {
      debugPrint('Error setting up analytics: $e');
    }
  }

  // Subscribe to topics
  Future<void> subscribeToTopics(List<String> topics) async {
    try {
      for (final topic in topics) {
        await _messaging.subscribeToTopic(topic);
        debugPrint('Subscribed to topic: $topic');
      }
      
      // Unsubscribe from deactivateAll if subscribing to any topic
      if (topics.isNotEmpty) {
        await _messaging.unsubscribeFromTopic('deactivateAll');
      }
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
      rethrow;
    }
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopics(List<String> topics) async {
    try {
      for (final topic in topics) {
        await _messaging.unsubscribeFromTopic(topic);
        debugPrint('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      debugPrint('Error unsubscribing from topics: $e');
      rethrow;
    }
  }

  // Get subscribed topics (this is a simulation as FCM doesn't provide this directly)
  Future<List<String>> getSubscribedTopics() async {
    try {
      // In a real implementation, you would need to track subscriptions locally
      // or use the Firebase Admin SDK on your server
      final prefs = await SharedPreferences.getInstance();
      final topics = prefs.getStringList('subscribed_topics') ?? [];
      return topics;
    } catch (e) {
      debugPrint('Error getting subscribed topics: $e');
      return [];
    }
  }

  // Save subscribed topics locally
  Future<void> _saveSubscribedTopics(List<String> topics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('subscribed_topics', topics);
    } catch (e) {
      debugPrint('Error saving subscribed topics: $e');
    }
  }

  // Log analytics events
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  // Log screen views
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  // Announce user (for app version tracking)
  Future<void> announceUser() async {
    if (_fcmToken == null) return;
    
    try {
      await _apiService.announceUser(_fcmToken!);
    } catch (e) {
      debugPrint('Error announcing user: $e');
    }
  }

  // Get FCM token
  String? get fcmToken => _fcmToken;

  // Refresh FCM token
  Future<String?> refreshToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      return _fcmToken;
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
      return null;
    }
  }
}