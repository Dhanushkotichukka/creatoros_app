import 'package:flutter/foundation.dart';
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
      final user = await authService.checkSession();
      if (user != null) {
        _isLoggedIn = true;
        _currentUser = user;
        final token = await AuthService.getStoredToken();
        ApiService.setAuthToken(token);
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
