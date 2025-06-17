import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simplified payload model for local notifications.
class NotificationPayload {
  final String? title;
  final String? body;
  final String? imageUrl;
  final String? navigationPath;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  NotificationPayload({
    this.title,
    this.body,
    this.imageUrl,
    this.navigationPath,
    required this.data,
    required this.timestamp,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      title: json['title'] as String?,
      body: json['body'] as String?,
      imageUrl: json['imageUrl'] as String?,
      navigationPath: json['navigationPath'] as String?,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'navigationPath': navigationPath,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class NotificationsModule {
  // Helper function to format the timestamp of a notification for display.
  // Example: "منذ 5 دقائق", "أمس الساعة 10:30 ص", "2023-03-15"
  static String formatTimestamp(DateTime timestamp, {bool detailed = false}) {
    return DateFormat('yyyy/MM/dd HH:mm', 'ar').format(timestamp);
  }

  // Helper to get a relevant icon for a notification type (if you add types)
  static IconData getNotificationIcon(NotificationPayload payload) {
    // Example logic:
    if (payload.navigationPath?.contains('/news/') == true) {
      return Icons.article_outlined;
    } else if (payload.navigationPath?.contains('/video/') == true) {
      return Icons.videocam_outlined;
    } else if (payload.navigationPath?.contains('/column/') == true) {
      return Icons.edit_note_outlined;
    }
    // Default icon for general notifications
    return Icons.notifications_active_outlined;
  }

  /// Load notification history stored in SharedPreferences.
  static Future<List<NotificationPayload>> loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('notification_history_v1');
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        return historyList
            .map((e) => NotificationPayload.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading notification history: $e');
    }
    return [];
  }

  /// Clear all stored notification history.
  static Future<void> clearNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_history_v1');
    } catch (e) {
      debugPrint('Error clearing notification history: $e');
    }
  }

  // You can add more utility functions here as needed, for example:
  // - Parsing specific data from payload.data
  // - Generating summary text for different notification types.
}
