import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../services/firebase_service.dart';
import '../../services/api_service.dart';

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

class DeviceInfo {
  final String deviceType;
  final String deviceModel;
  final String osVersion;
  final String platform;
  final String identifier;
  final bool isPhysicalDevice;
  final Map<String, dynamic> additionalInfo;

  DeviceInfo({
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

class SystemInfo {
  final AppInfo appInfo;
  final DeviceInfo deviceInfo;
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
    'twitter': 'https://twitter.com/#!/shorouk_news',
    'youtube': 'https://www.youtube.com/channel/UCGONWo6kCXGwtyA8SHrHIAw',
    'instagram': 'https://www.instagram.com/shorouknews/',
    'linkedin': 'https://www.linkedin.com/company/shorouknews/',
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
    'قراءة بدون إنترنت',
    'واجهة سهلة الاستخدام',
    'دعم اللغة العربية بالكامل',
  ];

  // Legal information
  static const Map<String, String> legalInfo = {
    'copyright': '© 2024 جريدة الشروق. جميع الحقوق محفوظة.',
    'license': 'مرخص لجريدة الشروق المصرية',
    'disclaimer': 'جميع المحتويات المنشورة تعبر عن رأي كاتبيها',
  };

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
        buildSignature: packageInfo.buildSignature,
        installerStore: packageInfo.installerStore ?? 'unknown',
      );
    } catch (e) {
      debugPrint('Error getting app info: $e');
      return AppInfo(
        appName: 'الشروق',
        packageName: 'com.shorouknews.app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
        installerStore: 'unknown',
      );
    }
  }

  // Get device information
  static Future<DeviceInfo> getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return DeviceInfo(
          deviceType: 'Android',
          deviceModel: '${androidInfo.manufacturer} ${androidInfo.model}',
          osVersion: 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})',
          platform: 'Android',
          identifier: androidInfo.id,
          isPhysicalDevice: androidInfo.isPhysicalDevice,
          additionalInfo: {
            'brand': androidInfo.brand,
            'device': androidInfo.device,
            'display': androidInfo.display,
            'fingerprint': androidInfo.fingerprint,
            'hardware': androidInfo.hardware,
            'host': androidInfo.host,
            'product': androidInfo.product,
            'tags': androidInfo.tags,
            'type': androidInfo.type,
            'androidId': androidInfo.id,
            'board': androidInfo.board,
            'bootloader': androidInfo.bootloader,
            'supported32BitAbis': androidInfo.supported32BitAbis,
            'supported64BitAbis': androidInfo.supported64BitAbis,
            'supportedAbis': androidInfo.supportedAbis,
          },
        );
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return DeviceInfo(
          deviceType: 'iOS',
          deviceModel: iosInfo.model,
          osVersion: '${iosInfo.systemName} ${iosInfo.systemVersion}',
          platform: 'iOS',
          identifier: iosInfo.identifierForVendor ?? 'unknown',
          isPhysicalDevice: iosInfo.isPhysicalDevice,
          additionalInfo: {
            'name': iosInfo.name,
            'localizedModel': iosInfo.localizedModel,
            'utsname': {
              'machine': iosInfo.utsname.machine,
              'nodename': iosInfo.utsname.nodename,
              'release': iosInfo.utsname.release,
              'sysname': iosInfo.utsname.sysname,
              'version': iosInfo.utsname.version,
            },
          },
        );
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    
    // Fallback for unsupported platforms
    return DeviceInfo(
      deviceType: 'Unknown',
      deviceModel: 'Unknown Device',
      osVersion: 'Unknown OS',
      platform: Platform.operatingSystem,
      identifier: 'unknown',
      isPhysicalDevice: true,
      additionalInfo: {},
    );
  }

  // Get complete system information
  static Future<SystemInfo> getSystemInfo() async {
    final appInfo = await getAppInfo();
    final deviceInfo = await getDeviceInfo();
    
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
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      throw Exception('فشل في فتح الرابط');
    }
  }

  // Open email client
  static Future<void> openEmail(String email, {String? subject, String? body}) async {
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        query: _encodeQueryParameters({
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
        }),
      );
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      debugPrint('Error opening email: $e');
      throw Exception('فشل في فتح تطبيق البريد الإلكتروني');
    }
  }

  // Share app information
  static Future<void> shareApp() async {
    try {
      final appInfo = await getAppInfo();
      final shareText = '''
📱 تطبيق ${appInfo.appName}
${appDescription}

📥 حمّل التطبيق الآن:
• Android: https://play.google.com/store/apps/details?id=${appInfo.packageName}
• iOS: https://apps.apple.com/app/id123456789

🌐 زوروا موقعنا: $websiteUrl

#الشروق #أخبار #مصر
      ''';
      
      await Share.share(
        shareText,
        subject: 'تطبيق ${appInfo.appName}',
      );
    } catch (e) {
      debugPrint('Error sharing app: $e');
      throw Exception('فشل في مشاركة التطبيق');
    }
  }

  // Copy to clipboard
  static Future<void> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      throw Exception('فشل في النسخ');
    }
  }

  // Rate app
  static Future<void> rateApp() async {
    try {
      final appInfo = await getAppInfo();
      String storeUrl;
      
      if (Platform.isAndroid) {
        storeUrl = 'market://details?id=${appInfo.packageName}';
      } else if (Platform.isIOS) {
        storeUrl = 'https://apps.apple.com/app/id123456789'; // Replace with actual App Store ID
      } else {
        throw Exception('Platform not supported');
      }
      
      await openUrl(storeUrl);
    } catch (e) {
      debugPrint('Error opening app store: $e');
      // Fallback to web version
      if (Platform.isAndroid) {
        final appInfo = await getAppInfo();
        await openUrl('https://play.google.com/store/apps/details?id=${appInfo.packageName}');
      } else {
        await openUrl('https://apps.apple.com/app/id123456789');
      }
    }
  }

  // Send feedback
  static Future<void> sendFeedback() async {
    try {
      final systemInfo = await getSystemInfo();
      final subject = 'ملاحظات على تطبيق الشروق - إصدار ${systemInfo.appInfo.version}';
      final body = '''
مرحباً فريق الشروق،

أود مشاركة الملاحظات التالية حول التطبيق:

[اكتب ملاحظاتك هنا]

---
معلومات النظام:
التطبيق: ${systemInfo.appInfo.appName} ${systemInfo.appInfo.version} (${systemInfo.appInfo.buildNumber})
الجهاز: ${systemInfo.deviceInfo.deviceModel}
نظام التشغيل: ${systemInfo.deviceInfo.osVersion}
التاريخ: ${systemInfo.timestamp.toString()}
      ''';
      
      await openEmail(supportEmail, subject: subject, body: body);
    } catch (e) {
      debugPrint('Error sending feedback: $e');
      throw Exception('فشل في إرسال الملاحظات');
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
التطبيق: ${systemInfo.appInfo.appName} ${systemInfo.appInfo.version} (${systemInfo.appInfo.buildNumber})
الحزمة: ${systemInfo.appInfo.packageName}
الجهاز: ${systemInfo.deviceInfo.deviceModel}
نظام التشغيل: ${systemInfo.deviceInfo.osVersion}
المنصة: ${systemInfo.deviceInfo.platform}
جهاز حقيقي: ${systemInfo.deviceInfo.isPhysicalDevice ? 'نعم' : 'لا'}
التاريخ: ${systemInfo.timestamp.toString()}
      ''';
      
      await openEmail(supportEmail, subject: subject, body: body);
    } catch (e) {
      debugPrint('Error reporting bug: $e');
      throw Exception('فشل في إرسال تقرير الخطأ');
    }
  }

  // Check for app updates
  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      return await _apiService.checkAppVersion();
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  // Track app version click (from original Ionic app)
  Future<void> trackVersionClick() async {
    try {
      await _firebaseService.announceUser();
      await _firebaseService.logEvent('version_clicked', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Error tracking version click: $e');
    }
  }

  // Get app changelog
  static List<Map<String, dynamic>> getChangelog() {
    return [
      {
        'version': '3.2.1',
        'date': '2024-01-15',
        'changes': [
          'تحسينات في الأداء والاستقرار',
          'إصلاح مشاكل التحميل',
          'تحسين واجهة المستخدم',
          'إضافة ميزات جديدة للبحث',
        ],
      },
      {
        'version': '3.2.0',
        'date': '2023-12-20',
        'changes': [
          'إضافة قسم المقالات المختارة',
          'تحسين سرعة التطبيق',
          'إصلاح مشاكل الإشعارات',
          'دعم أفضل للأجهزة الحديثة',
        ],
      },
      {
        'version': '3.1.5',
        'date': '2023-11-30',
        'changes': [
          'إصلاح مشاكل التحميل',
          'تحسين جودة الصور',
          'إضافة خيارات مشاركة جديدة',
        ],
      },
    ];
  }

  // Get app statistics
  static Future<Map<String, dynamic>> getAppStatistics() async {
    try {
      final systemInfo = await getSystemInfo();
      return {
        'totalDownloads': '1M+',
        'rating': '4.5',
        'lastUpdated': '2024-01-15',
        'supportedLanguages': ['العربية', 'English'],
        'minOSVersion': Platform.isAndroid ? 'Android 5.0' : 'iOS 12.0',
        'appSize': Platform.isAndroid ? '25 MB' : '30 MB',
        'currentVersion': systemInfo.appInfo.version,
        'buildNumber': systemInfo.appInfo.buildNumber,
      };
    } catch (e) {
      debugPrint('Error getting app statistics: $e');
      return {};
    }
  }

  // Helper method to encode query parameters
  static String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // Get privacy policy text
  static String getPrivacyPolicyText() {
    return '''
سياسة الخصوصية

يستخدم موقع و/أو برنامج الشروق بيانات مستخدمي الموقع و/أو البرنامج مثل البريد الإليكتروني أو معرف الهاتف المحمول (الموبايل) أو الجهاز اللوحي (التابلت) من أجل أن تتمكن من تقديم خدماتها لكم مثل خدمة القائمة البريدية أو إرسال الإشعارات، لذلك فإن موقع و/أو برنامج الشروق يكون بحاجة أحيانا إلى جمع معلومات عن مستخدميه.

يمكن لموقع و/أو برنامج الشروق مشاركة البيانات السابق توضيحها مع مزودي الخدمات المختلفة من أجل ضمان استمرار الخدمة.

يحتوي موقع و/أو برنامج الشروق على روابط لمواقع أخرى، موقع و/أو برنامج الشروق غير مسؤولان عن محتوى المواقع الخارجية، وتقع مسؤولية استخدامها على عاتق المستخدم.

يستخدم موقع و/أو برنامج الشروق ملفات تعريف الارتباط cookies بهدف التعرف على احتياجات المستخدمين.

يحق للشروق أو الشركة المبرمجة للموقع و/أو برنامج الشروق تغيير هذه البنود في أي وقت بدون التنويه سابقا بتغييرها.
    ''';
  }

  // Get terms of service text
  static String getTermsOfServiceText() {
    return '''
شروط الاستخدام

الخدمات والمعلومات والمحتوى التي يوفرها موقع و/أو برنامج الشروق ، المنشورة عليه أو التي يمكن الوصول إليها أو تحميلها من خلاله هي لأغراض إعلامية عامة فقط ، وليست لأغراض إعادة البيع ، والتوزيع ، والعرض العام ، أو الأداء ، أو غيرها من الاستخدامات بأي شكل أو طريقة كانت.

استخدمت الشروق طرقاً مشروعة ومكلفة للحصول على محتوى قيم في وقت مناسب ، بما في ذلك الصور والأخبار والمقالات وملفات الفيديو وغيرها ، ونحن نضمن دقة وصحة وملاءمة كل ذلك ، ويسعدنا تلقي أي تعليقات حول أي أخطاء بشرية قد تتجاوز الحدود القانونية والمهنية وحقوق الغير في الحصول على المحتوى أو استخدامه

والشروق غير مسئولة بشكل مباشر أو غير مباشر عن أي خسارة أو ضرر من أي نوع يحدث بسبب سوء استخدام المحتوى الوارد بالموقع

وتناشد الشروق قرائها الأعزاء احترام حقوق الغير في التعبير في إطار القانون واحترام الديانات والعقائد والأعراق والجنسيات ، وسوف يضطر فريق الموقع آسفاً إلى اتخاذ الإجراءات اللازمة لمنع أي تعليقات أو مشاركات تتعارض مع تلك القواعد ، بما فيها المنع النهائي من التعليق على الموقع إذا لزم الأمر
    ''';
  }

  // Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}