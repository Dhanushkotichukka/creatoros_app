import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/multi_post/post_model.dart';

class ApiService {
  // Use deployed Render URL for all platforms
  static String get baseUrl {
    // In debug mode, use local backend; in release, use deployed Render backend
    if (kDebugMode) {
      return 'http://localhost:3000';
    }
    return 'https://creatoros-backend-rb5b.onrender.com';
  }
  static bool hasConnected = false;

  // ── Auth Token Management ─────────────────────────────────────────────────
  static String? _authToken;

  /// Called by AuthProvider after login/session restore
  static void setAuthToken(String? token) => _authToken = token;

  /// Auth + JSON headers for POST requests to protected routes
  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// Auth-only headers for GET requests to protected routes (no body)
  static Map<String, String> get getAuthHeaders => {
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ── Platform OAuth (Public — no auth needed) ─────────────────────────────

  static Future<void> loginWithYouTube() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/youtube/login'), headers: getAuthHeaders);
    if (response.statusCode == 200) {
      final url = Uri.parse(jsonDecode(response.body)['url']);
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        hasConnected = true;
      }
    } else {
      throw Exception('Could not get YouTube login URL');
    }
  }

  static Future<void> loginWithMeta() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/meta/login'), headers: getAuthHeaders);
    if (response.statusCode == 200) {
      final url = Uri.parse(jsonDecode(response.body)['url']);
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        hasConnected = true;
      }
    } else {
      throw Exception('Could not get Meta login URL');
    }
  }

  static Future<void> loginWithLinkedIn() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/linkedin/login'), headers: getAuthHeaders);
    if (response.statusCode == 200) {
      final url = Uri.parse(jsonDecode(response.body)['url']);
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        hasConnected = true;
      }
    } else {
      throw Exception('Could not get LinkedIn login URL');
    }
  }

  // ── AI Routes (Protected) ─────────────────────────────────────────────────

  static Future<String> generateScript(String topic) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/script'),
      headers: authHeaders,
      body: jsonEncode({'topic': topic}),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? json['script'] ?? 'Success';
    } else {
      throw Exception('Failed to generate script');
    }
  }

  static Future<String> generateAIChat(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/chat'),
      headers: authHeaders,
      body: jsonEncode({'message': message, 'context': ''}),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? 'Success';
    } else {
      throw Exception('Failed to get AI chat response');
    }
  }

  static Future<String> generateHashtags(String topic) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/metadata'),
      headers: authHeaders,
      body: jsonEncode({'topic': topic}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['hashtags'];
    } else {
      throw Exception('Failed to generate hashtags');
    }
  }

  static Future<List<dynamic>> getTrendingTopics(String category) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/my-ai/trends'),
      headers: authHeaders,
      body: jsonEncode({'category': category}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['topics'];
    } else {
      throw Exception('Failed to fetch trending topics');
    }
  }

  static Future<List<dynamic>> generateMasterScripts(String niche, String targetAudience) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/master-ai/generate-batch'),
      headers: authHeaders,
      body: jsonEncode({'niche': niche, 'targetAudience': targetAudience}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['scripts'];
    } else {
      throw Exception('Failed to generate master scripts');
    }
  }

  // ── Analytics Routes (Protected) ─────────────────────────────────────────

  static Future<Map<String, dynamic>> getAnalyticsOverview({bool forceRefresh = false}) async {
    final uri = Uri.parse('$baseUrl/api/analytics/overview')
        .replace(queryParameters: forceRefresh ? {'refresh': '1'} : null);
    final response = await http.get(uri, headers: getAuthHeaders);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch analytics');
    }
  }

  static Future<Map<String, dynamic>> getPlatformAnalytics(String platform, {bool forceRefresh = false}) async {
    final uri = Uri.parse('$baseUrl/api/analytics/${platform.toLowerCase()}')
        .replace(queryParameters: forceRefresh ? {'refresh': '1'} : null);
    final response = await http.get(uri, headers: getAuthHeaders);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch platform analytics');
    }
  }

  // ── AI Insights — client-side 5-min cache ────────────────────────────────
  static final Map<String, Map<String, dynamic>> _insightsCacheMap = {};
  static final Map<String, DateTime> _insightsCacheTsMap = {};
  static const Duration _insightsCacheTtl = Duration(minutes: 5);

  static Future<Map<String, dynamic>> getAIInsights({String? platform, bool forceRefresh = false}) async {
    final String cacheKey = platform ?? 'overview';
    if (!forceRefresh && _insightsCacheMap.containsKey(cacheKey) && _insightsCacheTsMap.containsKey(cacheKey)) {
      if (DateTime.now().difference(_insightsCacheTsMap[cacheKey]!) < _insightsCacheTtl) {
        return _insightsCacheMap[cacheKey]!;
      }
    }

    final uri = Uri.parse('$baseUrl/api/analytics/insights').replace(
      queryParameters: platform != null && platform.toLowerCase() != 'overview'
          ? {'platform': platform}
          : null,
    );

    final response = await http.post(uri, headers: authHeaders);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _insightsCacheMap[cacheKey] = data;
      _insightsCacheTsMap[cacheKey] = DateTime.now();
      return data;
    } else {
      throw Exception('Failed to fetch AI insights (${response.statusCode})');
    }
  }

  static void clearInsightsCache() {
    _insightsCacheMap.clear();
    _insightsCacheTsMap.clear();
  }

  static Future<void> clearAnalyticsCache() async {
    try {
      await http.post(Uri.parse('$baseUrl/api/analytics/cache/clear'), headers: authHeaders);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getVideoAnalytics(String videoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/analytics/video/$videoId'),
      headers: getAuthHeaders,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch video analytics');
    }
  }

  static Future<Map<String, dynamic>> getVideoComments(String videoId, {String? pageToken}) async {
    String url = '$baseUrl/api/analytics/video/$videoId/comments';
    if (pageToken != null) url += '?pageToken=$pageToken';
    final response = await http.get(Uri.parse(url), headers: getAuthHeaders);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch video comments');
    }
  }

  static Future<bool> postVideoReply(String videoId, String commentId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/analytics/video/$videoId/reply'),
      headers: authHeaders,
      body: jsonEncode({'commentId': commentId, 'text': text}),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to post reply');
    }
  }

  // ── Media Routes (Protected) ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> searchMedia(
    String query, {
    String type = 'image',
    int page = 1,
    int perPage = 15,
  }) async {
    final uri = Uri.parse('$baseUrl/api/media/search').replace(queryParameters: {
      'q': query, 'type': type,
      'page': page.toString(), 'perPage': perPage.toString(),
    });
    final response = await http.get(uri, headers: getAuthHeaders);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search media (${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> importMediaFromUrl({
    required String url,
    required String fileName,
    String destination = 'local',
    String mimeType = 'image/jpeg',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/media/import-from-url'),
      headers: authHeaders,
      body: jsonEncode({'url': url, 'fileName': fileName, 'destination': destination, 'mimeType': mimeType}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit reached. Please wait a moment and try again.');
    } else if (response.statusCode == 403) {
      throw Exception('Access denied by media provider. Try a different image.');
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Import failed (${response.statusCode})');
    }
  }

  static Future<List<dynamic>> getStorageFiles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/media/list'),
      headers: getAuthHeaders,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['items'];
    } else {
      throw Exception('Failed to fetch storage files');
    }
  }

  static Future<Map<String, dynamic>> uploadFile(List<int> bytes, String fileName) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/media/upload'));
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upload file');
    }
  }

  static Future<void> deleteStorageFile(String fileName, String storage) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/media/delete'),
      headers: authHeaders,
      body: jsonEncode({'fileName': fileName, 'storage': storage}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete file: ${response.body}');
    }
  }

  static Future<String> getStorageDownloadUrl(String fileName, String storage) async {
    final uri = Uri.parse('$baseUrl/api/media/download-url')
        .replace(queryParameters: {'fileName': fileName, 'storage': storage});
    final response = await http.get(uri, headers: getAuthHeaders);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['url'];
    } else {
      throw Exception('Failed to get download URL');
    }
  }

  // ── Platform Status (Protected) ───────────────────────────────────────────

  static Future<List<dynamic>> getPlatformStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/analytics/platforms/status'),
      headers: getAuthHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      List<dynamic> platforms = [];
      data.forEach((key, val) {
        String brandedName;
        switch (key.toLowerCase()) {
          case 'youtube': brandedName = 'YouTube'; break;
          case 'instagram': brandedName = 'Instagram'; break;
          case 'linkedin': brandedName = 'LinkedIn'; break;
          default: brandedName = key[0].toUpperCase() + key.substring(1);
        }
        platforms.add({
          'name': brandedName,
          'isConnected': val['connected'] ?? false,
          'channelName': val['name'],
          'channelAvatar': val['avatar'],
        });
      });
      return platforms;
    } else {
      throw Exception('Failed to fetch platform status');
    }
  }

  static Future<Map<String, dynamic>> getPlatformStatuses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/analytics/platforms/status'),
      headers: getAuthHeaders,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch platform statuses');
    }
  }

  static Future<void> disconnectPlatform(String platform) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/${platform.toLowerCase()}/disconnect'),
      headers: authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to disconnect $platform');
    }
  }

  // ── Publish (Protected) ───────────────────────────────────────────────────

  static Future<bool> publishPost(PostModel post) async {
    try {
      Map<String, dynamic> platformJson = {};
      post.platformData.forEach((key, value) {
        platformJson[key.name] = {
          'title': value.title, 'description': value.description,
          'hashtags': value.hashtags, 'contentType': value.contentType,
          'privacyStatus': value.privacyStatus, 'madeForKids': value.madeForKids,
        };
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/publish'),
        headers: authHeaders,
        body: jsonEncode({
          'title': post.title,
          'scheduledTime': post.scheduledTime?.toIso8601String() ?? '',
          'platformData': jsonEncode(platformJson),
          'mediaUrls': post.mediaPaths,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error publishing post: $e');
      return false;
    }
  }
}
