import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../api_service.dart';

class LocationApiService {
  static final Logger _logger = Logger();
  static Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  static const String _baseUrl = 'https://helloauto-zwjd.onrender.com';

  static Future<List<String>> getSuggestions(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final token = await ApiService.getStoredToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/maps/get-suggestions?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('suggestions')) {
          final suggestions = data['suggestions'];
          if (suggestions is List) {
            _logger.i('Received suggestions: $suggestions');
            return suggestions.map((item) => item.toString()).toList();
          }
        }
      }

      _logger.w('Unexpected response format: ${response.body}');
      return [];
    } catch (e) {
      _logger.e('Error getting location suggestions: $e');
      return [];
    }
  }

  static Stream<List<String>> getRealtimeSuggestions(String query) async* {
    if (query.isEmpty) {
      yield [];
      return;
    }

    try {
      final suggestions = await getSuggestions(query);
      _logger.i('Streaming suggestions: $suggestions');
      yield suggestions;
    } catch (e) {
      _logger.e('Error in realtime suggestions: $e');
      yield [];
    }
  }

  static Future<Map<String, dynamic>?> getCoordinatesFromAddress(
      String address) async {
    try {
      final token = await ApiService.getStoredToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/maps/get-coordinate?address=$address'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Received coordinates for $address: $data');
        return {
          'description': address,
          'lat': data['lat'],
          'lng': data['lng'],
        };
      }

      _logger.e('Error getting coordinates: ${response.body}');
      return null;
    } catch (e) {
      _logger.e('Error getting coordinates: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getLocationDetails(
      String source, String destination) async {
    try {
      final token = await ApiService.getStoredToken();
      if (token == null) throw Exception('No authentication token found');

      // Get coordinates for both locations
      final sourceCoords = await getCoordinatesFromAddress(source);
      final destCoords = await getCoordinatesFromAddress(destination);

      if (sourceCoords == null || destCoords == null) {
        throw Exception('Failed to get coordinates for locations');
      }

      // Format coordinates as required by the API (longitude,latitude)
      final pickup = '${sourceCoords['lng']},${sourceCoords['lat']}';
      final dropoff = '${destCoords['lng']},${destCoords['lat']}';

      _logger
          .i('Sending price request with pickup: $pickup, dropoff: $dropoff');

      final response = await http.post(
        Uri.parse('$_baseUrl/rides/get-price'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'pickup': pickup,
          'dropoff': dropoff,
        }),
      );

      _logger.i('Raw response from get-price: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final rideData = data['data'];

          // Parse distance (remove 'km' and convert to double)
          final distanceStr =
              rideData['distance'].toString().replaceAll(' km', '');
          final distance = double.tryParse(distanceStr) ?? 0.0;

          // Parse duration (remove 'minutes' and convert to double)
          final durationStr =
              rideData['duration'].toString().replaceAll(' minutes', '');
          final duration = double.tryParse(durationStr) ?? 0.0;

          // Calculate price based on distance (₹30 per km, minimum ₹30)
          final price = (distance * 30).roundToDouble();
          final finalPrice = price < 30 ? 30.0 : price;

          _logger.i(
              'Calculated ride details - Distance: $distance km, Duration: $duration minutes, Price: ₹$finalPrice');

          return {
            'distance': distance,
            'duration': duration,
            'price': finalPrice,
          };
        } else {
          _logger.e('Invalid response format: $data');
          throw Exception(data['message'] ?? 'Failed to get ride details');
        }
      }

      _logger.e('Error response: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      _logger.e('Error getting ride details: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> reverseGeocode(
      double lat, double lng) async {
    try {
      final token = await ApiService.getStoredToken();
      if (token == null) throw Exception('No authentication token found');

      // Use the get-coordinate endpoint with the coordinates
      final response = await http.get(
        Uri.parse('$_baseUrl/maps/get-coordinate?address=$lat,$lng'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The response contains lat and lng directly
        return {
          'address':
              '${data['lat']}, ${data['lng']}', // Use coordinates as address
          'lat': data['lat'],
          'lng': data['lng'],
        };
      }

      _logger.e('Error reverse geocoding: ${response.body}');
      return null;
    } catch (e) {
      _logger.e('Error reverse geocoding: $e');
      return null;
    }
  }

  static void dispose() {
    _debounceTimer?.cancel();
  }
}
