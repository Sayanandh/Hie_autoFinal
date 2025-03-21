import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  // Logger for debugging
  final Logger _logger = Logger();

  // Socket server URL
  static const String _baseUrl = 'https://helloauto-20gp.onrender.com';

  // Socket instance
  io.Socket? _socket;

  // User/Captain ID
  String? userId;

  // Current ride ID
  String? rideId;

  // Current location
  Map<String, double>? currentLocation;

  // Timer for location updates
  Timer? locationTimer;

  // Initialization status
  bool _isInitialized = false;

  // Reconnection attempts counter
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Getters
  io.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;
  bool get isInitialized => _isInitialized;

  // Event callbacks
  Function(Map<String, dynamic>)? onRideAccepted;
  Function(Map<String, dynamic>)? onCaptainLocation;
  Function(Map<String, dynamic>)? onOTPGenerated;
  Function(Map<String, dynamic>)? onRideCompleted;
  Function(Map<String, dynamic>)? onRideCancelled;
  Function(Map<String, dynamic>)? onRideNotFound;
  Function(Map<String, dynamic>)? onRideError;
  Function(Map<String, dynamic>)? onNotification;
  Function(Map<String, dynamic>)? onRequestNotification;
  Function(Map<String, dynamic>)? onResponseNotification;
  Function(Map<String, dynamic>)? onError;
  Function()? onConnect;
  Function()? onDisconnect;

  /// Initialize the socket service with a user ID
  /// This only sets up the service but does not connect to the socket
  Future<void> initialize(String id) async {
    if (_isInitialized) {
      _logger.w('Socket service already initialized');
      return;
    }

    try {
      userId = id;
      _isInitialized = true;
      _logger.i('Socket service initialized with user ID: $id');
    } catch (e) {
      _isInitialized = false;
      _logger.e('Socket initialization error: $e');
      rethrow;
    }
  }

  /// Connect to the socket server after initialization
  Future<void> connect() async {
    if (!_isInitialized) {
      throw Exception(
          'Socket service not initialized. Call initialize() first.');
    }

    if (socket?.connected ?? false) {
      _logger.w('Socket already connected');
      return;
    }

    try {
      final token = await _getToken();
      if (token == null) {
        _logger.w('No token available for socket connection');
        return;
      }

      _socket = io.io(_baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token},
      });

      _setupSocketListeners();
      _socket?.connect();
      _logger.i('Socket connection initiated');
    } catch (e) {
      _isInitialized = false;
      _logger.e('Socket connection error: $e');
      rethrow;
    }
  }

  /// Set up all socket event listeners
  void _setupSocketListeners() {
    if (socket == null) return;

    // Connection events
    socket!.onConnect((_) {
      _logger.i('✅ Socket connected: ${socket!.id}');
      _reconnectAttempts =
          0; // Reset reconnect attempts on successful connection
      _registerUser();
      if (onConnect != null) onConnect!();
    });

    socket!.onDisconnect((_) {
      _logger.w('⚠ Socket disconnected');
      _stopLocationSharing();
      if (onDisconnect != null) onDisconnect!();
    });

    socket!.onConnectError((error) {
      _logger.e('❌ Socket connection error: $error');
      _handleReconnect();
    });

    socket!.onError((error) {
      _logger.e('❌ Socket error: $error');
      _handleReconnect();
      if (onError != null) onError!({"message": error.toString()});
    });

    // User-specific events

    // For users: When a ride is accepted by a captain
    socket!.on('ride_accepted', (data) {
      _logger.i('📣 Ride accepted event received: $data');
      if (onRideAccepted != null) onRideAccepted!(data);
    });

    // For users: Captain's location updates
    socket!.on('captain_location', (data) {
      _logger.i('📍 Captain location update received: $data');
      if (onCaptainLocation != null) onCaptainLocation!(data);
    });

    // For users: OTP generated for ride verification
    socket!.on('otp_generated', (data) {
      _logger.i('🔢 OTP generated event received: $data');
      if (onOTPGenerated != null) onOTPGenerated!(data);
    });

    // For users: Ride completed
    socket!.on('ride_completed', (data) {
      _logger.i('✅ Ride completed event received: $data');
      if (onRideCompleted != null) onRideCompleted!(data);
    });

    // For users: Ride cancelled
    socket!.on('ride_cancelled', (data) {
      _logger.i('❌ Ride cancelled event received: $data');
      if (onRideCancelled != null) onRideCancelled!(data);
    });

    // For users: General notifications
    socket!.on('notification', (data) {
      _logger.i('📱 Notification received: $data');
      if (onNotification != null) onNotification!(data);
    });

    // Auto Stand related events

    // For captains: Request notification for joining auto stand
    socket!.on('request_notification', (data) {
      _logger.i('🚕 Auto stand join request notification received: $data');
      if (onRequestNotification != null) onRequestNotification!(data);
    });

    // For users: Response notification for auto stand join request
    socket!.on('response_notification', (data) {
      _logger.i('📩 Auto stand join response notification received: $data');
      if (onResponseNotification != null) onResponseNotification!(data);
    });
  }

  /// Handle socket reconnection logic
  void _handleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      _logger.i(
          'Attempting to reconnect (attempt $_reconnectAttempts of $_maxReconnectAttempts)');
      Future.delayed(Duration(seconds: _reconnectAttempts), () {
        if (!isConnected) {
          socket?.connect();
        }
      });
    } else {
      _logger.e('Max reconnection attempts reached');
      disconnect();
    }
  }

  /// Register user with the socket server
  void _registerUser() {
    if (socket == null || !isConnected || userId == null) return;

    try {
      _logger.i('Registering user with socket server: $userId');
      socket!.emit('register_user', {'userId': userId});
    } catch (e) {
      _logger.e('Failed to register user with socket: $e');
    }
  }

  /// Start sharing user location with the socket server
  Future<void> startLocationSharing(
      String currentRideId, Map<String, dynamic> location) async {
    if (socket == null || !isConnected) {
      _logger.e('Cannot start location sharing: Socket not connected');
      return;
    }

    rideId = currentRideId;
    currentLocation = location as Map<String, double>?;

    // Cancel existing timer if any
    _stopLocationSharing();

    // Create a new timer to send location updates
    locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (currentLocation != null && rideId != null) {
        emitLocationUpdate(currentLocation! as Map<String, dynamic>);
      }
    });

    // Send initial location update
    if (currentLocation != null) {
      emitLocationUpdate(location);
    }

    _logger.i('Started location sharing for ride: $rideId');
  }

  /// Stop sharing user location
  void _stopLocationSharing() {
    locationTimer?.cancel();
    locationTimer = null;
    _logger.i('Stopped location sharing');
  }

  /// Update current location
  void updateCurrentLocation(Map<String, dynamic> location) {
    currentLocation = location as Map<String, double>?;
    if (locationTimer != null && locationTimer!.isActive && rideId != null) {
      emitLocationUpdate(location);
    }
  }

  /// Disconnect from the socket server
  Future<void> disconnect() async {
    _stopLocationSharing();

    if (_socket != null) {
      _logger.i('Disconnecting socket');
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }

    _isInitialized = false;
    userId = null;
    rideId = null;
    currentLocation = null;
    _logger.i('Socket disconnected and resources cleaned up');
  }

  /// Dispose method to clean up resources
  Future<void> dispose() async {
    _logger.i('Disposing socket service');
    await disconnect();
  }

  // =================== EMIT METHODS ===================

  /// Emit user location update
  void emitLocationUpdate(Map<String, dynamic> location) {
    if (socket == null || !isConnected || rideId == null) {
      _logger.e(
          'Cannot emit location update: Socket not connected or no active ride');
      return;
    }

    try {
      socket!.emit('location_update_user_$rideId', {
        'rideId': rideId,
        'location': location,
      });
      _logger.i('Location update emitted');
    } catch (e) {
      _logger.e('Failed to emit location update: $e');
    }
  }

  /// Emit ride cancellation event
  void emitRideCancellation(String rideId, String reason) {
    if (socket == null || !isConnected) {
      _logger.e('Cannot emit ride cancellation: Socket not connected');
      return;
    }

    try {
      socket!.emit('ride_cancelled', {
        'rideId': rideId,
        'reason': reason,
      });
      _logger.i('Ride cancellation emitted');
    } catch (e) {
      _logger.e('Failed to emit ride cancellation: $e');
    }
  }

  /// Emit ride completion event
  void emitRideCompletion(String rideId, Map<String, dynamic> rideData) {
    if (socket == null || !isConnected) {
      _logger.e('Cannot emit ride completion: Socket not connected');
      return;
    }

    try {
      socket!.emit('ride_completed', {
        'rideId': rideId,
        'data': rideData,
      });
      _logger.i('Ride completion emitted');
    } catch (e) {
      _logger.e('Failed to emit ride completion: $e');
    }
  }

  /// Emit OTP verification
  void emitOTPVerification(String rideId, String otp) {
    if (socket == null || !isConnected) {
      _logger.e('Cannot emit OTP verification: Socket not connected');
      return;
    }

    try {
      final otpData = {
        'rideId': rideId,
        'otp': otp,
        'userId': userId,
      };

      _logger.i('Emitting OTP verification: $otpData');
      socket!.emit('verify_otp', otpData);
    } catch (e) {
      _logger.e('Failed to emit OTP verification: $e');
    }
  }

  /// Emit ride request
  void emitRideRequest(Map<String, dynamic> rideDetails) {
    if (socket == null || !isConnected) {
      _logger.e('Cannot emit ride request: Socket not connected');
      return;
    }

    try {
      // Make sure userId is included in the ride details
      rideDetails['userId'] = userId;

      _logger.i('Emitting ride request: $rideDetails');
      socket!.emit('request_ride', rideDetails);
    } catch (e) {
      _logger.e('Failed to emit ride request: $e');
    }
  }

  /// Emit queue status toggle
  void emitQueueToggle(
      String autostandId, bool toggleStatus, Map<String, double> location) {
    if (socket == null || !isConnected) {
      _logger.e('Cannot emit queue toggle: Socket not connected');
      return;
    }

    try {
      final toggleData = {
        'autostandId': autostandId,
        'driverId': userId,
        'toggleStatus': toggleStatus,
        'currentLocation': location,
      };

      _logger.i('Emitting queue toggle: $toggleData');
      socket!.emit('toggle_queue', toggleData);
    } catch (e) {
      _logger.e('Failed to emit queue toggle: $e');
    }
  }

  /// Emit join request response
  void emitJoinRequestResponse(
      String standId, String joiningCaptainId, String response) {
    if (socket == null || !isConnected) {
      _logger.e('Cannot emit join request response: Socket not connected');
      return;
    }

    try {
      final responseData = {
        'standId': standId,
        'joiningCaptainId': joiningCaptainId,
        'response': response,
      };

      _logger.i('Emitting join request response: $responseData');
      socket!.emit('respond_to_request', responseData);
    } catch (e) {
      _logger.e('Failed to emit join request response: $e');
    }
  }

  /// Emit join request
  void emitJoinRequest(String standId) {
    if (socket == null || !isConnected) {
      _logger.e('Cannot emit join request: Socket not connected');
      return;
    }

    try {
      final requestData = {
        'standId': standId,
        'joiningCaptainId': userId,
      };

      _logger.i('Emitting join request: $requestData');
      socket!.emit('request_to_join', requestData);
    } catch (e) {
      _logger.e('Failed to emit join request: $e');
    }
  }

  /// Emit ride response
  void emitRideResponse(String rideId, bool accepted) {
    if (socket == null || !isConnected) {
      _logger.e('Cannot emit ride response: Socket not connected');
      return;
    }

    try {
      socket!.emit('ride_response', {
        'rideId': rideId,
        'accepted': accepted,
      });
      _logger.i('Ride response emitted: ${accepted ? 'accepted' : 'rejected'}');
    } catch (e) {
      _logger.e('Failed to emit ride response: $e');
    }
  }

  // Get token from SharedPreferences
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      _logger.e('Error getting token: $e');
      return null;
    }
  }

  void listenForRideAccepted(Function(Map<String, dynamic>) callback) {
    onRideAccepted = callback;
  }

  void listenForOtp(Function(Map<String, dynamic>) callback) {
    onOTPGenerated = callback;
  }

  void listenForRideNotFound(Function(Map<String, dynamic>) callback) {
    onRideNotFound = callback;
  }

  void listenForRideError(Function(Map<String, dynamic>) callback) {
    onRideError = callback;
  }

  void listenForCaptainLocation(
      String rideId, Function(Map<String, dynamic>) callback) {
    this.rideId = rideId;
    onCaptainLocation = callback;
  }

  void sendUserLocation(String rideId, Map<String, dynamic> location) {
    emitLocationUpdate(location);
  }
}
