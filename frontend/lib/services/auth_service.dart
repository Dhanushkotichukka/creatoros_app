import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static const String _tokenKey = 'creatoros_jwt_token';

  // Mobile-only GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: dotenv.env['GOOGLE_CLIENT_ID'],
  );

  // ── Token Storage (SharedPreferences — works on Web + Mobile) ─────────────

  static Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getStoredToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── JWT Decode ─────────────────────────────────────────────────────────────

  static Map<String, dynamic>? decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      while (payload.length % 4 != 0) payload += '=';
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = utf8.decode(base64.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JWT decode error: $e');
      return null;
    }
  }

  // ── Session Management ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> checkSessionLocally() async {
    try {
      final token = await getStoredToken();
      if (token == null) return null;
      final payload = decodeJwtPayload(token);
      if (payload == null) return null;

      if (payload.containsKey('exp')) {
        final exp = payload['exp'] as int;
        if (exp < DateTime.now().millisecondsSinceEpoch ~/ 1000) {
          await clearToken();
          return null;
        }
      }
      return {
        'id': payload['id'] ?? '',
        'name': payload['name'] ?? '',
        'email': payload['email'] ?? '',
        'profilePicture': payload['picture'] ?? payload['profilePicture'] ?? '',
        'phone': '',
        'bio': '',
        'creatorScore': 0,
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkSession() async {
    try {
      final token = await getStoredToken();
      if (token == null) return null;
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/auth/google-signin/me'),
        headers: headers,
      );
      if (response.statusCode == 200) return jsonDecode(response.body)['user'];
      if (response.statusCode == 401 || response.statusCode == 403) {
        await clearToken();
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> signInWithGoogle() async {
    if (kIsWeb) {
      final oauthUrl = Uri.parse('${ApiService.baseUrl}/auth/google-signin/web');
      await launchUrl(oauthUrl, mode: LaunchMode.platformDefault);
      throw Exception('web_redirect_initiated');
    }

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
      await storeToken(data['token']);
      return data['user'];
    }
    throw Exception('Backend authentication failed: ${response.body}');
  }

  Future<Map<String, dynamic>?> handleWebRedirectToken(String token) async {
    try {
      await storeToken(token);
      final payload = decodeJwtPayload(token);
      if (payload != null) {
        return {
          'id': payload['id'] ?? '',
          'name': payload['name'] ?? '',
          'email': payload['email'] ?? '',
          'profilePicture': payload['profilePicture'] ?? '',
          'phone': '', 'bio': '', 'creatorScore': 0,
        };
      }
    } catch (e) {
      debugPrint('handleWebRedirectToken error: $e');
    }
    return null;
  }

  // ── Email + Password Auth ─────────────────────────────────────────────────

  /// Returns { userId } on success — user must verify OTP next
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/google-signin/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Signup failed.');
  }

  /// Returns { token, user } on success
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/google-signin/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await storeToken(data['token']);
      return data;
    }
    throw Exception(data['error'] ?? 'Sign in failed.');
  }

  /// Returns { token, user } for verify_email or { resetToken } for reset_password
  Future<Map<String, dynamic>> verifyOtp({
    required String userId,
    required String otp,
    String type = 'verify_email',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/google-signin/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'otp': otp, 'type': type}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['token'] != null) await storeToken(data['token']);
      return data;
    }
    throw Exception(data['error'] ?? 'OTP verification failed.');
  }

  Future<void> resendOtp({required String userId, String type = 'verify_email'}) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/google-signin/resend-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'type': type}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to resend OTP.');
    }
  }

  /// Returns { userId } — used to identify which account to reset
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/google-signin/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Failed to send reset email.');
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/google-signin/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'resetToken': resetToken, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Password reset failed.');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      if (!kIsWeb) await _googleSignIn.signOut();
      final headers = await getAuthHeaders();
      await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/google-signin/logout'),
        headers: headers,
      ).catchError((_) => http.Response('{}', 200));
      await clearToken();
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  // ── Profile Update ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateProfile({String? name, String? phone, String? bio}) async {
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
    if (response.statusCode == 200) return jsonDecode(response.body)['user'];
    throw Exception('Failed to update profile: ${response.body}');
  }
}
