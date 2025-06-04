import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'dart:io';

import '../services/firebase_service.dart';
import '../services/api_service.dart';

class User {
  final String id;
  final String? email;
  final String? name;
  final String fcmToken;
  final String deviceId;
  final String deviceType;
  final String deviceModel;
  final String appVersion;
  final int osType; // 0: other, 1: Android, 2: iOS
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    this.email,
    this.name,
    required this.fcmToken,
    required this.deviceId,
    required this.deviceType,
    required this.deviceModel,
    required this.appVersion,
    required this.osType,
    required this.createdAt,
    required this.lastActiveAt,
    required this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'],
      name: json['name'],
      fcmToken: json['fcmToken'] ?? '',
      deviceId: json['deviceId'] ?? '',
      deviceType: json['deviceType'] ?? '',
      deviceModel: json['deviceModel'] ?? '',
      appVersion: json['appVersion'] ?? '',
      osType: json['osType'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] ?? DateTime.now().toIso8601String()),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'fcmToken': fcmToken,
      'deviceId': deviceId,
      'deviceType': deviceType,
      'deviceModel': deviceModel,
      'appVersion': appVersion,
      'osType': osType,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? fcmToken,
    String? deviceId,
    String? deviceType,
    String? deviceModel,
    String? appVersion,
    int? osType,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      fcmToken: fcmToken ?? this.fcmToken,
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      deviceModel: deviceModel ?? this.deviceModel,
      appVersion: appVersion ?? this.appVersion,
      osType: osType ?? this.osType,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Reading preferences
  double _fontSize = 16.0;
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  String _preferredLanguage = 'ar';

  // App usage statistics
  int _appOpenCount = 0;
  int _newsReadCount = 0;
  int _videosWatchedCount = 0;
  int _columnsReadCount = 0;
  DateTime? _firstInstallDate;
  DateTime? _lastUsedDate;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;
  
  // Preferences getters
  double get fontSize => _fontSize;
  bool get darkMode => _darkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get preferredLanguage => _preferredLanguage;
  
  // Statistics getters
  int get appOpenCount => _appOpenCount;
  int get newsReadCount => _newsReadCount;
  int get videosWatchedCount => _videosWatchedCount;
  int get columnsReadCount => _columnsReadCount;
  DateTime? get firstInstallDate => _firstInstallDate;
  DateTime? get lastUsedDate => _lastUsedDate;

  // Initialize authentication
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load user data from local storage
      await _loadUserData();
      
      // Initialize Firebase
      await _firebaseService.initialize();
      
      // Create or update user
      await _createOrUpdateUser();
      
      // Load user preferences
      await _loadUserPreferences();
      
      // Load app statistics
      await _loadAppStatistics();
      
      // Update last used date and app open count
      await _updateAppUsage();
      
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Failed to initialize: ${e.toString()}';
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user data from local storage
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        final Map<String, dynamic> userJson = jsonDecode(userData);
        _currentUser = User.fromJson(userJson);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Save user data to local storage
  Future<void> _saveUserData() async {
    if (_currentUser == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Create or update user
  Future<void> _createOrUpdateUser() async {
    try {
      final fcmToken = _firebaseService.fcmToken;
      if (fcmToken == null) {
        throw Exception('FCM token not available');
      }

      // Get device information
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Create user ID based on FCM token
      final userId = _generateUserId(fcmToken);
      
      // Create or update user object
      _currentUser = User(
        id: userId,
        fcmToken: fcmToken,
        deviceId: deviceInfo['deviceId'],
        deviceType: deviceInfo['deviceType'],
        deviceModel: deviceInfo['deviceModel'],
        appVersion: packageInfo.version,
        osType: deviceInfo['osType'],
        createdAt: _currentUser?.createdAt ?? DateTime.now(),
        lastActiveAt: DateTime.now(),
        preferences: _currentUser?.preferences ?? {},
      );

      // Create user on server
      await _apiService.createUser(
        token: fcmToken,
        os: deviceInfo['osType'],
        deviceType: deviceInfo['deviceType'],
        deviceModel: deviceInfo['deviceModel'],
      );

      // Save user data locally
      await _saveUserData();
      
    } catch (e) {
      debugPrint('Error creating/updating user: $e');
      rethrow;
    }
  }

  // Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'deviceId': androidInfo.id,
          'deviceType': androidInfo.manufacturer,
          'deviceModel': androidInfo.model,
          'osType': 1, // Android
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'deviceType': 'Apple',
          'deviceModel': iosInfo.model,
          'osType': 2, // iOS
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    
    return {
      'deviceId': 'unknown',
      'deviceType': 'Unknown',
      'deviceModel': 'Unknown',
      'osType': 0, // Other
    };
  }

  // Generate user ID from FCM token
  String _generateUserId(String fcmToken) {
    // Create a consistent user ID based on FCM token
    return fcmToken.hashCode.abs().toString();
  }

  // Load user preferences
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _fontSize = prefs.getDouble('font_size') ?? 16.0;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _preferredLanguage = prefs.getString('preferred_language') ?? 'ar';
      
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }
  }

  // Save user preferences
  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setDouble('font_size', _fontSize);
      await prefs.setBool('dark_mode', _darkMode);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setString('preferred_language', _preferredLanguage);
      
    } catch (e) {
      debugPrint('Error saving user preferences: $e');
    }
  }

  // Load app statistics
  Future<void> _loadAppStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _appOpenCount = prefs.getInt('app_open_count') ?? 0;
      _newsReadCount = prefs.getInt('news_read_count') ?? 0;
      _videosWatchedCount = prefs.getInt('videos_watched_count') ?? 0;
      _columnsReadCount = prefs.getInt('columns_read_count') ?? 0;
      
      final firstInstallString = prefs.getString('first_install_date');
      if (firstInstallString != null) {
        _firstInstallDate = DateTime.parse(firstInstallString);
      } else {
        _firstInstallDate = DateTime.now();
        await prefs.setString('first_install_date', _firstInstallDate!.toIso8601String());
      }
      
      final lastUsedString = prefs.getString('last_used_date');
      if (lastUsedString != null) {
        _lastUsedDate = DateTime.parse(lastUsedString);
      }
      
    } catch (e) {
      debugPrint('Error loading app statistics: $e');
    }
  }

  // Save app statistics
  Future<void> _saveAppStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('app_open_count', _appOpenCount);
      await prefs.setInt('news_read_count', _newsReadCount);
      await prefs.setInt('videos_watched_count', _videosWatchedCount);
      await prefs.setInt('columns_read_count', _columnsReadCount);
      
      if (_lastUsedDate != null) {
        await prefs.setString('last_used_date', _lastUsedDate!.toIso8601String());
      }
      
    } catch (e) {
      debugPrint('Error saving app statistics: $e');
    }
  }

  // Update app usage
  Future<void> _updateAppUsage() async {
    _appOpenCount++;
    _lastUsedDate = DateTime.now();
    
    await _saveAppStatistics();
    
    // Log analytics
    await _firebaseService.logEvent('app_open', {
      'open_count': _appOpenCount,
      'user_id': _currentUser?.id,
    });
    
    notifyListeners();
  }

  // Update font size
  Future<void> updateFontSize(double fontSize) async {
    if (fontSize >= 12.0 && fontSize <= 24.0) {
      _fontSize = fontSize;
      await _saveUserPreferences();
      notifyListeners();
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode(bool enabled) async {
    _darkMode = enabled;
    await _saveUserPreferences();
    notifyListeners();
  }

  // Toggle notifications
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveUserPreferences();
    notifyListeners();
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    _preferredLanguage = languageCode;
    await _saveUserPreferences();
    notifyListeners();
  }

  // Track news read
  Future<void> trackNewsRead(String newsId) async {
    _newsReadCount++;
    await _saveAppStatistics();
    
    // Track on server
    await _apiService.trackNewsView(newsId);
    
    // Log analytics
    await _firebaseService.logEvent('news_read', {
      'news_id': newsId,
      'user_id': _currentUser?.id,
      'total_read': _newsReadCount,
    });
    
    notifyListeners();
  }

  // Track video watched
  Future<void> trackVideoWatched(String videoId) async {
    _videosWatchedCount++;
    await _saveAppStatistics();
    
    // Track on server
    await _apiService.trackVideoView(videoId);
    
    // Log analytics
    await _firebaseService.logEvent('video_watched', {
      'video_id': videoId,
      'user_id': _currentUser?.id,
      'total_watched': _videosWatchedCount,
    });
    
    notifyListeners();
  }

  // Track column read
  Future<void> trackColumnRead(String columnId) async {
    _columnsReadCount++;
    await _saveAppStatistics();
    
    // Track on server
    await _apiService.trackColumnView(columnId);
    
    // Log analytics
    await _firebaseService.logEvent('column_read', {
      'column_id': columnId,
      'user_id': _currentUser?.id,
      'total_read': _columnsReadCount,
    });
    
    notifyListeners();
  }

  // Update user preference
  Future<void> updateUserPreference(String key, dynamic value) async {
    if (_currentUser != null) {
      final updatedPreferences = Map<String, dynamic>.from(_currentUser!.preferences);
      updatedPreferences[key] = value;
      
      _currentUser = _currentUser!.copyWith(preferences: updatedPreferences);
      await _saveUserData();
      notifyListeners();
    }
  }

  // Get user preference
  T? getUserPreference<T>(String key) {
    if (_currentUser?.preferences.containsKey(key) == true) {
      return _currentUser!.preferences[key] as T?;
    }
    return null;
  }

  // Refresh FCM token
  Future<void> refreshFCMToken() async {
    try {
      final newToken = await _firebaseService.refreshToken();
      if (newToken != null && _currentUser != null) {
        _currentUser = _currentUser!.copyWith(fcmToken: newToken);
        await _saveUserData();
        
        // Update on server
        await _createOrUpdateUser();
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
    }
  }

  // Announce user (for version tracking)
  Future<void> announceUser() async {
    try {
      if (_currentUser?.fcmToken != null) {
        await _firebaseService.announceUser();
      }
    } catch (e) {
      debugPrint('Error announcing user: $e');
    }
  }

  // Get user statistics summary
  Map<String, dynamic> getUserStatistics() {
    return {
      'appOpenCount': _appOpenCount,
      'newsReadCount': _newsReadCount,
      'videosWatchedCount': _videosWatchedCount,
      'columnsReadCount': _columnsReadCount,
      'firstInstallDate': _firstInstallDate?.toIso8601String(),
      'lastUsedDate': _lastUsedDate?.toIso8601String(),
      'daysSinceInstall': _firstInstallDate != null 
          ? DateTime.now().difference(_firstInstallDate!).inDays 
          : 0,
    };
  }

  // Reset statistics
  Future<void> resetStatistics() async {
    _appOpenCount = 0;
    _newsReadCount = 0;
    _videosWatchedCount = 0;
    _columnsReadCount = 0;
    
    await _saveAppStatistics();
    notifyListeners();
  }

  // Clear user data (logout)
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove user-specific data
      await prefs.remove('user_data');
      await prefs.remove('notification_settings');
      
      // Reset current user
      _currentUser = null;
      _isInitialized = false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  // Export user data
  Map<String, dynamic> exportUserData() {
    return {
      'user': _currentUser?.toJson(),
      'preferences': {
        'fontSize': _fontSize,
        'darkMode': _darkMode,
        'notificationsEnabled': _notificationsEnabled,
        'preferredLanguage': _preferredLanguage,
      },
      'statistics': getUserStatistics(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Check if user is new (first week)
  bool get isNewUser {
    if (_firstInstallDate == null) return true;
    return DateTime.now().difference(_firstInstallDate!).inDays <= 7;
  }

  // Check if user is active (used in last 7 days)
  bool get isActiveUser {
    if (_lastUsedDate == null) return false;
    return DateTime.now().difference(_lastUsedDate!).inDays <= 7;
  }

  // Get user engagement level
  String get userEngagementLevel {
    final totalInteractions = _newsReadCount + _videosWatchedCount + _columnsReadCount;
    
    if (totalInteractions < 10) return 'beginner';
    if (totalInteractions < 50) return 'casual';
    if (totalInteractions < 200) return 'regular';
    return 'power_user';
  }

  @override
  void dispose() {
    super.dispose();
  }
}