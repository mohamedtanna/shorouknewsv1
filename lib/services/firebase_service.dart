import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal stub for Firebase Messaging functionality. All methods
/// are retained for compatibility but perform only local actions.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Stub initialization. Firebase messaging has been removed,
  /// so this simply logs a message.
  Future<void> initialize() async {
    debugPrint('Firebase messaging disabled.');
  }

  /// Saves the provided topics locally.
  Future<void> subscribeToTopics(List<String> topics) async {
    await _saveSubscribedTopicsToLocal(topics);
  }

  /// Clears locally saved topics.
  Future<void> unsubscribeFromTopics(List<String> topics) async {
    await _saveSubscribedTopicsToLocal([]);
  }

  Future<List<String>> getSubscribedTopicsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('user_subscribed_fcm_topics') ?? [];
  }

  /// Persist the list of topics locally.
  Future<void> saveSubscribedTopicsToLocal(List<String> topics) async {
    await _saveSubscribedTopicsToLocal(topics);
  }

  Future<void> _saveSubscribedTopicsToLocal(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_subscribed_fcm_topics', topics);
  }

  Future<void> logAnalyticsEvent(String name,
      {Map<String, Object?>? parameters}) async {
    debugPrint('Analytics event: $name, params: $parameters');
  }

  Future<void> logAnalyticsScreenView(String screenName) async {
    debugPrint('Analytics screen view: $screenName');
  }

  Future<void> announceUserForVersionTracking() async {
    debugPrint('announceUserForVersionTracking called');
  }

  /// Returns `null` as no FCM token is available without messaging.
  Future<String?> refreshToken() async {
    debugPrint('Firebase messaging disabled; no token available.');
    return null;
  }
}
