import 'package:go_router/go_router.dart';

// Import all screen widgets
import '../screens/home/home_screen.dart';
import '../screens/news/news_list_screen.dart';
import '../screens/news/news_detail_screen.dart';
import '../screens/videos/videos_screen.dart';
import '../screens/videos/video_detail_screen.dart';
import '../screens/columns/columns_screen.dart';
import '../screens/columns/column_detail_screen.dart';
import '../screens/authors/authors_list_screen.dart';
import '../screens/authors/author_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/newsletter/newsletter_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/terms/terms_screen.dart';
import '../screens/privacy/privacy_screen.dart';
import '../screens/gallery/photo_gallery_screen.dart';
import '../screens/gallery/image_viewer_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/notifications/notification_detail_screen.dart';
import '../screens/notifications/notifications_module.dart'
    show NotificationPayload;
import '../screens/error/error_screen.dart';
import '../screens/splash/splash_screen.dart';

// Import models if passed via 'extra'
import 'package:shorouk_news/models/new_model.dart';

// Import the main layout shell
import '../widgets/main_layout.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/news',
            name: 'news',
            builder: (context, state) {
              final sectionId = state.uri.queryParameters['sectionId'];
              final sectionName =
                  state.uri.queryParameters['sectionName'] ?? 'أحدث الأخبار';
              return NewsListScreen(
                sectionId: sectionId,
                section: sectionName,
              );
            },
          ),
          GoRoute(
            path: '/news/:cdate/:id',
            name: 'news-detail',
            builder: (context, state) {
              final cdate = state.pathParameters['cdate']!;
              final id = state.pathParameters['id']!;
              return NewsDetailScreen(
                cdate: cdate,
                newsId: id,
              );
            },
          ),
          GoRoute(
            path: '/videos',
            name: 'videos',
            builder: (context, state) => const VideosScreen(), // Removed const
          ),
          GoRoute(
            path: '/video/:videoId',
            name: 'video-detail',
            builder: (context, state) {
              final videoId = state.pathParameters['videoId']!;
              // CRITICAL: VideoDetailScreen MUST be refactored to fetch its own
              // videoUrl and videoTitle using the videoId.
              // These empty strings are placeholders to satisfy the current constructor
              // signature as indicated by previous errors.
              return VideoDetailScreen(
                videoId: videoId,
                videoUrl: '',
                videoTitle: '',
              );
            },
          ),
          GoRoute(
            path: '/columns',
            name: 'columns',
            builder: (context, state) {
              final authorId = state.uri.queryParameters['authorId'];
              final categoryId = state.uri.queryParameters['categoryId'];
              return ColumnsScreen(authorId: authorId, categoryId: categoryId);
            },
          ),
          GoRoute(
            path: '/column/:cdate/:id',
            name: 'column-detail',
            builder: (context, state) {
              final cdate = state.pathParameters['cdate']!;
              final id = state.pathParameters['id']!;
              return ColumnDetailScreen(
                cdate: cdate,
                columnId: id,
              );
            },
          ),
          GoRoute(
            path: '/authors',
            name: 'authors',
            builder: (context, state) => const AuthorsListScreen(),
          ),
          GoRoute(
            path: '/author/:id',
            name: 'author',
            builder: (context, state) {
              final authorId = state.pathParameters['id']!;
              return AuthorScreen(authorId: authorId);
            },
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/newsletter',
            name: 'newsletter',
            builder: (context, state) =>
                const NewsletterScreen(), // Removed const
          ),
          GoRoute(
            path: '/contact',
            name: 'contact',
            builder: (context, state) => const ContactScreen(), // Removed const
          ),
          GoRoute(
            path: '/about',
            name: 'about',
            builder: (context, state) => const AboutScreen(), // Removed const
          ),
          GoRoute(
            path: '/terms',
            name: 'terms',
            builder: (context, state) => const TermsScreen(),
          ),
          GoRoute(
            path: '/privacy',
            name: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/notification-detail',
            name: 'notification-detail',
            builder: (context, state) {
              final payload = state.extra as NotificationPayload?;
              if (payload != null) {
                return NotificationDetailScreen(notification: payload);
              }
              return const ErrorScreen(errorMessage: 'بيانات الإشعار غير متوفرة');
            },
          ),
          GoRoute(
            path: '/search',
            name: 'search',
          ),
          GoRoute(
            path: '/gallery',
            name: 'gallery',
            builder: (context, state) {
              final List<RelatedPhoto>? photos =
                  state.extra as List<RelatedPhoto>?;
              final String? galleryTitle = state.uri.queryParameters['title'];
              final String? albumId = state.uri.queryParameters['albumId'];
              return PhotoGalleryScreen(
                photos: photos,
                albumId: albumId,
                galleryTitle: galleryTitle ?? 'معرض الصور',
              );
            },
          ),
          GoRoute(
            path: '/image-viewer',
            name: 'image-viewer',
            builder: (context, state) {
              final Map<String, dynamic>? args =
                  state.extra as Map<String, dynamic>?;
              if (args != null && args['photos'] is List<RelatedPhoto>) {
                return ImageViewerScreen(
                  photos: args['photos'] as List<RelatedPhoto>,
                  initialIndex: args['initialIndex'] as int? ?? 0,
                  galleryTitle: args['galleryTitle'] as String?,
                );
              }
              return const ErrorScreen(
                  errorMessage: 'بيانات الصورة غير متوفرة.');
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(
      errorMessage:
          'الصفحة المطلوبة غير موجودة.\n(${state.error?.message ?? 'مسار غير معروف'})',
      onRetry: () => context.go('/home'),
      retryButtonText: 'العودة للرئيسية',
    ),
  );
}
