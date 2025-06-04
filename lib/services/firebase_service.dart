import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart'; // For app version

import '../models/new_model.dart'; // For NewsSection if needed for default subscriptions
import 'api_service.dart';
import 'notification_service.dart';
import '../core/app_router.dart'; // For navigation from notification tap

// Key to check if initial default subscriptions have been set
const String _initialSubscriptionsSetKey = 'initial_fcm_subscriptions_set_v1';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final ApiService _apiService = ApiService(); // Instance of your ApiService
  final NotificationService _notificationService = NotificationService(); // Instance of NotificationService

  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;

  /// Initializes Firebase services: FCM, Analytics, and user registration.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for notifications (iOS and Android 13+)
      await _requestNotificationPermission();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');
        // Register user device with backend
        await _registerDeviceWithBackend();
        // Handle initial topic subscriptions (e.g., subscribe to all sections for new users)
        await _manageInitialDefaultSubscriptions();
      } else {
        debugPrint('Failed to get FCM token.');
      }

      // Set up message handlers for incoming notifications
      _setupMessageHandlers();

      // Setup Firebase Analytics
      await _setupAnalytics();

      _isInitialized = true;
      debugPrint('FirebaseService initialized successfully.');
    } catch (e) {
      debugPrint('Error initializing FirebaseService: $e');
    }
  }

  /// Requests notification permissions from the user.
  Future<void> _requestNotificationPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('User granted notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  /// Registers the device with the backend using the FCM token and device info.
  Future<void> _registerDeviceWithBackend() async {
    if (_fcmToken == null) {
      debugPrint('FCM token is null, cannot register device with backend.');
      return;
    }

    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceType = 'Unknown';
      String deviceModel = 'Unknown';
      int os = 0; // 0: other, 1: Android, 2: iOS

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceType = androidInfo.manufacturer;
        deviceModel = androidInfo.model;
        os = 1;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceType = 'Apple'; // Manufacturer is Apple for iOS devices
        deviceModel = iosInfo.model ?? 'Unknown Model';
        os = 2;
      }

      debugPrint('Registering device: Token: $_fcmToken, OS: $os, Type: $deviceType, Model: $deviceModel');
      await _apiService.createUser(
        token: _fcmToken!,
        os: os,
        deviceType: deviceType,
        deviceModel: deviceModel,
      );
      debugPrint('Device registered with backend successfully.');
    } catch (e) {
      debugPrint('Error registering device with backend: $e');
      // Optionally, implement retry logic or queue for later if critical
    }
  }

  /// Manages initial default topic subscriptions for new users.
  /// If not already set, subscribes the user to all available news sections.
  Future<void> _manageInitialDefaultSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool alreadySet = prefs.getBool(_initialSubscriptionsSetKey) ?? false;

      if (!alreadySet) {
        debugPrint('Setting initial default subscriptions...');
        final List<NewsSection> sections = await _apiService.getSections();
        if (sections.isNotEmpty) {
          final List<String> sectionTopics = sections.map((s) => s.id).toList();
          // Also subscribe to a general 'all' topic if your backend uses it
          if (!sectionTopics.contains('all')) {
             sectionTopics.add('all'); // Common practice for a general topic
          }
          // Add platform-specific topics
          if (Platform.isAndroid && !sectionTopics.contains('android')) {
            sectionTopics.add('android');
          } else if (Platform.isIOS && !sectionTopics.contains('ios')) {
            sectionTopics.add('ios');
          }

          await subscribeToTopics(sectionTopics);
          debugPrint('Subscribed to default topics: $sectionTopics');
        }
        await prefs.setBool(_initialSubscriptionsSetKey, true);
      } else {
        debugPrint('Initial default subscriptions already set.');
      }
    } catch (e) {
      debugPrint('Error managing initial default subscriptions: $e');
    }
  }


  /// Sets up handlers for incoming FCM messages (foreground, background tap).
  void _setupMessageHandlers() {
    // Handle messages received while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM Message Received: ${message.messageId}');
      debugPrint('Notification Title: ${message.notification?.title}');
      debugPrint('Notification Body: ${message.notification?.body}');
      debugPrint('Data payload: ${message.data}');

      // Show a local notification using NotificationService
      _notificationService.showNotification(
        title: message.notification?.title ?? 'الشروق نيوز', // Default title
        body: message.notification?.body ?? 'لديك رسالة جديدة', // Default body
        imageUrl: Platform.isAndroid ? message.notification?.android?.imageUrl : message.notification?.apple?.imageUrl,
        data: message.data,
        // Determine if it's breaking news based on payload or channel if available
        isBreakingNews: message.data['is_breaking'] == 'true' || message.data['priority'] == 'high',
      );
    });

    // Handle notification tap when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM Message Opened (App was in background/terminated): ${message.messageId}');
      _handleNotificationTap(message.data);
    });

    // Check if the app was opened from a terminated state via a notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state via FCM Message: ${message.messageId}');
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Handles navigation when a notification is tapped.
  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('Handling notification tap with data: $data');
    // Extract navigation path from common keys, case-insensitive
    final String? link = data['link']?.toString() ?? data['Link']?.toString();
    final String? url = data['url']?.toString() ?? data['Url']?.toString();
    final String? navigationPath = link ?? url;

    if (navigationPath != null && navigationPath.isNotEmpty) {
      debugPrint('Navigating to path: $navigationPath');
      try {
        // Ensure AppRouter.router is accessible, or pass router instance
        AppRouter.router.go(navigationPath);
      } catch (e) {
        debugPrint('Error navigating from notification tap: $e');
        // Fallback navigation if specific path fails
        AppRouter.router.go('/home');
      }
    } else {
      debugPrint('No navigation path found in notification data. Navigating to home.');
      AppRouter.router.go('/home'); // Default navigation
    }
  }

  /// Sets up Firebase Analytics.
  Future<void> _setupAnalytics() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      debugPrint('Firebase Analytics collection enabled.');
      // Log app open event
      await _analytics.logAppOpen();
      // Set user ID for analytics if available (e.g., after login)
      // If you have a user ID from your backend:
      // await _analytics.setUserId(id: 'YOUR_USER_ID');
      // If using FCM token as a pseudo-user ID for analytics:
      if (_fcmToken != null) {
        await _analytics.setUserProperty(name: 'fcm_token_present', value: 'true');
      }
    } catch (e) {
      debugPrint('Error setting up Firebase Analytics: $e');
    }
  }

  /// Subscribes the device to a list of FCM topics.
  Future<void> subscribeToTopics(List<String> topics) async {
    if (topics.isEmpty) return;
    try {
      for (final topic in topics) {
        if (topic.trim().isNotEmpty) {
          await _messaging.subscribeToTopic(topic.trim());
          debugPrint('Subscribed to FCM topic: ${topic.trim()}');
        }
      }
      // If subscribing to specific topics, ensure "deactivateAll" is unsubscribed
      // This logic might be specific to how your backend handles "deactivateAll"
      if (topics.any((t) => t != 'deactivateAll')) {
         await _messaging.unsubscribeFromTopic('deactivateAll').catchError((e) {
            debugPrint("Minor error unsubscribing from 'deactivateAll', possibly not subscribed: $e");
         });
      }
    } catch (e) {
      debugPrint('Error subscribing to FCM topics ($topics): $e');
      // Optionally, rethrow or handle to inform the user/SettingsProvider
    }
  }

  /// Unsubscribes the device from a list of FCM topics.
  Future<void> unsubscribeFromTopics(List<String> topics) async {
    if (topics.isEmpty) return;
    try {
      for (final topic in topics) {
         if (topic.trim().isNotEmpty) {
          await _messaging.unsubscribeFromTopic(topic.trim());
          debugPrint('Unsubscribed from FCM topic: ${topic.trim()}');
        }
      }
    } catch (e) {
      debugPrint('Error unsubscribing from FCM topics ($topics): $e');
    }
  }

  /// Retrieves a list of currently subscribed topics.
  /// NOTE: FCM client SDK does not provide a direct way to get subscribed topics.
  /// This method relies on SharedPreferences to store topics the app *thinks* it's subscribed to.
  /// For authoritative state, your server should manage subscriptions.
  Future<List<String>> getSubscribedTopicsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use a different key for topics managed by SettingsProvider vs initial defaults
      return prefs.getStringList('user_subscribed_fcm_topics') ?? [];
    } catch (e) {
      debugPrint('Error getting locally stored subscribed topics: $e');
      return [];
    }
  }

  /// Saves the list of topics (usually managed by SettingsProvider) to SharedPreferences.
  Future<void> saveSubscribedTopicsToLocal(List<String> topics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_subscribed_fcm_topics', topics);
    } catch (e) {
      debugPrint('Error saving subscribed topics locally: $e');
    }
  }

  /// Logs a custom event to Firebase Analytics.
  Future<void> logAnalyticsEvent(String name, {Map<String, Object?>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint('Logged Analytics event: $name');
    } catch (e) {
      debugPrint('Error logging analytics event "$name": $e');
    }
  }

  /// Logs a screen view event to Firebase Analytics.
  Future<void> logAnalyticsScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('Logged Analytics screen view: $screenName');
    } catch (e) {
      debugPrint('Error logging screen view "$screenName": $e');
    }
  }

  /// Announces the user to the backend, typically for app version tracking.
  /// This corresponds to `onClickAppVersion` in the Ionic service.
  Future<void> announceUserForVersionTracking() async {
    if (_fcmToken == null) {
      debugPrint('FCM token is null, cannot announce user.');
      return;
    }
    try {
      await _apiService.announceUser(_fcmToken!);
      debugPrint('User announced successfully for version tracking.');
    } catch (e) {
      debugPrint('Error announcing user for version tracking: $e');
    }
  }

  /// Refreshes the FCM token if it's stale or missing.
  Future<String?> refreshToken() async {
    try {
      final newToken = await _messaging.getToken();
      if (newToken != null && newToken != _fcmToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        // Re-register the device with the new token
        await _registerDeviceWithBackend();
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
      return null;
    }
  }
}
