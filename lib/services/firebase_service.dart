import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

import 'package:shorouk_news/models/new_model.dart';
import 'api_service.dart';
import 'notification_service.dart';
import '../core/app_router.dart';

const String _initialSubscriptionsSetKey = 'initial_fcm_subscriptions_set_v1';

/// Stubbed FirebaseService with Firebase functionality disabled.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    _isInitialized = true;
    debugPrint('FirebaseService disabled: initialize called');
  }

  Future<void> subscribeToTopics(List<String> topics) async {
    debugPrint('FirebaseService disabled: subscribeToTopics \$topics');
  }

  Future<void> unsubscribeFromTopics(List<String> topics) async {
    debugPrint('FirebaseService disabled: unsubscribeFromTopics \$topics');
  }

  Future<List<String>> getSubscribedTopicsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('user_subscribed_fcm_topics') ?? [];
  }

  Future<void> saveSubscribedTopicsToLocal(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_subscribed_fcm_topics', topics);
  }

  Future<void> logAnalyticsEvent(String name, {Map<String, Object?>? parameters}) async {
    debugPrint('FirebaseService disabled: logAnalyticsEvent \$name');
  }

  Future<void> logAnalyticsScreenView(String screenName) async {
    debugPrint('FirebaseService disabled: logAnalyticsScreenView \$screenName');
  }

  Future<void> announceUserForVersionTracking() async {
    debugPrint('FirebaseService disabled: announceUserForVersionTracking');
  }

  Future<String?> refreshToken() async {
    debugPrint('FirebaseService disabled: refreshToken');
    return _fcmToken;
  }
}
