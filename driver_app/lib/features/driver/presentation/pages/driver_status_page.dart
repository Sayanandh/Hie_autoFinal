import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/ride_provider.dart';
import '../../../../core/providers/location_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverStatusPage extends StatefulWidget {
  const DriverStatusPage({super.key});

  @override
  State<DriverStatusPage> createState() => _DriverStatusPageState();
}

class _DriverStatusPageState extends State<DriverStatusPage> {
  final Set<Circle> _circles = {};
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildStatusCard(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        final currentPosition = locationProvider.currentPosition;
        if (currentPosition == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final location = LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        );

        _updateSearchRadius(location);

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: location,
            zoom: 15,
          ),
          onMapCreated: (controller) => _mapController = controller,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          circles: _circles,
        );
      },
    );
  }

  void _updateSearchRadius(LatLng center) {
    _circles.clear();
    _circles.add(
      Circle(
        circleId: const CircleId('search_radius'),
        center: center,
        radius: 2000, // 2km radius
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blue,
        strokeWidth: 1,
      ),
    );
  }

  Widget _buildStatusCard() {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, _) {
        final isOnline = rideProvider.isOnline;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Driver Status',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: isOnline,
                              onChanged: (value) =>
                                  rideProvider.toggleOnlineStatus(value),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatusIndicator(isOnline),
                        if (isOnline) ...[
                          const SizedBox(height: 16),
                          _buildSearchingAnimation(),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isOnline) ...[
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.circle : Icons.circle_outlined,
            color: isOnline ? Colors.green : Colors.grey,
            size: 12,
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'Online - Ready for Rides' : 'Offline',
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingAnimation() {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          'Searching for rides in your area...',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Stats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.timer,
                  value: '2h 30m',
                  label: 'Online Time',
                ),
                _buildStatItem(
                  icon: Icons.directions_car,
                  value: '5',
                  label: 'Rides',
                ),
                _buildStatItem(
                  icon: Icons.currency_rupee,
                  value: '₹500',
                  label: 'Earnings',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
