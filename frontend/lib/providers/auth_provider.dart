import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService = AuthService();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initSession();
  }

  void _clearError() => _errorMessage = null;

  Future<void> _initSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      // WEB: Check URL for auth_token from backend redirect
      if (kIsWeb) {
        final uri = Uri.base;
        final tokenFromUrl = uri.queryParameters['auth_token'];
        final authError = uri.queryParameters['auth_error'];

        if (tokenFromUrl != null && tokenFromUrl.isNotEmpty) {
          final user = await authService.handleWebRedirectToken(tokenFromUrl);
          if (user != null) {
            _isLoggedIn = true;
            _currentUser = user;
            ApiService.setAuthToken(tokenFromUrl);
            _isLoading = false;
            notifyListeners();
            return;
          }
        } else if (authError != null) {
          debugPrint('[AUTH] Web auth error from redirect: $authError');
        }
      }

      // Normal optimistic session check
      final localUser = await authService.checkSessionLocally();
      if (localUser != null) {
        _isLoggedIn = true;
        _currentUser = localUser;
        final token = await AuthService.getStoredToken();
        ApiService.setAuthToken(token);
        _isLoading = false;
        notifyListeners();

        // Silently refresh profile in background
        authService.checkSession().then((freshUser) async {
          if (freshUser != null) {
            _currentUser = freshUser;
            notifyListeners();
          } else {
            final currentToken = await AuthService.getStoredToken();
            if (currentToken == null) {
              _isLoggedIn = false;
              _currentUser = null;
              ApiService.setAuthToken(null);
              notifyListeners();
            }
          }
        });
        return;
      }

      _isLoggedIn = false;
      _currentUser = null;
      ApiService.setAuthToken(null);
    } catch (e) {
      debugPrint('Session init error: $e');
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    _clearError();
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
      if (kIsWeb && e.toString().contains('web_redirect_initiated')) {
        return false;
      }
      _errorMessage = 'Google sign-in failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Email Sign-Up ──────────────────────────────────────────────────────────

  /// Returns userId string on success (user must verify OTP next)
  Future<String?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final result = await authService.signUp(name: name, email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return result['userId'] as String?;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ── Email Sign-In ──────────────────────────────────────────────────────────

  /// Returns null on success (user is logged in), or userId if email not verified
  Future<Map<String, dynamic>?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final result = await authService.signInWithEmail(email: email, password: password);
      _isLoggedIn = true;
      _currentUser = result['user'];
      final token = await AuthService.getStoredToken();
      ApiService.setAuthToken(token);
      _isLoading = false;
      notifyListeners();
      return null; // success
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ── OTP Verification ───────────────────────────────────────────────────────

  Future<bool> verifyOtp({
    required String userId,
    required String otp,
    String type = 'verify_email',
  }) async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final result = await authService.verifyOtp(userId: userId, otp: otp, type: type);
      if (result['token'] != null) {
        // Email verified — log user in
        _isLoggedIn = true;
        _currentUser = result['user'];
        final token = await AuthService.getStoredToken();
        ApiService.setAuthToken(token);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp({required String userId, String type = 'verify_email'}) async {
    try {
      await authService.resendOtp(userId: userId, type: type);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Forgot / Reset Password ────────────────────────────────────────────────

  Future<String?> forgotPassword(String email) async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      final result = await authService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return result['userId'] as String?;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> resetPassword({required String resetToken, required String newPassword}) async {
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      await authService.resetPassword(resetToken: resetToken, newPassword: newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  void updateUser(Map<String, dynamic> updatedUser) {
    _currentUser = {...?_currentUser, ...updatedUser};
    notifyListeners();
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

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
