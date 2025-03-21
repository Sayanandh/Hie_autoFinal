import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'package:logging/logging.dart';

enum RideStatus {
  none,
  pending,
  searching,
  accepted,
  arrived,
  inProgress,
  completed,
  cancelled
}

class RideProvider with ChangeNotifier {
  final _logger = Logger('RideProvider');
  final ApiService _apiService;
  final SocketService _socketService;

  Ride? _currentRide;
  List<Ride> _rideHistory = [];
  bool _isLoading = false;
  String? _error;
  Timer? _locationTimer;
  RideStatus _rideStatus = RideStatus.none;
  Position? _lastKnownLocation;
  bool _isOnline = false;

  RideProvider(this._apiService, this._socketService) {
    _setupSocketListeners();
    _initializeLocationService();
  }

  // Getters
  Ride? get currentRide => _currentRide;
  List<Ride> get rideHistory => _rideHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  RideStatus get rideStatus => _rideStatus;
  bool get isOnline => _isOnline;
  Position? get lastKnownLocation => _lastKnownLocation;

  Future<void> _initializeLocationService() async {
    try {
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
    } catch (e) {
      _error = e.toString();
      _logger.severe('Location service initialization failed: $_error');
      notifyListeners();
    }
  }

  void _handleLocationUpdate(Position position) {
    _lastKnownLocation = position;
    if (_currentRide != null && _rideStatus == RideStatus.inProgress) {
      _emitLocationUpdate();
    }
  }

  void _emitLocationUpdate() {
    if (_lastKnownLocation == null || _currentRide == null) return;

    _socketService.emitDriverLocation(
      _currentRide!.id,
      {
        'lat': _lastKnownLocation!.latitude,
        'lng': _lastKnownLocation!.longitude,
      },
    );
  }

  void _setupSocketListeners() {
    _socketService.onRideRequest((data) {
      _logger.info('New ride request received: $data');
      _handleNewRideRequest(data);
    });

    _socketService.onRideStatusChange((status, data) {
      _logger.info('Ride status changed: $status');
      _handleRideStatusChange(status, data);
    });

    _socketService.onNotification((message, data) {
      _logger.info('Notification received: $message');
      // Handle notification
    });

    _socketService.onRequestNotification((data) {
      _logger.info('Request notification received: $data');
      // Handle request notification
    });

    _socketService.onResponseNotification((data) {
      _logger.info('Response notification received: $data');
      // Handle response notification
    });

    if (_currentRide != null) {
      _socketService.onLocationUpdate(_currentRide!.id, (data) {
        _logger.info('User location update received: $data');
        // Update user location on map
        notifyListeners();
      });

      _socketService.onTerminateLocationSharing(_currentRide!.id, (data) {
        _logger.info('Location sharing terminated: $data');
        _stopLocationSharing();
      });
    }
  }

  void _handleNewRideRequest(Map<String, dynamic> data) {
    if (!_isOnline || _currentRide != null) {
      _logger
          .info('Ignoring ride request - Driver is offline or has active ride');
      return;
    }

    // Create a Ride object from the request data
    _currentRide = Ride(
      id: data['rideId'],
      userId: data['user']['id'],
      pickup: {
        'lat': data['pickup']['lat'].toDouble(),
        'lng': data['pickup']['lng'].toDouble(),
      },
      dropoff: {
        'lat': data['dropoff']['lat'].toDouble(),
        'lng': data['dropoff']['lng'].toDouble(),
      },
      price: data['price'].toDouble(),
      status: 'pending',
    );

    // Notify UI about new ride request
    notifyListeners();
  }

  void _handleRideStatusChange(String status, Map<String, dynamic> data) {
    switch (status) {
      case 'accepted':
        _rideStatus = RideStatus.accepted;
        break;
      case 'arrived':
        _rideStatus = RideStatus.arrived;
        break;
      case 'in_progress':
        _rideStatus = RideStatus.inProgress;
        _startLocationSharing();
        break;
      case 'completed':
        _rideStatus = RideStatus.completed;
        _stopLocationSharing();
        break;
      case 'cancelled':
        _rideStatus = RideStatus.cancelled;
        _stopLocationSharing();
        break;
    }
    notifyListeners();
  }

  Future<void> toggleOnlineStatus(bool status) async {
    try {
      _isOnline = status;
      // Update server about driver's availability
      _socketService.emit('driver_status', {
        'status': status ? 'active' : 'inactive',
        'captainId': _currentRide?.captainId,
      });
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _logger.severe('Failed to toggle online status: $_error');
      notifyListeners();
    }
  }

  Future<void> acceptRide(String rideId) async {
    try {
      _setLoading(true);
      _error = null;

      // Emit ride response to server
      _socketService.emit('ride_response', {
        'rideId': rideId,
        'captainId': _currentRide?.captainId,
        'accepted': true,
      });

      final response = await _apiService.acceptRide(rideId);
      _currentRide = Ride.fromJson(response['ride']);
      _rideStatus = RideStatus.accepted;

      // Start monitoring user location
      _socketService.onLocationUpdate(_currentRide!.id, (location) {
        // Update user location on map
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _logger.severe('Failed to accept ride: $_error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectRide(String rideId) async {
    try {
      _setLoading(true);
      _error = null;

      // Emit ride response to server
      _socketService.emit('ride_response', {
        'rideId': rideId,
        'captainId': _currentRide?.captainId,
        'accepted': false,
      });

      await _apiService.rejectRide(rideId);
      _currentRide = null;
      _rideStatus = RideStatus.none;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _logger.severe('Failed to reject ride: $_error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyRideOTP(String otp) async {
    try {
      _setLoading(true);
      _error = null;

      if (_currentRide == null) {
        throw 'No active ride found';
      }

      if (_lastKnownLocation == null) {
        throw 'Current location not available';
      }

      final response = await _apiService.verifyRideOTP(
        rideId: _currentRide!.id,
        otp: otp,
        location: {
          'ltd': _lastKnownLocation!.latitude,
          'lng': _lastKnownLocation!.longitude,
        },
      );

      _currentRide = Ride.fromJson(response['ride']);
      _rideStatus = RideStatus.inProgress;
      _startLocationSharing();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _logger.severe('Failed to verify OTP: $_error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeRide() async {
    try {
      _setLoading(true);
      _error = null;

      if (_currentRide == null) {
        throw 'No active ride found';
      }

      if (_lastKnownLocation == null) {
        throw 'Current location not available';
      }

      final response = await _apiService.completeRide(
        rideId: _currentRide!.id,
        location: {
          'ltd': _lastKnownLocation!.latitude,
          'lng': _lastKnownLocation!.longitude,
        },
      );

      _currentRide = Ride.fromJson(response['ride']);
      _rideStatus = RideStatus.completed;
      _stopLocationSharing();
      _currentRide = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _logger.severe('Failed to complete ride: $_error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRideHistory() async {
    try {
      _setLoading(true);
      _error = null;

      final response = await _apiService.getRideHistory();
      _rideHistory = response.map((ride) => Ride.fromJson(ride)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _logger.severe('Failed to load ride history: $_error');
    } finally {
      _setLoading(false);
    }
  }

  void _startLocationSharing() {
    if (_currentRide == null) return;

    _socketService.startLocationSharing(_currentRide!.id);

    // Start periodic location updates
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _emitLocationUpdate();
    });
  }

  void _stopLocationSharing() {
    if (_currentRide == null) return;

    _socketService.stopLocationSharing(_currentRide!.id);
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopLocationSharing();
    _locationTimer?.cancel();
    super.dispose();
  }
}
