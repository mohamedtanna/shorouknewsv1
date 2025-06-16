import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Required for jsonEncode and jsonDecode

import 'package:shorouk_news/models/new_model.dart';
import '../models/additional_models.dart'; // For NotificationSettings
import '../services/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  List<NewsSection> _sections = [];
  NotificationSettings _notificationSettings =
      NotificationSettings(sections: {});
  // Corrected: _pendingChanges can be final as the Set object itself isn't reassigned, only its content.
  final Set<String> _pendingChanges = <String>{};

  // SharedPreferences key for storing notification settings
  static const String _notificationSettingsKey =
      'notification_settings_v1'; // Added versioning

  // Getters
  bool get isLoading => _isLoading;
  List<NewsSection> get sections =>
      List.unmodifiable(_sections); // Return unmodifiable list
  NotificationSettings get notificationSettings => _notificationSettings;
  Set<String> get pendingChanges =>
      Set.unmodifiable(_pendingChanges); // Expose for UI if needed

  // Load settings (sections from API and notification preferences from local storage)
  Future<void> loadSettings() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Load all available news sections from the API
      _sections = await _apiService.getSections();

      // Load user's notification preferences from local storage
      await _loadNotificationSettings();

      // Preferences are stored locally only; Firebase integration removed.
    } catch (e) {
      debugPrint('Error loading settings in SettingsProvider: $e');
      // Optionally, set an error state to be displayed in the UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load notification settings from SharedPreferences
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJsonString = prefs.getString(_notificationSettingsKey);

      if (settingsJsonString != null && settingsJsonString.isNotEmpty) {
        final Map<String, dynamic> decodedData =
            jsonDecode(settingsJsonString) as Map<String, dynamic>;
        _notificationSettings = NotificationSettings.fromJson(decodedData);
        debugPrint('Notification settings loaded from SharedPreferences.');
      } else {
        // If no settings found, initialize with default (all sections enabled for notifications)
        // This happens only if _sections are already loaded.
        if (_sections.isNotEmpty) {
          final Map<String, bool> defaultSettings = {
            for (final section in _sections) section.id: true,
          };
          _notificationSettings =
              NotificationSettings(sections: defaultSettings);
          debugPrint(
              'Initialized with default notification settings (all enabled).');
          // Optionally save these defaults immediately
          // await _saveNotificationSettings();
        } else {
          _notificationSettings = NotificationSettings(
              sections: {}); // Initialize empty if no sections yet
          debugPrint(
              'No sections available to initialize default notification settings.');
        }
      }
    } catch (e) {
      debugPrint(
          'Error loading notification settings from SharedPreferences: $e');
      // Fallback to default if loading fails
      if (_sections.isNotEmpty) {
        final Map<String, bool> defaultSettings = {
          for (final section in _sections) section.id: true,
        };
        _notificationSettings = NotificationSettings(sections: defaultSettings);
      } else {
        _notificationSettings = NotificationSettings(sections: {});
      }
    }
  }


  /// Checks if notifications for a given section ID are enabled.
  bool isSectionEnabled(String sectionId) {
    return _notificationSettings.sections[sectionId] ?? false;
  }

  /// Toggles the notification preference for a specific section.
  void toggleSection(String sectionId, bool enabled) {
    // Create a mutable copy of the current settings
    final updatedSections =
        Map<String, bool>.from(_notificationSettings.sections);
    updatedSections[sectionId] = enabled;

    // Update the notificationSettings state
    _notificationSettings =
        _notificationSettings.copyWith(sections: updatedSections);

    // Track pending changes for topic subscriptions
    final subscribeKey = 'subscribe_$sectionId';
    final unsubscribeKey = 'unsubscribe_$sectionId';

    if (enabled) {
      _pendingChanges.add(subscribeKey);
      _pendingChanges.remove(unsubscribeKey);
    } else {
      _pendingChanges.add(unsubscribeKey);
      _pendingChanges.remove(subscribeKey);
    }

    notifyListeners(); // Notify UI of the change
  }

  /// Activates notifications for all available sections.
  void activateAll() {
    if (_sections.isEmpty) return;
    final updatedSections = <String, bool>{};
    _pendingChanges.clear(); // Clear previous individual pending changes

    for (final section in _sections) {
      updatedSections[section.id] = true;
      _pendingChanges.add('subscribe_${section.id}'); // Add all to subscribe
    }

    _notificationSettings =
        _notificationSettings.copyWith(sections: updatedSections);
    notifyListeners();
  }

  /// Deactivates notifications for all available sections.
  void deactivateAll() {
    if (_sections.isEmpty) return;
    final updatedSections = <String, bool>{};
    _pendingChanges.clear(); // Clear previous individual pending changes

    for (final section in _sections) {
      updatedSections[section.id] = false;
      _pendingChanges
          .add('unsubscribe_${section.id}'); // Add all to unsubscribe
    }

    _notificationSettings =
        _notificationSettings.copyWith(sections: updatedSections);
    notifyListeners();
  }

  /// Saves the pending notification settings and persists them locally.
  Future<void> saveSettings() async {
    if (_pendingChanges.isEmpty && !_isLoading) {
      return; // No changes to save or already saving
    }

    _isLoading = true;
    notifyListeners();

    try {
      final List<String> toSubscribe = [];
      final List<String> toUnsubscribe = [];

      for (final change in _pendingChanges) {
        if (change.startsWith('subscribe_')) {
          toSubscribe.add(change.substring(10)); // Length of "subscribe_"
        } else if (change.startsWith('unsubscribe_')) {
          toUnsubscribe.add(change.substring(12)); // Length of "unsubscribe_"
        }
      }

      // Firebase messaging removed; subscriptions are stored locally only.

      // Persist the current state of _notificationSettings (which reflects user's choices)
      await _saveNotificationSettings();

      _pendingChanges.clear(); // Clear pending changes after successful save
      debugPrint('Settings saved successfully.');
    } catch (e) {
      debugPrint('Error saving settings: $e');
      // Optionally, notify UI about the error
      // Do not clear pending changes on error, so user can retry
      rethrow; // Allow UI to catch and display error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves the current notification settings to SharedPreferences.
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Corrected: Serialize the _notificationSettings object to JSON
      final String settingsJsonString =
          jsonEncode(_notificationSettings.toJson());
      await prefs.setString(_notificationSettingsKey, settingsJsonString);
      debugPrint('Notification settings saved to SharedPreferences.');
    } catch (e) {
      debugPrint('Error saving notification settings to SharedPreferences: $e');
    }
  }

  /// Clears all local settings state.
  void clearSettings() {
    _sections = [];
    _notificationSettings = NotificationSettings(sections: {});
    _pendingChanges.clear();
    // Optionally, clear from SharedPreferences as well
    // SharedPreferences.getInstance().then((prefs) => prefs.remove(_notificationSettingsKey));
    notifyListeners();
    debugPrint('SettingsProvider state cleared.');
  }
}
