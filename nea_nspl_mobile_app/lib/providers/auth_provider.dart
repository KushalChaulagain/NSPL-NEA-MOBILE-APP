import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String _errorMessage = '';
  bool _rememberMe = false;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;

  // Initialize
  Future<void> initialize() async {
    _status = AuthStatus.initial;
    notifyListeners();

    // Check if token is valid
    final isValid = await _authService.isTokenValid();

    if (isValid) {
      // Get current user data
      _user = await _authService.getCurrentUser();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    // Get remember me preference
    final savedUsername = await _authService.getSavedUsername();
    _rememberMe = savedUsername != null;

    notifyListeners();
  }

  // Login
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    final ApiResponse<User> response =
        await _authService.login(username, password);

    if (response.success && response.data != null) {
      _user = response.data;
      _status = AuthStatus.authenticated;

      // Save remember me preference
      if (_rememberMe) {
        await _authService.saveRememberMe(true, username);
      }

      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.error;
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<bool> logout() async {
    _status = AuthStatus.initial;
    notifyListeners();

    final success = await _authService.logout();

    if (success) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    } else {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to logout';
    }

    notifyListeners();
    return success;
  }

  // Set remember me
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  // Get saved username
  Future<String?> getSavedUsername() async {
    return await _authService.getSavedUsername();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _status == AuthStatus.authenticated && _user != null;
  }
}
