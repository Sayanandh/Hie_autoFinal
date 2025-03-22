import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'secrets.dart';

class RideBookingPage extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const RideBookingPage({
    super.key,
    required this.bookingData,
  });

  @override
  State<RideBookingPage> createState() => _RideBookingPageState();
}

class _RideBookingPageState extends State<RideBookingPage> {
  final MapController _mapController = MapController();
  String _selectedVehicleType = 'Auto';

  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'type': 'Auto',
      'icon': Icons.electric_rickshaw,
      'price': 150,
      'time': '15 min',
      'color': Colors.indigo,
      'description': 'Affordable rides for short trips',
    },
    {
      'type': 'Car',
      'icon': Icons.electric_rickshaw,
      'price': 250,
      'time': '15 min',
      'color': Colors.black,
      'description': 'Comfortable sedan for your journey',
    },
    {
      'type': 'Premium',
      'icon': Icons.electric_rickshaw,
      'price': 350,
      'time': '15 min',
      'color': Colors.deepPurple,
      'description': 'Luxury vehicles for premium experience',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  void _fitBounds() {
    if (widget.bookingData.isEmpty) return;

    final pickup = widget.bookingData['pickup']?['location'] as LatLng?;
    final destination =
        widget.bookingData['destination']?['location'] as LatLng?;

    if (pickup == null || destination == null) return;

    final bounds = LatLngBounds.fromPoints([pickup, destination]);
    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(
        padding: EdgeInsets.all(50),
      ),
    );
  }

  List<LatLng> _getRoutePoints() {
    if (widget.bookingData.isEmpty) return [];

    final pickup = widget.bookingData['pickup']?['location'] as LatLng?;
    final destination =
        widget.bookingData['destination']?['location'] as LatLng?;

    if (pickup == null || destination == null) return [];

    if (widget.bookingData['route']?['geometry']?['coordinates'] != null) {
      final coordinates =
          widget.bookingData['route']['geometry']['coordinates'] as List;
      return coordinates
          .map((coord) => LatLng(coord[1] as double, coord[0] as double))
          .toList();
    }

    return [pickup, destination];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookingData.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No booking data available'),
        ),
      );
    }

    final pickup = widget.bookingData['pickup']?['location'] as LatLng?;
    if (pickup == null) {
      return const Scaffold(
        body: Center(
          child: Text('Invalid pickup location'),
        ),
      );
    }

    final destination =
        widget.bookingData['destination']?['location'] as LatLng?;
    if (destination == null) {
      return const Scaffold(
        body: Center(
          child: Text('Invalid destination location'),
        ),
      );
    }

    final routePoints = _getRoutePoints();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: pickup,
              zoom: 15,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/${Secrets.mapboxStyleId}/tiles/256/{z}/{x}/{y}@2x?access_token=${Secrets.mapboxAccessToken}',
                additionalOptions: const {
                  'accessToken': Secrets.mapboxAccessToken,
                  'id': 'mapbox.mapbox-streets-v8',
                },
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: Colors.blue,
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pickup,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Marker(
                    point: destination,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distance',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(widget.bookingData['route']?['distance'] ?? 0.0 / 1000).toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duration',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(widget.bookingData['route']?['duration'] ?? 0.0 / 60).round()} min',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Vehicle Type',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._vehicleTypes.map(_buildVehicleOption),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final selectedVehicle = _vehicleTypes.firstWhere(
                            (v) => v['type'] == _selectedVehicleType,
                          );
                          Navigator.pushNamed(
                            context,
                            '/payment',
                            arguments: {
                              ...widget.bookingData,
                              'vehicle': selectedVehicle,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _vehicleTypes.firstWhere((v) =>
                              v['type'] == _selectedVehicleType)['color'],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Book Now - ₹${_vehicleTypes.firstWhere((v) => v['type'] == _selectedVehicleType)['price']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOption(Map<String, dynamic> vehicle) {
    final bool isSelected = _selectedVehicleType == vehicle['type'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = vehicle['type'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? vehicle['color'].withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? vehicle['color'] : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              vehicle['icon'],
              color: vehicle['color'],
              size: 30,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle['type'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    vehicle['description'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${vehicle['price']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  vehicle['time'],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
