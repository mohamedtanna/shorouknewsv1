import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/news/news_list_screen.dart';
import '../screens/news/news_detail_screen.dart';
import '../screens/videos/videos_screen.dart';
import '../screens/videos/video_detail_screen.dart';
import '../screens/columns/columns_screen.dart';
import '../screens/columns/column_detail_screen.dart';
import '../screens/authors/author_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/newsletter/newsletter_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/terms/terms_screen.dart';
import '../screens/privacy/privacy_screen.dart';
import '../widgets/main_layout.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
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
              final sectionName = state.uri.queryParameters['sectionName'] ?? 'أحدث الأخبار';
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
              return VideoDetailScreen(videoId: videoId);
            },
          ),
          GoRoute(
            path: '/columns',
            name: 'columns',
            builder: (context, state) {
              final columnistId = state.uri.queryParameters['columnistId'];
              return ColumnsScreen(columnistId: columnistId);
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
        ],
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text(
          'الصفحة غير موجودة',
          style: TextStyle(fontSize: 18),
        ),
      ),
    ),
  );
}