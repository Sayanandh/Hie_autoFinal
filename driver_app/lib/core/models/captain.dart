class Fullname {
  final String firstname;
  final String lastname;

  Fullname({
    required this.firstname,
    required this.lastname,
  });

  factory Fullname.fromJson(Map<String, dynamic> json) {
    return Fullname(
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstname': firstname,
      'lastname': lastname,
    };
  }

  @override
  String toString() => '$firstname $lastname';
}

class Captain {
  final String id;
  final Fullname fullname;
  final String email;
  final String phone;
  final String status;
  final Vehicle vehicle;
  final Verification verification;
  final bool isUnionMember;
  final double? rating;

  Captain({
    required this.id,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.status,
    required this.vehicle,
    required this.verification,
    required this.isUnionMember,
    this.rating,
  });

  factory Captain.fromJson(Map<String, dynamic> json) {
    return Captain(
      id: json['_id'] ?? '',
      fullname: Fullname.fromJson(json['fullname'] ?? {}),
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'inactive',
      vehicle: Vehicle.fromJson(json['vehicle'] ?? {}),
      verification: Verification.fromJson(json['verification'] ?? {}),
      isUnionMember: json['IsUnionMember'] ?? false,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname.toJson(),
      'email': email,
      'phone': phone,
      'status': status,
      'vehicle': vehicle.toJson(),
      'verification': verification.toJson(),
      'isUnionMember': isUnionMember,
      'rating': rating,
    };
  }
}

class Vehicle {
  final String color;
  final String plate;
  final int capacity;
  final String vehicleType;

  String get type => vehicleType;
  String get number => plate;
  String get model => vehicleType;

  Vehicle({
    required this.color,
    required this.plate,
    required this.capacity,
    required this.vehicleType,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      color: json['color'] ?? '',
      plate: json['plate'] ?? '',
      capacity: json['capacity'] ?? 0,
      vehicleType: json['vehicleType'] ?? '',
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
}

class Verification {
  final String licenseNumber;
  final String vehicleRegistrationNumber;
  final String insuranceNumber;
  final String commercialRegistrationNumber;

  String get license => licenseNumber;
  String get insurance => insuranceNumber;
  String get permit => vehicleRegistrationNumber;
  String get identity => commercialRegistrationNumber;

  Verification({
    required this.licenseNumber,
    required this.vehicleRegistrationNumber,
    required this.insuranceNumber,
    required this.commercialRegistrationNumber,
  });

  factory Verification.fromJson(Map<String, dynamic> json) {
    return Verification(
      licenseNumber: json['LicenseNumber'] ?? '',
      vehicleRegistrationNumber: json['VehicleRegistrationNumber'] ?? '',
      insuranceNumber: json['InsuranceNumber'] ?? '',
      commercialRegistrationNumber: json['CommertialRegistrationNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'LicenseNumber': licenseNumber,
      'VehicleRegistrationNumber': vehicleRegistrationNumber,
      'InsuranceNumber': insuranceNumber,
      'CommertialRegistrationNumber': commercialRegistrationNumber,
    };
  }
} 