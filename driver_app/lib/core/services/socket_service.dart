import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/secrets.dart';
import '../config/api_config.dart';
import 'package:logging/logging.dart';
import '../models/ride.dart';
import 'dart:async';

typedef LocationUpdateCallback = void Function(Map<String, dynamic> location);
typedef RideRequestCallback = void Function(Map<String, dynamic> rideRequest);
typedef RideStatusCallback = void Function(
    String status, Map<String, dynamic> data);
typedef NotificationCallback = void Function(
    String message, Map<String, dynamic> data);

class SocketService {
  final _logger = Logger('SocketService');
  late IO.Socket _socket;
  String? _userId;
  String? _userType; // 'driver' or 'user'
  Timer? _reconnectionTimer;
  bool _isReconnecting = false;

  // Callback storage
  final Map<String, List<Function>> _eventHandlers = {};

  // Singleton pattern
  static SocketService? _instance;
  SocketService._() {
    _initializeSocket();
  }

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  bool get isConnected => _socket.connected;

  void initialize(String userId, String userType) {
    _userId = userId;
    _userType = userType;
    _setupSocket();
  }

  void _initializeSocket() {
    _socket = IO.io(ApiConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      _logger.info('Socket connected');
      _isReconnecting = false;
      _reconnectionTimer?.cancel();
    });

    _socket.onDisconnect((_) {
      _logger.info('Socket disconnected');
      _handleReconnection();
    });

    _socket.onConnectError((error) {
      _logger.severe('Socket connection error: $error');
      _handleReconnection();
    });

    _socket.onError((error) {
      _logger.severe('Socket error: $error');
      _handleReconnection();
    });

    _socket.on('location_update', (data) {
      final rideId = data['rideId'];
      if (_eventHandlers.containsKey('location_update_user_$rideId')) {
        for (var handler in _eventHandlers['location_update_user_$rideId']!) {
          try {
            handler(data);
          } catch (e) {
            _logger.severe(
                'Error in event handler for location_update_user_$rideId: $e');
          }
        }
      }
    });

    _socket.on('ride_status_update', (data) {
      final rideId = data['rideId'];
      if (_eventHandlers.containsKey('ride_status_change_$rideId')) {
        for (var handler in _eventHandlers['ride_status_change_$rideId']!) {
          try {
            handler(
                data['status'] as String, data['data'] as Map<String, dynamic>);
          } catch (e) {
            _logger.severe(
                'Error in event handler for ride_status_change_$rideId: $e');
          }
        }
      }
    });

    _socket.on('terminate_location_sharing', (data) {
      final rideId = data['rideId'];
      if (_eventHandlers.containsKey('terminate_location_sharing_$rideId')) {
        for (var handler
            in _eventHandlers['terminate_location_sharing_$rideId']!) {
          try {
            handler(data);
          } catch (e) {
            _logger.severe(
                'Error in event handler for terminate_location_sharing_$rideId: $e');
          }
        }
      }
    });

    _socket.on('ride_request', (data) {
      _logger.info('Received ride request: $data');
      _notifyHandlers('ride_request', data);
    });

    _socket.on('otp_verified', (data) {
      _logger.info('OTP verified: $data');
      _notifyHandlers('otp_verified', data);
    });

    _socket.on('request_notification', (data) {
      _logger.info('Received auto stand request: $data');
      _notifyHandlers('request_notification', data);
    });

    _socket.on('response_notification', (data) {
      _logger.info('Received auto stand response: $data');
      _notifyHandlers('response_notification', data);
    });

    _socket.on('queue_update', (data) {
      _logger.info('Received queue update: $data');
      _notifyHandlers('queue_update', data);
    });
  }

  void _setupSocket() {
    try {
      _socket.connect();
    } catch (e) {
      _logger.severe('Error setting up socket: $e');
      _handleReconnection();
    }
  }

  void _handleReconnection() {
    if (_isReconnecting) return;
    _isReconnecting = true;

    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isConnected && _userId != null) {
        _logger.info('Attempting to reconnect...');
        _setupSocket();
      } else {
        timer.cancel();
        _isReconnecting = false;
      }
    });
  }

  void on(String event, Function handler) {
    _eventHandlers.putIfAbsent(event, () => []).add(handler);
  }

  void _notifyHandlers(String event, dynamic data) {
    if (_eventHandlers.containsKey(event)) {
      for (var handler in _eventHandlers[event]!) {
        try {
          handler(data);
        } catch (e) {
          _logger.severe('Error in event handler for $event: $e');
        }
      }
    }
  }

  void emit(String event, dynamic data) {
    try {
      if (!isConnected) {
        _logger.warning('Socket not connected. Attempting to reconnect...');
        _handleReconnection();
        return;
      }
      _socket.emit(event, data);
      _logger.info('Emitted $event with data: $data');
    } catch (e) {
      _logger.severe('Error emitting event $event: $e');
    }
  }

  // Ride-specific methods
  void onRideRequest(RideRequestCallback handler) {
    on('ride_request', (data) => handler(data as Map<String, dynamic>));
  }

  void onRideStatusChange(RideStatusCallback handler) {
    on(
        'ride_status_change',
        (data) => handler(
            data['status'] as String, data['data'] as Map<String, dynamic>));
  }

  void onNotification(NotificationCallback handler) {
    on(
        'notifications',
        (data) => handler(
            data['message'] as String, data['data'] as Map<String, dynamic>));
  }

  // Location sharing methods
  void startLocationUpdates(String rideId, LocationUpdateCallback handler) {
    _eventHandlers
        .putIfAbsent('location_update_user_$rideId', () => [])
        .add(handler);
    emit('join_ride', {'rideId': rideId});
  }

  void stopLocationUpdates(String rideId) {
    _eventHandlers.remove('location_update_user_$rideId');
    emit('leave_ride', {'rideId': rideId});
  }

  void emitLocationUpdate(String rideId, Map<String, dynamic> location) {
    emit('location_update', {
      'rideId': rideId,
      'location': location,
    });
  }

  // Auto stand methods
  void emitQueueStatus(String autostandId, bool isAvailable) {
    emit('queue_status_update', {
      'autostandId': autostandId,
      'isAvailable': isAvailable,
    });
  }

  void onTerminateLocationSharing(
      String rideId, Function(Map<String, dynamic>) handler) {
    _logger.info(
        'Setting up terminate location sharing handler for ride: $rideId');
    _addEventHandler('terminate_location_sharing_$rideId', handler);
  }

  void disconnect() {
    _reconnectionTimer?.cancel();
    _socket.disconnect();
    _userId = null;
    _userType = null;
    _eventHandlers.clear();
    _isReconnecting = false;
    _logger.info('Socket disconnected and service reset');
  }

  @override
  void dispose() {
    disconnect();
  }

  String? getToken() {
    // TODO: Implement token retrieval from secure storage
    return null;
  }

  void emitDriverLocation(String rideId, Map<String, double> location) {
    _logger.info('Emitting driver location for ride: $rideId');
    _socket.emit('location_update_captain_$rideId', {
      'rideId': rideId,
      'captainLocation': location,
    });
  }

  void onLocationUpdate(String rideId, Function(Map<String, dynamic>) handler) {
    _logger.info('Setting up location update handler for ride: $rideId');
    _addEventHandler('location_update_user_$rideId', handler);
  }

  void startLocationSharing(String rideId) {
    _logger.info('Starting location sharing for ride: $rideId');
    _socket.emit('start_location_sharing', {'rideId': rideId});
  }

  void stopLocationSharing(String rideId) {
    _logger.info('Stopping location sharing for ride: $rideId');
    _socket.emit('terminate_location_sharing', {'rideId': rideId});
  }

  void onRideStatusUpdate(
      String rideId, Function(Map<String, dynamic>) handler) {
    _eventHandlers
        .putIfAbsent('ride_status_change_$rideId', () => [])
        .add(handler);
  }

  void onRequestNotification(Function(Map<String, dynamic>) handler) {
    _logger.info('Setting up request notification handler');
    _addEventHandler('request_notification', handler);
  }

  void onResponseNotification(Function(Map<String, dynamic>) handler) {
    _logger.info('Setting up response notification handler');
    _addEventHandler('response_notification', handler);
  }

  void _addEventHandler(String event, Function handler) {
    _eventHandlers.putIfAbsent(event, () => []).add(handler);
  }
}
