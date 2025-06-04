import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import all screen widgets
import '../screens/home/home_screen.dart';
import '../screens/news/news_list_screen.dart';
import '../screens/news/news_detail_screen.dart';
import '../screens/videos/videos_screen.dart';
import '../screens/videos/video_detail_screen.dart';
import '../screens/columns/columns_screen.dart';
import '../screens/columns/column_detail_screen.dart';
import '../screens/authors/authors_list_screen.dart'; // Added for completeness
import '../screens/authors/author_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/newsletter/newsletter_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/terms/terms_screen.dart';
import '../screens/privacy/privacy_screen.dart';
import '../screens/search/search_screen.dart'; // Added
import '../screens/search/search_results_screen.dart'; // Added
import '../screens/notifications/notifications_screen.dart'; // Added
import '../screens/notifications/notification_detail_screen.dart'; // Added
import '../screens/gallery/photo_gallery_screen.dart'; // Added
import '../screens/gallery/image_viewer_screen.dart'; // Added
import '../screens/error/error_screen.dart'; // For fallback in router

// Import models if passed via 'extra' and type checking is desired at router level (optional)
import '../models/new_model.dart';
import '../services/notification_service.dart' show NotificationPayload;


// Import the main layout shell
import '../widgets/main_layout.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home', // The default screen when the app starts
    debugLogDiagnostics: true, // Useful for debugging navigation issues
    routes: [
      // ShellRoute applies MainLayout to all its child routes
      ShellRoute(
        builder: (context, state, child) {
          // MainLayout will wrap all screens defined in the routes below
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
              final sectionName = state.uri.queryParameters['sectionName'] ?? 'أحدث الأخبار'; // Default title
              // Corrected: NewsListScreen expects sectionId and sectionName
              return NewsListScreen(
                sectionId: sectionId,
                sectionName: sectionName,
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
            builder: (context, state) => const VideosScreen(),
          ),
          GoRoute(
            path: '/video/:videoId',
            name: 'video-detail',
            builder: (context, state) {
              final videoId = state.pathParameters['videoId']!;
              // Assuming VideoDetailScreen takes videoId and fetches details.
              // If it needs more parameters (like title or URL) passed directly,
              // this route or the VideoDetailScreen itself would need adjustment.
              return VideoDetailScreen(videoId: videoId);
            },
          ),
          GoRoute(
            path: '/columns',
            name: 'columns',
            builder: (context, state) {
              final authorId = state.uri.queryParameters['authorId']; // Changed from columnistId
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
            path: '/authors', // Added route for listing all authors
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
            builder: (context, state) => const NewsletterScreen(),
          ),
          GoRoute(
            path: '/contact',
            name: 'contact',
            builder: (context, state) => const ContactScreen(),
          ),
          GoRoute(
            path: '/about',
            name: 'about',
            builder: (context, state) => const AboutScreen(),
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
          // Added Search Routes
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/search-results',
            name: 'search-results',
            builder: (context, state) {
              final query = state.uri.queryParameters['query'] ?? '';
              final decodedQuery = Uri.decodeComponent(query);
              return SearchResultsScreen(query: decodedQuery);
            },
          ),
          // Added Notification Routes
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/notification-detail',
            name: 'notification-detail',
            builder: (context, state) {
              final NotificationPayload? notification = state.extra as NotificationPayload?;
              if (notification != null) {
                return NotificationDetailScreen(notification: notification);
              }
              return const ErrorScreen(errorMessage: 'تفاصيل الإشعار غير متوفرة.');
            },
          ),
          // Added Gallery Routes
          GoRoute(
            path: '/gallery',
            name: 'gallery',
            builder: (context, state) {
              final List<RelatedPhoto>? photos = state.extra as List<RelatedPhoto>?;
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
              final Map<String, dynamic>? args = state.extra as Map<String, dynamic>?;
              if (args != null && args['photos'] is List<RelatedPhoto>) {
                return ImageViewerScreen(
                  photos: args['photos'] as List<RelatedPhoto>,
                  initialIndex: args['initialIndex'] as int? ?? 0,
                  galleryTitle: args['galleryTitle'] as String?,
                );
              }
              return const ErrorScreen(errorMessage: 'بيانات الصورة غير متوفرة.');
            },
          ),
        ],
      ),
    ],
    // Error builder for routes that are not found
    errorBuilder: (context, state) => ErrorScreen(
      errorMessage: 'الصفحة المطلوبة غير موجودة.\n(${state.error?.message ?? 'مسار غير معروف'})',
      onRetry: () => context.go('/home'), // Option to go home
      retryButtonText: 'العودة للرئيسية',
    ),
  );
}
