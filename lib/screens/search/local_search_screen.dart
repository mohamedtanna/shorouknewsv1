import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/local_search_service.dart';
import '../../widgets/news_card.dart';
import '../../core/theme.dart';
import '../../models/new_model.dart';

class LocalSearchScreen extends StatefulWidget {
  const LocalSearchScreen({super.key});

  @override
  State<LocalSearchScreen> createState() => _LocalSearchScreenState();
}

class _LocalSearchScreenState extends State<LocalSearchScreen> {
  final LocalSearchService _service = LocalSearchService();
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
    _loadInitial();
    _controller.addListener(_onChanged);
  }

  Future<void> _loadInitial() async {
    await _service.init();
    final latest = _service.getLatestArticles(5);
    setState(() {
      _latest = latest;
      _initLoading = false;
    });
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final text = _controller.text;
      if (text.isEmpty) {
        setState(() {
          _suggestions = [];
          _results = [];
        });
        return;
      }
      setState(() => _loading = true);
      final results = await _service.search(text);
      await _service.addSearchTerm(text);
      final sugg = text.length > 4 ? _service.getSuggestions(text) : <String>[];
      if (mounted) {
        setState(() {
          _results = results;
          _suggestions = sugg;
          _loading = false;
        });
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
                prefixIcon: Icon(Icons.search),
                hintText: 'Search...'
              ),
            ),
          ),
          if (_controller.text.isEmpty)
            _buildLatest()
          else
            _buildResults(),
        ],
      ),
    );
  }

  Widget _buildLatest() {
    if (_initLoading) {
      return const Expanded(
          child: Center(child: CircularProgressIndicator()));
    }
    if (_latest.isEmpty) {
      return const Expanded(
        child: Center(child: Text('No local articles found.')),
      );
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
            ..._suggestions
                .map((s) => ListTile(
                      title: Text(s),
                      leading: const Icon(Icons.history),
                      onTap: () {
                        _controller.text = s;
                        _onChanged();
                      },
                    ))
                .toList(),
          ..._results
              .map((article) => NewsCard(
                    article: article,
                    isHorizontal: true,
                    onTap: () =>
                        context.push('/news/${article.cDate}/${article.id}'),
                  ))
              .toList(),
        ],
      ),
    );
  }
}
