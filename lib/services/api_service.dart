import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shorouk_news/models/new_model.dart';
import 'package:shorouk_news/models/additional_models.dart';
import 'package:shorouk_news/models/column_model.dart';

class ApiService {
  // Updated baseUrl with the provided API URL
  static const String baseUrl = 'https://shorouknews.pri.land/api/v1/';
  static const String apiToken =
      'shorouknews_6s6sd3@ewd#\$Ji\$8sd5EAljkW*sw@ddwqq*w002';

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
        // Consider adding other common headers like 'Accept' if needed
        // 'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30), // 30 seconds
      receiveTimeout: const Duration(seconds: 30), // 30 seconds
    ));

    // Add interceptors for logging and potentially error handling/retries
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) =>
          debugPrint(obj.toString()), // Use debugPrint for Flutter
      requestHeader: true,
      responseHeader:
          false, // Avoid logging too much header info unless needed for debugging
      error: true,
    ));

    // Example: Custom interceptor for more advanced error handling or token refresh
    // _dio.interceptors.add(InterceptorsWrapper(
    //   onRequest: (options, handler) {
    //     // Do something before request is sent
    //     // e.g., add dynamic token
    //     return handler.next(options); //continue
    //   },
    //   onResponse: (response, handler) {
    //     // Do something with response data
    //     return handler.next(response); // continue
    //   },
    //   onError: (DioException e, handler) {
    //     // Handle specific error codes, e.g., 401 for unauthorized
    //     debugPrint('DioException: ${e.message}, Response: ${e.response?.data}');
    //     // Potentially refresh token or navigate to login
    //     return handler.next(e); // Forward the error or resolve it
    //   },
    // ));
  }

  /// Checks internet connectivity.
  /// Returns true if connected to Mobile, WiFi, or Ethernet.
  Future<bool> _hasInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResults = (await Connectivity()
          .checkConnectivity()) as List<ConnectivityResult>;
      if (connectivityResults.contains(ConnectivityResult.none) &&
          connectivityResults.length == 1) {
        return false; // Explicitly offline
      }
      // If it's not 'none' or if the list contains other types like mobile, wifi, ethernet, vpn, etc.
      // it's generally considered connected for basic purposes.
      // For more granular control, you might check for specific types:
      // return connectivityResults.any((result) =>
      //   result == ConnectivityResult.mobile ||
      //   result == ConnectivityResult.wifi ||
      //   result == ConnectivityResult.ethernet);
      return connectivityResults.isNotEmpty &&
          !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint("Error checking connectivity: $e");
      return false; // Assume no connection if check fails
    }
  }

  /// Generates a cache key based on endpoint and query parameters.
  String _generateCacheKey(String endpoint, Map<String, dynamic>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) {
      return endpoint;
    }
    // Sort queryParams by key to ensure consistent key order for caching
    final sortedKeys = queryParams.keys.toList()..sort();
    final queryString =
        sortedKeys.map((key) => '$key=${queryParams[key]}').join('&');
    return '$endpoint?$queryString';
  }

  /// Generic GET request with caching.
  Future<T> _get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool useCache = false,
    Duration cacheDuration = const Duration(hours: 1), // Default cache duration
    T Function(Map<String, dynamic> json)? fromJson, // For single objects
    T Function(List<dynamic> jsonList)? fromJsonList, // For lists of objects
  }) async {
    debugPrint('GET request to $endpoint with params: $queryParameters, useCache: $useCache');
    final String cacheKey =
        useCache ? _generateCacheKey(endpoint, queryParameters) : endpoint;

    if (useCache) {
      final bool isConnected = await _hasInternetConnection();
      if (!isConnected) {
        debugPrint('Offline: Attempting to load "$cacheKey" from cache.');
        try {
          return await _getCachedData<T>(
              cacheKey, fromJson, fromJsonList, cacheDuration);
        } catch (e) {
          debugPrint('Offline and cache miss/error for "$cacheKey": $e');
          throw Exception('لا يوجد اتصال بالإنترنت ولا توجد بيانات مخبأة.');
        }
      }
      // Optional: If online, you could still check for valid, non-expired cache first
      // before making a network request to save data, depending on your app's freshness needs.
      // For example:
      // try {
      //   final cached = await _getCachedData<T>(cacheKey, fromJson, fromJsonList, cacheDuration);
      //   debugPrint('Online: Cache hit and valid for "$cacheKey", returning cached data.');
      //   return cached;
      // } catch (e) {
      //   debugPrint('Online: Cache miss or expired for "$cacheKey", proceeding with network request.');
      // }
    }

    try {
      final response =
          await _dio.get(endpoint, queryParameters: queryParameters);

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('Response for $endpoint: ${response.statusCode}, data type: ${data.runtimeType}');
        if (useCache) {
          await _cacheData(cacheKey, data);
        }

        if (fromJson != null && data is Map<String, dynamic>) {
          return fromJson(data);
        } else if (fromJsonList != null && data is List<dynamic>) {
          return fromJsonList(data);
        } else if (data is T) {
          return data;
        }
        // Handle cases where T might be void (represented as Null in Dart generics)
        // and the API returns an empty body or null, which is valid for void returns.
        if (T == Null &&
            (data == null ||
                (data is Map && data.isEmpty) ||
                (data is List && data.isEmpty))) {
          return null as T; // Cast null to T (which is Null)
        }
        throw Exception(
            'Type mismatch or parsing function not provided for response data type: ${data.runtimeType} for endpoint $endpoint. Expected $T.');
      } else {
        debugPrint(
            'API Error for GET "$endpoint": ${response.statusCode} - ${response.statusMessage}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load data: ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException for GET "$endpoint": ${e.message}');
      if (useCache) {
        debugPrint(
            'Network error: Attempting to load "$cacheKey" from cache due to DioException.');
        try {
          return await _getCachedData<T>(
              cacheKey, fromJson, fromJsonList, cacheDuration);
        } catch (cacheError) {
          debugPrint(
              'Cache miss/error for "$cacheKey" after DioException: $cacheError');
          throw Exception(
              'خطأ في الشبكة ولم يتم العثور على بيانات مخبأة: ${e.message}');
        }
      }
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in _get for "$endpoint": $e');
      rethrow;
    }
  }

  /// Public wrapper around [_get].
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool useCache = false,
    Duration cacheDuration = const Duration(hours: 1),
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(List<dynamic> jsonList)? fromJsonList,
  }) {
    return _get<T>(
      endpoint,
      queryParameters: queryParameters,
      useCache: useCache,
      cacheDuration: cacheDuration,
      fromJson: fromJson,
      fromJsonList: fromJsonList,
    );
  }

  /// Generic POST request.
  Future<T> _post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(dynamic responseData)? fromData,
  }) async {
    if (!await _hasInternetConnection()) {
      throw Exception('لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك.');
    }

    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        final responseData = response.data;

        if (response.statusCode == 204) {
          if (T == Null || null is T) {
            return null as T;
          } else {
            if (T != dynamic) {
              throw Exception(
                  'Received 204 No Content, but expected a non-nullable $T for endpoint $endpoint');
            }
            return null as T;
          }
        }

        if (fromJson != null && responseData is Map<String, dynamic>) {
          return fromJson(responseData);
        } else if (fromData != null) {
          return fromData(responseData);
        } else if (responseData is T) {
          return responseData;
        } else if (T == Null && responseData == null) {
          return null as T;
        }
        throw Exception(
            'Type mismatch or parsing function not provided for POST response data type: ${responseData.runtimeType} for endpoint $endpoint. Expected $T.');
      } else {
        debugPrint(
            'API Error for POST "$endpoint": ${response.statusCode} - ${response.statusMessage}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to post data: ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      debugPrint('DioException for POST "$endpoint": ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in _post for "$endpoint": $e');
      rethrow;
    }
  }

  /// Cache data locally using SharedPreferences.
  Future<void> _cacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'api_cache_$key', jsonEncode(data)); // Added prefix for clarity
      await prefs.setInt(
          'api_cache_time_$key', DateTime.now().millisecondsSinceEpoch);
      debugPrint('Data cached for key: api_cache_$key');
    } catch (e) {
      debugPrint('Error caching data for key api_cache_$key: $e');
    }
  }

  /// Get cached data from SharedPreferences.
  Future<T> _getCachedData<T>(
    String key,
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(List<dynamic> jsonList)? fromJsonList,
    Duration cacheDuration,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt('api_cache_time_$key');
      final cachedDataString = prefs.getString('api_cache_$key');

      if (cachedDataString != null && cacheTimestamp != null) {
        if (!_isCacheExpired(cacheTimestamp, cacheDuration)) {
          debugPrint('Cache hit and valid for key: api_cache_$key');
          final decodedData = jsonDecode(cachedDataString);
          if (fromJson != null && decodedData is Map<String, dynamic>) {
            return fromJson(decodedData);
          } else if (fromJsonList != null && decodedData is List<dynamic>) {
            return fromJsonList(decodedData);
          } else if (decodedData is T) {
            return decodedData;
          }
          throw Exception(
              'Cached data type mismatch or parser not provided for key: api_cache_$key');
        } else {
          debugPrint('Cache expired for key: api_cache_$key. Removing.');
          await prefs.remove('api_cache_$key');
          await prefs.remove('api_cache_time_$key');
        }
      }
    } catch (e) {
      debugPrint('Error getting cached data for key api_cache_$key: $e');
    }
    throw Exception('No valid cached data available for key: api_cache_$key');
  }

  /// Check if cache is expired.
  bool _isCacheExpired(int cacheTimestampMillis, Duration cacheValidity) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - cacheTimestampMillis;
    return diff > cacheValidity.inMilliseconds;
  }

  /// Clear all API cache.
  Future<void> clearAllApiCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('api_cache_')) {
          // Check for prefixed keys
          await prefs.remove(key);
        }
      }
      debugPrint('All API cache cleared.');
    } catch (e) {
      debugPrint('Error clearing API cache: $e');
    }
  }

  // --- Specific API Methods (Ensure these match your backend endpoints and response structures) ---

  Future<List<NewsArticle>> getMainStories() async {
    return await _get<List<NewsArticle>>(
      'news/collections/mainstories',
      useCache: true,
      fromJsonList: (list) => list
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<NewsArticle>> getTopStories() async {
    return await _get<List<NewsArticle>>(
      'news/collections/topstories',
      useCache: true,
      fromJsonList: (list) => list
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<NewsArticle>> getMostReadStories() async {
    return await _get<List<NewsArticle>>(
      'news/mostread',
      useCache: true,
      fromJsonList: (list) => list
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<NewsArticle>> getNews({
    String? sectionId,
    int currentPage = 1,
    int pageSize = 10,
    String? nextPageToken,
  }) async {
    String endpoint = sectionId != null ? 'sections/$sectionId/news' : 'news';
    debugPrint("getNews called: sectionId=$sectionId, currentPage=$currentPage, pageSize=$pageSize, nextPageToken=$nextPageToken");
    Map<String, dynamic> queryParams = {
      'currentpage': currentPage
          .toString(), // Ensure query params are strings if API expects
      'pagesize': pageSize.toString(),
    };
    if (nextPageToken != null) {
      queryParams['nextpagetoken'] = nextPageToken;
    }
    final articles = await _get<List<NewsArticle>>(
      endpoint,
      queryParameters: queryParams,
      // Caching for general news list might be short-lived or disabled if it changes very frequently
      // useCache: true, cacheDuration: const Duration(minutes: 10),
      fromJsonList: (list) => list
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    debugPrint('getNews returned ${articles.length} articles');
    return articles;
  }

  Future<NewsArticle> getNewsDetail(String cdate, String id) async {
    return await _get<NewsArticle>(
      'news/$cdate/$id',
      useCache: true,
      cacheDuration: const Duration(hours: 6),
      fromJson: (json) => NewsArticle.fromJson(json),
    );
  }

  Future<List<NewsSection>> getSections() async {
    return await _get<List<NewsSection>>(
      'sections',
      useCache: true,
      cacheDuration: const Duration(days: 1),
      fromJsonList: (list) => list
          .map((item) => NewsSection.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<VideoModel>> getVideos({
    String? nextPageToken,
    int pageSize = 10,
  }) async {
    return await _get<List<VideoModel>>(
      'videos',
      queryParameters: {
        if (nextPageToken != null) 'nextpagetoken': nextPageToken,
        'pagesize': pageSize.toString(),
      },
      fromJsonList: (list) => list
          .map((item) => VideoModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<VideoModel> getVideoDetail(String videoId) async {
    return await _get<VideoModel>(
      'videos/$videoId',
      useCache: true,
      fromJson: (json) => VideoModel.fromJson(json),
    );
  }

  Future<List<ColumnModel>> getSelectedColumns() async {
    return await _get<List<ColumnModel>>(
      'columns/collections/selected',
      useCache: true,
      fromJsonList: (list) => list
          .map((item) => ColumnModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<ColumnModel>> getColumns({
    String? columnistId,
    int currentPage = 1,
    int pageSize = 10,
  }) async {
    String endpoint =
        columnistId != null ? 'columnists/$columnistId/columns' : 'columns';
    return await _get<List<ColumnModel>>(
      endpoint,
      queryParameters: {
        'currentpage': currentPage.toString(),
        'pagesize': pageSize.toString(),
      },
      fromJsonList: (list) => list
          .map((item) => ColumnModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ColumnModel> getColumnDetail(String cdate, String id) async {
    return await _get<ColumnModel>(
      'columns/$cdate/$id',
      useCache: true,
      fromJson: (json) => ColumnModel.fromJson(json),
    );
  }

  Future<AuthorModel> getAuthor(String authorId) async {
    return await _get<AuthorModel>(
      'columnists/$authorId',
      useCache: true, // Author details might not change often
      cacheDuration: const Duration(days: 1),
      fromJson: (json) => AuthorModel.fromJson(json),
    );
  }

  Future<List<ColumnModel>> getAuthorColumns(
    String authorId, {
    int currentPage = 1,
    int pageSize = 10,
  }) async {
    return await _get<List<ColumnModel>>(
      'columnists/$authorId/columns',
      queryParameters: {
        'currentpage': currentPage.toString(),
        'pagesize': pageSize.toString(),
      },
      fromJsonList: (list) => list
          .map((item) => ColumnModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<int> subscribeToNewsletter(String email) async {
    try {
      final result = await _post<dynamic>(
        'subscribers/create',
        queryParameters: {'email': email},
      );
      // Adapt based on actual API response for this endpoint
      if (result is int) {
        return result;
      } else if (result is String) {
        return int.tryParse(result) ?? 10; // Default to general failure (10)
      } else if (result is Map<String, dynamic> &&
          result.containsKey('status_code')) {
        // Example if API returns JSON
        return result['status_code'] as int? ?? 10;
      } else if (result == null) {
        // If _post returns null for 204 or similar success
        return 1; // Assuming 1 is success code from your enum
      }
      return 10;
    } catch (e) {
      debugPrint('Error subscribing to newsletter: $e');
      return 10;
    }
  }

  Future<void> createUser({
    required String token,
    required int os,
    required String deviceType,
    required String deviceModel,
  }) async {
    await _post<void>(
      'users/create',
      queryParameters: {
        'token': token,
        'os': os.toString(),
        'devicetype': deviceType,
        'devicemodel': deviceModel,
      },
    );
  }

  Future<void> announceUser(String token) async {
    await _post<void>(
      'users/announce',
      queryParameters: {'token': token},
    );
  }

  Future<List<NewsArticle>> searchNews(
    String query, {
    int currentPage = 1,
    int pageSize = 10,
  }) async {
    return await _get<List<NewsArticle>>(
      'news/search',
      queryParameters: {
        'q': query,
        'currentpage': currentPage.toString(),
        'pagesize': pageSize.toString(),
      },
      // Search results are dynamic, so disable cache or use very short duration
      // useCache: false,
      fromJsonList: (list) => list
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<NewsArticle>> getRelatedNews(
    String newsId, {
    int pageSize = 6,
  }) async {
    return await _get<List<NewsArticle>>(
      'news/$newsId/related',
      queryParameters: {'pagesize': pageSize.toString()},
      fromJsonList: (list) => list
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> trackNewsView(String newsId) async {
    await _post<void>(
      'analytics/news/view',
      data: {
        'newsId': newsId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> trackVideoView(String videoId) async {
    await _post<void>(
      'analytics/video/view',
      data: {
        'videoId': videoId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> trackColumnView(String columnId) async {
    await _post<void>(
      'analytics/column/view',
      data: {
        'columnId': columnId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<bool> submitContactForm({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      await _post<void>(
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
      debugPrint('Error submitting contact form: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkAppVersion() async {
    try {
      return await _get<Map<String, dynamic>?>(
        'app/version',
        fromJson: (json) => json,
      );
    } catch (e) {
      debugPrint('Error checking app version: $e');
      return null;
    }
  }

  Future<List<String>> getTrendingTopics() async {
    return await _get<List<String>>(
      'trending/topics',
      useCache: true,
      cacheDuration: const Duration(minutes: 30),
      fromJsonList: (list) => list.map((item) => item.toString()).toList(),
    );
  }

  Future<Map<String, dynamic>?> getWeatherInfo() async {
    return await _get<Map<String, dynamic>?>(
      'weather/current',
      useCache: true,
      cacheDuration: const Duration(minutes: 15),
      fromJson: (json) => json,
    );
  }

  Future<List<NewsArticle>> getBreakingNews() async {
    return await _get<List<NewsArticle>>(
      'news/breaking',
      useCache: true,
      cacheDuration:
          const Duration(minutes: 2), // Breaking news needs frequent updates
      fromJsonList: (list) => list
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  void dispose() {
    _dio.close(force: true);
    debugPrint('ApiService disposed and Dio client closed.');
  }
}
