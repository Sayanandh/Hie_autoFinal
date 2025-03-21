import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_service.dart';
import 'socket_service.dart';

class RideService {
  static RideService? _instance;
  final ApiService _apiService = ApiService.instance;
  final SocketService _socketService = SocketService.instance;

  RideService._();

  static RideService get instance {
    _instance ??= RideService._();
    return _instance!;
  }

  Future<Map<String, dynamic>> getRouteDetails(
      LatLng pickup, LatLng dropoff) async {
    return await _apiService.getRouteDetails({
      'pickup': '${pickup.longitude},${pickup.latitude}',
      'dropoff': '${dropoff.longitude},${dropoff.latitude}',
    });
  }

  Future<Map<String, dynamic>> requestRide(
      LatLng pickup, LatLng dropoff, double price) async {
    return await _apiService.requestRide({
      'pickup': {
        'lat': pickup.latitude,
        'lng': pickup.longitude,
      },
      'dropoff': {
        'lat': dropoff.latitude,
        'lng': dropoff.longitude,
      },
      'price': price,
    });
  }

  Future<Map<String, dynamic>> verifyRideOTP(
      String otp, String rideId, LatLng location) async {
    return await _apiService.verifyRideOTP(
      rideId: rideId,
      otp: otp,
      location: {
        'ltd': location.latitude,
        'lng': location.longitude,
      },
    );
  }

  Future<Map<String, dynamic>> completeRide(
      String rideId, LatLng location) async {
    return await _apiService.completeRide(
      rideId: rideId,
      location: {
        'ltd': location.latitude,
        'lng': location.longitude,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRideHistory() async {
    return await _apiService.getRideHistory();
  }

  void startLocationUpdates(String rideId, Function(LatLng) onLocationUpdate) {
    _socketService.startLocationUpdates(rideId, (data) {
      onLocationUpdate(LatLng(
        data['location']['ltd'].toDouble(),
        data['location']['lng'].toDouble(),
      ));
    });
  }

  void stopLocationUpdates(String rideId) {
    _socketService.stopLocationUpdates(rideId);
  }

  void emitLocationUpdate(String rideId, LatLng location) {
    _socketService.emitLocationUpdate(rideId, {
      'ltd': location.latitude,
      'lng': location.longitude,
    });
  }

  void onRideRequest(Function(Map<String, dynamic>) onRideRequest) {
    _socketService.onRideRequest(onRideRequest);
  }

  void onRideStatusUpdate(
      String rideId, Function(Map<String, dynamic>) onStatusUpdate) {
    _socketService.onRideStatusUpdate(rideId, onStatusUpdate);
  }

  void onTerminateLocationSharing(
      String rideId, Function(Map<String, dynamic>) onTerminate) {
    _socketService.onTerminateLocationSharing(rideId, onTerminate);
  }

  void onLocationUpdate(String rideId, Function(Map<String, dynamic>) handler) {
    _socketService.onLocationUpdate(rideId, handler);
  }
}
