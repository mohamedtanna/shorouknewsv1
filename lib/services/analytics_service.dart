import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    debugPrint('Analytics event: $name, params: $parameters');
  }
}
