import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/service_locator.dart';

class ApiService {
  static final Logger _logger = Logger();
  static const String _baseUrl = 'https://helloauto-zwjd.onrender.com/api';
  static const String _mapboxApiKey =
      'pk.eyJ1IjoidmFydW5tZW5vbiIsImEiOiJjbTM3MjNmZWMwNGJlMm1xdXg1OTk1NHlnIn0.5yLCFGI6Mr3tMzcjJZgYlg';
  static const String _mapboxBaseUrl = 'https://api.mapbox.com';

  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  // Backdoor admin credentials for testing
  static const String _adminEmail = 'admin@test.com';
  static const String _adminPassword = 'admin123';
  static const String _adminToken = 'test_admin_token_123';

  Future<String?> get token async {
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
    }
    return _token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform GET request: $e');
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, dynamic body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform POST request: $e');
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, dynamic body) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform PUT request: $e');
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint, [dynamic body]) async {
    try {
      final request = http.Request('DELETE', Uri.parse('$_baseUrl$endpoint'));
      request.headers.addAll(_headers);
      if (body != null) {
        request.body = json.encode(body);
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform DELETE request: $e');
    }
  }

  // Handle API response
  static dynamic _handleResponse(http.Response response) {
    _logger.i('Response Status: ${response.statusCode}');
    _logger.i('Response Body: ${response.body}');

    if (response.body.trim().startsWith('<!DOCTYPE html>')) {
      throw Exception('Invalid server response. Please try again later.');
    }

    try {
      if (response.body.isEmpty) {
        return {
          'success': true,
          'status': 'success',
          'message': 'Operation completed successfully',
          'data': null
        };
      }

      final data = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'status': 'success',
          'message': data['message'] ?? 'Operation completed successfully',
          'data': data
        };
      } else {
        String errorMessage = data['message'] ?? 'Request failed';
        String status = 'error';

        switch (response.statusCode) {
          case 400:
            status = 'warning';
            break;
          case 401:
            status = 'unauthorized';
            break;
          case 403:
            status = 'forbidden';
            break;
          case 404:
            status = 'not_found';
            break;
          case 500:
            status = 'server_error';
            break;
          default:
            status = 'error';
        }

        return {
          'success': false,
          'status': status,
          'message': errorMessage,
          'data': null
        };
      }
    } catch (e) {
      _logger.e('Error parsing response: $e');
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      }
      rethrow;
    }
  }

  // =================== USER METHODS ===================

  /// Registers a new user and sends an OTP
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      _logger.i('=== Starting User Registration Process ===');
      _logger.i('Email: $email');
      _logger.i('First Name: $firstName');
      _logger.i('Last Name: $lastName');
      _logger.i('Password Length: ${password.length}');

      final requestBody = {
        'fullname': {
          'firstname': firstName,
          'lastname': lastName,
        },
        'email': email,
        'password': password,
      };

      _logger.i('=== Request Details ===');
      _logger.i('URL: $_baseUrl/users/register');
      _logger.i('Headers: ${_headers.toString()}');
      _logger.i('Request Body: ${jsonEncode(requestBody)}');

      // First check if server is reachable
      try {
        final serverCheck =
            await http.get(Uri.parse(_baseUrl.replaceAll('/api', '')));
        _logger.i('Server check status: ${serverCheck.statusCode}');
        if (serverCheck.statusCode != 200) {
          throw Exception(
              'Server is not responding correctly. Status: ${serverCheck.statusCode}');
        }
      } catch (e) {
        _logger.e('Server check failed: $e');
        throw Exception(
            'Unable to reach the server. Please check your internet connection.');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/users/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final result = _handleResponse(response);

      if (result['success']) {
        _logger.i('Registration successful: ${result['data']}');
        return result;
      } else {
        _logger.e('Registration error: ${result['message']}');
        throw Exception(result['message']);
      }
    } catch (e) {
      _logger.e('=== Registration Process Error ===');
      _logger.e('Error Type: ${e.runtimeType}');
      _logger.e('Error Message: $e');
      _logger.e('Stack Trace: ${StackTrace.current}');

      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException')) {
        throw Exception(
            'Unable to connect to the server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  /// Validates OTP sent to user's email
  Future<Map<String, dynamic>> validateOTP({
    required String email,
    required String otp,
  }) async {
    try {
      _logger.i('Validating OTP for email: $email');

      final response = await http.post(
        Uri.parse('$_baseUrl/users/validate-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final result = _handleResponse(response);

      if (result['success']) {
        if (result['data']?['result']?['userRec']?['token'] != null) {
          _token = result['data']['result']['userRec']['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _token!);
          await prefs.setBool('isLoggedIn', true);

          // Initialize socket service after successful OTP validation
          final userId = result['data']['result']['userRec']['id'];
          await initializeSocketService(userId);

          _logger.i('OTP validated successfully and token stored');
          return result;
        } else {
          throw Exception('No token received in response');
        }
      } else {
        _logger.e('OTP validation error: ${result['message']}');
        throw Exception(result['message']);
      }
    } catch (e) {
      _logger.e('OTP validation error: $e');
      rethrow;
    }
  }

  /// Resends OTP to user's email
  Future<Map<String, dynamic>> resendOTP({required String email}) async {
    try {
      _logger.i('Resending OTP to email: $email');

      final response = await http.post(
        Uri.parse('$_baseUrl/users/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final result = _handleResponse(response);
      return result;
    } catch (e) {
      _logger.e('Resend OTP error: $e');
      rethrow;
    }
  }

  // Backdoor login method for testing
  static Future<Map<String, dynamic>> backdoorLogin(
      String email, String password) async {
    if (email == _adminEmail && password == _adminPassword) {
      _logger.i('Backdoor admin access granted');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _adminToken);
      await prefs.setBool('isLoggedIn', true);

      return {
        'success': true,
        'token': _adminToken,
        'message': 'Admin access granted',
        'user': {
          'id': 'admin_test_id',
          'email': email,
          'role': 'admin',
          'name': 'Test Admin'
        }
      };
    }
    throw Exception('Invalid admin credentials');
  }

  /// User login with email and password
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    try {
      // Check for backdoor admin access first
      if (email == _adminEmail && password == _adminPassword) {
        return await backdoorLogin(email, password);
      }

      // Regular login flow
      final response = await http.post(
        Uri.parse('$_baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final result = _handleResponse(response);

      if (result['success'] && result['data']?['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result['data']['token']);
        await prefs.setBool('isLoggedIn', true);
      }

      return result;
    } catch (e) {
      _logger.e('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  /// Gets the user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      _logger.i('Fetching user profile');
      final response = await get('/users/profile');
      return response;
    } catch (e) {
      _logger.e('Get profile error: $e');
      rethrow;
    }
  }

  /// Logs out the user
  Future<void> logout() async {
    try {
      _logger.i('Logging out user');

      // Clean up socket service
      await cleanupSocketService();

      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _token = null;

      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Error during logout: $e');
      rethrow;
    }
  }

  // =================== MAPS METHODS ===================

  /// Gets coordinates for an address
  Future<Map<String, dynamic>> getCoordinates(String address) async {
    try {
      final response = await get('/maps/get-coordinate?address=$address');
      return response;
    } catch (e) {
      _logger.e('Get coordinates error: $e');
      rethrow;
    }
  }

  /// Gets distance and time between two locations
  Future<Map<String, dynamic>> getDistanceTime({
    required String origin,
    required String destination,
  }) async {
    try {
      final response = await get(
          '/maps/get-distance-time?origin=$origin&destination=$destination');
      return response;
    } catch (e) {
      _logger.e('Get distance and time error: $e');
      rethrow;
    }
  }

  /// Gets location suggestions based on query
  Future<List<String>> getLocationSuggestions(String query) async {
    try {
      final response = await get('/maps/get-suggestions?query=$query');

      if (response['success'] && response['data']?['suggestions'] is List) {
        return List<String>.from(
            response['data']['suggestions'].map((item) => item['name'] ?? ''));
      }
      return [];
    } catch (e) {
      _logger.e('Get suggestions error: $e');
      return [];
    }
  }

  // =================== AUTO STANDS METHODS ===================

  /// Creates a new auto stand
  Future<Map<String, dynamic>> createAutoStand({
    required String standName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await post('/autostands/create', {
        'standname': standName,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
      });

      return response;
    } catch (e) {
      _logger.e('Create auto stand error: $e');
      rethrow;
    }
  }

  /// Updates an auto stand
  Future<Map<String, dynamic>> updateAutoStand({
    required String standId,
    String? standName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {};

      if (standName != null) {
        requestBody['standname'] = standName;
      }

      if (latitude != null && longitude != null) {
        requestBody['location'] = {
          'latitude': latitude,
          'longitude': longitude,
        };
      }

      final response = await put('/autostands/update/$standId', requestBody);
      return response;
    } catch (e) {
      _logger.e('Update auto stand error: $e');
      rethrow;
    }
  }

  /// Deletes an auto stand
  Future<Map<String, dynamic>> deleteAutoStand(String standId) async {
    try {
      final response = await delete('/autostands/delete/$standId');
      return response;
    } catch (e) {
      _logger.e('Delete auto stand error: $e');
      rethrow;
    }
  }

  /// Adds a member to an auto stand
  Future<Map<String, dynamic>> addMemberToAutoStand({
    required String standId,
    required String joiningCaptainId,
  }) async {
    try {
      final response = await post('/autostands/add-member', {
        'standId': standId,
        'joiningCaptainId': joiningCaptainId,
      });

      return response;
    } catch (e) {
      _logger.e('Add member to auto stand error: $e');
      rethrow;
    }
  }

  /// Responds to a join request
  Future<Map<String, dynamic>> respondToJoinRequest({
    required String standId,
    required String joiningCaptainId,
    required String responseStatus,
  }) async {
    try {
      final response = await post('/autostands/respond-to-request', {
        'standId': standId,
        'joiningCaptainId': joiningCaptainId,
        'response': responseStatus,
      });

      return response;
    } catch (e) {
      _logger.e('Respond to join request error: $e');
      rethrow;
    }
  }

  /// Searches for auto stands
  Future<List<Map<String, dynamic>>> searchAutoStands({
    required String name,
    required double captainLat,
    required double captainLng,
  }) async {
    try {
      final response = await post('/autostands/search', {
        'name': name,
        'captainLat': captainLat,
        'captainLng': captainLng,
      });

      if (response['success'] && response['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } catch (e) {
      _logger.e('Search auto stands error: $e');
      return [];
    }
  }

  /// Removes a member from an auto stand
  Future<Map<String, dynamic>> removeMemberFromAutoStand({
    required String standId,
    required String driverId,
  }) async {
    try {
      final response = await delete('/autostands/$standId/remove-member', {
        'driverID': driverId,
      });

      return response;
    } catch (e) {
      _logger.e('Remove member from auto stand error: $e');
      rethrow;
    }
  }

  /// Gets members of an auto stand
  Future<List<Map<String, dynamic>>> getAutoStandMembers(String standId) async {
    try {
      final response = await get('/autostands/$standId/members');

      if (response['success'] && response['data']?['members'] is List) {
        return List<Map<String, dynamic>>.from(response['data']['members']);
      }

      return [];
    } catch (e) {
      _logger.e('Get auto stand members error: $e');
      return [];
    }
  }

  /// Toggles queue status
  Future<Map<String, dynamic>> toggleQueueStatus({
    required String autostandId,
    required String driverId,
    required bool toggleStatus,
    required Map<String, double> currentLocation,
  }) async {
    try {
      final response =
          await put('/autostands/toggle/toggle-queue/$autostandId', {
        'driverID': driverId,
        'toggleStatus': toggleStatus,
        'currentLocation': currentLocation,
      });

      return response;
    } catch (e) {
      _logger.e('Toggle queue status error: $e');
      rethrow;
    }
  }

  // =================== RIDES METHODS ===================

  /// Gets ride price
  Future<Map<String, dynamic>> getRidePrice({
    required String pickup,
    required String dropoff,
  }) async {
    try {
      final response = await post('/rides/get-price', {
        'pickup': pickup,
        'dropoff': dropoff,
      });

      return response;
    } catch (e) {
      _logger.e('Get ride price error: $e');
      rethrow;
    }
  }

  /// Requests a ride
  Future<Map<String, dynamic>> requestRide({
    required Map<String, double> pickup,
    required Map<String, double> dropoff,
    required double price,
  }) async {
    try {
      _logger.i(
          'Requesting ride with pickup: $pickup, dropoff: $dropoff, price: $price');

      final response = await post('/rides/request-ride', {
        'pickup': pickup,
        'dropoff': dropoff,
        'price': price,
      });

      return response;
    } catch (e) {
      _logger.e('Request ride error: $e');
      rethrow;
    }
  }

  /// Verifies ride OTP
  Future<Map<String, dynamic>> verifyRideOTP({
    required String rideId,
    required String otp,
    required Map<String, double> location,
  }) async {
    try {
      final response = await post('/rides/verify-otp', {
        'rideId': rideId,
        'otp': otp,
        'location': location,
      });

      return response;
    } catch (e) {
      _logger.e('Verify ride OTP error: $e');
      rethrow;
    }
  }

  /// Completes a ride
  Future<Map<String, dynamic>> completeRide({
    required String rideId,
    required Map<String, double> location,
  }) async {
    try {
      final response = await post('/rides/ride-completed', {
        'rideId': rideId,
        'status': 'completed',
        'location': location,
      });

      return response;
    } catch (e) {
      _logger.e('Complete ride error: $e');
      rethrow;
    }
  }

  /// Cancels a ride
  Future<Map<String, dynamic>> cancelRide(String rideId) async {
    try {
      final response = await post('/rides/cancel-ride', {
        'rideId': rideId,
      });

      return response;
    } catch (e) {
      _logger.e('Cancel ride error: $e');
      rethrow;
    }
  }

  /// Gets ride history
  Future<List<Map<String, dynamic>>> getRideHistory() async {
    try {
      final response = await get('/rides/get-ride-history-for-user');

      if (response['success'] && response['data']?['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data']['data']);
      }

      return [];
    } catch (e) {
      _logger.e('Get ride history error: $e');
      return [];
    }
  }

  /// Books a ride
  Future<Map<String, dynamic>> bookRide({
    required String pickupLocation,
    required String dropLocation,
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    required String distance,
    required String duration,
    required double fare,
  }) async {
    try {
      final response = await post('/rides/book', {
        'pickupLocation': pickupLocation,
        'dropLocation': dropLocation,
        'pickupCoordinates': {'lat': pickupLat, 'lng': pickupLng},
        'dropCoordinates': {'lat': dropLat, 'lng': dropLng},
        'distance': distance,
        'duration': duration,
        'fare': fare,
      });

      return response;
    } catch (e) {
      _logger.e('Book ride error: $e');
      rethrow;
    }
  }

  /// Gets ride status
  Future<Map<String, dynamic>> getRideStatus(String rideId) async {
    try {
      final response = await get('/rides/$rideId/status');
      return response;
    } catch (e) {
      _logger.e('Get ride status error: $e');
      rethrow;
    }
  }

  /// Processes payment for a ride
  Future<Map<String, dynamic>> processPayment({
    required String rideId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final response = await post('/rides/process-payment', {
        'rideId': rideId,
        'amount': amount,
        'paymentMethod': paymentMethod,
      });

      return response;
    } catch (e) {
      _logger.e('Process payment error: $e');
      rethrow;
    }
  }

  /// Rates a ride
  Future<Map<String, dynamic>> rateRide({
    required String rideId,
    required int rating,
    String? comment,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'rideId': rideId,
        'rating': rating,
      };

      if (comment != null) {
        requestBody['comment'] = comment;
      }

      final response = await post('/rides/rate', requestBody);
      return response;
    } catch (e) {
      _logger.e('Rate ride error: $e');
      rethrow;
    }
  }

  // =================== CAPTAIN METHODS ===================

  /// Registers a new captain
  Future<Map<String, dynamic>> registerCaptain({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String vehicleColor,
    required String vehiclePlate,
    required int vehicleCapacity,
    required String vehicleType,
    required String licenseNumber,
    required String vehicleRegistrationNumber,
    required String insuranceNumber,
    required String commercialRegistrationNumber,
  }) async {
    try {
      final response = await post('/captains/register', {
        'fullname': {
          'firstname': firstName,
          'lastname': lastName,
        },
        'email': email,
        'password': password,
        'vehicle': {
          'color': vehicleColor,
          'plate': vehiclePlate,
          'capacity': vehicleCapacity,
          'vehicleType': vehicleType,
        },
        'verification': {
          'LicenseNumber': licenseNumber,
          'VehicleRegistrationNumber': vehicleRegistrationNumber,
          'InsuranceNumber': insuranceNumber,
          'CommertialRegistrationNumber': commercialRegistrationNumber,
        },
      });

      return response;
    } catch (e) {
      _logger.e('Register captain error: $e');
      rethrow;
    }
  }

  /// Validates captain OTP
  Future<Map<String, dynamic>> validateCaptainOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await post('/captains/validate-otp', {
        'email': email,
        'otp': otp,
      });

      return response;
    } catch (e) {
      _logger.e('Validate captain OTP error: $e');
      rethrow;
    }
  }

  /// Logs in a captain
  Future<Map<String, dynamic>> loginCaptain({
    required String email,
    required String password,
  }) async {
    try {
      final response = await post('/captains/login', {
        'email': email,
        'password': password,
      });

      if (response['success'] && response['data']?['token'] != null) {
        _token = response['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setBool('isLoggedIn', true);
      }

      return response;
    } catch (e) {
      _logger.e('Login captain error: $e');
      rethrow;
    }
  }

  /// Gets captain profile
  Future<Map<String, dynamic>> getCaptainProfile() async {
    try {
      final response = await get('/captains/profile');
      return response;
    } catch (e) {
      _logger.e('Get captain profile error: $e');
      rethrow;
    }
  }

  /// Logs out a captain
  Future<Map<String, dynamic>> logoutCaptain() async {
    try {
      final response = await get('/captains/logout');

      if (response['success']) {
        _token = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.setBool('isLoggedIn', false);
      }

      return response;
    } catch (e) {
      _logger.e('Logout captain error: $e');
      rethrow;
    }
  }

  // =================== UTILITY METHODS ===================

  /// Checks if the server is reachable
  Future<bool> checkServerConnection() async {
    try {
      final response =
          await http.get(Uri.parse(_baseUrl.replaceAll('/api', '')));
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Server connection error: $e');
      return false;
    }
  }

  /// Checks if the user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  /// Gets the server status
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final baseUrl = _baseUrl.replaceAll('/api', '');
      final response = await http.get(Uri.parse('$baseUrl/status'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'unavailable',
          'message': 'Server is not responding correctly',
        };
      }
    } catch (e) {
      _logger.e('Get server status error: $e');
      return {
        'status': 'error',
        'message': 'Unable to reach the server',
      };
    }
  }
}
