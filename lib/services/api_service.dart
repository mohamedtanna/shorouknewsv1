import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_model.dart';
import '../models/additional_models.dart';

class ApiService {
  static const String baseUrl = 'https://your-api-url.com/api/'; // Replace with actual API URL
  static const String apiToken = 'shorouknews_6s6sd3@ewd#\$Ji\$8sd5EAljkW*sw@ddwqq*w002';
  
  late Dio _dio;
  static ApiService? _instance;
  
  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'shorouknews-api-token': apiToken,
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));
  }

  // Check internet connectivity
  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Generic GET request with caching
  Future<T> _get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool useCache = false,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(List<dynamic>)? fromJsonList,
  }) async {
    try {
      // Check for cached data if offline
      if (!await _hasInternetConnection() && useCache) {
        return await _getCachedData<T>(endpoint, fromJson, fromJsonList);
      }

      final response = await _dio.get(endpoint, queryParameters: queryParameters);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Cache the response if caching is enabled
        if (useCache) {
          await _cacheData(endpoint, data);
        }
        
        if (fromJson != null && data is Map<String, dynamic>) {
          return fromJson(data);
        } else if (fromJsonList != null && data is List) {
          return fromJsonList(data);
        }
        
        return data as T;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Try to get cached data if request fails
      if (useCache) {
        try {
          return await _getCachedData<T>(endpoint, fromJson, fromJsonList);
        } catch (cacheError) {
          throw Exception('Network error and no cached data available');
        }
      }
      
      throw Exception('Network error: ${e.message}');
    }
  }

  // Generic POST request
  Future<T> _post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(dynamic)? fromData,
  }) async {
    try {
      if (!await _hasInternetConnection()) {
        throw Exception('No internet connection');
      }

      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (fromJson != null && responseData is Map<String, dynamic>) {
          return fromJson(responseData);
        } else if (fromData != null) {
          return fromData(responseData);
        }
        
        return responseData as T;
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Cache data locally
  Future<void> _cacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_$key', jsonEncode(data));
      await prefs.setInt('cache_time_$key', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching data: $e');
    }
  }

  // Get cached data
  Future<T> _getCachedData<T>(
    String key,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(List<dynamic>)? fromJsonList,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cache_$key');
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        
        if (fromJson != null && data is Map<String, dynamic>) {
          return fromJson(data);
        } else if (fromJsonList != null && data is List) {
          return fromJsonList(data);
        }
        
        return data as T;
      }
    } catch (e) {
      print('Error getting cached data: $e');
    }
    
    throw Exception('No cached data available');
  }

  // Check if cache is valid (within 1 hour)
  Future<bool> _isCacheValid(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt('cache_time_$key');
      
      if (cacheTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final diff = now - cacheTime;
        return diff < (60 * 60 * 1000); // 1 hour in milliseconds
      }
    } catch (e) {
      print('Error checking cache validity: $e');
    }
    
    return false;
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // News API methods
  Future<List<NewsArticle>> getMainStories() async {
    return await _get<List<NewsArticle>>(
      'news/collections/mainstories',
      useCache: true,
      fromJsonList: (list) => list.map((item) => NewsArticle.fromJson(item)).toList(),
    );
  }

  Future<List<NewsArticle>> getTopStories() async {
    return await _get<List<NewsArticle>>(
      'news/collections/topstories',
      useCache: true,
      fromJsonList: (list) => list.map((item) => NewsArticle.fromJson(item)).toList(),
    );
  }

  Future<List<NewsArticle>> getMostReadStories() async {
    return await _get<List<NewsArticle>>(
      'news/mostread',
      useCache: true,
      fromJsonList: (list) => list.map((item) => NewsArticle.fromJson(item)).toList(),
    );
  }

  Future<List<NewsArticle>> getNews({
    String? sectionId,
    int currentPage = 1,
    int pageSize = 10,
  }) async {
    String endpoint = sectionId != null 
        ? 'sections/$sectionId/news' 
        : 'news';
    
    return await _get<List<NewsArticle>>(
      endpoint,
      queryParameters: {
        'currentpage': currentPage,
        'pagesize': pageSize,
      },
      fromJsonList: (list) => list.map((item) => NewsArticle.fromJson(item)).toList(),
    );
  }

  Future<NewsArticle> getNewsDetail(String cdate, String id) async {
    return await _get<NewsArticle>(
      'news/$cdate/$id',
      fromJson: (json) => NewsArticle.fromJson(json),
    );
  }

  Future<List<NewsSection>> getSections() async {
    return await _get<List<NewsSection>>(
      'sections',
      useCache: true,
      fromJsonList: (list) => list.map((item) => NewsSection.fromJson(item)).toList(),
    );
  }

  // Videos API methods
  Future<List<VideoModel>> getVideos({
    String? nextPageToken,
    int pageSize = 10,
  }) async {
    return await _get<List<VideoModel>>(
      'videos',
      queryParameters: {
        if (nextPageToken != null) 'nextpagetoken': nextPageToken,
        'pagesize': pageSize,
      },
      fromJsonList: (list) => list.map((item) => VideoModel.fromJson(item)).toList(),
    );
  }

  Future<VideoModel> getVideoDetail(String videoId) async {
    return await _get<VideoModel>(
      'videos/$videoId',
      fromJson: (json) => VideoModel.fromJson(json),
    );
  }

  // Columns API methods
  Future<List<ColumnModel>> getSelectedColumns() async {
    return await _get<List<ColumnModel>>(
      'columns/collections/selected',
      useCache: true,
      fromJsonList: (list) => list.map((item) => ColumnModel.fromJson(item)).toList(),
    );
  }

  Future<List<ColumnModel>> getColumns({
    String? columnistId,
    int currentPage = 1,
    int pageSize = 10,
  }) async {
    String endpoint = columnistId != null 
        ? 'columnists/$columnistId/columns' 
        : 'columns';
    
    return await _get<List<ColumnModel>>(
      endpoint,
      queryParameters: {
        'currentpage': currentPage,
        'pagesize': pageSize,
      },
      fromJsonList: (list) => list.map((item) => ColumnModel.fromJson(item)).toList(),
    );
  }

  Future<ColumnModel> getColumnDetail(String cdate, String id) async {
    return await _get<ColumnModel>(
      'columns/$cdate/$id',
      fromJson: (json) => ColumnModel.fromJson(json),
    );
  }

  // Authors API methods
  Future<AuthorModel> getAuthor(String authorId) async {
    return await _get<AuthorModel>(
      'columnists/$authorId',
      fromJson: (json) => AuthorModel.fromJson(json),
    );
  }

  Future<List<ColumnModel>> getAuthorColumns(String authorId, {
    int currentPage = 1,
    int pageSize = 10,
  }) async {
    return await _get<List<ColumnModel>>(
      'columnists/$authorId/columns',
      queryParameters: {
        'currentpage': currentPage,
        'pagesize': pageSize,
      },
      fromJsonList: (list) => list.map((item) => ColumnModel.fromJson(item)).toList(),
    );
  }

  // Newsletter API method
  Future<int> subscribeToNewsletter(String email) async {
    try {
      final result = await _post<int>(
        'subscribers/create',
        queryParameters: {'email': email},
        fromData: (data) {
          if (data is String) {
            return int.parse(data);
          }
          return data as int;
        },
      );
      return result;
    } catch (e) {
      print('Error subscribing to newsletter: $e');
      return 10; // General failure
    }
  }

  // User management for push notifications
  Future<void> createUser({
    required String token,
    required int os, // 0: other, 1: Android, 2: iOS
    required String deviceType,
    required String deviceModel,
  }) async {
    try {
      await _post(
        'users/create',
        queryParameters: {
          'token': token,
          'os': os,
          'devicetype': deviceType,
          'devicemodel': deviceModel,
        },
      );
    } catch (e) {
      print('Error creating user: $e');
    }
  }

  Future<void> announceUser(String token) async {
    try {
      await _post(
        'users/announce',
        queryParameters: {'token': token},
      );
    } catch (e) {
      print('Error announcing user: $e');
    }
  }

  // Search functionality
  Future<List<NewsArticle>> searchNews(String query, {
    int currentPage = 1,
    int pageSize = 10,
  }) async {
    return await _get<List<NewsArticle>>(
      'news/search',
      queryParameters: {
        'q': query,
        'currentpage': currentPage,
        'pagesize': pageSize,
      },
      fromJsonList: (list) => list.map((item) => NewsArticle.fromJson(item)).toList(),
    );
  }

  // Related content
  Future<List<NewsArticle>> getRelatedNews(String newsId, {
    int pageSize = 6,
  }) async {
    return await _get<List<NewsArticle>>(
      'news/$newsId/related',
      queryParameters: {
        'pagesize': pageSize,
      },
      fromJsonList: (list) => list.map((item) => NewsArticle.fromJson(item)).toList(),
    );
  }

  // Analytics and tracking
  Future<void> trackNewsView(String newsId) async {
    try {
      await _post(
        'analytics/news/view',
        data: {
          'newsId': newsId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking news view: $e');
    }
  }

  Future<void> trackVideoView(String videoId) async {
    try {
      await _post(
        'analytics/video/view',
        data: {
          'videoId': videoId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking video view: $e');
    }
  }

  Future<void> trackColumnView(String columnId) async {
    try {
      await _post(
        'analytics/column/view',
        data: {
          'columnId': columnId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error tracking column view: $e');
    }
  }

  // Contact form submission
  Future<bool> submitContactForm({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      await _post(
        'contact/submit',
        data: {
          'name': name,
          'email': email,
          'subject': subject,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      print('Error submitting contact form: $e');
      return false;
    }
  }

  // App version check
  Future<Map<String, dynamic>?> checkAppVersion() async {
    try {
      return await _get<Map<String, dynamic>>(
        'app/version',
        fromJson: (json) => json,
      );
    } catch (e) {
      print('Error checking app version: $e');
      return null;
    }
  }

  // Get trending topics
  Future<List<String>> getTrendingTopics() async {
    try {
      return await _get<List<String>>(
        'trending/topics',
        fromJsonList: (list) => list.cast<String>(),
      );
    } catch (e) {
      print('Error getting trending topics: $e');
      return [];
    }
  }

  // Weather info (if included in the app)
  Future<Map<String, dynamic>?> getWeatherInfo() async {
    try {
      return await _get<Map<String, dynamic>>(
        'weather/current',
        fromJson: (json) => json,
      );
    } catch (e) {
      print('Error getting weather info: $e');
      return null;
    }
  }

  // Breaking news alerts
  Future<List<NewsArticle>> getBreakingNews() async {
    try {
      return await _get<List<NewsArticle>>(
        'news/breaking',
        fromJsonList: (list) => list.map((item) => NewsArticle.fromJson(item)).toList(),
      );
    } catch (e) {
      print('Error getting breaking news: $e');
      return [];
    }
  }

  // Dispose method
  void dispose() {
    _dio.close();
  }
}