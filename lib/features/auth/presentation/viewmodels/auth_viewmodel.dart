import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<UserModel?>? _authStateSubscription;

  AuthViewModel(this._authRepository) {
    _user = _authRepository.currentUser;
    _subscribeToAuthState();
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  // ─── Session Persistence via Auth Stream ─────────────────────────────────

  void _subscribeToAuthState() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (userModel) {
        _user = userModel;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('AuthViewModel: authStateChanges error — $e');
      },
    );
  }

  // ─── UI Helpers ──────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Auth Actions ─────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.loginWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.signUpWithEmail(email, password, displayName);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.logout();
      _user = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    final freshUser = await _authRepository.refreshUser();
    if (freshUser != null) {
      _user = freshUser;
      notifyListeners();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _friendlyError(String raw) {
    final msg = raw
        .replaceAll('Exception: ', '')
        .replaceAll('[firebase_auth/wrong-password]', '')
        .replaceAll('[firebase_auth/user-not-found]', '')
        .replaceAll('[firebase_auth/email-already-in-use]', '');
    if (raw.contains('wrong-password') || raw.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('user-not-found')) {
      return 'No account found with this email. Please sign up.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    }
    return msg.isNotEmpty ? msg : 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
