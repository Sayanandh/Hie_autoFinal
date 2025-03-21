class ApiConfig {
  // Base URL for the API server
  static const String baseUrl = 'https://helloauto-20gp.onrender.com';

  // Socket URL for real-time communication
  static const String socketUrl = 'https://helloauto-20gp.onrender.com';

  // Captain Authentication Endpoints
  static const String captainRegister = '/api/users/register';
  static const String captainValidateOtp = '/api/users/validate-otp';
  static const String captainLogin = '/api/users/login';
  static const String captainProfile = '/api/users/profile';
  static const String captainLogout = '/api/users/logout';

  // Maps Endpoints
  static const String getCoordinate = '/api/maps/geocode';
  static const String getDistanceTime = '/api/maps/distance-time';
  static const String getSuggestions = '/api/maps/suggestions';
  static const String getRouteDetails = '/api/maps/route';

  // Auto Stands Endpoints
  static const String searchAutoStands = '/api/auto-stands/search';
  static const String createAutoStand = '/api/auto-stands';
  static const String updateAutoStand = '/api/auto-stands';
  static const String deleteAutoStand = '/api/auto-stands';
  static const String addMember = '/api/auto-stands/members';
  static const String respondToRequest = '/api/auto-stands/requests';
  static const String removeMember = '/api/auto-stands/remove-member';
  static const String getMembers = '/api/auto-stands/members';
  static const String toggleQueue = '/api/auto-stands/queue';

  // Rides Endpoints
  static const String getPrice = '/api/rides/price';
  static const String requestRide = '/api/rides/request';
  static const String verifyRideOtp = '/api/rides/verify-otp';
  static const String completeRide = '/api/rides/complete';
  static const String rideHistory = '/api/rides/history';
  static const String captainRideHistory = '/api/rides/captain/history';

  // Timeout durations (in milliseconds)
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
