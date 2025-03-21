import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logging/logging.dart';

class LocationProvider with ChangeNotifier {
  final _logger = Logger('LocationProvider');
  final ApiService _apiService;
  Position? _currentPosition;
  StreamSubscription<Position>? _locationSubscription;
  bool _isLoading = false;
  String? _error;
  List<String> _suggestions = [];
  Map<String, dynamic>? _distanceTime;
  Map<String, dynamic>? _coordinates;

  LocationProvider(this._apiService);

  Position? get currentPosition => _currentPosition;
  String? get error => _error;
  bool get isLoading => _isLoading;
  List<String> get suggestions => _suggestions;
  Map<String, dynamic>? get distanceTime => _distanceTime;
  Map<String, dynamic>? get coordinates => _coordinates;

  Future<void> initializeLocation() async {
    try {
      _isLoading = true;
      notifyListeners();

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      // Start location updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(_handleLocationUpdate);

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _logger.severe('Location service initialization failed: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleLocationUpdate(Position position) {
    _currentPosition = position;
    notifyListeners();
  }

  LatLng? getCurrentLatLng() {
    if (_currentPosition == null) return null;
    return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
  }

  Future<void> getLocationSuggestions(String query) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _suggestions = await _apiService.getLocationSuggestions(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCoordinates(String address) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getCoordinates(address);
      _coordinates = response;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getDistanceTime(String origin, String destination) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getDistanceTime(origin, destination);
      _distanceTime = response;
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

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
