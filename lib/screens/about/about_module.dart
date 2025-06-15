import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform; // Explicitly import Platform

import '../../services/firebase_service.dart';
import '../../services/api_service.dart';

/// Data class for holding application information.
class AppInfo {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String buildSignature;
  final String installerStore;

  AppInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.buildSignature,
    required this.installerStore,
  });

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'packageName': packageName,
      'version': version,
      'buildNumber': buildNumber,
      'buildSignature': buildSignature,
      'installerStore': installerStore,
    };
  }
}

/// Data class for holding device information.
class DeviceInfoModel {
  // Renamed to avoid conflict with DeviceInfo from device_info_plus
  final String deviceType;
  final String deviceModel;
  final String osVersion;
  final String platform;
  final String identifier;
  final bool isPhysicalDevice;
  final Map<String, dynamic> additionalInfo;

  DeviceInfoModel({
    required this.deviceType,
    required this.deviceModel,
    required this.osVersion,
    required this.platform,
    required this.identifier,
    required this.isPhysicalDevice,
    required this.additionalInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceType': deviceType,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'platform': platform,
      'identifier': identifier,
      'isPhysicalDevice': isPhysicalDevice,
      'additionalInfo': additionalInfo,
    };
  }
}

/// Data class for holding combined system information.
class SystemInfo {
  final AppInfo appInfo;
  final DeviceInfoModel deviceInfo; // Using renamed DeviceInfoModel
  final DateTime timestamp;

  SystemInfo({
    required this.appInfo,
    required this.deviceInfo,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'appInfo': appInfo.toJson(),
      'deviceInfo': deviceInfo.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class AboutModule {
  static const String developerName = 'برايلاند';
  static const String developerWebsite = 'http://www.priland.com/';
  static const String appDescription = 'البرنامج الرسمي لجريدة الشروق المصرية';
  static const String companyName = 'جريدة الشروق';
  static const String supportEmail = 'support@shorouknews.com';
  static const String websiteUrl = 'https://www.shorouknews.com';

  // Social media links
  static const Map<String, String> socialLinks = {
    'facebook': 'https://www.facebook.com/shorouknews',
    'twitter': 'https://twitter.com/shorouk_news', // Corrected Twitter handle
    'youtube': 'https://www.youtube.com/user/shorouknews', // Corrected YouTube
    'instagram': 'https://www.instagram.com/shorouknews',
    'linkedin': 'https://www.linkedin.com/company/shorouknews',
  };

  // App features list
  static const List<String> appFeatures = [
    'آخر الأخبار والتطورات',
    'الأخبار العاجلة والإشعارات الفورية',
    'مقالات الرأي من أفضل الكتّاب',
    'مقاطع فيديو حصرية',
    'معرض الصور التفاعلي',
    'البحث المتقدم في الأخبار',
    'مشاركة الأخبار على وسائل التواصل',
    'قراءة بدون إنترنت (للأخبار المحملة)',
    'واجهة سهلة الاستخدام باللغة العربية',
    'إعدادات لتخصيص تجربة القراءة والإشعارات',
  ];

  // Legal information
  static const Map<String, String> legalInfo = {
    'copyright': '© ${2025} جريدة الشروق. جميع الحقوق محفوظة.', // Dynamic year
    'license': 'مرخص لجريدة الشروق المصرية للاستخدام عبر هذا التطبيق.',
    'disclaimer':
        'جميع المحتويات المنشورة تعبر عن رأي كاتبيها ولا تعكس بالضرورة رأي المؤسسة.',
  };

  // Instance members for services if non-static methods need them
  final FirebaseService _firebaseService = FirebaseService();
  final ApiService _apiService = ApiService();

  // Get app information
  static Future<AppInfo> getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      return AppInfo(
        appName: packageInfo.appName,
        packageName: packageInfo.packageName,
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        buildSignature:
            packageInfo.buildSignature, // May be empty on some platforms
        installerStore: packageInfo.installerStore ?? 'unknown',
      );
    } catch (e) {
      debugPrint('Error getting app info: $e');
      // Fallback information
      return AppInfo(
        appName: 'الشروق نيوز', // More specific fallback
        packageName: 'com.shorouknews.app', // Example package name
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
        installerStore: 'unknown',
      );
    }
  }

  // Get device information
  static Future<DeviceInfoModel> getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceType = 'Unknown';
    String deviceModel = 'Unknown Device';
    String osVersion = 'Unknown OS';
    String platform = Platform.operatingSystem; // Default to general OS
    String identifier = 'unknown_id';
    bool isPhysicalDevice = true; // Assume physical unless known otherwise
    Map<String, dynamic> additionalInfo = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceType = 'Android';
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        osVersion =
            'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
        platform = 'Android';
        identifier = androidInfo.id; // Use id, androidId is deprecated
        isPhysicalDevice = androidInfo.isPhysicalDevice;
        additionalInfo = {
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          // 'display': androidInfo.displayMetrics.toString(), // More detailed display info
          'fingerprint': androidInfo.fingerprint,
          'hardware': androidInfo.hardware,
          'host': androidInfo.host,
          'product': androidInfo.product,
          'tags': androidInfo.tags,
          'type': androidInfo.type,
          'board': androidInfo.board,
          'bootloader': androidInfo.bootloader,
          'supportedAbis': androidInfo.supportedAbis.join(', '),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceType = 'iOS';
        deviceModel = iosInfo.model;
        osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        platform = 'iOS';
        identifier = iosInfo.identifierForVendor ?? 'unknown_ios_id';
        isPhysicalDevice = iosInfo.isPhysicalDevice;
        additionalInfo = {
          'name': iosInfo.name,
          'localizedModel': iosInfo.localizedModel,
          'utsname_machine': iosInfo.utsname.machine,
          'utsname_nodename': iosInfo.utsname.nodename,
          'utsname_release': iosInfo.utsname.release,
          'utsname_sysname': iosInfo.utsname.sysname,
          'utsname_version': iosInfo.utsname.version,
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return DeviceInfoModel(
      deviceType: deviceType,
      deviceModel: deviceModel,
      osVersion: osVersion,
      platform: platform,
      identifier: identifier,
      isPhysicalDevice: isPhysicalDevice,
      additionalInfo: additionalInfo,
    );
  }

  // Get complete system information
  static Future<SystemInfo> getSystemInfo() async {
    final appInfo = await getAppInfo();
    final deviceInfo = await getDeviceInfo(); // Uses renamed DeviceInfoModel

    return SystemInfo(
      appInfo: appInfo,
      deviceInfo: deviceInfo,
      timestamp: DateTime.now(),
    );
  }

  // Open URL in external browser
  static Future<void> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error opening URL: $url - $e');
      // Optionally, rethrow or show a user-facing error
      // throw Exception('فشل في فتح الرابط: $url');
    }
  }

  // Open email client
  static Future<void> openEmail(String email,
      {String? subject, String? body}) async {
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        query: _encodeQueryParameters({
          if (subject != null && subject.isNotEmpty) 'subject': subject,
          if (body != null && body.isNotEmpty) 'body': body,
        }),
      );

      if (!await launchUrl(uri)) {
        throw Exception('Could not launch email client for $email');
      }
    } catch (e) {
      debugPrint('Error opening email to $email: $e');
      // throw Exception('فشل في فتح تطبيق البريد الإلكتروني');
    }
  }

  // Share app information
  static Future<void> shareApp() async {
    try {
      final appInfo = await getAppInfo();
      // Corrected: Removed unnecessary braces for simple variable interpolation
      final shareText = '''
📱 تطبيق ${appInfo.appName}
$appDescription

📥 حمّل التطبيق الآن:
• Android: https://play.google.com/store/apps/details?id=$appInfo.packageName
• iOS: https://apps.apple.com/app/idYOUR_APP_STORE_ID_HERE 

🌐 زوروا موقعنا: $websiteUrl

#الشروق #أخبار #مصر
      '''; // Remember to replace YOUR_APP_STORE_ID_HERE

      await Share.share(
        shareText,
        subject: 'تطبيق ${appInfo.appName}',
      );
    } catch (e) {
      debugPrint('Error sharing app: $e');
      // throw Exception('فشل في مشاركة التطبيق');
    }
  }

  // Copy to clipboard
  static Future<void> copyToClipboard(String text,
      {BuildContext? context}) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم النسخ إلى الحافظة'),
              duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      // throw Exception('فشل في النسخ');
    }
  }

  // Rate app
  static Future<void> rateApp() async {
    try {
      final appInfo = await getAppInfo();
      String storeUrl;

      if (Platform.isAndroid) {
        storeUrl = 'market://details?id=${appInfo.packageName}';
        // Fallback for web if market URI fails or Play Store not installed
        final webStoreUrl =
            'https://play.google.com/store/apps/details?id=${appInfo.packageName}';
        if (!await launchUrl(Uri.parse(storeUrl),
            mode: LaunchMode.externalApplication)) {
          await openUrl(webStoreUrl);
        }
      } else if (Platform.isIOS) {
        // IMPORTANT: Replace 'YOUR_APP_STORE_ID_HERE' with your actual Apple App Store ID
        storeUrl = 'https://apps.apple.com/app/idYOUR_APP_STORE_ID_HERE';
        await openUrl(storeUrl);
      } else {
        debugPrint(
            'Rating not supported on this platform: ${Platform.operatingSystem}');
        return; // Or throw an exception
      }
    } catch (e) {
      debugPrint('Error opening app store for rating: $e');
      // General fallback if specific platform logic fails
      final appInfo = await getAppInfo();
      if (Platform.isAndroid) {
        await openUrl(
            'https://play.google.com/store/apps/details?id=${appInfo.packageName}');
      } else if (Platform.isIOS) {
        await openUrl('https://apps.apple.com/app/idYOUR_APP_STORE_ID_HERE');
      }
    }
  }

  // Send feedback
  static Future<void> sendFeedback() async {
    try {
      final systemInfo = await getSystemInfo();
      final subject =
          'ملاحظات على تطبيق الشروق - إصدار ${systemInfo.appInfo.version}';
      final body = '''
مرحباً فريق الشروق،

أود مشاركة الملاحظات التالية حول التطبيق:

[اكتب ملاحظاتك هنا]

---
معلومات النظام:
التطبيق: ${systemInfo.appInfo.appName} ${systemInfo.appInfo.version} (بناء ${systemInfo.appInfo.buildNumber})
الجهاز: ${systemInfo.deviceInfo.deviceModel} (${systemInfo.deviceInfo.deviceType})
نظام التشغيل: ${systemInfo.deviceInfo.osVersion}
معرف الجهاز: ${systemInfo.deviceInfo.identifier}
التاريخ: ${systemInfo.timestamp.toIso8601String()}
      ''';

      await openEmail(supportEmail, subject: subject, body: body);
    } catch (e) {
      debugPrint('Error preparing feedback email: $e');
    }
  }

  // Report bug
  static Future<void> reportBug() async {
    try {
      final systemInfo = await getSystemInfo();
      final subject = 'تقرير خطأ - تطبيق الشروق ${systemInfo.appInfo.version}';
      final body = '''
مرحباً فريق التطوير،

أود الإبلاغ عن خطأ في التطبيق:

وصف الخطأ:
[اكتب وصفاً مفصلاً للخطأ]

خطوات إعادة الإنتاج:
1. [الخطوة الأولى]
2. [الخطوة الثانية]
3. [الخطوة الثالثة]

النتيجة المتوقعة:
[ما كان متوقعاً أن يحدث]

النتيجة الفعلية:
[ما حدث فعلاً]

---
معلومات تقنية:
التطبيق: ${systemInfo.appInfo.appName} ${systemInfo.appInfo.version} (بناء ${systemInfo.appInfo.buildNumber})
الحزمة: ${systemInfo.appInfo.packageName}
الجهاز: ${systemInfo.deviceInfo.deviceModel} (${systemInfo.deviceInfo.deviceType})
نظام التشغيل: ${systemInfo.deviceInfo.osVersion}
المنصة: ${systemInfo.deviceInfo.platform}
جهاز حقيقي: ${systemInfo.deviceInfo.isPhysicalDevice ? 'نعم' : 'لا'}
معرف الجهاز: ${systemInfo.deviceInfo.identifier}
التاريخ: ${systemInfo.timestamp.toIso8601String()}
      ''';

      await openEmail(supportEmail, subject: subject, body: body);
    } catch (e) {
      debugPrint('Error preparing bug report email: $e');
    }
  }

  // Check for app updates (Instance method as it uses _apiService)
  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      return await _apiService.checkAppVersion();
    } catch (e) {
      debugPrint('Error checking for updates in AboutModule: $e');
      return null;
    }
  }

  // Track app version click (Instance method as it uses _firebaseService)
  Future<void> trackVersionClick() async {
    try {
      // Corrected: Call announceUserForVersionTracking
      await _firebaseService.announceUserForVersionTracking();
      // Corrected: Call logAnalyticsEvent
      await _firebaseService.logAnalyticsEvent('version_clicked', parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint("Version click tracked.");
    } catch (e) {
      debugPrint('Error tracking version click: $e');
    }
  }

  // Get app changelog
  static List<Map<String, dynamic>> getChangelog() {
    // This should ideally come from a remote source or a more maintainable local store
    return [
      {
        'version': '1.0.0', // Example, update with your actual versions
        'date': '2025-06-01',
        'changes': [
          'الإصدار الأولي للتطبيق.',
          'تحسينات عامة في الأداء.',
        ],
      },
      // Add more changelog entries here
    ];
  }

  // Get app statistics (Placeholder - real stats would come from analytics or backend)
  static Future<Map<String, dynamic>> getAppStatistics() async {
    try {
      final systemInfo = await getSystemInfo();
      return {
        'totalDownloads': '100,000+', // Placeholder
        'rating': '4.3', // Placeholder
        'lastUpdated': '2025-05-20', // Placeholder
        'supportedLanguages': ['العربية'],
        'minOSVersion':
            Platform.isAndroid ? 'Android 5.0 (Lollipop)' : 'iOS 12.0',
        'appSize': Platform.isAndroid ? '~20 MB' : '~35 MB', // Approximate
        'currentVersion': systemInfo.appInfo.version,
        'buildNumber': systemInfo.appInfo.buildNumber,
      };
    } catch (e) {
      debugPrint('Error getting app statistics: $e');
      return {};
    }
  }

  // Helper method to encode query parameters for mailto links
  static String? _encodeQueryParameters(Map<String, String> params) {
    if (params.isEmpty) return null;
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // Get privacy policy text (Static method, as it's constant text)
  static String getPrivacyPolicyText() {
    // IMPORTANT: Replace this with your actual, legally compliant privacy policy.
    return '''
سياسة الخصوصية لتطبيق الشروق نيوز

آخر تحديث: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}

مقدمة:
نحن في جريدة الشروق ("نحن"، "لنا"، أو "الخاص بنا") نحترم خصوصيتك ونلتزم بحمايتها من خلال امتثالنا لهذه السياسة.
تصف هذه السياسة أنواع المعلومات التي قد نجمعها منك أو التي قد تقدمها عند استخدامك لتطبيق الشروق نيوز (الـ "تطبيق") وممارساتنا لجمع تلك المعلومات واستخدامها والحفاظ عليها وحمايتها والإفصاح عنها.

1. المعلومات التي نجمعها:
   أ. معلومات تقدمها أنت:
      - معلومات التعريف الشخصية مثل الاسم وعنوان البريد الإلكتروني عند التسجيل في القائمة البريدية أو الاتصال بنا.
   ب. معلومات تجمع تلقائياً:
      - بيانات استخدام التطبيق.
      - معلومات الجهاز: طراز الجهاز، نظام التشغيل، معرفات الجهاز الفريدة، عنوان IP.
      - بيانات الموقع (إذا سمحت بذلك).
      - ملفات تعريف الارتباط (Cookies) والتقنيات المشابهة.

2. كيف نستخدم معلوماتك:
   - لتزويدك بالتطبيق وخدماته.
   - لإدارة حسابك في القائمة البريدية.
   - للرد على استفساراتك.
   - لتحليل استخدام التطبيق وتحسين خدماتنا.
   - لمنع الاحتيال وضمان أمن التطبيق.
   - للامتثال للمتطلبات القانونية.

3. مشاركة معلوماتك:
   - مع مزودي الخدمات من الأطراف الثالثة (مثل الإشعارات، التحليلات، الإعلانات).
   - مع السلطات القانونية إذا طُلب ذلك.

(الرجاء استكمال باقي بنود سياسة الخصوصية بشكل مفصل وقانوني)
    ''';
  }

  // Get terms of service text (Static method)
  static String getTermsOfServiceText() {
    // IMPORTANT: Replace this with your actual, legally compliant terms of service.
    return '''
شروط استخدام تطبيق الشروق نيوز

آخر تحديث: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}

مقدمة:
مرحباً بك في تطبيق الشروق نيوز. باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بهذه الشروط والأحكام.

1. استخدام التطبيق:
   - المحتوى المقدم هو لأغراض إعلامية عامة.
   - لا يجوز استخدام التطبيق لأي أغراض غير قانونية.

2. الملكية الفكرية:
   - جميع المحتويات (نصوص، صور، فيديوهات، شعارات) هي ملك لجريدة الشروق أو مرخصة لها.

3. إخلاء المسؤولية:
   - نسعى لتقديم معلومات دقيقة، ولكن لا نضمن خلوها من الأخطاء.
   - الآراء المنشورة تعبر عن كاتبيها.

(الرجاء استكمال باقي بنود شروط الاستخدام بشكل مفصل وقانوني)
    ''';
  }

  /// Call this method when the module instance is no longer needed,
  /// e.g., if it were managed by a Provider that gets disposed.
  /// For a module with mostly static methods, this might not be strictly necessary
  /// unless the instance members (_firebaseService, _apiService) need explicit disposal.
  void dispose() {
    // If _apiService or _firebaseService had their own dispose methods that needed calling:
    // _apiService.dispose();
    // _firebaseService.dispose();
    debugPrint(
        'AboutModule disposed (if instance methods were used extensively).');
  }
}
