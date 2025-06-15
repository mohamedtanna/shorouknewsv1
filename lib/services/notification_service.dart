import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Unused
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data'; // For Uint8List for images
import 'package:http/http.dart' as http; // For downloading images

// Timezone package for scheduled notifications
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
      title: json['title'] as String?,
      body: json['body'] as String?,
      imageUrl: json['imageUrl'] as String?,
      navigationPath: json['navigationPath'] as String?,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
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

// Enum for notification priorities, matching flutter_local_notifications
enum NotificationPriorityLevel {
  low,
  normal,
  high,
  urgent,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  List<NotificationPayload> _notificationHistory = [];
  int _notificationIdCounter = 0; // Renamed for clarity

  // Notification channels (IDs should be unique)
  static const String _defaultChannelId = 'shorouk_news_default_channel';
  static const String _breakingNewsChannelId = 'shorouk_news_breaking_channel';
  static const String _updatesChannelId = 'shorouk_news_updates_channel';

  // Helper to download image for BigPictureStyle
  Future<Uint8List?> _getByteArrayFromUrl(String url) async {
    try {
      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('Failed to load image from $url, status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading image from $url: $e');
      return null;
    }
  }


  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      // Set a default local location (e.g., your app's primary user base)
      // This can be updated later if you get user's specific timezone.
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      } catch(e) {
        debugPrint("Error setting default timezone, using UTC. $e");
        // Fallback or handle as needed if location is not found
      }


      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher'); // Ensure this icon exists

      // iOS & macOS initialization settings
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        // For older iOS (<=9) foreground notifications.
        // For iOS 10+, onDidReceiveNotificationResponse is used.
       // onDidReceiveLocalNotification: _onDidReceiveLocalNotificationForOldIOS,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin, // Can use the same for macOS
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
      );

      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      await _requestPermissions();
      await _loadNotificationHistory();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _defaultChannelId,
          'الأخبار العامة', // General News
          description: 'إشعارات الأخبار العامة من الشروق',
          importance: Importance.defaultImportance,
        ),
      );
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _breakingNewsChannelId,
          'الأخبار العاجلة', // Breaking News
          description: 'إشعارات الأخبار العاجلة والمهمة',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          ledColor: Colors.red,
          enableLights: true,
        ),
      );
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _updatesChannelId,
          'تحديثات التطبيق', // App Updates
          description: 'إشعارات تحديثات التطبيق والمقالات الجديدة',
          importance: Importance.low,
        ),
      );
      debugPrint("Android notification channels created.");
    }
  }

  Future<bool> _requestPermissions() async {
    bool? permissionsGranted = false;
    if (Platform.isIOS || Platform.isMacOS) {
      permissionsGranted = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      permissionsGranted ??= await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      permissionsGranted = await androidImplementation?.requestNotificationsPermission();
    }
    debugPrint("Notification permissions granted: $permissionsGranted");
    return permissionsGranted ?? false;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationPriorityLevel priority = NotificationPriorityLevel.normal,
    bool isBreakingNews = false,
  }) async {
    if (!_isInitialized) await initialize();

    final payload = NotificationPayload(
      title: title,
      body: body,
      imageUrl: imageUrl,
      navigationPath: _extractNavigationPath(data),
      data: data ?? {},
      timestamp: DateTime.now(),
    );

    _notificationHistory.insert(0, payload);
    await _saveNotificationHistory();

    final int notificationId = _getNextNotificationId();
    String channelId = isBreakingNews ? _breakingNewsChannelId : _defaultChannelId;

    AndroidNotificationDetails? androidDetails;
    ByteArrayAndroidBitmap? bigPictureBitmap;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final imageBytes = await _getByteArrayFromUrl(imageUrl);
      if (imageBytes != null) {
        bigPictureBitmap = ByteArrayAndroidBitmap(imageBytes);
      }
    }

    androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: _getImportance(priority),
      priority: _getPriority(priority),
      showWhen: true,
      ticker: title,
      styleInformation: bigPictureBitmap != null
          ? BigPictureStyleInformation(
              bigPictureBitmap,
              largeIcon: bigPictureBitmap, // Can also use a different icon for largeIcon
              contentTitle: title,
              htmlFormatContentTitle: true,
              summaryText: body,
              htmlFormatSummaryText: true,
            )
          : BigTextStyleInformation( // Default to BigText if no image
              body,
              htmlFormatBigText: true,
              contentTitle: title,
              htmlFormatContentTitle: true,
              summaryText: 'الشروق نيوز',
              htmlFormatSummaryText: true,
            ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('read_action', 'قراءة', showsUserInterface: true),
        const AndroidNotificationAction('dismiss_action', 'تجاهل', cancelNotification: true),
      ],
      ledColor: isBreakingNews ? Colors.red : null,
      enableLights: isBreakingNews,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'shorouk_news_thread',
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(payload.toJson()),
      );
      debugPrint('Notification shown: ID $notificationId, Title: $title');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Note: _showBigPictureNotification is now integrated into showNotification.

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? imageUrl, // imageUrl for scheduled notifications might be complex due to caching/validity
    Map<String, dynamic>? data,
    NotificationPriorityLevel priority = NotificationPriorityLevel.normal,
  }) async {
    if (!_isInitialized) await initialize();

    final payload = NotificationPayload(
      title: title,
      body: body,
      imageUrl: imageUrl,
      navigationPath: _extractNavigationPath(data),
      data: data ?? {},
      timestamp: scheduledDate,
    );

    final int notificationId = _getNextNotificationId();
    final tz.TZDateTime tzScheduledDate = _convertToTZDateTime(scheduledDate);

    // For scheduled notifications, BigPictureStyle might be less reliable if URL expires.
    // Consider downloading image at schedule time if critical, or use simpler notification.
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _updatesChannelId, // Use updates channel or a specific scheduled channel
      _getChannelName(_updatesChannelId),
      channelDescription: _getChannelDescription(_updatesChannelId),
      importance: _getImportance(priority),
      priority: _getPriority(priority),
    );
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(presentSound: true);

    final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      //  uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode(payload.toJson()),
        matchDateTimeComponents: DateTimeComponents.time, // Or .dateAndTime depending on needs
      );
      debugPrint('Notification scheduled for: $tzScheduledDate, ID: $notificationId');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }
  
  Future<void> showProgressNotification({
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    int id = 999, // Fixed ID for progress, or manage dynamically
  }) async {
    if (!_isInitialized) await initialize();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _updatesChannelId,
      _getChannelName(_updatesChannelId),
      channelDescription: _getChannelDescription(_updatesChannelId),
      importance: Importance.low, // Progress usually low importance
      priority: Priority.low,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      indeterminate: maxProgress == 0, // Indeterminate if maxProgress is 0
      autoCancel: progress == maxProgress, // Auto cancel when complete
      ongoing: progress < maxProgress, // Ongoing until complete
      onlyAlertOnce: true,
    );
    final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    try {
      await _flutterLocalNotificationsPlugin.show(id, title, body, notificationDetails);
    } catch (e) {
      debugPrint('Error showing progress notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  static void _onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('Background Notification Tapped (payload: ${response.payload})');
    // Handle navigation or other actions for background taps
    // This might be where you initialize parts of your app if it was terminated
     if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        final payload = NotificationPayload.fromJson(data);
        _handleNotificationNavigation(payload, response.actionId);
      } catch (e) {
        debugPrint('Error parsing background notification payload: $e');
      }
    }
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Notification Tapped (payload: ${response.payload}) Action: ${response.actionId}');
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

  // Callback for older iOS versions (<=9) when app is in foreground

  static void _handleNotificationNavigation(NotificationPayload payload, String? actionId) {
    if (actionId == 'dismiss_action') {
      debugPrint('Notification dismissed by user action.');
      return;
    }

    String? navigationPath = payload.navigationPath;
    if (navigationPath == null || navigationPath.isEmpty) {
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
        navigationPath = '/home'; // Default fallback
      }
    }
    
    debugPrint('Attempting to navigate to: $navigationPath');
    // Ensure AppRouter.router is accessible or pass it if needed
    // For simplicity, assuming AppRouter.router is a static getter.
    try {
        AppRouter.router.go(navigationPath);
    } catch (e) {
        debugPrint("Error navigating from notification: $e. Path: $navigationPath");
        // Fallback if specific navigation fails
        AppRouter.router.go('/home');
    }
  }

  String? _extractNavigationPath(Map<String, dynamic>? data) {
    if (data == null) return null;
    return data['link']?.toString() ?? data['url']?.toString();
  }

  int _getNextNotificationId() {
    _notificationIdCounter++;
    return _notificationIdCounter;
  }

  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // Ensure tz.local is properly initialized (e.g., tz.setLocalLocation(tz.getLocation('Africa/Cairo')))
    // If not, this will use UTC or whatever the default local location is.
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case _defaultChannelId: return 'الأخبار العامة';
      case _breakingNewsChannelId: return 'الأخبار العاجلة';
      case _updatesChannelId: return 'تحديثات التطبيق';
      default: return 'إشعارات الشروق';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _defaultChannelId: return 'إشعارات الأخبار العامة من الشروق';
      case _breakingNewsChannelId: return 'إشعارات الأخبار العاجلة والمهمة';
      case _updatesChannelId: return 'إشعارات تحديثات التطبيق والمقالات الجديدة';
      default: return 'إشعارات عامة من تطبيق الشروق';
    }
  }

  Importance _getImportance(NotificationPriorityLevel priority) {
    switch (priority) {
      case NotificationPriorityLevel.low: return Importance.low;
      case NotificationPriorityLevel.normal: return Importance.defaultImportance;
      case NotificationPriorityLevel.high: return Importance.high;
      case NotificationPriorityLevel.urgent: return Importance.max;
    }
  }

  Priority _getPriority(NotificationPriorityLevel priority) {
    switch (priority) {
      case NotificationPriorityLevel.low: return Priority.low;
      case NotificationPriorityLevel.normal: return Priority.defaultPriority;
      case NotificationPriorityLevel.high: return Priority.high;
      case NotificationPriorityLevel.urgent: return Priority.max;
    }
  }

  Future<void> _loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('notification_history_v1'); // Versioned key
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _notificationHistory = historyList
            .map((item) => NotificationPayload.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('${_notificationHistory.length} notifications loaded from history.');
      }
    } catch (e) {
      debugPrint('Error loading notification history: $e');
      _notificationHistory = []; // Ensure it's empty on error
    }
  }

  Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_notificationHistory.length > 100) {
        _notificationHistory = _notificationHistory.sublist(0, 100);
      }
      final historyJson = jsonEncode(
          _notificationHistory.map((n) => n.toJson()).toList());
      await prefs.setString('notification_history_v1', historyJson);
    } catch (e) {
      debugPrint('Error saving notification history: $e');
    }
  }

  List<NotificationPayload> getNotificationHistory() {
    return List.unmodifiable(_notificationHistory);
  }

  Future<void> clearNotificationHistory() async {
    _notificationHistory.clear();
    await _saveNotificationHistory();
    debugPrint('Notification history cleared.');
  }

  Future<bool> arePlatformNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }
    // For iOS, permission is requested. System-level check is different.
    // This method primarily reflects Android's specific API.
    return true; // Assume enabled or rely on permission request for iOS
  }

  Future<void> openPlatformNotificationSettings() async {
    // This functionality is not directly provided by flutter_local_notifications.
    // You might need another plugin like `app_settings` to open system settings.
    // For Android, requesting permission again often takes user to settings if denied.
    if (Platform.isAndroid) {
       await _requestPermissions(); // Re-requesting can sometimes open settings
    }
    debugPrint("Attempted to open platform notification settings (manual implementation may be needed via other plugins for direct navigation).");
  }

  Future<void> sendTestNotification() async {
    await showNotification(
      title: 'اختبار الإشعارات من التطبيق',
      body: 'هذا إشعار اختباري للتحقق من عمل خدمة الإشعارات المحلية.',
      data: {'test_id': '123', 'type': 'test_notification'},
      priority: NotificationPriorityLevel.high,
      isBreakingNews: true, // To test breaking news channel
      imageUrl: 'https://via.placeholder.com/400x200.png?text=Test+Image' // Test image
    );
  }

  void dispose() {
    // No specific resources to dispose in this singleton,
    // but if you had streams, close them here.
  }
}
