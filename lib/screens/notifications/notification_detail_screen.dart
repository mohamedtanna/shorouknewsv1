import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // If body can contain HTML
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'notifications_module.dart'; // For NotificationPayload and utilities
import '../../core/theme.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationPayload notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  Future<void> _handleNavigation(BuildContext context) async {
    if (notification.navigationPath != null &&
        notification.navigationPath!.isNotEmpty) {
      // Attempt to navigate using GoRouter
      // This assumes the navigationPath is a valid route in your app
      try {
        context.push(notification.navigationPath!);
      } catch (e) {
        debugPrint("Failed to navigate to ${notification.navigationPath}: $e");
        // Optionally, show a message to the user if navigation fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح الرابط: ${notification.navigationPath}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareNotification() async {
    String shareText = notification.title ?? 'إشعار من الشروق';
    if (notification.body != null && notification.body!.isNotEmpty) {
      shareText += '\n\n${notification.body}';
    }
    if (notification.navigationPath != null && notification.navigationPath!.isNotEmpty) {
      // Ideally, you'd share a web link to the content if available
      // For now, appending the app's navigation path or a placeholder
      shareText += '\n\nاقرأ المزيد: ${notification.navigationPath}';
    }
    await Share.share(shareText, subject: notification.title ?? 'إشعار من الشروق');
  }


  Widget _buildBreadcrumb(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.tertiaryColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Text(
              'الرئيسية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
           GestureDetector(
            onTap: () => context.push('/notifications'), // Navigate back to notifications list
            child: const Text(
              'الإشعارات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              notification.title ?? 'تفاصيل الإشعار',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(notification.title ?? 'تفاصيل الإشعار'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.push('/notifications'); // Fallback
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareNotification,
            tooltip: 'مشاركة الإشعار',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumb(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    notification.title ?? 'لا يوجد عنوان',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Timestamp
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_outlined, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        NotificationsModule.formatTimestamp(notification.timestamp, detailed: true),
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image (if available)
                  if (notification.imageUrl != null &&
                      notification.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: CachedNetworkImage(
                          imageUrl: notification.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => AspectRatio(
                            aspectRatio: 16/9,
                            child: Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                          ),
                          errorWidget: (context, url, error) => AspectRatio(
                            aspectRatio: 16/9,
                            child: Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Body content
                  // Use Html widget if body can contain HTML, otherwise Text
                  if (notification.body != null && notification.body!.isNotEmpty)
                    Html(
                      data: notification.body!,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(16),
                          lineHeight: const LineHeight(1.6),
                        ),
                        "p": Style(
                          margin: Margins.only(bottom: 12),
                        ),
                        // Add more styles for other HTML tags if needed
                      },
                      onLinkTap: (url, attributes, element) {
                        if (url != null) {
                           // Try to launch URL externally
                           Uri? uri = Uri.tryParse(url);
                           if (uri != null) {
                             launchUrl(uri, mode: LaunchMode.externalApplication);
                           }
                        }
                      },
                    )
                  else
                    const Text(
                      'لا يوجد محتوى لهذا الإشعار.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),

                  const SizedBox(height: 24),

                  // Navigation button (if path exists)
                  if (notification.navigationPath != null &&
                      notification.navigationPath!.isNotEmpty)
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new_outlined),
                        label: const Text('الانتقال إلى المحتوى'),
                        onPressed: () => _handleNavigation(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tertiaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
