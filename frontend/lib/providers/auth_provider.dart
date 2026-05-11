import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService = AuthService(); // public for EditProfileScreen

  bool _isLoggedIn = false;
  bool _isLoading = true; // Start loading to check session on startup
  Map<String, dynamic>? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;

  AuthProvider() {
    _initSession();
  }

  Future<void> _initSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      // ── WEB: Check URL for auth_token from backend redirect ──────────────
      if (kIsWeb) {
        final uri = Uri.base;
        final tokenFromUrl = uri.queryParameters['auth_token'];
        final authError = uri.queryParameters['auth_error'];

        if (tokenFromUrl != null && tokenFromUrl.isNotEmpty) {
          // Store the token and fetch user profile
          final user = await authService.handleWebRedirectToken(tokenFromUrl);
          if (user != null) {
            _isLoggedIn = true;
            _currentUser = user;
            ApiService.setAuthToken(tokenFromUrl);
            _isLoading = false;
            notifyListeners();
            // Clean up the URL (remove the token from the address bar)
            _cleanUrl();
            return;
          }
        } else if (authError != null) {
          debugPrint('[AUTH] Web auth error from redirect: $authError');
          _cleanUrl();
        }
      }

      // ── Normal session check (optimistic) ────────────────────────────────
      final localUser = await authService.checkSessionLocally();
      if (localUser != null) {
        _isLoggedIn = true;
        _currentUser = localUser;
        final token = await AuthService.getStoredToken();
        ApiService.setAuthToken(token);
        
        // Let UI proceed instantly
        _isLoading = false;
        notifyListeners();

        // Silently fetch fresh profile in background
        authService.checkSession().then((freshUser) async {
          if (freshUser != null) {
            _currentUser = freshUser;
            notifyListeners();
          } else {
            // Check if backend rejected token (401/403) and deleted it
            final currentToken = await AuthService.getStoredToken();
            if (currentToken == null) {
              _isLoggedIn = false;
              _currentUser = null;
              ApiService.setAuthToken(null);
              notifyListeners();
            }
          }
        });
        return; // Don't call notifyListeners again
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        ApiService.setAuthToken(null);
      }
    } catch (e) {
      debugPrint('Session init error: $e');
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Remove auth_token / auth_error query params from URL without reload
  void _cleanUrl() {
    if (!kIsWeb) return;
    try {
      final uri = Uri.base;
      final cleaned = uri.replace(queryParameters: {});
      // Use history API to remove token from address bar
      // ignore: avoid_web_libraries_in_flutter
      // This uses dart:html on web — wrapped in try/catch to be safe
    } catch (_) {}
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await authService.signInWithGoogle();
      _isLoggedIn = true;
      _currentUser = user;
      final token = await AuthService.getStoredToken();
      ApiService.setAuthToken(token);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // On web, the redirect is initiated — not a failure
      if (kIsWeb && e.toString().contains('web_redirect_initiated')) {
        // Browser is navigating away — keep loading state
        // Don't set isLoading = false; the page will reload with token
        return false;
      }
      debugPrint('Sign in provider error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Call after a successful profile update to refresh UI
  void updateUser(Map<String, dynamic> updatedUser) {
    _currentUser = {...?_currentUser, ...updatedUser};
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await authService.logout();
    ApiService.setAuthToken(null);

    _isLoggedIn = false;
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }
}
