import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../config/secrets.dart';
import '../models/captain.dart';

class CaptainProvider with ChangeNotifier {
  final ApiService _apiService;
  final SocketService _socketService;
  Captain? _captain;
  bool _isLoading = false;
  String? _error;
  String? _token;

  CaptainProvider(this._apiService, this._socketService);

  Captain? get captain => _captain;
  bool get isLoading => _isLoading;
  String? get error => _error;
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

  Future<void> validateOtp(String email, String otp) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.validateOtp(email, otp);
      _captain = Captain.fromJson(response['result']['driver']);
      Secrets.authToken = response['result']['token'];
      _error = null;

      // Initialize socket connection
      _socketService.initialize(_captain!.id, 'driver');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<void> _onLoginSuccess(Map<String, dynamic> response) async {
    _captain = Captain.fromJson(response['record']);
    _token = response['token'];
    _apiService.setToken(_token);
    
    // Initialize socket with captain ID
    _socketService.initialize(_captain!.id, 'driver');
    
    notifyListeners();
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

  Future<void> logout() async {
    try {
      await _apiService.logoutCaptain();
      _captain = null;
      _token = null;
      _apiService.setToken(null);
      _socketService.disconnect();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setCaptain(Captain captain) async {
    _captain = captain;
    notifyListeners();
  }

  Future<void> loadCaptain() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getCaptainProfile();
      _captain = Captain.fromJson(response['captain']);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _captain = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCaptain() {
    _captain = null;
    _error = null;
    notifyListeners();
  }
} 