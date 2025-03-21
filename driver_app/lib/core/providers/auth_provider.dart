import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../services/api_service.dart';
import '../models/captain.dart';
import '../config/secrets.dart';
import '../services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final SocketService _socketService;
  bool _isLoading = false;
  String? _error;
  Captain? _captain;
  String? _token;
  final _logger = Logger('AuthProvider');

  AuthProvider(this._apiService, this._socketService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  Captain? get captain => _captain;
  bool get isAuthenticated => _captain != null;

  Future<void> register(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.registerCaptain(data);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _onLoginSuccess(Map<String, dynamic> response) async {
    _captain = Captain.fromJson(response['captain']);
    _token = response['token'];
    _apiService.setToken(_token);
    
    // Initialize socket with captain ID
    _socketService.initialize(_captain!.id, 'driver');
    
    notifyListeners();
  }

  Future<void> validateOtp(String email, String otp) async {
    try {
      _logger.info('=== Starting OTP validation ===');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.validateOtp(email, otp);
      _logger.info('OTP validation response received');
      _logger.info('Response structure: ${response.keys}');

      Map<String, dynamic>? result;

      // Check if response has 'result' key
      if (response.containsKey('result')) {
        if (response['result'] is Map<String, dynamic>) {
          result = response['result'] as Map<String, dynamic>;
          _logger.info('Result structure: ${result.keys}');
        } else {
          throw 'Invalid response format';
        }
      } 
      // If not, check if response directly contains 'driver' and 'token'
      else if (response.containsKey('driver') && response.containsKey('token')) {
        result = response;
        _logger.info('Response used directly as result.');
      } else {
        throw 'Invalid response format';
      }

      if (result!.containsKey('token') && result.containsKey('driver')) {
        _token = result['token'];
        _apiService.setToken(_token);
        _captain = Captain.fromJson(result['driver']);
        _error = null;

        _logger.info('Token set and captain parsed');
        _logger.info('Captain ID: ${_captain?.id}');
        _logger.info('Is authenticated: $isAuthenticated');

        // Initialize socket connection after successful OTP verification
        _socketService.initialize(_captain!.id, 'driver');
        _logger.info('Socket connection initialized');
      } else {
        throw 'Invalid response structure';
      }
    } catch (e) {
      _logger.severe('Error during OTP validation: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
      _logger.info('=== OTP validation completed. Error: $_error');
    }
  }

  Future<void> verifyOTP(String email, String otp) => validateOtp(email, otp);

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.loginCaptain(email, password);
      await _onLoginSuccess(response);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getCaptainProfile();
      _captain = Captain.fromJson(response['captain']);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkAuth() async {
    if (Secrets.authToken != null) {
      await loadProfile();
      return isAuthenticated;
    }
    return false;
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.logoutCaptain();
      _token = null;
      _apiService.setToken(null);
      _captain = null;
      _socketService.disconnect();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 