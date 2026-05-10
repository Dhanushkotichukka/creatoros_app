import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';

  // Mobile-only GoogleSignIn (not used on web)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '376637535192-ira5lufv3fe6se6ga4k2d5jjcl3o564h.apps.googleusercontent.com',
  );

  /// Get stored JWT token
  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Store a JWT token (called from web redirect callback handler)
  static Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get headers for protected API calls
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getStoredToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Trigger Google Sign-In
  /// - Web:    Opens backend redirect OAuth URL in same browser tab
  /// - Mobile: Uses google_sign_in popup flow → sends idToken to backend
  Future<Map<String, dynamic>> signInWithGoogle() async {
    if (kIsWeb) {
      // ── WEB: Redirect to backend OAuth flow ─────────────────────────────
      // The backend will redirect back to this app with ?auth_token=JWT
      final oauthUrl = Uri.parse('${ApiService.baseUrl}/auth/google-signin/web');
      await launchUrl(oauthUrl, mode: LaunchMode.platformDefault);
      // Return empty — AuthProvider will handle token from URL on next load
      throw Exception('web_redirect_initiated');
    }

    // ── MOBILE: Traditional idToken flow ────────────────────────────────
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) throw Exception('Google Sign-In aborted');

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      if (idToken == null) throw Exception('Failed to get ID token from Google');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/google-signin/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        return user;
      } else {
        throw Exception('Backend authentication failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Auth Error: $e');
      rethrow;
    }
  }

  /// Decode JWT payload locally (no network needed) to get basic user info
  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      // Pad to valid base64 length
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      // Convert base64url → base64
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = utf8.decode(base64.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JWT decode error: $e');
      return null;
    }
  }

  /// Called after web redirect returns — token is in URL params.
  /// Decodes the JWT locally and returns basic user info immediately.
  Future<Map<String, dynamic>?> handleWebRedirectToken(String token) async {
    try {
      await storeToken(token);
      // Decode JWT payload locally — no network call needed
      final payload = _decodeJwtPayload(token);
      if (payload != null) {
        return {
          'id': payload['id'] ?? '',
          'name': payload['name'] ?? '',
          'email': payload['email'] ?? '',
          'profilePicture': payload['profilePicture'] ?? '',
          'phone': '',
          'bio': '',
          'creatorScore': 0,
        };
      }
    } catch (e) {
      debugPrint('handleWebRedirectToken error: $e');
    }
    return null;
  }

  /// Clear session and logout
  Future<void> logout() async {
    try {
      if (!kIsWeb) await _googleSignIn.signOut();
      final headers = await getAuthHeaders();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/google-signin/logout'),
        headers: headers,
      ).catchError((_) => null);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  /// Fetch user profile from backend using stored token
  Future<Map<String, dynamic>?> checkSession() async {
    try {
      final token = await getStoredToken();
      if (token == null) return null;
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/auth/google-signin/me'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['user'];
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        return null;
      }
    } catch (e) {
      debugPrint('Session check error: $e');
      return null;
    }
  }

  /// Update editable profile fields (name, phone, bio)
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? bio,
  }) async {
    final headers = await getAuthHeaders();
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/auth/google-signin/profile'),
      headers: headers,
      body: jsonEncode({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['user'];
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }
}
