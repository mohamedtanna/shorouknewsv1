import 'package:flutter/foundation.dart';

class AnalyticsService {
  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    debugPrint('Analytics event: \$name \$parameters');
  }
}
