import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../services/notification_service.dart'; // Access to NotificationPayload

class NotificationsModule {
  // Helper function to format the timestamp of a notification for display.
  // Example: "منذ 5 دقائق", "أمس الساعة 10:30 ص", "2023-03-15"
  static String formatTimestamp(DateTime timestamp, {bool detailed = false}) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        if (difference.inMinutes < 1) {
          return 'الآن';
        }
        return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
      }
      if (detailed) {
        return 'اليوم, ${DateFormat('h:mm a', 'ar').format(timestamp)}';
      }
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inDays == 1) {
      return 'أمس, ${DateFormat('h:mm a', 'ar').format(timestamp)}';
    } else if (difference.inDays < 7) {
      // Within the last week, show day name and time
      return '${DateFormat('EEEE', 'ar').format(timestamp)}, ${DateFormat('h:mm a', 'ar').format(timestamp)}';
    } else {
      // Older than a week, show full date
      return DateFormat('yyyy/MM/dd', 'ar').format(timestamp);
    }
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

  // You can add more utility functions here as needed, for example:
  // - Parsing specific data from payload.data
  // - Generating summary text for different notification types.
}
