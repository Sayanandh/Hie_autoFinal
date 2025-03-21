import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final GetIt _serviceLocator;
  late final UserService _userService;
  bool _isFirstTime = true;
  bool _isAuthenticated = false;

  AuthProvider(this._serviceLocator) {
    _userService = _serviceLocator<UserService>();
    _initializeAuth();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isFirstTime => _isFirstTime;
  Map<String, dynamic>? get userData => _userService.currentUser;

  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;
      _isFirstTime = !hasSeenIntro;

      // Check if user is already logged in
      _isAuthenticated = await _userService.isAuthenticated();
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _userService.login(
        email: email,
        password: password,
      );
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    }
  }

  Future<void> signup(
      String email, String firstName, String lastName, String password) async {
    try {
      await _userService.register(
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> validateOtp(String email, String otp) async {
    try {
      await _userService.validateOtp(
        email: email,
        otp: otp,
      );
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _userService.logout();
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    try {
      await _userService.refreshProfile();
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    }
  }

  Future<void> markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro', true);
    _isFirstTime = false;
    notifyListeners();
  }
}
