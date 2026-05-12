import 'package:flutter_test/flutter_test.dart';
import 'package:creator_os/services/api_service.dart';

void main() {
  group('ApiService Tests', () {
    test('baseUrl returns expected format', () {
      expect(ApiService.baseUrl, isNotEmpty);
      expect(ApiService.baseUrl.startsWith('http'), isTrue);
    });

    test('Insights cache can be cleared', () {
      // Ensure the static method runs without throwing
      expect(() => ApiService.clearInsightsCache(), returnsNormally);
    });
    
    test('authHeaders includes token when set', () {
      ApiService.setAuthToken('test-token');
      expect(ApiService.authHeaders.containsKey('Authorization'), isTrue);
      expect(ApiService.authHeaders['Authorization'], 'Bearer test-token');
      expect(ApiService.authHeaders['Content-Type'], 'application/json');
    });

    test('authHeaders does not include token when cleared', () {
      ApiService.setAuthToken(null);
      expect(ApiService.authHeaders.containsKey('Authorization'), isFalse);
      expect(ApiService.authHeaders['Content-Type'], 'application/json');
    });
  });
}
