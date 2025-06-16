import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'dart:io' show Platform;

import '../services/api_service.dart';

// User Model (assuming it's defined as you provided)
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
      id: json['id']?.toString() ?? '', // Ensure ID is a string
      email: json['email'] as String?,
      name: json['name'] as String?,
      fcmToken: json['fcmToken'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      deviceType: json['deviceType'] as String? ?? '',
      deviceModel: json['deviceModel'] as String? ?? '',
      appVersion: json['appVersion'] as String? ?? '',
      osType: json['osType'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt']?.toString() ?? '') ?? DateTime.now(),
      preferences: Map<String, dynamic>.from(json['preferences'] as Map? ?? {}),
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
      await _loadUserData();
      await _createOrUpdateUser();
      await _loadUserPreferences();
      await _loadAppStatistics();
      await _updateAppUsage();
      
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'فشل تهيئة المصادقة: ${e.toString()}';
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data_v1'); // Consider versioning keys
      
      if (userDataString != null) {
        final Map<String, dynamic> userJson = jsonDecode(userDataString);
        _currentUser = User.fromJson(userJson);
        debugPrint('User data loaded from SharedPreferences.');
      } else {
        debugPrint('No user data found in SharedPreferences.');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Optionally clear corrupted data
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove('user_data_v1');
    }
  }

  Future<void> _saveUserData() async {
    if (_currentUser == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data_v1', jsonEncode(_currentUser!.toJson()));
      debugPrint('User data saved to SharedPreferences.');
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  Future<void> _createOrUpdateUser() async {
    try {
      final deviceInfoMap = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();
      final seed = deviceInfoMap['deviceId'] as String;
      final userId = _generateUserId(seed);

      _currentUser = User(
        id: userId,
        fcmToken: '',
        deviceId: deviceInfoMap['deviceId'] as String,
        deviceType: deviceInfoMap['deviceType'] as String,
        deviceModel: deviceInfoMap['deviceModel'] as String,
        appVersion: packageInfo.version,
        osType: deviceInfoMap['osType'] as int,
        createdAt: _currentUser?.createdAt ?? DateTime.now(),
        lastActiveAt: DateTime.now(),
        preferences: _currentUser?.preferences ?? {},
      );

      // Call API to create/update user on the backend
      await _apiService.createUser(
        token: '',
        os: _currentUser!.osType,
        deviceType: _currentUser!.deviceType,
        deviceModel: _currentUser!.deviceModel,
      );
      debugPrint('User created/updated on backend.');

      await _saveUserData();
      
    } catch (e) {
      _errorMessage = 'فشل في إنشاء أو تحديث المستخدم: ${e.toString()}';
      debugPrint('Error creating/updating user: $e');
      // Do not rethrow here if initialize should continue,
      // but the error is logged and stored in _errorMessage.
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceId = 'unknown_device_id';
    String deviceType = 'UnknownType';
    String deviceModel = 'UnknownModel';
    int osType = 0; // 0: other

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id; // androidId is deprecated, use id
        deviceType = androidInfo.manufacturer;
        deviceModel = androidInfo.model;
        osType = 1; // Android
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_id';
        deviceType = 'Apple';
        deviceModel = iosInfo.model;
        osType = 2; // iOS
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    
    return {
      'deviceId': deviceId,
      'deviceType': deviceType,
      'deviceModel': deviceModel,
      'osType': osType,
    };
  }

  String _generateUserId(String seed) {
    // Simple hash-based ID from provided seed.
    return seed.hashCode.abs().toString().padLeft(10, '0');
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontSize = prefs.getDouble('pref_font_size') ?? 16.0;
      _darkMode = prefs.getBool('pref_dark_mode') ?? false;
      _notificationsEnabled = prefs.getBool('pref_notifications_enabled') ?? true;
      _preferredLanguage = prefs.getString('pref_language') ?? 'ar';
      debugPrint('User preferences loaded.');
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }
  }

  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('pref_font_size', _fontSize);
      await prefs.setBool('pref_dark_mode', _darkMode);
      await prefs.setBool('pref_notifications_enabled', _notificationsEnabled);
      await prefs.setString('pref_language', _preferredLanguage);
      debugPrint('User preferences saved.');
    } catch (e) {
      debugPrint('Error saving user preferences: $e');
    }
  }

  Future<void> _loadAppStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _appOpenCount = prefs.getInt('stat_app_open_count') ?? 0;
      _newsReadCount = prefs.getInt('stat_news_read_count') ?? 0;
      _videosWatchedCount = prefs.getInt('stat_videos_watched_count') ?? 0;
      _columnsReadCount = prefs.getInt('stat_columns_read_count') ?? 0;
      
      final firstInstallString = prefs.getString('stat_first_install_date');
      if (firstInstallString != null) {
        _firstInstallDate = DateTime.tryParse(firstInstallString);
      }
      if (_firstInstallDate == null) { // If still null (not found or parse failed)
        _firstInstallDate = DateTime.now();
        await prefs.setString('stat_first_install_date', _firstInstallDate!.toIso8601String());
      }
      
      final lastUsedString = prefs.getString('stat_last_used_date');
      if (lastUsedString != null) {
        _lastUsedDate = DateTime.tryParse(lastUsedString);
      }
      debugPrint('App statistics loaded.');
    } catch (e) {
      debugPrint('Error loading app statistics: $e');
    }
  }

  Future<void> _saveAppStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stat_app_open_count', _appOpenCount);
      await prefs.setInt('stat_news_read_count', _newsReadCount);
      await prefs.setInt('stat_videos_watched_count', _videosWatchedCount);
      await prefs.setInt('stat_columns_read_count', _columnsReadCount);
      
      if (_lastUsedDate != null) {
        await prefs.setString('stat_last_used_date', _lastUsedDate!.toIso8601String());
      }
      debugPrint('App statistics saved.');
    } catch (e) {
      debugPrint('Error saving app statistics: $e');
    }
  }

  Future<void> _updateAppUsage() async {
    _appOpenCount++;
    _lastUsedDate = DateTime.now();
    await _saveAppStatistics();
    
    debugPrint('App open count: $_appOpenCount');
    
    notifyListeners();
  }

  Future<void> updateFontSize(double fontSize) async {
    if (fontSize >= 12.0 && fontSize <= 24.0) {
      _fontSize = fontSize;
      await _saveUserPreferences();
      notifyListeners();
    }
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _darkMode = enabled;
    await _saveUserPreferences();
    // Potentially trigger theme change globally
    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveUserPreferences();
    // This might also trigger changes in Firebase topic subscriptions via SettingsProvider
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    _preferredLanguage = languageCode;
    await _saveUserPreferences();
    // This would trigger UI rebuilds to reflect new language
    notifyListeners();
  }

  Future<void> trackNewsRead(String newsId) async {
    _newsReadCount++;
    await _saveAppStatistics();
    
    try {
      await _apiService.trackNewsView(newsId);
      debugPrint('News read: $newsId');
    } catch (e) {
      debugPrint("Error tracking news view on API/Analytics: $e");
    }
    notifyListeners();
  }

  Future<void> trackVideoWatched(String videoId) async {
    _videosWatchedCount++;
    await _saveAppStatistics();
    
    try {
      await _apiService.trackVideoView(videoId);
      debugPrint('Video watched: $videoId');
    } catch (e) {
       debugPrint("Error tracking video view on API/Analytics: $e");
    }
    notifyListeners();
  }

  Future<void> trackColumnRead(String columnId) async {
    _columnsReadCount++;
    await _saveAppStatistics();
    
    try {
      await _apiService.trackColumnView(columnId);
      debugPrint('Column read: $columnId');
    } catch (e) {
      debugPrint("Error tracking column view on API/Analytics: $e");
    }
    notifyListeners();
  }

  Future<void> updateUserPreference(String key, dynamic value) async {
    if (_currentUser != null) {
      final updatedPreferences = Map<String, dynamic>.from(_currentUser!.preferences);
      updatedPreferences[key] = value;
      
      _currentUser = _currentUser!.copyWith(preferences: updatedPreferences);
      await _saveUserData();
      notifyListeners();
    }
  }

  T? getUserPreference<T>(String key, {T? defaultValue}) {
    final value = _currentUser?.preferences[key];
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  Future<void> refreshFCMToken() async {
    try {
      debugPrint('refreshFCMToken called but Firebase is disabled.');
    } catch (e) {
      debugPrint('Error refreshing FCM token in AuthProvider: $e');
    }
  }

  Future<void> announceUser() async {
    try {
      debugPrint('announceUser called.');
    } catch (e) {
      debugPrint('Error announcing user from AuthProvider: $e');
    }
  }

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

  Future<void> resetStatistics() async {
    _appOpenCount = 0;
    _newsReadCount = 0;
    _videosWatchedCount = 0;
    _columnsReadCount = 0;
    // Should _firstInstallDate also be reset? Probably not.
    // _lastUsedDate will be updated on next app open.
    await _saveAppStatistics();
    notifyListeners();
  }

  Future<void> clearUserDataAndLogout() async { // Renamed for clarity
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove user-specific data
      await prefs.remove('user_data_v1');
      // Also clear other user-related preferences if any (e.g., notification section choices)
      // await prefs.remove('notification_settings'); // If managed here, but likely in SettingsProvider

      // Reset local state
      _currentUser = null;
      _isInitialized = false; // App will need to re-initialize user on next start
      
      // Reset preferences to default
      _fontSize = 16.0;
      _darkMode = false;
      _notificationsEnabled = true;
      _preferredLanguage = 'ar';
      // Reset statistics (optional, depends on desired behavior on logout)
      // await resetStatistics(); 

      debugPrint('User data cleared (logout).');
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

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

  bool get isNewUser {
    if (_firstInstallDate == null) return true; // If no date, assume new
    return DateTime.now().difference(_firstInstallDate!).inDays <= 7;
  }

  bool get isActiveUser {
    if (_lastUsedDate == null) return false; // If never used, not active
    return DateTime.now().difference(_lastUsedDate!).inDays <= 7;
  }

  String get userEngagementLevel {
    final totalInteractions = _newsReadCount + _videosWatchedCount + _columnsReadCount;
    
    if (totalInteractions < 10) return 'مبتدئ'; // Beginner
    if (totalInteractions < 50) return 'عادي'; // Casual
    if (totalInteractions < 200) return 'منتظم'; // Regular
    return 'متقدم'; // Power user
  }

  // Removed unnecessary override of dispose
  // @override
  // void dispose() {
  //   super.dispose();
  // }
}
