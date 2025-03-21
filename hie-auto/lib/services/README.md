# Hello Auto API and Socket Services

This directory contains the API and Socket services for the Hello Auto application. These services are designed to work together to provide a seamless experience for users and captains (drivers).

## API Service

The `ApiService` provides methods for interacting with the Hello Auto backend API. It handles authentication, user management, ride management, and more.

### Key Features

- Authentication (login, register, OTP verification)
- User and Captain profile management
- Ride booking and management
- Auto stand operations
- Map services (coordinates, distance, suggestions)
- Payment processing

### Usage

```dart
import 'package:hie_auto/services/services.dart';

// Initialize the API service (singleton, automatically created)
final apiService = ApiService();

// User registration
await apiService.registerUser(
  email: 'user@example.com',
  password: 'securepassword',
  firstName: 'John',
  lastName: 'Doe',
);

// OTP validation
final otpResult = await apiService.validateOTP(
  email: 'user@example.com',
  otp: '123456',
);

// Login
final loginResult = await ApiService.loginUser(
  'user@example.com',
  'securepassword',
);

// Book a ride
final rideResult = await apiService.bookRide(
  pickupLocation: 'City Center',
  dropLocation: 'Airport',
  pickupLat: 9.9312,
  pickupLng: 76.2673,
  dropLat: 9.9701,
  dropLng: 76.3077,
  distance: '15.2 km',
  duration: '32 min',
  fare: 250.0,
);
```

## Socket Service

The `SocketService` provides real-time communication with the Hello Auto backend. It handles events such as ride status updates, location sharing, notifications, and more.

### Key Features

- Real-time ride status updates
- Location sharing
- OTP generation notifications
- Auto stand join request notifications
- General notifications

### Usage

```dart
import 'package:hie_auto/services/services.dart';

// Initialize the socket service (singleton, automatically created)
final socketService = SocketService();

// Initialize with user ID (after login)
await socketService.initialize('user_id_123');

// Connect to the socket server
await socketService.connect();

// Set up event handlers
socketService.onRideAccepted = (data) {
  print('Ride accepted: ${data['rideId']}');
  // Update UI or navigate to ride tracking screen
};

socketService.onCaptainLocation = (data) {
  print('Captain location: ${data['location']}');
  // Update the captain's location on the map
};

socketService.onOTPGenerated = (data) {
  print('OTP generated: ${data['otp']}');
  // Show OTP to the user
};

// Start sharing location for a ride
socketService.startLocationSharing(
  'ride_id_123',
  {'lat': 9.9312, 'lng': 76.2673},
);

// Update location during a ride
socketService.updateCurrentLocation(
  {'lat': 9.9315, 'lng': 76.2680},
);

// Emit ride cancellation
socketService.emitRideCancellation(
  'ride_id_123',
  'Changed my plans',
);

// Disconnect when done
await socketService.disconnect();
```

## Combined Usage Example

Here's an example of how to use both services together in a typical ride booking flow:

```dart
import 'package:hie_auto/services/services.dart';

class RideBookingManager {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  
  // Initialize after user login
  Future<void> initialize(String userId) async {
    await _socketService.initialize(userId);
    await _socketService.connect();
    
    // Set up socket event handlers
    _socketService.onRideAccepted = _handleRideAccepted;
    _socketService.onCaptainLocation = _handleCaptainLocation;
    _socketService.onOTPGenerated = _handleOTPGenerated;
  }
  
  // Book a ride
  Future<void> bookRide(Map<String, dynamic> rideDetails) async {
    try {
      // First, get the ride price
      final priceResult = await _apiService.getRidePrice(
        pickup: '${rideDetails['pickupLng']},${rideDetails['pickupLat']}',
        dropoff: '${rideDetails['dropLng']},${rideDetails['dropLat']}',
      );
      
      // Book the ride using the API
      final bookingResult = await _apiService.bookRide(
        pickupLocation: rideDetails['pickupAddress'],
        dropLocation: rideDetails['dropAddress'],
        pickupLat: rideDetails['pickupLat'],
        pickupLng: rideDetails['pickupLng'],
        dropLat: rideDetails['dropLat'],
        dropLng: rideDetails['dropLng'],
        distance: priceResult['data']['distance'],
        duration: priceResult['data']['duration'],
        fare: double.parse(priceResult['data']['price']),
      );
      
      // Emit the ride request through the socket for faster matching
      _socketService.emitRideRequest({
        'rideId': bookingResult['data']['rideId'],
        'pickup': {
          'lat': rideDetails['pickupLat'],
          'lng': rideDetails['pickupLng'],
        },
        'dropoff': {
          'lat': rideDetails['dropLat'],
          'lng': rideDetails['dropLng'],
        },
        'price': double.parse(priceResult['data']['price']),
      });
      
      // Start location sharing
      _socketService.startLocationSharing(
        bookingResult['data']['rideId'],
        {
          'lat': rideDetails['pickupLat'],
          'lng': rideDetails['pickupLng'],
        },
      );
      
      return bookingResult;
    } catch (e) {
      print('Error booking ride: $e');
      rethrow;
    }
  }
  
  // Handle socket events
  void _handleRideAccepted(Map<String, dynamic> data) {
    print('Ride accepted by captain: ${data['captainId']}');
    // Update UI, notify user, etc.
  }
  
  void _handleCaptainLocation(Map<String, dynamic> data) {
    print('Captain location updated: ${data['location']}');
    // Update captain marker on map
  }
  
  void _handleOTPGenerated(Map<String, dynamic> data) {
    print('Ride OTP generated: ${data['otp']}');
    // Display OTP to user for verification
  }
  
  // Clean up
  Future<void> dispose() async {
    await _socketService.disconnect();
  }
}
```

## Backdoor Admin Access

For testing purposes, a backdoor admin access is available:

```dart
// Admin credentials
const email = 'admin@test.com';
const password = 'admin123';

// Login using backdoor
final result = await ApiService.loginUser(email, password);
// No server call is made, login is simulated
```

## Error Handling

Both services include comprehensive error handling. API errors are thrown as exceptions, while socket errors are logged and can be handled through the `onError` callback.

## Logging

Both services use the `Logger` package for logging. You can monitor logs for debugging purposes.

```dart
// Set up a custom logger configuration if needed
Logger.level = Level.debug;
``` 