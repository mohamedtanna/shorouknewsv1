import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// If you decide to use a provider for notifications state
import 'package:shimmer/shimmer.dart';

import '../../services/notification_service.dart'; // Your main notification service
import '../../core/theme.dart';
// import '../../widgets/ad_banner.dart';
import 'notifications_module.dart'; // For utility functions like formatting

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationPayload> _notifications = [];
  bool _isLoading = true;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    // Ensure service is initialized (it should handle its own initialization state)
    await _notificationService.initialize();
    final history = _notificationService.getNotificationHistory();
    if (mounted) {
      setState(() {
        _notifications = List.from(history); // Make a mutable copy
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد'),
          content: const Text('هل أنت متأكد أنك تريد مسح جميع الإشعارات؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('مسح', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _notificationService.clearNotificationHistory();
      _loadNotifications(); // Refresh the list
    }
  }

  Widget _buildBreadcrumb() {
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
            onTap: () => context.go('/home'),
            child: const Text(
              'الرئيسية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text(
            'الإشعارات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الإشعارات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          if (_notifications.isNotEmpty && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'مسح السجل',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: Column(
          children: [
          // const AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
          _buildBreadcrumb(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _isLoading
                  ? _buildLoadingShimmer()
                  : _notifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 7, // Number of shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.white, radius: 25),
            title: Container(height: 16, width: double.infinity, color: Colors.white),
            subtitle: Container(height: 12, width: MediaQuery.of(context).size.width * 0.7, color: Colors.white),
            trailing: Container(height: 10, width: 50, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد إشعارات حالياً',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'سيتم عرض الإشعارات الجديدة هنا عند وصولها.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.separated(
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(
              NotificationsModule.getNotificationIcon(notification),
              color: AppTheme.primaryColor,
            ),
          ),
          title: Text(
            notification.title ?? 'إشعار جديد',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            notification.body ?? 'لا يوجد محتوى',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            NotificationsModule.formatTimestamp(notification.timestamp),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          onTap: () {
            // Navigate to NotificationDetailScreen
            // Pass the whole payload or necessary parts
            context.goNamed(
              'notification-detail',
               extra: notification, // Pass the entire payload
            );
          },
        );
      },
    );
  }
}
