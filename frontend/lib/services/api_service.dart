import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ApiService {
  // Use local IP for mobile device to reach the backend
  static const String baseUrl = 'http://192.168.1.7:3000';
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
      Uri.parse('$baseUrl/api/ai/generate-script'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'topic': topic}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['script'];
    } else {
      throw Exception('Failed to generate script');
    }
  }

  static Future<String> generateHashtags(String topic) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/generate-hashtags'),
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

  static Future<Map<String, dynamic>> getAnalyticsOverview() async {
    final response = await http.get(Uri.parse('$baseUrl/api/analytics/overview'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch analytics');
    }
  }

  static Future<Map<String, dynamic>> getPlatformAnalytics(String platform) async {
    final response = await http.get(Uri.parse('$baseUrl/api/analytics/${platform.toLowerCase()}'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch platform analytics');
    }
  }

  static Future<Map<String, dynamic>> getVideoAnalytics(String videoId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/analytics/video/$videoId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch video analytics');
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

  // --- PLATFORM STATUS & DISCONNECT ---
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
}
