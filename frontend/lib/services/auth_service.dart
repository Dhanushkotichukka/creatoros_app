import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '376637535192-ira5lufv3fe6se6ga4k2d5jjcl3o564h.apps.googleusercontent.com', // Web Client ID for backend validation
  );

  /// Get stored JWT token
  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get headers for protected API calls
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getStoredToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Trigger Google Sign-In and authenticate with backend
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In on device
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In aborted');
      }

      // Get auth details (ID token)
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      // Send ID token to backend
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/google-signin/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = data['user'];

        // Store JWT
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

  /// Clear session and logout
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      
      // Notify backend (optional since JWT is stateless)
      final headers = await getAuthHeaders();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/google-signin/logout'),
        headers: headers,
      ).catchError((_) => null); // Ignore error on logout

      // Clear local JWT
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
        // Token might be expired, clear it
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
