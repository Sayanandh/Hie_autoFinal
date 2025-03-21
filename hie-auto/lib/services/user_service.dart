import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'dart:convert';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final Logger _logger = Logger();
  Map<String, dynamic>? _currentUser;

  // Getters
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Initialize user service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final userDataString = prefs.getString('user_data');

      if (isLoggedIn && userDataString != null) {
        _currentUser = Map<String, dynamic>.from(jsonDecode(userDataString));
        _logger.i('User data restored from storage: ${_currentUser?['email']}');
      }
    } catch (e) {
      _logger.e('Error initializing user service: $e');
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      final response = await ApiService.registerUser(
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
      );

      _logger.i('User registered successfully: $email');
      return response;
    } catch (e) {
      _logger.e('Registration error: $e');
      rethrow;
    }
  }

  // Validate OTP
  Future<Map<String, dynamic>> validateOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await ApiService.validateOtp(email, otp);

      if (response['token'] != null) {
        await _loadUserProfile();
      }

      return response;
    } catch (e) {
      _logger.e('OTP validation error: $e');
      rethrow;
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.loginUser(
        email: email,
        password: password,
      );

      if (response['token'] != null) {
        await _loadUserProfile();
      }

      return response;
    } catch (e) {
      _logger.e('Login error: $e');
      rethrow;
    }
  }

  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      final response = await ApiService.getUserProfile();
      _currentUser = response['user'];

      // Store user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_currentUser));
      await prefs.setBool('isLoggedIn', true);

      _logger.i('User profile loaded: ${_currentUser?['email']}');
    } catch (e) {
      _logger.e('Error loading user profile: $e');
      await logout();
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await ApiService.logoutUser();
      _currentUser = null;

      // Clear all stored data
      await ApiService.clearUserData();

      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Logout error: $e');
      rethrow;
    }
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      return await ApiService.isLoggedIn();
    } catch (e) {
      _logger.e('Error checking authentication: $e');
      return false;
    }
  }
}
