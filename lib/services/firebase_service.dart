import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';



/// Stubbed FirebaseService with Firebase functionality disabled.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();


  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
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
