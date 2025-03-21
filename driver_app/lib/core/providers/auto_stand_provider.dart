import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'package:logging/logging.dart';
import 'package:geolocator/geolocator.dart';

class AutoStand {
  final String id;
  final String name;
  final Map<String, double> location;
  final List<String> members;
  final bool isInQueue;
  final double? distance;

  AutoStand({
    required this.id,
    required this.name,
    required this.location,
    required this.members,
    this.isInQueue = false,
    this.distance,
  });

  factory AutoStand.fromJson(Map<String, dynamic> json) {
    return AutoStand(
      id: json['_id'],
      name: json['standname'],
      location: {
        'lat': json['location']['ltd'].toDouble(),
        'lng': json['location']['lng'].toDouble(),
      },
      members: List<String>.from(json['members']),
      isInQueue: json['isInQueue'] ?? false,
      distance: json['distance']?.toDouble(),
    );
  }
}

class AutoStandProvider with ChangeNotifier {
  final _logger = Logger('AutoStandProvider');
  final ApiService _apiService;
  final SocketService _socketService;

  List<AutoStand> _nearbyStands = [];
  AutoStand? _currentStand;
  bool _isLoading = false;
  String? _error;
  bool _isInQueue = false;

  AutoStandProvider(this._apiService, this._socketService) {
    _setupSocketListeners();
  }

  // Getters
  List<AutoStand> get nearbyStands => _nearbyStands;
  AutoStand? get currentStand => _currentStand;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInQueue => _isInQueue;

  void _setupSocketListeners() {
    _socketService.on('request_notification', (data) {
      _logger.info('Received auto stand request notification: $data');
      // Handle join request notification
      notifyListeners();
    });

    _socketService.on('response_notification', (data) {
      _logger.info('Received auto stand response notification: $data');
      // Handle response to join request
      _handleJoinResponse(data);
    });

    _socketService.on('queue_update', (data) {
      _logger.info('Received queue update: $data');
      _handleQueueUpdate(data);
    });
  }

  void _handleJoinResponse(Map<String, dynamic> data) {
    final standId = data['standId'];
    final response = data['response'];

    if (response == 'accept') {
      // Update current stand
      _loadAutoStandDetails(standId);
    }
    notifyListeners();
  }

  void _handleQueueUpdate(Map<String, dynamic> data) {
    if (_currentStand?.id == data['autostandId']) {
      _isInQueue = data['isInQueue'] ?? false;
      notifyListeners();
    }
  }

  Future<void> searchAutoStands(String query) async {
    try {
      _setLoading(true);
      _error = null;

      Position position = await Geolocator.getCurrentPosition();
      
      final response = await _apiService.searchAutoStands(
        query,
        position.latitude,
        position.longitude,
      );

      _nearbyStands = response.map((stand) => AutoStand.fromJson(stand)).toList();
    } catch (e) {
      _error = e.toString();
      _logger.severe('Failed to search auto stands: $_error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> requestJoinAutoStand(String standId) async {
    try {
      _setLoading(true);
      _error = null;

      await _apiService.requestJoinAutoStand(standId, '');  // captainId from auth
      _logger.info('Join request sent for auto stand: $standId');
    } catch (e) {
      _error = e.toString();
      _logger.severe('Failed to request joining auto stand: $_error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleQueueStatus(bool status) async {
    try {
      if (_currentStand == null) {
        throw 'No auto stand selected';
      }

      _setLoading(true);
      _error = null;

      Position position = await Geolocator.getCurrentPosition();
      
      await _apiService.toggleQueueStatus(
        _currentStand!.id,
        '',  // driverId from auth
        status,
        {
          'lat': position.latitude,
          'lng': position.longitude,
        },
      );

      _isInQueue = status;
      _socketService.emitQueueStatus(_currentStand!.id, status);
    } catch (e) {
      _error = e.toString();
      _logger.severe('Failed to toggle queue status: $_error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadAutoStandDetails(String standId) async {
    try {
      final members = await _apiService.getAutoStandMembers(standId);
      // Update current stand with member details
      notifyListeners();
    } catch (e) {
      _logger.severe('Failed to load auto stand details: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
} 