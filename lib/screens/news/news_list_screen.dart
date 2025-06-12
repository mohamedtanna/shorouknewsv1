import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/new_model.dart';
import '../../providers/news_provider.dart';
import '../../widgets/news_card.dart';

class NewsListScreen extends StatefulWidget {
  final String? sectionId;
  final String section;

  const NewsListScreen({super.key, this.sectionId, required this.section});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<NewsArticle> _newsList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNews(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(NewsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if section parameters have changed
    if (oldWidget.sectionId != widget.sectionId ||
        oldWidget.section != widget.section) {
      // Reload news for new section
      _loadNews(refresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNews({bool refresh = false}) async {
    final provider = context.read<NewsProvider>();

    if (refresh) {
      setState(() {
        _newsList.clear();
        _isLoading = true;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    final newItems = await provider.loadNews(
      sectionId: widget.sectionId,
      refresh: refresh,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
      _newsList.addAll(newItems);
      if (newItems.isEmpty) _hasMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadNews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNews(refresh: true),
        color: AppTheme.primaryColor,
        child: _isLoading && _newsList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                itemCount: _newsList.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _newsList.length) {
                    final article = _newsList[index];
                    return NewsCard(
                      article: article,
                      isHorizontal: true,
                      onTap: () =>
                          context.go('/news/${article.cDate}/${article.id}'),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
      ),
    );
  }
}
