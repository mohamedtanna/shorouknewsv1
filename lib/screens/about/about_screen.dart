import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/ad_banner.dart';
import '../../core/theme.dart';
import 'about_module.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with TickerProviderStateMixin {
  final AboutModule _aboutModule = AboutModule();
  
  SystemInfo? _systemInfo;
  Map<String, dynamic>? _appStatistics;
  bool _isLoading = true;
  bool _isCheckingUpdates = false;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _aboutModule.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final systemInfo = await AboutModule.getSystemInfo();
      final appStatistics = await AboutModule.getAppStatistics();
      
      setState(() {
        _systemInfo = systemInfo;
        _appStatistics = appStatistics;
        _isLoading = false;
        _errorMessage = null;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل معلومات التطبيق';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdates = true);
    
    try {
      final updateInfo = await _aboutModule.checkForUpdates();
      
      if (mounted) {
        if (updateInfo != null) {
          _showUpdateDialog(updateInfo);
        } else {
          _showMessage('لا توجد تحديثات متاحة حالياً');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('فشل في التحقق من التحديثات');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdates = false);
      }
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحديث متاح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار الجديد: ${updateInfo['version']}'),
            const SizedBox(height: 8),
            Text('التغييرات:\n${updateInfo['changes']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AboutModule.rateApp(); // Redirect to app store
            },
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _onVersionTap() async {
    try {
      await _aboutModule.trackVersionClick();
      await HapticFeedback.lightImpact();
      
      if (mounted) {
        _showMessage('تم تسجيل النقرة');
      }
    } catch (e) {
      debugPrint('Error tracking version click: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عن البرنامج'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: Icon(_isCheckingUpdates ? Icons.hourglass_empty : Icons.system_update),
            onPressed: _isCheckingUpdates ? null : _checkForUpdates,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جاري تحميل معلومات التطبيق...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Ad Banner
              const SliverToBoxAdapter(
                child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
              ),
              
              // Breadcrumb
              SliverToBoxAdapter(
                child: _buildBreadcrumb(),
              ),
              
              // App Info Section
              SliverToBoxAdapter(
                child: _buildAppInfoSection(),
              ),
              
              // Developer Section
              SliverToBoxAdapter(
                child: _buildDeveloperSection(),
              ),
              
              // Features Section
              SliverToBoxAdapter(
                child: _buildFeaturesSection(),
              ),
              
              // Statistics Section
              SliverToBoxAdapter(
                child: _buildStatisticsSection(),
              ),
              
              // Actions Section
              SliverToBoxAdapter(
                child: _buildActionsSection(),
              ),
              
              // Social Media Section
              SliverToBoxAdapter(
                child: _buildSocialMediaSection(),
              ),
              
              // System Info Section (Debug)
              if (_systemInfo != null)
                SliverToBoxAdapter(
                  child: _buildSystemInfoSection(),
                ),
              
              // Legal Section
              SliverToBoxAdapter(
                child: _buildLegalSection(),
              ),
              
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
            'عن البرنامج',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // App Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.newspaper,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // App Title
          Text(
            _systemInfo?.appInfo.appName ?? 'الشروق',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // App Description
          const Text(
            AboutModule.appDescription,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Version Info
          GestureDetector(
            onTap: _onVersionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                'إصدار ${_systemInfo?.appInfo.version ?? '1.0.0'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'برمجة وتصميم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AboutModule.developerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => AboutModule.openUrl(AboutModule.developerWebsite),
                  icon: const Icon(Icons.web, size: 16),
                  label: const Text('زيارة الموقع'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => AboutModule.openUrl(AboutModule.developerWebsite),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  'assets/images/priland-logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.business,
                      color: AppTheme.primaryColor,
                      size: 40,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'مميزات التطبيق',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...AboutModule.appFeatures.map((feature) => Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.tertiaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    if (_appStatistics == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إحصائيات التطبيق',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'التحميلات',
                  _appStatistics!['totalDownloads'] ?? 'غير متاح',
                  Icons.download,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'التقييم',
                  '${_appStatistics!['rating'] ?? 'غير متاح'} ⭐',
                  Icons.star,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'حجم التطبيق',
                  _appStatistics!['appSize'] ?? 'غير متاح',
                  Icons.storage,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'آخر تحديث',
                  _appStatistics!['lastUpdated'] ?? 'غير متاح',
                  Icons.update,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: AboutModule.shareApp,
                  icon: const Icon(Icons.share),
                  label: const Text('مشاركة التطبيق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: AboutModule.rateApp,
                  icon: const Icon(Icons.star_rate),
                  label: const Text('تقييم التطبيق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: AboutModule.sendFeedback,
                  icon: const Icon(Icons.feedback),
                  label: const Text('إرسال ملاحظات'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: AboutModule.reportBug,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('تقرير خطأ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'تابعونا على وسائل التواصل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                'Facebook',
                Icons.facebook,
                AboutModule.socialLinks['facebook']!,
                Colors.blue[700]!,
              ),
              _buildSocialButton(
                'Twitter',
                Icons.alternate_email,
                AboutModule.socialLinks['twitter']!,
                Colors.lightBlue[400]!,
              ),
              _buildSocialButton(
                'YouTube',
                Icons.play_circle_fill,
                AboutModule.socialLinks['youtube']!,
                Colors.red[600]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String name, IconData icon, String url, Color color) {
    return GestureDetector(
      onTap: () => AboutModule.openUrl(url),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildSystemInfoSection() {
    return ExpansionTile(
      title: const Text(
        'معلومات النظام',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('اسم التطبيق', _systemInfo!.appInfo.appName),
              _buildInfoRow('الإصدار', _systemInfo!.appInfo.version),
              _buildInfoRow('رقم البناء', _systemInfo!.appInfo.buildNumber),
              _buildInfoRow('نوع الجهاز', _systemInfo!.deviceInfo.deviceModel),
              _buildInfoRow('نظام التشغيل', _systemInfo!.deviceInfo.osVersion),
              _buildInfoRow('المنصة', _systemInfo!.deviceInfo.platform),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final systemJson = _systemInfo!.toJson().toString();
                        AboutModule.copyToClipboard(systemJson);
                        _showMessage('تم نسخ معلومات النظام');
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('نسخ المعلومات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات قانونية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...AboutModule.legalInfo.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              entry.value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => context.go('/privacy'),
                  child: const Text('سياسة الخصوصية'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => context.go('/terms'),
                  child: const Text('شروط الاستخدام'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}