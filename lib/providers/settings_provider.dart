import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_model.dart';
import '../models/additional_models.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class SettingsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  List<NewsSection> _sections = [];
  NotificationSettings _notificationSettings = NotificationSettings(sections: {});
  Set<String> _pendingChanges = <String>{};

  // Getters
  bool get isLoading => _isLoading;
  List<NewsSection> get sections => _sections;
  NotificationSettings get notificationSettings => _notificationSettings;

  // Load settings
  Future<void> loadSettings() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Load sections
      _sections = await _apiService.getSections();
      
      // Load notification settings
      await _loadNotificationSettings();
      
      // Get current FCM subscriptions
      await _syncWithFirebase();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load notification settings from local storage
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings');
      
      if (settingsJson != null) {
        // Parse stored settings
        final Map<String, dynamic> data = {};
        // Implement JSON parsing here
        _notificationSettings = NotificationSettings.fromJson(data);
      } else {
        // Initialize with default settings (all enabled)
        final Map<String, bool> defaultSettings = {};
        for (final section in _sections) {
          defaultSettings[section.id] = true;
        }
        _notificationSettings = NotificationSettings(sections: defaultSettings);
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  // Sync settings with Firebase subscriptions
  Future<void> _syncWithFirebase() async {
    try {
      final subscribedTopics = await _firebaseService.getSubscribedTopics();
      
      // Update local settings based on Firebase subscriptions
      final Map<String, bool> updatedSettings = {};
      for (final section in _sections) {
        updatedSettings[section.id] = subscribedTopics.contains(section.id);
      }
      
      _notificationSettings = NotificationSettings(sections: updatedSettings);
    } catch (e) {
      debugPrint('Error syncing with Firebase: $e');
    }
  }

  // Check if section is enabled
  bool isSectionEnabled(String sectionId) {
    return _notificationSettings.sections[sectionId] ?? false;
  }

  // Toggle section notification
  void toggleSection(String sectionId, bool enabled) {
    final updatedSections = Map<String, bool>.from(_notificationSettings.sections);
    updatedSections[sectionId] = enabled;
    
    _notificationSettings = _notificationSettings.copyWith(sections: updatedSections);
    
    // Track pending changes
    if (enabled) {
      _pendingChanges.add('subscribe_$sectionId');
      _pendingChanges.remove('unsubscribe_$sectionId');
    } else {
      _pendingChanges.add('unsubscribe_$sectionId');
      _pendingChanges.remove('subscribe_$sectionId');
    }
    
    notifyListeners();
  }

  // Activate all sections
  void activateAll() {
    final updatedSections = <String, bool>{};
    
    for (final section in _sections) {
      updatedSections[section.id] = true;
      _pendingChanges.add('subscribe_${section.id}');
      _pendingChanges.remove('unsubscribe_${section.id}');
    }
    
    _notificationSettings = _notificationSettings.copyWith(sections: updatedSections);
    notifyListeners();
  }

  // Deactivate all sections
  void deactivateAll() {
    final updatedSections = <String, bool>{};
    
    for (final section in _sections) {
      updatedSections[section.id] = false;
      _pendingChanges.add('unsubscribe_${section.id}');
      _pendingChanges.remove('subscribe_${section.id}');
    }
    
    _notificationSettings = _notificationSettings.copyWith(sections: updatedSections);
    notifyListeners();
  }

  // Save settings
  Future<void> saveSettings() async {
    if (_pendingChanges.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Process pending changes
      final toSubscribe = <String>[];
      final toUnsubscribe = <String>[];
      
      for (final change in _pendingChanges) {
        if (change.startsWith('subscribe_')) {
          toSubscribe.add(change.substring(10));
        } else if (change.startsWith('unsubscribe_')) {
          toUnsubscribe.add(change.substring(12));
        }
      }

      // Update Firebase subscriptions
      if (toUnsubscribe.isNotEmpty) {
        await _firebaseService.unsubscribeFromTopics(toUnsubscribe);
      }
      
      if (toSubscribe.isNotEmpty) {
        await _firebaseService.subscribeToTopics(toSubscribe);
      } else if (toUnsubscribe.isNotEmpty && toSubscribe.isEmpty) {
        // If unsubscribing from all, subscribe to deactivateAll topic
        await _firebaseService.subscribeToTopics(['deactivateAll']);
      }

      // Save to local storage
      await _saveNotificationSettings();
      
      // Clear pending changes
      _pendingChanges.clear();
      
    } catch (e) {
      debugPrint('Error saving settings: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save notification settings to local storage
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Implement JSON serialization here
      await prefs.setString('notification_settings', ''); // JSON string
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  // Clear all settings
  void clearSettings() {
    _sections.clear();
    _notificationSettings = NotificationSettings(sections: {});
    _pendingChanges.clear();
    notifyListeners();
  }
}