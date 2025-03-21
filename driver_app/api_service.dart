import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class ApiService {
  static const String baseUrl =
      'https://helloauto-20gp.onrender.com'; // Base URL
  static const String mapboxApiKey =
      'pk.eyJ1IjoidmFydW5tZW5vbiIsImEiOiJjbTM3MjNmZWMwNGJlMm1xdXg1OTk1NHlnIn0.5yLCFGI6Mr3tMzcjJZgYlg'; // Replace with your Mapbox access token
  static const String mapboxBaseUrl = 'https://api.mapbox.com';
  static final logger = Logger();

  // Get token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Add token to headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper method to handle API responses
  static dynamic _handleResponse(http.Response response) {
    logger.i('Response Status: ${response.statusCode}');
    logger.i('Response Body: ${response.body}');

    if (response.body.trim().startsWith('<!DOCTYPE html>')) {
      throw Exception('Invalid server response. Please try again later.');
    }

    try {
      final data = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception(data['message'] ??
            'Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      rethrow;
    }
  }

  // Register User - Matches /users/register endpoint
  static Future<Map<String, dynamic>> registerUser(
      String email, String firstName, String lastName, String password) async {
    try {
      logger.i('Registering user: $email');

      final requestBody = json.encode({
        "fullname": {"firstname": firstName, "lastname": lastName},
        "email": email,
        "password": password
      });

      logger.i('Request Body for Registration: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // Validate OTP - Matches /users/validate-otp endpoint
  static Future<Map<String, dynamic>> validateOtp({
    required String email,
    required String otp,
  }) async {
    try {
      logger.i('Validating OTP for email: $email');

      final requestBody = jsonEncode({
        'email': email,
        'otp': otp,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/users/validate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      final data = _handleResponse(response);

      if (data['result']?.containsKey('userRec') == true) {
        final token = data['result']['userRec']['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setBool('isLoggedIn', true);
        }
      }

      return data;
    } catch (e) {
      logger.e('OTP validation error: $e');
      throw Exception('Failed to validate OTP: $e');
    }
  }

  // Login User - Matches /users/login endpoint
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = _handleResponse(response);

      if (data['result']?.containsKey('userRec') == true) {
        final token = data['result']['userRec']['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setBool('isLoggedIn', true);
        }
      }

      return data;
    } catch (e) {
      logger.e('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  // Get User Profile - Matches /users/profile endpoint
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      logger.i('Fetching user profile with headers: $headers');

      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      );

      final data = _handleResponse(response);
      logger.i('Profile response data: $data');

      // Check if the response has the user data directly
      if (data.containsKey('user')) {
        return data['user'];
      }
      // Check if the response has the data in result
      else if (data.containsKey('result') &&
          data['result'].containsKey('user')) {
        return data['result']['user'];
      }
      // If neither format is found, throw an error
      throw Exception('Invalid profile data format');
    } catch (e) {
      logger.e('Get profile error: $e');
      throw Exception('Failed to load profile: $e');
    }
  }

  // Logout - Matches /users/logout endpoint
  static Future<void> logout() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/logout'),
        headers: headers,
      );

      _handleResponse(response);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      logger.e('Logout error: $e');
      throw Exception('Logout failed: $e');
    }
  }

  // Get Coordinates - Matches /maps/get-coordinate endpoint
  static Future<Map<String, dynamic>> getCoordinates(String address) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maps/get-coordinate?address=$address'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Get coordinates error: $e');
      throw Exception('Failed to get coordinates: $e');
    }
  }

  // Get Distance and Time - Matches /maps/get-distance-time endpoint
  static Future<Map<String, dynamic>> getDistanceTime({
    required String origin,
    required String destination,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/maps/get-distance-time?origin=$origin&destination=$destination'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Get distance/time error: $e');
      throw Exception('Failed to get distance and time: $e');
    }
  }

  // Get Location Suggestions - Matches /maps/get-suggestions endpoint
  static Future<List<String>> getSuggestions(String query) async {
    try {
      logger.i('Fetching suggestions for query: $query');

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maps/get-suggestions?query=$query'),
        headers: headers,
      );

      final data = _handleResponse(response);

      if (data['suggestions'] is List) {
        return List<String>.from(data['suggestions']);
      }
      return [];
    } catch (e) {
      logger.e('Get suggestions error: $e');
      return [];
    }
  }

  // Check Server Connection
  static Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      return response.statusCode == 200;
    } catch (e) {
      logger.e('Server connection error: $e');
      return false;
    }
  }

  // Check Login Status
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Send OTP
  static Future<Map<String, dynamic>> sendOtp({required String email}) async {
    try {
      logger.i('Sending OTP to email: $email');

      final requestBody = jsonEncode({'email': email});

      // Print the request body
      logger.i('Request Body for Sending OTP: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/users/resend-otp'),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      final data = _handleResponse(response);

      return {
        'success': data['message']?.contains('OTP sent') ?? false,
        'message': data['message'] ?? 'Failed to send OTP',
      };
    } catch (e) {
      logger.e('Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP: $e',
      };
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    try {
      await logout();
      logger.i('User signed out successfully');
    } catch (e) {
      logger.e('Sign out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Add Member to AutoStand - Matches /autostands/add-member endpoint
  static Future<Map<String, dynamic>> addMemberToAutoStand({
    required String standId,
    required String joiningCaptainId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/autostands/add-member'),
        headers: headers,
        body: jsonEncode({
          'standId': standId,
          'joiningCaptainId': joiningCaptainId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Add member error: $e');
      throw Exception('Failed to add member: $e');
    }
  }

  // Respond to Join Request - Matches /autostands/respond-to-request endpoint
  static Future<Map<String, dynamic>> respondToJoinRequest({
    required String standId,
    required String joiningCaptainId,
    required String responseStatus,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/autostands/respond-to-request'),
        headers: headers,
        body: jsonEncode({
          'standId': standId,
          'joiningCaptainId': joiningCaptainId,
          'response': responseStatus,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Respond to request error: $e');
      throw Exception('Failed to respond to request: $e');
    }
  }

  // Create AutoStand - Matches /autostands/create endpoint
  static Future<Map<String, dynamic>> createAutoStand({
    required String standname,
    required Map<String, dynamic> location,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/autostands/create'),
        headers: headers,
        body: jsonEncode({
          'standname': standname,
          'location': location,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Create autostand error: $e');
      throw Exception('Failed to create autostand: $e');
    }
  }

  // Update AutoStand - Matches /autostands/update/:id endpoint
  static Future<Map<String, dynamic>> updateAutoStand({
    required String standId,
    String? standname,
    Map<String, dynamic>? location,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (standname != null) body['standname'] = standname;
      if (location != null) body['location'] = location;

      final response = await http.put(
        Uri.parse('$baseUrl/autostands/update/$standId'),
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Update autostand error: $e');
      throw Exception('Failed to update autostand: $e');
    }
  }

  // Delete AutoStand - Matches /autostands/delete/:id endpoint
  static Future<Map<String, dynamic>> deleteAutoStand(String standId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/autostands/delete/$standId'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Delete autostand error: $e');
      throw Exception('Failed to delete autostand: $e');
    }
  }

  // Search AutoStand - Matches /autostands/search endpoint
  static Future<List<Map<String, dynamic>>> searchAutoStand(
      String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/autostands/search'),
        headers: headers,
        body: jsonEncode({'query': query}),
      );

      final data = _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    } catch (e) {
      logger.e('Search autostand error: $e');
      throw Exception('Failed to search autostands: $e');
    }
  }

  // Remove Member - Matches /autostands/:id/remove-member endpoint
  static Future<Map<String, dynamic>> removeMember({
    required String standId,
    required String memberId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/autostands/$standId/remove-member'),
        headers: headers,
        body: jsonEncode({'memberId': memberId}),
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Remove member error: $e');
      throw Exception('Failed to remove member: $e');
    }
  }

  // View Members - Matches /autostands/:id/members endpoint
  static Future<List<Map<String, dynamic>>> getAutoStandMembers(
      String standId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/autostands/$standId/members'),
        headers: headers,
      );

      final data = _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['members'] ?? []);
    } catch (e) {
      logger.e('Get members error: $e');
      throw Exception('Failed to get members: $e');
    }
  }

  // Toggle Queue Status
  static Future<Map<String, dynamic>> toggleQueueStatus({
    required String autostandId,
    required String driverID,
    required bool toggleStatus,
    required Map<String, double> currentLocation,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/autostands/toggle/toggle-queue/$autostandId'),
        headers: headers,
        body: jsonEncode({
          'driverID': driverID,
          'toggleStatus': toggleStatus,
          'currentLocation': currentLocation,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Toggle queue error: $e');
      throw Exception('Failed to toggle queue: $e');
    }
  }

  // Get Ride Price - Matches /rides/get-price endpoint
  static Future<Map<String, dynamic>> getRidePrice({
    required String pickup,
    required String dropoff,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/get-price'),
        headers: headers,
        body: jsonEncode({
          'pickup': pickup, // Format: "longitude,latitude"
          'dropoff': dropoff, // Format: "longitude,latitude"
        }),
      );

      final data = _handleResponse(response);

      if (data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': {
            'distance': data['data']['distance'],
            'duration': data['data']['duration'],
            'price': data['data']['price'],
            'rawData': data['data']['rawData'],
          }
        };
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      logger.e('Get ride price error: $e');
      throw Exception('Failed to get ride price: $e');
    }
  }

  // Request Ride - Matches /rides/request-ride endpoint
  static Future<Map<String, dynamic>> requestRide({
    required String pickup,
    required String dropoff,
    required double price,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/request-ride'),
        headers: headers,
        body: jsonEncode({
          'pickup': pickup,
          'dropoff': dropoff,
          'price': price,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Request ride error: $e');
      throw Exception('Failed to request ride: $e');
    }
  }

  // Verify Ride OTP - Matches /rides/verify-otp endpoint
  static Future<Map<String, dynamic>> verifyRideOtp({
    required String otp,
    required String rideId,
    required Map<String, dynamic> location,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/verify-otp'),
        headers: headers,
        body: jsonEncode({
          'otp': otp,
          'rideId': rideId,
          'location': location,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Verify ride OTP error: $e');
      throw Exception('Failed to verify ride OTP: $e');
    }
  }

  // Complete Ride - Matches /rides/ride-completed endpoint
  static Future<Map<String, dynamic>> completeRide({
    required String rideId,
    required String status,
    required Map<String, dynamic> location,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/ride-completed'),
        headers: headers,
        body: jsonEncode({
          'rideId': rideId,
          'status': status,
          'location': location,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      logger.e('Complete ride error: $e');
      throw Exception('Failed to complete ride: $e');
    }
  }

  // Get User Ride History - Matches /rides/get-ride-history-for-user endpoint
  static Future<List<Map<String, dynamic>>> getUserRideHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rides/get-ride-history-for-user'),
        headers: headers,
      );

      final data = _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['rides'] ?? []);
    } catch (e) {
      logger.e('Get user ride history error: $e');
      throw Exception('Failed to get user ride history: $e');
    }
  }

  // Get Captain Ride History - Matches /rides/get-ride-history-for-captain endpoint
  static Future<List<Map<String, dynamic>>> getCaptainRideHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rides/get-ride-history-for-captain'),
        headers: headers,
      );

      final data = _handleResponse(response);
      return List<Map<String, dynamic>>.from(data['rides'] ?? []);
    } catch (e) {
      logger.e('Get captain ride history error: $e');
      throw Exception('Failed to get captain ride history: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp) async {
    try {
      // Your implementation for verifying OTP
      // Example:
      final response = await http.post(
        Uri.parse('$baseUrl/users/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      return _handleResponse(
          response); // Ensure this returns a Map<String, dynamic>
    } catch (e) {
      logger.e('Verify OTP error: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<http.Response> getProtectedData() async {
    final token = await getAuthToken();
    return await http.get(
      Uri.parse('$baseUrl/protected-route'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Mapbox Forward Geocoding - Convert address to coordinates
  static Future<Map<String, dynamic>> getMapboxCoordinates(
      String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final response = await http.get(
        Uri.parse(
            '$mapboxBaseUrl/geocoding/v5/mapbox.places/$encodedAddress.json?access_token=$mapboxApiKey'),
      );

      final data = json.decode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        final feature = data['features'][0];
        return {
          'coordinates': {
            'longitude': feature['center'][0],
            'latitude': feature['center'][1]
          },
          'place_name': feature['place_name']
        };
      }
      throw Exception('No results found');
    } catch (e) {
      logger.e('Mapbox geocoding error: $e');
      throw Exception('Failed to get coordinates: $e');
    }
  }

  // Mapbox Reverse Geocoding - Convert coordinates to address
  static Future<String> getMapboxAddress(
      double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$mapboxBaseUrl/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$mapboxApiKey'),
      );

      final data = json.decode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        return data['features'][0]['place_name'];
      }
      throw Exception('No address found');
    } catch (e) {
      logger.e('Mapbox reverse geocoding error: $e');
      throw Exception('Failed to get address: $e');
    }
  }

  // Mapbox Directions API - Get route information
  static Future<Map<String, dynamic>> getMapboxDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$mapboxBaseUrl/directions/v5/mapbox/driving/$startLng,$startLat;$endLng,$endLat'
            '?access_token=$mapboxApiKey'
            '&geometries=geojson'
            '&overview=full'),
      );

      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        return {
          'distance': route['distance'], // in meters
          'duration': route['duration'], // in seconds
          'geometry': route['geometry'], // GeoJSON geometry
        };
      }
      throw Exception('No route found');
    } catch (e) {
      logger.e('Mapbox directions error: $e');
      throw Exception('Failed to get directions: $e');
    }
  }

  // Mapbox Static Image API - Get static map image
  static String getStaticMapImageUrl({
    required double latitude,
    required double longitude,
    required int zoom,
    required int width,
    required int height,
    String? marker,
  }) {
    final markerQuery = marker != null ? '&markers=$marker' : '';
    return '$mapboxBaseUrl/styles/v1/mapbox/streets-v11/static/'
        '${longitude},${latitude},${zoom}/${width}x${height}'
        '?access_token=$mapboxApiKey$markerQuery';
  }

  // Mapbox Place Search API - Get location suggestions
  static Future<List<Map<String, dynamic>>> getMapboxSuggestions(
      String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await http.get(
        Uri.parse('$mapboxBaseUrl/geocoding/v5/mapbox.places/$encodedQuery.json'
            '?access_token=$mapboxApiKey'
            '&types=address,poi'
            '&limit=5'),
      );

      final data = json.decode(response.body);
      if (data['features'] != null) {
        return List<Map<String, dynamic>>.from(
            data['features'].map((feature) => {
                  'place_name': feature['place_name'],
                  'coordinates': {
                    'longitude': feature['center'][0],
                    'latitude': feature['center'][1]
                  }
                }));
      }
      return [];
    } catch (e) {
      logger.e('Mapbox suggestions error: $e');
      return [];
    }
  }
}
