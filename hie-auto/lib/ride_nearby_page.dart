import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:logger/logger.dart';
import 'secrets.dart';
import 'utils/ui_utils.dart';

class RideNearbyPage extends StatefulWidget {
  final Map<String, dynamic> rideData;

  const RideNearbyPage({
    super.key,
    required this.rideData,
  });

  @override
  State<RideNearbyPage> createState() => _RideNearbyPageState();
}

class _RideNearbyPageState extends State<RideNearbyPage> {
  final MapController _mapController = MapController();
  final logger = Logger();
  String _selectedVehicleType = 'Auto';
  bool _isLoading = false;
  Map<String, dynamic>? _priceInfo;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'type': 'Auto',
      'icon': Icons.electric_rickshaw,
      'basePrice': 150,
      'pricePerKm': 12,
      'duration': '15 min',
      'color': Colors.indigo,
      'description': 'Affordable rides for short trips',
    },
    {
      'type': 'Car',
      'icon': Icons.directions_car,
      'basePrice': 250,
      'pricePerKm': 15,
      'duration': '15 min',
      'color': Colors.black,
      'description': 'Comfortable sedan for your journey',
    },
    {
      'type': 'Premium',
      'icon': Icons.local_taxi,
      'basePrice': 350,
      'pricePerKm': 20,
      'duration': '15 min',
      'color': Colors.deepPurple,
      'description': 'Luxury vehicles for premium experience',
    },
  ];

  @override
  void initState() {
    super.initState();
    UIUtils.setFullScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
      _calculatePrice();
    });
  }

  Future<void> _calculatePrice() async {
    setState(() => _isLoading = true);
    try {
      // Use the route info directly instead of API call
      final routeInfo = widget.rideData['route'];
      if (routeInfo != null) {
        setState(() {
          _priceInfo = {
            'distance': routeInfo['distance'],
            'duration': routeInfo['duration'],
          };
        });
      }
    } catch (e) {
      logger.e('Error calculating price: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _calculateFinalPrice(Map<String, dynamic> vehicleType) {
    if (_priceInfo == null) return vehicleType['basePrice'];

    final distance = _priceInfo!['distance'] as num;
    final distanceKm = distance / 1000;
    final duration = _priceInfo!['duration'] as num;
    final durationMinutes = duration / 60;

    // Base price + (distance × rate per km) + (duration × rate per minute)
    return (vehicleType['basePrice'] +
            (distanceKm * vehicleType['pricePerKm']) +
            (durationMinutes * 2) // ₹2 per minute
        )
        .round();
  }

  void _fitBounds() {
    final pickup = widget.rideData['pickup']?['location'] as LatLng?;
    final destination = widget.rideData['destination']?['location'] as LatLng?;

    if (pickup == null || destination == null) return;

    final bounds = LatLngBounds.fromPoints([pickup, destination]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Widget _buildVehicleTypeCard(Map<String, dynamic> vehicle) {
    final isSelected = _selectedVehicleType == vehicle['type'];
    final price = _calculateFinalPrice(vehicle);
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicleType = vehicle['type']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? vehicle['color'].withAlpha(25)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? vehicle['color'] : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              vehicle['icon'],
              size: 32,
              color: isSelected
                  ? vehicle['color']
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle['type'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? vehicle['color']
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                  ),
                  Text(
                    vehicle['description'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withAlpha(179),
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$price',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? vehicle['color']
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                ),
                Text(
                  _priceInfo != null
                      ? '${(_priceInfo!['duration'] / 60).round()} min'
                      : vehicle['duration'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withAlpha(179),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickup = widget.rideData['pickup'];
    final destination = widget.rideData['destination'];
    final routeInfo = widget.rideData['route'];

    return UIUtils.wrapWithFullScreen(
      Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: pickup['location'],
                initialZoom: 15,
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
                if (routeInfo != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: (routeInfo['geometry']['coordinates'] as List)
                            .map((coord) =>
                                LatLng(coord[1] as double, coord[0] as double))
                            .toList(),
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: pickup['location'],
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
                      width: 40,
                      height: 40,
                      point: destination['location'],
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

            // Top Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading Indicator
            if (_isLoading)
              Container(
                color: Colors.black.withAlpha(77),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Bottom Sheet
            DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        20 + MediaQuery.of(context).viewPadding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(77),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Route Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildRouteInfo(
                                icon: Icons.timeline,
                                label: 'Distance',
                                value:
                                    '${(routeInfo['distance'] / 1000).toStringAsFixed(1)} km',
                              ),
                              _buildRouteInfo(
                                icon: Icons.access_time,
                                label: 'Duration',
                                value:
                                    '${(routeInfo['duration'] / 60).round()} min',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),

                          Text(
                            'Select Vehicle Type',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // Vehicle Types
                          ..._vehicleTypes
                              .map((vehicle) => _buildVehicleTypeCard(vehicle)),

                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      final selectedVehicle =
                                          _vehicleTypes.firstWhere(
                                        (v) =>
                                            v['type'] == _selectedVehicleType,
                                      );

                                      Navigator.pushNamed(
                                        context,
                                        '/payment',
                                        arguments: {
                                          'pickup': pickup,
                                          'destination': destination,
                                          'route': routeInfo,
                                          'vehicle': {
                                            ...selectedVehicle,
                                            'finalPrice': _calculateFinalPrice(
                                                selectedVehicle),
                                          },
                                          'priceInfo': _priceInfo,
                                        },
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: _vehicleTypes.firstWhere((v) =>
                                    v['type'] == _selectedVehicleType)['color'],
                              ),
                              child: Text(
                                'Proceed to Payment - ₹${_calculateFinalPrice(_vehicleTypes.firstWhere((v) => v['type'] == _selectedVehicleType))}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      isDark,
    );
  }
}
