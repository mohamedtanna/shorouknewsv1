import 'package:flutter_test/flutter_test.dart';
import 'package:shorouk_news/services/api_service.dart';

void main() {
  group('ApiService.generateCacheKeyForTest', () {
    test('parameter order does not affect generated key', () {
      final service = ApiService();
      const endpoint = 'sample/endpoint';
      final params1 = {'a': '1', 'b': '2', 'c': '3'};
      final params2 = {'c': '3', 'a': '1', 'b': '2'};

      final key1 = service.generateCacheKeyForTest(endpoint, params1);
      final key2 = service.generateCacheKeyForTest(endpoint, params2);

      expect(key1, equals(key2));
    });
  });
}
