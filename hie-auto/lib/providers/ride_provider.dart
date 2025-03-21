import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/ride_service.dart';

class RideProvider extends ChangeNotifier {
  final GetIt _serviceLocator;
  late final RideService _rideService;

  String? _currentRideId;
  Map<String, dynamic>? _currentRide;
  Map<String, dynamic>? _driverLocation;
  bool _isRequesting = false;
  String? _error;
  List<Map<String, dynamic>> _rideHistory = [];

  RideProvider(this._serviceLocator) {
    _rideService = _serviceLocator<RideService>();
    _setupRideListeners();
  }

  // Getters
  String? get currentRideId => _currentRideId;
  Map<String, dynamic>? get currentRide => _currentRide;
  Map<String, dynamic>? get driverLocation => _driverLocation;
  bool get isRequesting => _isRequesting;
  String? get error => _error;
  List<Map<String, dynamic>> get rideHistory => _rideHistory;
  bool get isRideActive => _rideService.isRideActive;

  void _setupRideListeners() {
    _rideService.initialize();
  }

  Future<Map<String, dynamic>> calculateRidePrice({
    required String pickupCoordinates,
    required String dropoffCoordinates,
  }) async {
    try {
      return await _rideService.calculateRidePrice(
        pickupCoordinates: pickupCoordinates,
        dropoffCoordinates: dropoffCoordinates,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> requestRide({
    required Map<String, double> pickup,
    required Map<String, double> dropoff,
    required double price,
  }) async {
    try {
      _isRequesting = true;
      _error = null;
      notifyListeners();

      final response = await _rideService.requestRide(
        pickup: pickup,
        dropoff: dropoff,
        price: price,
      );

      _currentRideId = response['data']?['rideId'];
      _currentRide = response;

      if (_currentRideId != null) {
        _startLocationTracking();
      }

      _isRequesting = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isRequesting = false;
      notifyListeners();
    }
  }

  void _startLocationTracking() {
    _rideService.startLocationSharing((location) {
      _driverLocation = location;
      notifyListeners();
    });
  }

  void _stopLocationTracking() {
    _rideService.stopLocationSharing();
  }

  Future<void> loadRideHistory() async {
    try {
      _rideHistory = await _rideService.getRideHistory();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopLocationTracking();
    _rideService.dispose();
    super.dispose();
  }
}
