import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/news_provider.dart';
import 'package:shorouk_news/models/new_model.dart';
import '../core/theme.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<NewsSection> sections = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSections();
    });
  }

  Future<void> _loadSections() async {
    try {
      final newsProvider = context.read<NewsProvider>();
      final loadedSections = await newsProvider.loadSections();
      setState(() {
        sections = loadedSections;
      });
    } catch (e) {
      print('Error loading sections: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final isHome = currentLocation == '/home';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (isHome) {
              // Refresh home page
              context.read<NewsProvider>().refreshAllData();
            } else {
              context.go('/home');
            }
          },
          child: Image.asset(
            'assets/images/logo.png', // Add your logo image
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                'الشروق',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (!isHome)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                // Use context.canPop() to check if we can pop
                if (context.canPop()) {
                  context.pop();
                } else {
                  // If we can't pop, go home
                  context.go('/home');
                }
              },
            ),
          if (isHome)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.go('/settings'),
            ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: widget.child,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_white.png', // Add your white logo
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'الشروق',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      // Close drawer first
                      Navigator.of(context).pop();
                      // Then navigate
                      context.go('/settings');
                    },
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: const Text(
                      'الإعدادات',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  title: 'الرئيسية',
                  onTap: () {
                    // Close drawer
                    Navigator.of(context).pop();
                    // Navigate to home
                    context.go('/home');
                  },
                  isFirst: true,
                ),
                _buildDrawerItem(
                  title: 'رأي ومقالات',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/columns');
                  },
                ),
                _buildDrawerItem(
                  title: 'أحدث الأخبار',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/news');
                  },
                ),

                // News Sections
                ...sections.map((section) => _buildDrawerItem(
                      title: section.arName,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(
                            '/news?sectionId=${section.id}&sectionName=${section.arName}');
                      },
                    )),

                _buildDrawerItem(
                  title: 'فيديو',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/videos');
                  },
                  isTopBorder: true,
                ),
                _buildDrawerItem(
                  title: 'القائمة البريدية',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/newsletter');
                  },
                ),
                _buildDrawerItem(
                  title: 'اتصل بنا',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/contact');
                  },
                ),
                _buildDrawerItem(
                  title: 'شروط الاستخدام',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/terms');
                  },
                ),
                _buildDrawerItem(
                  title: 'سياسة الخصوصية',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/privacy');
                  },
                ),
                _buildDrawerItem(
                  title: 'عن البرنامج',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/about');
                  },
                ),
              ],
            ),
          ),

          // Social Media Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialIcon('assets/images/facebook.svg',
                    'https://www.facebook.com/shorouknews'),
                _buildSocialIcon('assets/images/youtube.svg',
                    'https://www.youtube.com/channel/UCGONWo6kCXGwtyA8SHrHIAw'),
                _buildSocialIcon('assets/images/twitter.svg',
                    'https://twitter.com/#!/shorouk_news'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required String title,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isTopBorder = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        border: Border(
          bottom: BorderSide(
            color: isFirst ? AppTheme.tertiaryColor : Colors.transparent,
            width: 2,
          ),
          top: BorderSide(
            color: isTopBorder ? AppTheme.tertiaryColor : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildSocialIcon(String assetPath, String url) {
    return GestureDetector(
      onTap: () {
        // Launch URL - you'll need to implement this with url_launcher
        print('Opening: $url');
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.link, // Replace with actual social media icons
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
    );
  }
}
