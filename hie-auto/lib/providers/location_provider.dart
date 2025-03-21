import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get_it/get_it.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final GetIt _serviceLocator;
  late final LocationService _locationService;
  LatLng? _currentLocation;
  String? _currentAddress;
  bool _isLoading = false;
  List<String> _suggestions = [];

  LocationProvider(this._serviceLocator) {
    _locationService = _serviceLocator<LocationService>();
  }

  LatLng? get currentLocation => _currentLocation;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  List<String> get suggestions => _suggestions;

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
      await _getAddressFromLatLng(_currentLocation!);
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        _currentAddress = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
  }

  Future<String?> getAddressFromLatLng(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return null;
  }

  Future<void> getLocationSuggestions(String query) async {
    if (query.isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    try {
      _suggestions = await _locationService.getLocationSuggestions(query);
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location suggestions: $e');
      _suggestions = [];
      notifyListeners();
    }
  }

  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      return await _locationService.getCoordinates(address);
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDistanceAndTime({
    required String origin,
    required String destination,
  }) async {
    try {
      return await _locationService.getDistanceAndTime(
        origin: origin,
        destination: destination,
      );
    } catch (e) {
      debugPrint('Error getting distance and time: $e');
      return null;
    }
  }

  String formatCoordinates(LatLng location) {
    return _locationService.formatCoordinates({
      'lat': location.latitude,
      'lng': location.longitude,
    });
  }

  LatLng? parseCoordinates(String coordinates) {
    try {
      final coords = _locationService.parseCoordinates(coordinates);
      return LatLng(coords['lat']!, coords['lng']!);
    } catch (e) {
      debugPrint('Error parsing coordinates: $e');
      return null;
    }
  }

  double calculateEstimatedPrice(double distanceInMeters) {
    return _locationService.calculateEstimatedPrice(distanceInMeters);
  }
}
