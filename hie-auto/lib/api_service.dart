import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class ApiService {
  static final Logger logger = Logger();
  static const String baseUrl = 'https://helloauto-zwjd.onrender.com';

  // Get token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Public method to get stored token
  static Future<String?> getStoredToken() async {
    return await _getToken();
  }

  // Add token to headers
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await _getToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      };
    } catch (e) {
      logger.e('Error getting headers: $e');
      throw ApiException('Failed to get headers: ${e.toString()}', 500);
    }
  }

  // Helper method to handle API responses
  static Future<Map<String, dynamic>> _handleResponse(http.Response response) {
    try {
      if (response.statusCode == 404) {
        throw ApiException(
            'Endpoint not found. Please check the API URL.', 404);
      }

      if (response.body.isEmpty) {
        throw ApiException('Empty response from server', response.statusCode);
      }

      try {
        final data = jsonDecode(response.body);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return Future.value(data);
        } else {
          final errorMessage =
              data['error'] ?? data['message'] ?? 'Unknown error occurred';
          throw ApiException(errorMessage, response.statusCode);
        }
      } catch (e) {
        throw ApiException(
            'Server response: ${response.body}', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Failed to process response: ${e.toString()}', response.statusCode);
    }
  }

  // Register User
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      logger.i('Registering user: $email');

      final requestBody = json.encode({
        "fullname": {"firstname": firstName, "lastname": lastName},
        "email": email,
        "password": password
      });

      logger.i('Registration URL: $baseUrl/users/register');
      logger.i('Request Body: $requestBody');

      final response = await http
          .post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ApiException('Registration request timed out', 408);
        },
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Registration error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Registration failed: ${e.toString()}', 500);
    }
  }

  // Backwards compatibility method for older code
  static Future<bool> registerUserLegacy(
    String email,
    String firstName,
    String lastName,
    String password,
  ) async {
    try {
      final response = await registerUser(
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
      );
      return response['message']?.contains('OTP sent') ?? false;
    } catch (e) {
      logger.e('Registration compatibility error: $e');
      return false;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      return token != null && isLoggedIn;
    } catch (e) {
      logger.e('Error checking login status: $e');
      return false;
    }
  }

  // Store user data
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      logger.e('Error storing user data: $e');
    }
  }

  // Get stored user data
  static Future<Map<String, dynamic>?> getStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        return jsonDecode(userDataString);
      }
      return null;
    } catch (e) {
      logger.e('Error getting stored user data: $e');
      return null;
    }
  }

  // Clear user data on logout
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      await prefs.remove('isLoggedIn');
    } catch (e) {
      logger.e('Error clearing user data: $e');
    }
  }

  // Update validateOtp method to store user data
  static Future<Map<String, dynamic>> validateOtp(
      String email, String otp) async {
    logger.i('Validating OTP for email: $email');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/validate-otp'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'otp': otp,
            }),
          )
          .timeout(const Duration(seconds: 30));

      // Check if response is JSON
      final contentType = response.headers['content-type'];
      if (contentType == null || !contentType.contains('application/json')) {
        logger.e('Invalid response type: $contentType');
        logger.e('Response body: ${response.body}');
        throw ApiException(
          'Server returned invalid response format',
          response.statusCode,
        );
      }

      final data = jsonDecode(response.body);
      logger.d('OTP validation response: $data');

      if (response.statusCode == 200) {
        // Check for nested token in result.userRec
        final userRec = data['result']?['userRec'];
        if (userRec != null && userRec['token'] != null) {
          // Store the token and user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', userRec['token']);
          await storeUserData(userRec);

          // Return success with user data
          return {
            'success': true,
            'token': userRec['token'],
            'user': userRec,
          };
        }
      }

      // Handle specific error messages
      if (data['message'] != null) {
        throw ApiException(
          data['message'] ?? 'Invalid OTP',
          response.statusCode,
        );
      }

      throw ApiException(
        'Invalid OTP. Please try again.',
        response.statusCode,
      );
    } catch (e) {
      logger.e('OTP validation error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to validate OTP. Please try again.', 500);
    }
  }

  // Send OTP
  static Future<Map<String, dynamic>> sendOtp({required String email}) async {
    try {
      logger.i('Sending OTP to email: $email');

      final requestBody = jsonEncode({'email': email});
      logger.i('Request Body for Sending OTP: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/users/resend-otp'),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      final data = await _handleResponse(response);

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

  // Update loginUser method to store user data
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = await _handleResponse(response);

      if (data['token'] != null) {
        await storeUserData(data);
      }

      return data;
    } catch (e) {
      logger.e('Login error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Login failed: ${e.toString()}', 500);
    }
  }

  // Backwards compatibility method for older code
  static Future<Map<String, dynamic>> loginUserLegacy(
    String email,
    String password,
  ) async {
    return await loginUser(
      email: email,
      password: password,
    );
  }

  // Get User Profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Get profile error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load profile: ${e.toString()}', 500);
    }
  }

  // Update logoutUser method to clear all data
  static Future<Map<String, dynamic>> logoutUser() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/logout'),
        headers: headers,
      );

      final data = await _handleResponse(response);
      await clearUserData();
      return data;
    } catch (e) {
      logger.e('Logout error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Logout failed: ${e.toString()}', 500);
    }
  }

  // Backwards compatibility method for older code
  static Future<void> logout() async {
    try {
      await logoutUser();
    } catch (e) {
      logger.e('Logout compatibility error: $e');
    }
  }

  // Get coordinates from address
  static Future<Map<String, dynamic>> getCoordinates(String address) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maps/get-coordinate?address=$address'),
        headers: headers,
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Get coordinates error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get coordinates: ${e.toString()}', 500);
    }
  }

  // Get distance and time between locations
  static Future<Map<String, dynamic>> getDistanceAndTime({
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

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Get distance and time error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
          'Failed to get distance and time: ${e.toString()}', 500);
    }
  }

  // Get location suggestions
  static Future<Map<String, dynamic>> getLocationSuggestions(
      String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maps/get-suggestions?query=$query'),
        headers: headers,
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Get location suggestions error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
          'Failed to get location suggestions: ${e.toString()}', 500);
    }
  }

  // Get AutoStand Members
  static Future<Map<String, dynamic>> getAutoStandMembers(
      String standId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/autostands/$standId/members'),
        headers: headers,
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Get auto stand members error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
          'Failed to get auto stand members: ${e.toString()}', 500);
    }
  }

  // Toggle Queue Status
  static Future<Map<String, dynamic>> toggleQueueStatus({
    required String autostandId,
    required String driverId,
    required bool toggleStatus,
    required Map<String, double> currentLocation,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/toggle/toggle-queue/$autostandId'),
        headers: headers,
        body: json.encode({
          'driverID': driverId,
          'toggleStatus': toggleStatus,
          'currentLocation': currentLocation,
        }),
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Toggle queue status error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to toggle queue status: ${e.toString()}', 500);
    }
  }

  // Get ride price
  static Future<Map<String, dynamic>> getRidePrice({
    required String pickup,
    required String dropoff,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/get-price'),
        headers: headers,
        body: json.encode({
          'pickup': pickup,
          'dropoff': dropoff,
        }),
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Get ride price error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get ride price: ${e.toString()}', 500);
    }
  }

  // Request ride
  static Future<Map<String, dynamic>> requestRide({
    required Map<String, double> pickup,
    required Map<String, double> dropoff,
    required double price,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/request-ride'),
        headers: headers,
        body: json.encode({
          'pickup': {
            'ltd': pickup['lat'],
            'lng': pickup['lng'],
          },
          'dropoff': {
            'ltd': dropoff['lat'],
            'lng': dropoff['lng'],
          },
          'price': price,
        }),
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Request ride error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to request ride: ${e.toString()}', 500);
    }
  }

  // Verify ride OTP
  static Future<Map<String, dynamic>> verifyRideOtp({
    required String rideId,
    required String otp,
    required Map<String, double> location,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/verify-otp'),
        headers: headers,
        body: json.encode({
          'rideId': rideId,
          'otp': otp,
          'location': {
            'ltd': location['lat'],
            'lng': location['lng'],
          },
        }),
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Verify ride OTP error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to verify ride OTP: ${e.toString()}', 500);
    }
  }

  // Complete ride
  static Future<Map<String, dynamic>> completeRide({
    required String rideId,
    required String status,
    required Map<String, double> location,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/ride-completed'),
        headers: headers,
        body: json.encode({
          'rideId': rideId,
          'status': status,
          'location': {
            'ltd': location['lat'],
            'lng': location['lng'],
          },
        }),
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Complete ride error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to complete ride: ${e.toString()}', 500);
    }
  }

  // Get ride history for user
  static Future<Map<String, dynamic>> getUserRideHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rides/get-ride-history-for-user'),
        headers: headers,
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Get ride history error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get ride history: ${e.toString()}', 500);
    }
  }

  // Get Captain Ride History
  static Future<Map<String, dynamic>> getCaptainRideHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rides/get-ride-history-for-captain'),
        headers: headers,
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Get captain ride history error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(
          'Failed to get captain ride history: ${e.toString()}', 500);
    }
  }

  // Get Ride History
  static Future<Map<String, dynamic>> getRideHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rides/get-ride-history'),
        headers: headers,
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Get ride history error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get ride history: ${e.toString()}', 500);
    }
  }

  // Cancel ride
  static Future<Map<String, dynamic>> cancelRide({
    required String rideId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/cancel'),
        headers: headers,
      );

      return await _handleResponse(response);
    } catch (e) {
      logger.e('Cancel ride error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to cancel ride: ${e.toString()}', 500);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}
