import 'package:logger/logger.dart';
import '../api_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Logger _logger = Logger();

  // Get coordinates from address
  Future<Map<String, double>> getCoordinates(String address) async {
    try {
      final response = await ApiService.getCoordinates(address);
      return {
        'lat': response['lat'].toDouble(),
        'lng': response['lng'].toDouble(),
      };
    } catch (e) {
      _logger.e('Error getting coordinates: $e');
      rethrow;
    }
  }

  // Get distance and time between two locations
  Future<Map<String, dynamic>> getDistanceAndTime({
    required String origin,
    required String destination,
  }) async {
    try {
      final response = await ApiService.getDistanceAndTime(
        origin: origin,
        destination: destination,
      );

      return {
        'distance': response['distance'],
        'duration': response['duration'],
        'rawData': response['rawData'],
      };
    } catch (e) {
      _logger.e('Error getting distance and time: $e');
      rethrow;
    }
  }

  // Get location suggestions
  Future<List<String>> getLocationSuggestions(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final response = await ApiService.getLocationSuggestions(query);
      return List<String>.from(response['suggestions'] ?? []);
    } catch (e) {
      _logger.e('Error getting location suggestions: $e');
      rethrow;
    }
  }

  // Format coordinates to string
  String formatCoordinates(Map<String, double> coordinates) {
    return '${coordinates['lng']},${coordinates['lat']}';
  }

  // Parse coordinates string to map
  Map<String, double> parseCoordinates(String coordinates) {
    try {
      final parts = coordinates.split(',');
      if (parts.length != 2) {
        throw FormatException('Invalid coordinates format');
      }

      return {
        'lng': double.parse(parts[0]),
        'lat': double.parse(parts[1]),
      };
    } catch (e) {
      _logger.e('Error parsing coordinates: $e');
      rethrow;
    }
  }

  // Calculate estimated price based on distance
  double calculateEstimatedPrice(double distanceInMeters) {
    // Convert distance to kilometers and round up
    final distanceInKm = (distanceInMeters / 1000).ceil();

    // Minimum charge is 30
    if (distanceInKm < 1) {
      return 30.0;
    }

    // 30 per kilometer
    return distanceInKm * 30.0;
  }
}
