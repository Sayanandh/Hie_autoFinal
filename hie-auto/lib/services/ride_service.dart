import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../api_service.dart';
import 'socket_service.dart';
import 'package:geolocator/geolocator.dart';
import 'user_service.dart';

class RideService {
  static final RideService _instance = RideService._internal();
  factory RideService() => _instance;
  RideService._internal();

  final Logger _logger = Logger();
  final SocketService _socketService = SocketService();
  final UserService _userService = UserService();
  String? _currentRideId;
  Timer? _locationUpdateTimer;
  bool _isRideActive = false;

  // Getters
  bool get isRideActive => _isRideActive;
  String? get currentRideId => _currentRideId;

  // Initialize ride service
  Future<void> initialize() async {
    try {
      _setupSocketListeners();
    } catch (e) {
      _logger.e('Error initializing ride service: $e');
      rethrow;
    }
  }

  // Setup socket listeners for ride events
  void _setupSocketListeners() {
    if (!_socketService.isInitialized) return;

    _socketService.onRideAccepted = _handleRideAccepted;
    _socketService.onOTPGenerated = _handleOtpReceived;
    _socketService.onRideNotFound = _handleRideNotFound;
    _socketService.onRideError = _handleRideError;
  }

  // Initialize socket listeners after user login
  Future<void> initializeSocketListeners() async {
    if (_socketService.isInitialized) {
      _setupSocketListeners();
    }
  }

  // Calculate ride price
  Future<Map<String, dynamic>> calculateRidePrice({
    required String pickupCoordinates,
    required String dropoffCoordinates,
  }) async {
    try {
      return await ApiService.getRidePrice(
        pickup: pickupCoordinates,
        dropoff: dropoffCoordinates,
      );
    } catch (e) {
      _logger.e('Error calculating ride price: $e');
      rethrow;
    }
  }

  // Request a ride
  Future<Map<String, dynamic>> requestRide({
    required Map<String, double> pickup,
    required Map<String, double> dropoff,
    required double price,
  }) async {
    try {
      final response = await ApiService.requestRide(
        pickup: pickup,
        dropoff: dropoff,
        price: price,
      );

      if (response['success'] == true && response['data']?['rideId'] != null) {
        _currentRideId = response['data']['rideId'];
        _isRideActive = true;
      }

      return response;
    } catch (e) {
      _logger.e('Error requesting ride: $e');
      rethrow;
    }
  }

  // Start location sharing
  void startLocationSharing(
      Function(Map<String, dynamic>) onCaptainLocationUpdate) {
    if (_currentRideId == null) {
      _logger.w('No active ride to start location sharing');
      return;
    }

    // Listen for captain's location updates
    _socketService.onCaptainLocation = onCaptainLocationUpdate;

    // Start sending user's location updates
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        final userLocation = {
          'lat': position.latitude,
          'lng': position.longitude,
        };
        _socketService.emitLocationUpdate(userLocation);
      } catch (e) {
        _logger.e('Error getting user location: $e');
      }
    });
  }

  // Stop location sharing
  void stopLocationSharing() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  // Handle ride accepted event
  void _handleRideAccepted(Map<String, dynamic> data) {
    _logger.i('Ride accepted: $data');
    // Implement your ride accepted logic here
  }

  // Handle OTP received event
  void _handleOtpReceived(Map<String, dynamic> data) {
    _logger.i('OTP received: $data');
    // Implement your OTP handling logic here
  }

  // Handle ride not found event
  void _handleRideNotFound(Map<String, dynamic> data) {
    _logger.w('Ride not found: $data');
    _currentRideId = null;
    _isRideActive = false;
    stopLocationSharing();
    // Implement your ride not found logic here
  }

  // Handle ride error event
  void _handleRideError(Map<String, dynamic> data) {
    _logger.e('Ride error: $data');
    // Implement your error handling logic here
  }

  // Get ride history
  Future<List<Map<String, dynamic>>> getRideHistory() async {
    try {
      final response = await ApiService.getUserRideHistory();
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      _logger.e('Error fetching ride history: $e');
      rethrow;
    }
  }

  // Verify ride OTP
  Future<Map<String, dynamic>> verifyRideOtp({
    required String otp,
    required Map<String, double> location,
  }) async {
    if (_currentRideId == null) {
      throw Exception('No active ride to verify OTP');
    }

    try {
      return await ApiService.verifyRideOtp(
        rideId: _currentRideId!,
        otp: otp,
        location: location,
      );
    } catch (e) {
      _logger.e('Error verifying ride OTP: $e');
      rethrow;
    }
  }

  // Complete ride
  Future<Map<String, dynamic>> completeRide({
    required Map<String, double> location,
  }) async {
    if (_currentRideId == null) {
      throw Exception('No active ride to complete');
    }

    try {
      final response = await ApiService.completeRide(
        rideId: _currentRideId!,
        status: 'completed',
        location: location,
      );

      _currentRideId = null;
      _isRideActive = false;
      stopLocationSharing();

      return response;
    } catch (e) {
      _logger.e('Error completing ride: $e');
      rethrow;
    }
  }

  // Cancel ride
  Future<void> cancelRide() async {
    if (_currentRideId == null) {
      throw Exception('No active ride to cancel');
    }

    try {
      await ApiService.cancelRide(rideId: _currentRideId!);
      _currentRideId = null;
      _isRideActive = false;
      stopLocationSharing();
      _logger.i('Ride cancelled successfully');
    } catch (e) {
      _logger.e('Error cancelling ride: $e');
      rethrow;
    }
  }

  // Clean up resources
  void dispose() {
    stopLocationSharing();
    _socketService.dispose();
    _currentRideId = null;
    _isRideActive = false;
  }

  Future<Map<String, dynamic>> getRideStatus(String rideId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://helloauto-zwjd.onrender.com/api/rides/$rideId/status'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Ride status retrieved: $data');
        return data;
      } else {
        throw Exception('Failed to get ride status: ${response.body}');
      }
    } catch (e) {
      _logger.e('Error getting ride status: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(
      String rideId, Map<String, dynamic> location) async {
    try {
      await http.post(
        Uri.parse(
            'https://helloauto-zwjd.onrender.com/api/rides/$rideId/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(location),
      );

      // Also emit location update through socket
      _socketService.emitLocationUpdate(location);
    } catch (e) {
      _logger.e('Error updating location: $e');
      rethrow;
    }
  }
}
