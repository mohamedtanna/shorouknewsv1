import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart'; // For loading shimmer effect

import '../../providers/settings_provider.dart'; // Manages settings state and logic
// For NewsSection model
// import '../../widgets/ad_banner.dart'; // For displaying ads
import '../../core/theme.dart'; // For consistent app styling

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _errorLoadingSections; // To store any error message during initial load

  @override
  void initState() {
    super.initState();
    // Load settings as soon as the screen is initialized.
    // Using addPostFrameCallback to ensure BuildContext is available if needed by provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialSettings();
    });
  }

  Future<void> _loadInitialSettings() async {
    try {
      // Reset any previous error
      if (mounted) setState(() => _errorLoadingSections = null);
      // Call the provider to load sections and current notification preferences.
      await context.read<SettingsProvider>().loadSettings();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorLoadingSections = 'فشل في تحميل إعدادات الإشعارات.';
          debugPrint("Error in _loadInitialSettings: $e");
        });
      }
    }
  }

  /// Handles the pull-to-refresh action.
  Future<void> _refreshSettings() async {
    await _loadInitialSettings();
  }

  /// Builds the breadcrumb navigation path.
  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor, // Or specific background
        border: const Border(
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
          const Text(
            'ضبط الإعدادات', // "Settings"
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
        title: const Text('ضبط إعدادات الإشعارات'), // "Notification Settings"
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
        body: Column(
        children: [
          // Advertisement Banner at the top
          // const AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
          _buildBreadcrumb(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshSettings,
              color: AppTheme.primaryColor,
              child: Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  // Handle initial loading error for sections
                  if (_errorLoadingSections != null && settingsProvider.sections.isEmpty && !settingsProvider.isLoading) {
                    return _buildErrorState(_errorLoadingSections!);
                  }
                  // Show shimmer while sections are loading for the first time
                  if (settingsProvider.isLoading && settingsProvider.sections.isEmpty) {
                    return _buildLoadingShimmer();
                  }
                  // If no sections are available after loading
                  if (!settingsProvider.isLoading && settingsProvider.sections.isEmpty) {
                    return _buildEmptyState();
                  }
                  // Build the main settings content once sections are loaded
                  return _buildSettingsContent(settingsProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds the shimmer loading effect for the settings content.
  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer for title
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(height: 24, width: MediaQuery.of(context).size.width * 0.7, color: Colors.white, margin: const EdgeInsets.only(bottom: 20)),
          ),
          // Shimmer for control buttons
          Row(
            children: [
              Expanded(child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 48, color: Colors.white, margin: const EdgeInsets.only(right: 8)))),
              Expanded(child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 48, color: Colors.white, margin: const EdgeInsets.only(left: 8)))),
            ],
          ),
          const SizedBox(height: 20),
          // Shimmer for sections grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8, // Adjusted for better shimmer appearance
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6, // Display a few shimmer placeholders
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Card(child: Container(color: Colors.white)),
              );
            },
          ),
           const SizedBox(height: 30),
          // Shimmer for action buttons
           Row(
            children: [
              Expanded(child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 48, color: Colors.white, margin: const EdgeInsets.only(right: 8)))),
              Expanded(child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 48, color: Colors.white, margin: const EdgeInsets.only(left: 8)))),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the UI when there are no sections to display.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_suggest_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'لا توجد أقسام لضبط إشعاراتها حالياً.',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'يرجى المحاولة مرة أخرى لاحقاً أو التأكد من اتصالك بالإنترنت.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
             const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _refreshSettings,
            )
          ],
        ),
      ),
    );
  }

  /// Builds the UI when an error occurs loading sections.
  Widget _buildErrorState(String errorMessage) {
     return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 80, color: Colors.red[600]),
            const SizedBox(height: 20),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 18, color: Colors.red[700], fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
             const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _refreshSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white
              ),
            )
          ],
        ),
      ),
    );
  }


  /// Builds the main content of the settings screen.
  Widget _buildSettingsContent(SettingsProvider settingsProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title for the settings section
          Text(
            'استقبال الإشعارات للأخبار العاجلة والأقسام المختارة:',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),

          // Control buttons for activating/deactivating all notifications
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: settingsProvider.isLoading ? null : settingsProvider.activateAll,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('تفعيل الكل'), // "Activate All"
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: settingsProvider.isLoading ? null : settingsProvider.deactivateAll,
                  icon: const Icon(Icons.highlight_off_outlined), // More distinct icon
                  label: const Text('إلغاء تفعيل الكل'), // "Deactivate All"
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Grid displaying toggles for each news section
          if (settingsProvider.sections.isNotEmpty)
            GridView.builder(
              shrinkWrap: true, // Important for GridView inside SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2, // Responsive columns
                childAspectRatio: 2.8, // Adjust aspect ratio for card height
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: settingsProvider.sections.length,
              itemBuilder: (context, index) {
                final section = settingsProvider.sections[index];
                final isEnabled = settingsProvider.isSectionEnabled(section.id);
                
                return Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: SwitchListTile(
                    title: Text(
                      section.arName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isEnabled ? AppTheme.primaryColor : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: isEnabled,
                    onChanged: settingsProvider.isLoading 
                        ? null 
                        : (bool value) {
                            settingsProvider.toggleSection(section.id, value);
                          },
                    activeThumbColor: AppTheme.tertiaryColor, // Use a distinct active color
                    dense: true, // Makes the tile more compact
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  ),
                );
              },
            ),
          
          const SizedBox(height: 30),

          // Action buttons for saving settings or returning to home
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: settingsProvider.isLoading || settingsProvider.pendingChanges.isEmpty
                      ? null // Disable if loading or no changes
                      : () => _saveSettings(settingsProvider),
                  icon: settingsProvider.isLoading && settingsProvider.pendingChanges.isNotEmpty // Show loader only when saving
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_alt_outlined),
                  label: const Text('حفظ الإعدادات'), // "Save Settings"
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon( // Changed to OutlinedButton for distinction
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('الرئيسية'), // "Main Menu"
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.tertiaryColor,
                    side: const BorderSide(color: AppTheme.tertiaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }

  /// Saves the current settings by calling the provider's save method.
  /// Displays feedback to the user via SnackBar.
  Future<void> _saveSettings(SettingsProvider settingsProvider) async {
    try {
      await settingsProvider.saveSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حفظ الإعدادات: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
