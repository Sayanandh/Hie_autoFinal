class Captain {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final Vehicle vehicle;
  final double rating;
  final String status;
  final bool isUnionMember;
  final DateTime? createdAt;

  Captain({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.vehicle,
    required this.rating,
    required this.status,
    required this.isUnionMember,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory Captain.fromJson(Map<String, dynamic> json) {
    return Captain(
      id: json['_id'],
      firstName: json['fullname']['firstname'],
      lastName: json['fullname']['lastname'],
      email: json['email'],
      vehicle: Vehicle.fromJson(json['vehicle']),
      rating: (json['rating'] ?? 0).toDouble(),
      status: json['status'] ?? 'inactive',
      isUnionMember: json['IsUnionMember'] ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullname': {
        'firstname': firstName,
        'lastname': lastName,
      },
      'email': email,
      'vehicle': vehicle.toJson(),
      'rating': rating,
      'status': status,
      'IsUnionMember': isUnionMember,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Captain copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    Vehicle? vehicle,
    double? rating,
    String? status,
    bool? isUnionMember,
    DateTime? createdAt,
  }) {
    return Captain(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      vehicle: vehicle ?? this.vehicle,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      isUnionMember: isUnionMember ?? this.isUnionMember,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Captain{id: $id, name: $fullName, email: $email, rating: $rating}';
  }
}

class Vehicle {
  final String color;
  final String plate;
  final int capacity;
  final String vehicleType;

  Vehicle({
    required this.color,
    required this.plate,
    required this.capacity,
    required this.vehicleType,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      color: json['color'],
      plate: json['plate'],
      capacity: json['capacity'],
      vehicleType: json['vehicleType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'plate': plate,
      'capacity': capacity,
      'vehicleType': vehicleType,
    };
  }

  Vehicle copyWith({
    String? color,
    String? plate,
    int? capacity,
    String? vehicleType,
  }) {
    return Vehicle(
      color: color ?? this.color,
      plate: plate ?? this.plate,
      capacity: capacity ?? this.capacity,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }

  @override
  String toString() {
    return 'Vehicle{color: $color, plate: $plate, type: $vehicleType}';
  }
}
