import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/multi_post/post_model.dart';

class ApiService {
  // Use local IP for mobile device, and 127.0.0.1 for web to avoid IPv6 resolution issues on Windows Chrome
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000'; // Android Emulator loopback
    return 'http://192.168.1.7:3000'; // iOS Simulator or physical device
  }
  static bool hasConnected = false; // Mock local persistent state for demo UX

  static Future<void> loginWithYouTube() async {
    final url = Uri.parse('$baseUrl/auth/youtube/login');
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      hasConnected = true;
    } else {
      throw Exception('Could not launch browser for YouTube login');
    }
  }

  static Future<void> loginWithMeta() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/meta/login'));
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
    final response = await http.get(Uri.parse('$baseUrl/auth/linkedin/login'));
    if (response.statusCode == 200) {
      final url = Uri.parse(jsonDecode(response.body)['url']);
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        hasConnected = true;
      }
    } else {
      throw Exception('Could not get LinkedIn login URL');
    }
  }

  static Future<String> generateScript(String topic) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/script'),
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'niche': niche,
        'targetAudience': targetAudience,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['scripts'];
    } else {
      throw Exception('Failed to generate master scripts');
    }
  }

  static Future<Map<String, dynamic>> getAnalyticsOverview({bool forceRefresh = false}) async {
    final uri = Uri.parse('$baseUrl/api/analytics/overview')
        .replace(queryParameters: forceRefresh ? {'refresh': '1'} : null);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch analytics');
    }
  }

  static Future<Map<String, dynamic>> getPlatformAnalytics(String platform, {bool forceRefresh = false}) async {
    final uri = Uri.parse('$baseUrl/api/analytics/${platform.toLowerCase()}')
        .replace(queryParameters: forceRefresh ? {'refresh': '1'} : null);
    final response = await http.get(uri);

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

  /// Fetch AI insights. Uses a local in-memory cache (5 min TTL) to avoid
  /// repeated Groq calls on every rebuild or hot-reload.
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
    
    final response = await http.post(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _insightsCacheMap[cacheKey] = data;
      _insightsCacheTsMap[cacheKey] = DateTime.now();
      return data;
    } else {
      throw Exception('Failed to fetch AI insights (${response.statusCode})');
    }
  }

  /// Clear the client-side insights cache (call after connecting a new platform).
  static void clearInsightsCache() {
    _insightsCacheMap.clear();
    _insightsCacheTsMap.clear();
  }


  /// Call this after connecting or disconnecting a platform so fresh data loads.
  static Future<void> clearAnalyticsCache() async {
    try {
      await http.post(Uri.parse('$baseUrl/api/analytics/cache/clear'));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getVideoAnalytics(String videoId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/analytics/video/$videoId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch video analytics');
    }
  }

  static Future<Map<String, dynamic>> getVideoComments(String videoId, {String? pageToken}) async {
    String url = '$baseUrl/api/analytics/video/$videoId/comments';
    if (pageToken != null) url += '?pageToken=$pageToken';
    
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch video comments');
    }
  }

  static Future<bool> postVideoReply(String videoId, String commentId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/analytics/video/$videoId/reply'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'commentId': commentId, 'text': text}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to post reply');
    }
  }

  // --- SMART MEDIA SEARCH ---
  static Future<Map<String, dynamic>> searchMedia(
    String query, {
    String type = 'image',
    int page = 1,
    int perPage = 15,
  }) async {
    final uri = Uri.parse('$baseUrl/api/media/search').replace(queryParameters: {
      'q': query,
      'type': type,
      'page': page.toString(),
      'perPage': perPage.toString(),
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search media (${response.statusCode})');
    }
  }

  /// Import a stock media URL into CreatorOS storage.
  /// [destination] is 'local' or 's3'.
  static Future<Map<String, dynamic>> importMediaFromUrl({
    required String url,
    required String fileName,
    String destination = 'local',
    String mimeType = 'image/jpeg',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/media/import-from-url'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'url': url,
        'fileName': fileName,
        'destination': destination,
        'mimeType': mimeType,
      }),
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

  // --- STORAGE & MEDIA ---
  static Future<List<dynamic>> getStorageFiles() async {
    final response = await http.get(Uri.parse('$baseUrl/api/media/list'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['items'];
    } else {
      throw Exception('Failed to fetch storage files');
    }
  }

  static Future<Map<String, dynamic>> uploadFile(List<int> bytes, String fileName) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/media/upload'));
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fileName': fileName, 'storage': storage}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete file: ${response.body}');
    }
  }

  static Future<String> getStorageDownloadUrl(String fileName, String storage) async {
    final uri = Uri.parse('$baseUrl/api/media/download-url')
        .replace(queryParameters: {'fileName': fileName, 'storage': storage});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['url'];
    } else {
      throw Exception('Failed to get download URL');
    }
  }


  // --- PLATFORM STATUS & DISCONNECT ---
  static Future<List<dynamic>> getPlatformStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/api/analytics/platforms/status'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Convert map to list for UI chips
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

  // Helper for components expecting a Map structure
  static Future<Map<String, dynamic>> getPlatformStatuses() async {
    final response = await http.get(Uri.parse('$baseUrl/api/analytics/platforms/status'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch platform statuses');
    }
  }

  static Future<void> disconnectPlatform(String platform) async {
    final response = await http.post(Uri.parse('$baseUrl/auth/${platform.toLowerCase()}/disconnect'));
    if (response.statusCode != 200) {
      throw Exception('Failed to disconnect $platform');
    }
  }

  static Future<bool> publishPost(PostModel post) async {
    try {
      // Build platform data as JSON string
      Map<String, dynamic> platformJson = {};
      post.platformData.forEach((key, value) {
        platformJson[key.name] = {
          'title': value.title,
          'description': value.description,
          'hashtags': value.hashtags,
          'contentType': value.contentType,
          'privacyStatus': value.privacyStatus,
          'madeForKids': value.madeForKids,
        };
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/publish'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': post.title,
          'scheduledTime': post.scheduledTime?.toIso8601String() ?? '',
          'platformData': jsonEncode(platformJson),
          'mediaUrls': post.mediaPaths, // Passing S3 URLs now
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error publishing post: $e');
      return false;
    }
  }
}

