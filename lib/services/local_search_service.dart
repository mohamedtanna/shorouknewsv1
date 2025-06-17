import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/new_model.dart';

class LocalSearchService {
  static const String articlesBoxName = 'articlesBox';
  static const String termsBoxName = 'searchTermsBox';

  late Box _articlesBox;
  late Box _termsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _articlesBox = await Hive.openBox(articlesBoxName);
    _termsBox = await Hive.openBox(termsBoxName);
  }

  Future<void> saveArticles(List<NewsArticle> articles) async {
    for (var article in articles) {
      await _articlesBox.put(article.id, article.toJson());
    }
  }

  List<NewsArticle> getLatestArticles(int count) {
    final items = _articlesBox.values
        .cast<Map>()
        .map((e) => NewsArticle.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    items.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return items.take(count).toList();
  }

  Future<List<NewsArticle>> search(String query) async {
    final normQuery = normalizeArabic(query);
    final results = <NewsArticle>[];
    for (var item in _articlesBox.values) {
      final article = NewsArticle.fromJson(Map<String, dynamic>.from(item));
      final text = normalizeArabic('${article.title} ${article.summary} ${article.body}');
      if (text.contains(normQuery)) {
        results.add(article);
      }
    }
    return results;
  }

  Future<void> addSearchTerm(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    final List<String> terms = _termsBox.get('terms', defaultValue: <String>[])!.cast<String>();
    if (!terms.contains(trimmed)) {
      terms.insert(0, trimmed);
      await _termsBox.put('terms', terms);
    }
  }

  List<String> getSuggestions(String query) {
    final norm = normalizeArabic(query);
    final List<String> terms = _termsBox.get('terms', defaultValue: <String>[])!.cast<String>();
    return terms.where((t) => normalizeArabic(t).contains(norm)).take(5).toList();
  }
}

String normalizeArabic(String input) {
  var result = input;
  result = result.replaceAll(RegExp('[\u0623\u0625\u0622]'), 'ا');
  result = result.replaceAll('ى', 'ي');
  result = result.replaceAll('ة', 'ه');
  result = result.replaceAll('ؤ', 'و');
  result = result.replaceAll(RegExp('[\u064B-\u0652]'), '');
  result = result.replaceAll(RegExp('[\u061B\u061F\u066A-\u066D\u06D4\u060C.,!?]'), '');
  result = result.trim();
  return result;
}
