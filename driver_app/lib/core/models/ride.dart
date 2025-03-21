import 'package:google_maps_flutter/google_maps_flutter.dart';

extension MapLocationExtension on Map<String, dynamic> {
  LatLng toLatLng() {
    final lat = (this['latitude'] ?? this['ltd'] as num).toDouble();
    final lng = (this['longitude'] ?? this['lng'] as num).toDouble();
    return LatLng(lat, lng);
  }
}

class Ride {
  final String id;
  final String userId;
  final String? captainId;
  final Map<String, double> pickup;
  final Map<String, double> dropoff;
  final double price;
  final String status;
  final String? otp;
  final double? rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Ride({
    required this.id,
    required this.userId,
    this.captainId,
    required this.pickup,
    required this.dropoff,
    required this.price,
    required this.status,
    this.otp,
    this.rating,
    this.createdAt,
    this.updatedAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String,
      userId: json['userId'] as String,
      captainId: json['captainId']?.toString(),
      pickup: {
        'lat': (json['pickup']['lat'] as num).toDouble(),
        'lng': (json['pickup']['lng'] as num).toDouble(),
      },
      dropoff: {
        'lat': (json['dropoff']['lat'] as num).toDouble(),
        'lng': (json['dropoff']['lng'] as num).toDouble(),
      },
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
      otp: json['otp']?.toString(),
      rating: json['rating']?.toDouble(),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'captainId': captainId,
      'pickup': pickup,
      'dropoff': dropoff,
      'price': price,
      'status': status,
      'otp': otp,
      'rating': rating,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  LatLng get pickupLatLng => LatLng(pickup['lat']!, pickup['lng']!);
  LatLng get dropoffLatLng => LatLng(dropoff['lat']!, dropoff['lng']!);

  Ride copyWith({
    String? id,
    String? userId,
    String? captainId,
    Map<String, double>? pickup,
    Map<String, double>? dropoff,
    double? price,
    String? status,
    String? otp,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ride(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      captainId: captainId ?? this.captainId,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      price: price ?? this.price,
      status: status ?? this.status,
      otp: otp ?? this.otp,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Ride{id: $id, status: $status, price: $price}';
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['ltd'] ?? json['latitude'] as num).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ltd': latitude,
      'lng': longitude,
    };
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}
