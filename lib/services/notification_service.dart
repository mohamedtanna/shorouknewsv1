import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

import '../core/app_router.dart';

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
      title: json['title'],
      body: json['body'],
      imageUrl: json['imageUrl'],
      navigationPath: json['navigationPath'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
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

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  List<NotificationPayload> _notificationHistory = [];
  int _notificationId = 0;

  // Notification channels
  static const String _defaultChannelId = 'shorouk_news_default';
  static const String _breakingNewsChannelId = 'shorouk_news_breaking';
  static const String _updatesChannelId = 'shorouk_news_updates';

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      // MacOS initialization settings
      const DarwinInitializationSettings initializationSettingsMacOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combine initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: initializationSettingsMacOS,
      );

      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Create notification channels for Android
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      // Request permissions
      await _requestPermissions();

      // Load notification history
      await _loadNotificationHistory();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final plugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (plugin != null) {
      // Default channel
      await plugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _defaultChannelId,
          'الأخبار العامة',
          description: 'إشعارات الأخبار العامة من الشروق',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Breaking news channel
      await plugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _breakingNewsChannelId,
          'الأخبار العاجلة',
          description: 'إشعارات الأخبار العاجلة والمهمة',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.red,
        ),
      );

      // Updates channel
      await plugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _updatesChannelId,
          'تحديثات التطبيق',
          description: 'إشعارات تحديثات التطبيق والمقالات الجديدة',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );
    }
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final plugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      
      if (plugin != null) {
        final granted = await plugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } else if (Platform.isAndroid) {
      final plugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (plugin != null) {
        final granted = await plugin.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    return true;
  }

  // Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    bool isBreakingNews = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final payload = NotificationPayload(
        title: title,
        body: body,
        imageUrl: imageUrl,
        navigationPath: _extractNavigationPath(data),
        data: data ?? {},
        timestamp: DateTime.now(),
      );

      // Add to history
      _notificationHistory.insert(0, payload);
      await _saveNotificationHistory();

      // Generate unique notification ID
      final notificationId = _getNextNotificationId();

      // Select appropriate channel
      String channelId = _defaultChannelId;
      if (isBreakingNews) {
        channelId = _breakingNewsChannelId;
      }

      // Android notification details
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: _getImportance(priority),
        priority: _getPriority(priority),
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        usesChronometer: false,
        playSound: priority != NotificationPriority.low,
        enableVibration: priority != NotificationPriority.low,
        enableLights: isBreakingNews,
        ledColor: isBreakingNews ? Colors.red : null,
        ledOnMs: isBreakingNews ? 1000 : null,
        ledOffMs: isBreakingNews ? 500 : null,
        ticker: title,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: 'الشروق',
          htmlFormatSummaryText: true,
        ),
        actions: [
          const AndroidNotificationAction(
            'read_action',
            'قراءة',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'dismiss_action',
            'تجاهل',
            cancelNotification: true,
          ),
        ],
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'shorouk_news',
        categoryIdentifier: 'shorouk_category',
      );

      // Combined notification details
      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(payload.toJson()),
      );

      // Show big picture notification if image URL is provided
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _showBigPictureNotification(
          notificationId + 1000, // Offset to avoid conflicts
          title,
          body,
          imageUrl,
          payload,
        );
      }

      debugPrint('Notification shown: $title');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Show big picture notification with image
  Future<void> _showBigPictureNotification(
    int id,
    String title,
    String body,
    String imageUrl,
    NotificationPayload payload,
  ) async {
    try {
      final BigPictureStyleInformation bigPictureStyleInformation =
          BigPictureStyleInformation(
        NetworkImage(imageUrl),
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: body,
        htmlFormatSummaryText: true,
      );

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _defaultChannelId,
        'الأخبار العامة',
        channelDescription: 'إشعارات الأخبار العامة من الشروق',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: bigPictureStyleInformation,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(payload.toJson()),
      );
    } catch (e) {
      debugPrint('Error showing big picture notification: $e');
    }
  }

  // Schedule a notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final payload = NotificationPayload(
        title: title,
        body: body,
        imageUrl: imageUrl,
        navigationPath: _extractNavigationPath(data),
        data: data ?? {},
        timestamp: scheduledDate,
      );

      final notificationId = _getNextNotificationId();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _updatesChannelId,
        'تحديثات التطبيق',
        channelDescription: 'إشعارات تحديثات التطبيق والمقالات الجديدة',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode(payload.toJson()),
      );

      debugPrint('Notification scheduled for: $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Show progress notification
  Future<void> showProgressNotification({
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _updatesChannelId,
        'تحديثات التطبيق',
        channelDescription: 'إشعارات تحديثات التطبيق والمقالات الجديدة',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: maxProgress,
        progress: progress,
        indeterminate: false,
        autoCancel: false,
        ongoing: true,
        onlyAlertOnce: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        999, // Fixed ID for progress notifications
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing progress notification: $e');
    }
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Handle notification tap
  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        final payload = NotificationPayload.fromJson(data);
        
        _handleNotificationNavigation(payload, response.actionId);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  // Handle iOS foreground notification
  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('iOS foreground notification: $title - $body');
  }

  // Handle notification navigation
  static void _handleNotificationNavigation(
    NotificationPayload payload,
    String? actionId,
  ) {
    if (actionId == 'dismiss_action') {
      return; // Do nothing for dismiss action
    }

    // Navigate to appropriate screen based on payload data
    String? navigationPath = payload.navigationPath;
    
    if (navigationPath == null) {
      // Try to determine navigation path from data
      final data = payload.data;
      
      if (data.containsKey('newsId') && data.containsKey('cdate')) {
        navigationPath = '/news/${data['cdate']}/${data['newsId']}';
      } else if (data.containsKey('videoId')) {
        navigationPath = '/video/${data['videoId']}';
      } else if (data.containsKey('columnId') && data.containsKey('cdate')) {
        navigationPath = '/column/${data['cdate']}/${data['columnId']}';
      } else if (data.containsKey('sectionId')) {
        navigationPath = '/news?sectionId=${data['sectionId']}';
      } else {
        navigationPath = '/home';
      }
    }

    // Use router to navigate
    if (navigationPath != null) {
      AppRouter.router.go(navigationPath);
    }
  }

  // Extract navigation path from data
  String? _extractNavigationPath(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    if (data.containsKey('link')) {
      return data['link'];
    } else if (data.containsKey('url')) {
      return data['url'];
    }
    
    return null;
  }

  // Get next notification ID
  int _getNextNotificationId() {
    return ++_notificationId;
  }

  // Convert DateTime to TZDateTime
  TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // For simplicity, using UTC. In production, use proper timezone handling
    return TZDateTime.from(dateTime, TZ.UTC);
  }

  // Get channel name
  String _getChannelName(String channelId) {
    switch (channelId) {
      case _defaultChannelId:
        return 'الأخبار العامة';
      case _breakingNewsChannelId:
        return 'الأخبار العاجلة';
      case _updatesChannelId:
        return 'تحديثات التطبيق';
      default:
        return 'إشعارات الشروق';
    }
  }

  // Get channel description
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _defaultChannelId:
        return 'إشعارات الأخبار العامة من الشروق';
      case _breakingNewsChannelId:
        return 'إشعارات الأخبار العاجلة والمهمة';
      case _updatesChannelId:
        return 'إشعارات تحديثات التطبيق والمقالات الجديدة';
      default:
        return 'إشعارات عامة من تطبيق الشروق';
    }
  }

  // Get Android importance level
  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  // Get Android priority level
  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  // Load notification history
  Future<void> _loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('notification_history');
      
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _notificationHistory = historyList
            .map((item) => NotificationPayload.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading notification history: $e');
    }
  }

  // Save notification history
  Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Keep only last 100 notifications
      if (_notificationHistory.length > 100) {
        _notificationHistory = _notificationHistory.take(100).toList();
      }
      
      final historyJson = jsonEncode(
        _notificationHistory.map((notification) => notification.toJson()).toList(),
      );
      
      await prefs.setString('notification_history', historyJson);
    } catch (e) {
      debugPrint('Error saving notification history: $e');
    }
  }

  // Get notification history
  List<NotificationPayload> getNotificationHistory() {
    return List.unmodifiable(_notificationHistory);
  }

  // Clear notification history
  Future<void> clearNotificationHistory() async {
    _notificationHistory.clear();
    await _saveNotificationHistory();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final plugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (plugin != null) {
        return await plugin.areNotificationsEnabled() ?? false;
      }
    }
    return true;
  }

  // Open notification settings
  Future<void> openNotificationSettings() async {
    if (Platform.isAndroid) {
      final plugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (plugin != null) {
        await plugin.requestNotificationsPermission();
      }
    }
  }

  // Test notification
  Future<void> sendTestNotification() async {
    await showNotification(
      title: 'اختبار الإشعارات',
      body: 'هذا إشعار اختبار من تطبيق الشروق',
      data: {'test': 'true'},
      priority: NotificationPriority.normal,
    );
  }

  // Dispose
  void dispose() {
    // Clean up resources if needed
  }
}

// Notification priority enum
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

// Missing timezone import placeholder
class TZ {
  static get UTC => null;
}

class TZDateTime {
  static TZDateTime from(DateTime dateTime, dynamic location) {
    // Placeholder implementation
    return TZDateTime._internal();
  }
  
  TZDateTime._internal();
}