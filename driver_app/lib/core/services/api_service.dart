import 'package:dio/dio.dart';
import '../config/secrets.dart';
import '../config/api_config.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final Dio _dio;
  final _logger = Logger('ApiService');
  String? _token;
  static ApiService? _instance;
  final String _baseUrl = ApiConfig.baseUrl;

  ApiService._() : _dio = Dio() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout =
        const Duration(milliseconds: ApiConfig.connectionTimeout);
    _dio.options.receiveTimeout =
        const Duration(milliseconds: ApiConfig.receiveTimeout);

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => _logger.info(obj.toString())));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.info('Making ${options.method} request to ${options.path}');
        _logger.info('Request data: ${options.data}');

        final token = Secrets.authToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          _logger.info('Added auth token to request');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.info(
            'Received response [${response.statusCode}] from ${response.requestOptions.path}');
        _logger.info('Response data: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        _logger.severe('Request failed: ${e.message}');
        _logger.severe('Error response: ${e.response?.data}');
        return handler.next(e);
      },
    ));
  }

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      _logger.info('=== Starting GET Request ===');
      _logger.info('URL: $path');
      _logger.info('Query Parameters: $queryParameters');

      final response = await _dio.get(path, queryParameters: queryParameters);

      _logger.info('=== GET Request Successful ===');
      _logger.info('Status Code: ${response.statusCode}');
      _logger.info('Response Headers: ${response.headers}');
      _logger.info('Response Data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      _logger.severe('=== GET Request Failed ===');
      _logger.severe('URL: $path');
      _logger.severe('Query Parameters: $queryParameters');
      _logger.severe('Error: ${e.message}');
      _logger.severe('Response: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, dynamic data) async {
    try {
      _logger.info('=== Starting POST Request ===');
      _logger.info('URL: $path');
      _logger.info('Request Data: $data');

      final response = await _dio.post(path, data: data);

      _logger.info('=== POST Request Successful ===');
      _logger.info('Status Code: ${response.statusCode}');
      _logger.info('Response Headers: ${response.headers}');
      _logger.info('Response Data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      _logger.severe('=== POST Request Failed ===');
      _logger.severe('URL: $path');
      _logger.severe('Request Data: $data');
      _logger.severe('Error: ${e.message}');
      _logger.severe('Response: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String path, dynamic data) async {
    try {
      _logger.info('=== Starting PUT Request ===');
      _logger.info('URL: $path');
      _logger.info('Request Data: $data');

      final response = await _dio.put(path, data: data);

      _logger.info('=== PUT Request Successful ===');
      _logger.info('Status Code: ${response.statusCode}');
      _logger.info('Response Headers: ${response.headers}');
      _logger.info('Response Data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      _logger.severe('=== PUT Request Failed ===');
      _logger.severe('URL: $path');
      _logger.severe('Request Data: $data');
      _logger.severe('Error: ${e.message}');
      _logger.severe('Response: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      _logger.info('=== Starting DELETE Request ===');
      _logger.info('URL: $path');

      final response = await _dio.delete(path);

      _logger.info('=== DELETE Request Successful ===');
      _logger.info('Status Code: ${response.statusCode}');
      _logger.info('Response Headers: ${response.headers}');
      _logger.info('Response Data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      _logger.severe('=== DELETE Request Failed ===');
      _logger.severe('URL: $path');
      _logger.severe('Error: ${e.message}');
      _logger.severe('Response: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    _logger.severe('=== Error Handler ===');
    _logger.severe('Error Type: ${error.type}');
    _logger.severe('Error Message: ${error.message}');
    _logger.severe('Request Options: ${error.requestOptions.toString()}');
    _logger.severe('Response Status: ${error.response?.statusCode}');
    _logger.severe('Response Data: ${error.response?.data}');

    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Server error: ${error.response!.statusCode}';
    }
    return error.message ?? 'Network error occurred';
  }

  void setToken(String? token) {
    _token = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  // Captain Authentication
  Future<Map<String, dynamic>> registerCaptain(
      Map<String, dynamic> data) async {
    try {
      _logger.info('=== Starting Captain Registration ===');
      _logger.info('Registration data: $data');

      // Format the request data according to the API requirements
      final requestData = {
        'fullname': {
          'firstname': data['firstname'],
          'lastname': data['lastname'],
        },
        'email': data['email'],
        'password': data['password'],
      };

      _logger.info('Sending request to: ${ApiConfig.captainRegister}');
      _logger.info('Request data: $requestData');

      final response = await _dio.post(
        ApiConfig.captainRegister,
        data: requestData,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          contentType: 'application/json',
        ),
      );

      _logger.info('Response received:');
      _logger.info('  Status code: ${response.statusCode}');
      _logger.info('  Headers: ${response.headers}');
      _logger.info('  Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }

      final errorMsg = response.data['message'] ??
          response.data['error'] ??
          'Registration failed';
      throw errorMsg;
    } on DioException catch (e) {
      _logger.severe('Registration error: ${e.message}');
      _logger.severe('Response data: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      _logger.severe('Unexpected error during registration: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> validateOtp(String email, String otp) async {
    try {
      _logger.info('=== Starting OTP Validation ===');
      _logger.info('Raw input values:');
      _logger.info('  Email: "$email"');
      _logger.info('  OTP: "$otp"');

      // Input validation and sanitization
      final sanitizedEmail = email.trim();
      final sanitizedOtp = otp.trim();

      _logger.info('Sanitized values (after trim):');
      _logger.info('  Email: "$sanitizedEmail"');
      _logger.info('  OTP: "$sanitizedOtp"');
      _logger.info('  Email length: ${sanitizedEmail.length}');
      _logger.info('  OTP length: ${sanitizedOtp.length}');

      if (sanitizedEmail.isEmpty || sanitizedOtp.isEmpty) {
        _logger.warning('Validation failed: Empty email or OTP');
        throw 'Email and OTP are required';
      }

      // Prepare request data
      final requestData = {
        'email': sanitizedEmail,
        'otp': sanitizedOtp,
      };

      _logger.info('Sending request to: ${ApiConfig.captainValidateOtp}');
      _logger.info('Request data: $requestData');

      // Make the request
      final response = await _dio.post(
        ApiConfig.captainValidateOtp,
        data: requestData,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          contentType: 'application/json',
        ),
      );

      _logger.info('Response received:');
      _logger.info('  Status code: ${response.statusCode}');
      _logger.info('  Headers: ${response.headers}');
      _logger.info('  Response data: ${response.data}');

      // Handle error responses
      if (response.statusCode != 200) {
        final errorMsg = response.data['message'] ??
            response.data['error'] ??
            'OTP validation failed';
        _logger.warning('Server returned error response:');
        _logger.warning('  Status code: ${response.statusCode}');
        _logger.warning('  Error message: $errorMsg');
        _logger.warning('  Full response: ${response.data}');
        throw errorMsg;
      }

      // Parse successful response
      final responseData = response.data;
      _logger.info('Parsing response data type: ${responseData.runtimeType}');

      if (responseData is Map<String, dynamic>) {
        _logger.info('Response data keys: ${responseData.keys.join(', ')}');
        return responseData;
      }

      throw 'Invalid response format';
    } on DioException catch (e) {
      _logger.severe('DioException during OTP validation:');
      _logger.severe('  Error type: ${e.type}');
      _logger.severe('  Error message: ${e.message}');
      _logger.severe('  Response data: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      _logger.severe('Unexpected error during OTP validation: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginCaptain(
      String email, String password) async {
    try {
      _logger.info('Attempting to login captain with email: $email');

      final requestData = {
        'email': email,
        'password': password,
      };

      final response = await post(ApiConfig.captainLogin, requestData);
      _logger.info('Login response received: $response');

      if (response is Map<String, dynamic>) {
        if (response.containsKey('token')) {
          _logger.info('Login successful. Setting auth token.');
          final token = response['token'] as String;
          setToken(token);
          return response;
        }
      }

      _logger.warning('Unexpected login response format: $response');
      throw 'Invalid login response format from server';
    } catch (e) {
      _logger.severe('Error during login: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCaptainProfile() async {
    _logger.info('Fetching captain profile');
    final response = await get(ApiConfig.captainProfile);
    return Map<String, dynamic>.from(response['captain']);
  }

  Future<void> logoutCaptain() async {
    _logger.info('Logging out captain');
    await get(ApiConfig.captainLogout);
  }

  // Maps
  Future<Map<String, dynamic>> getCoordinates(String address) async {
    _logger.info('Getting coordinates for address: $address');
    final response = await get(ApiConfig.getCoordinate,
        queryParameters: {'address': address});
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> getDistanceTime(
      String origin, String destination) async {
    _logger.info('Getting distance and time between $origin and $destination');
    final response = await get(ApiConfig.getDistanceTime,
        queryParameters: {'origin': origin, 'destination': destination});
    return Map<String, dynamic>.from(response);
  }

  Future<List<String>> getLocationSuggestions(String query) async {
    _logger.info('Getting location suggestions for query: $query');
    final response =
        await get(ApiConfig.getSuggestions, queryParameters: {'query': query});
    return List<String>.from(response['suggestions']);
  }

  // Auto Stands
  Future<Map<String, dynamic>> createAutoStand(
      String standname, double latitude, double longitude) async {
    _logger.info('Creating auto stand: $standname');
    final response = await post(ApiConfig.createAutoStand, {
      'standname': standname,
      'location': {'latitude': latitude, 'longitude': longitude}
    });
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> updateAutoStand(
      String id, String standname, double latitude, double longitude) async {
    _logger.info('Updating auto stand: $id');
    final response = await put('${ApiConfig.updateAutoStand}/$id', {
      'standname': standname,
      'location': {'latitude': latitude, 'longitude': longitude}
    });
    return Map<String, dynamic>.from(response);
  }

  Future<void> deleteAutoStand(String id) async {
    _logger.info('Deleting auto stand: $id');
    await delete('${ApiConfig.deleteAutoStand}/$id');
  }

  Future<Map<String, dynamic>> requestJoinAutoStand(
      String standId, String joiningCaptainId) async {
    _logger.info('Requesting to join auto stand: $standId');
    final response = await post(ApiConfig.addMember,
        {'standId': standId, 'joiningCaptainId': joiningCaptainId});
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> respondToJoinRequest(
      String standId, String joiningCaptainId, String response) async {
    _logger.info('Responding to join request for stand: $standId');
    final resp = await post(ApiConfig.respondToRequest, {
      'standId': standId,
      'joiningCaptainId': joiningCaptainId,
      'response': response
    });
    return Map<String, dynamic>.from(resp);
  }

  Future<List<Map<String, dynamic>>> searchAutoStands(
      String name, double captainLat, double captainLng) async {
    _logger.info('Searching auto stands with name: $name');
    final response = await post(ApiConfig.searchAutoStands,
        {'name': name, 'captainLat': captainLat, 'captainLng': captainLng});
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAutoStandMembers(String standId) async {
    _logger.info('Getting members for auto stand: $standId');
    final response = await get('${ApiConfig.getMembers}/$standId');
    return List<Map<String, dynamic>>.from(response['members']);
  }

  Future<Map<String, dynamic>> toggleQueueStatus(
      String autostandId,
      String driverId,
      bool toggleStatus,
      Map<String, double> currentLocation) async {
    _logger.info('Toggling queue status for driver: $driverId');
    final response = await put('${ApiConfig.toggleQueue}/$autostandId', {
      'driverId': driverId,
      'toggleStatus': toggleStatus,
      'currentLocation': currentLocation
    });
    return Map<String, dynamic>.from(response);
  }

  // Rides
  Future<Map<String, dynamic>> getRidePrice(
      String pickup, String dropoff) async {
    _logger.info('Getting ride price from $pickup to $dropoff');
    final response =
        await post(ApiConfig.getPrice, {'pickup': pickup, 'dropoff': dropoff});
    return Map<String, dynamic>.from(response['data']);
  }

  Future<List<Map<String, dynamic>>> getCaptainRideHistory() async {
    _logger.info('Fetching captain ride history');
    final response = await get(ApiConfig.captainRideHistory);
    return List<Map<String, dynamic>>.from(response['data']);
  }

  // Request Ride - Matches /rides/request-ride endpoint
  Future<Map<String, dynamic>> requestRide(
      Map<String, dynamic> rideData) async {
    try {
      _logger.info('=== Starting Ride Request ===');

      // Validate required fields
      if (!rideData.containsKey('pickup') ||
          !rideData.containsKey('dropoff') ||
          !rideData.containsKey('price')) {
        throw 'Pickup location, dropoff location, and price are required';
      }

      // Ensure pickup and dropoff have required coordinates
      final pickup = rideData['pickup'] as Map<String, dynamic>;
      final dropoff = rideData['dropoff'] as Map<String, dynamic>;

      if (!pickup.containsKey('ltd') ||
          !pickup.containsKey('lng') ||
          !dropoff.containsKey('ltd') ||
          !dropoff.containsKey('lng')) {
        throw 'Pickup and dropoff must include latitude (ltd) and longitude (lng)';
      }

      // Format request data according to API requirements
      final requestData = {
        'pickup': {'ltd': pickup['ltd'], 'lng': pickup['lng']},
        'dropoff': {'ltd': dropoff['ltd'], 'lng': dropoff['lng']},
        'price': rideData['price']
      };

      _logger.info('Request data: $requestData');

      final response = await post(ApiConfig.requestRide, requestData);
      _logger.info('Ride request response: $response');

      return Map<String, dynamic>.from(response);
    } catch (e) {
      _logger.severe('Request ride error: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> verifyRideOTP({
    required String rideId,
    required String otp,
    required Map<String, dynamic> location,
  }) async {
    _logger.info('Verifying ride OTP: $rideId');
    final response = await post(ApiConfig.verifyRideOtp, {
      'rideId': rideId,
      'otp': otp,
      'location': location,
    });
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> completeRide({
    required String rideId,
    required Map<String, dynamic> location,
  }) async {
    _logger.info('Completing ride: $rideId');
    final response = await post(ApiConfig.completeRide, {
      'rideId': rideId,
      'location': location,
    });
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> acceptRide(String rideId) async {
    try {
      final response = await _dio.post('/rides/$rideId/accept');
      return response.data;
    } catch (e) {
      _logger.severe('Failed to accept ride: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectRide(String rideId) async {
    try {
      final response = await _dio.post('/rides/$rideId/reject');
      return response.data;
    } catch (e) {
      _logger.severe('Failed to reject ride: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRideHistory() async {
    _logger.info('Getting ride history');
    final response = await get(ApiConfig.rideHistory);
    return List<Map<String, dynamic>>.from(response['rides']);
  }

  Future<Map<String, dynamic>> getRouteDetails(
      Map<String, String> params) async {
    _logger.info('Getting route details');
    final response =
        await get(ApiConfig.getRouteDetails, queryParameters: params);
    return Map<String, dynamic>.from(response);
  }
}
