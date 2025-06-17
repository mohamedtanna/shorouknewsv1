import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import 'search_module.dart';
import '../../widgets/news_card.dart';
import '../../models/new_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _api = ApiService();
  final SearchModule _module = SearchModule();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<NewsArticle> _results = [];
  List<String> _suggestions = [];
  bool _loading = false;
  bool _initLoading = true;
  List<NewsArticle> _latest = [];

  @override
  void initState() {
    super.initState();
    _loadLatest();
    _controller.addListener(_onChanged);
  }

  Future<void> _loadLatest() async {
    setState(() => _initLoading = true);
    try {
      _latest = await _api.getNews(pageSize: 5);
    } catch (e) {
      debugPrint('Error loading latest news: $e');
    }
    if (mounted) {
      setState(() => _initLoading = false);
    }
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final text = _controller.text.trim();
      if (text.isEmpty) {
        setState(() {
          _suggestions = [];
          _results = [];
        });
        return;
      }
      setState(() => _loading = true);
      try {
        final norm = normalizeArabic(text);
        final results = await _api.searchNews(norm);
        await _module.addRecentSearch(text);
        List<String> sugg = [];
        if (text.length > 4) {
          final recent = await _module.getRecentSearches();
          sugg = recent
              .where((s) => s.toLowerCase().contains(text.toLowerCase()))
              .take(5)
              .toList();
        }
        if (mounted) {
          setState(() {
            _results = results;
            _suggestions = sugg;
            _loading = false;
          });
        }
      } catch (e) {
        debugPrint('Search error: $e');
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: 'Search...'),
            ),
          ),
          if (_controller.text.isEmpty) _buildLatest() else _buildResults(),
        ],
      ),
    );
  }

  Widget _buildLatest() {
    if (_initLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (_latest.isEmpty) {
      return const Expanded(child: Center(child: Text('No news found.')));
    }
    return Expanded(
      child: ListView.builder(
        itemCount: _latest.length,
        itemBuilder: (context, index) {
          final article = _latest[index];
          return NewsCard(
            article: article,
            isHorizontal: true,
            onTap: () => context.push('/news/${article.cDate}/${article.id}'),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    return Expanded(
      child: ListView(
        children: [
          if (_suggestions.isNotEmpty)
            ..._suggestions.map((s) => ListTile(
                  title: Text(s),
                  leading: const Icon(Icons.history),
                  onTap: () {
                    _controller.text = s;
                    _onChanged();
                  },
                )),
          ..._results.map((article) => NewsCard(
                article: article,
                isHorizontal: true,
                onTap: () =>
                    context.push('/news/${article.cDate}/${article.id}'),
              )),
        ],
      ),
    );
  }
}

String normalizeArabic(String input) {
  var result = input;
  result = result.replaceAll(RegExp('[\\u0623\\u0625\\u0622]'), 'ا');
  result = result.replaceAll('ى', 'ي');
  result = result.replaceAll('ة', 'ه');
  result = result.replaceAll('ؤ', 'و');
  result = result.replaceAll(RegExp('[\\u064B-\\u0652]'), '');
  result = result.replaceAll(
      RegExp('[\\u061B\\u061F\\u066A-\\u066D\\u06D4\\u060C.,!?]'), '');
  result = result.trim();
  return result;
}
