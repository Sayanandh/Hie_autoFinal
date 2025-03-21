import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/ride_provider.dart';
import '../../../../core/providers/location_provider.dart';
import '../widgets/ride_status_card.dart';

class RideTrackingPage extends StatefulWidget {
  const RideTrackingPage({super.key});

  @override
  State<RideTrackingPage> createState() => _RideTrackingPageState();
}

class _RideTrackingPageState extends State<RideTrackingPage> {
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Consumer<LocationProvider>(
            builder: (context, locationProvider, _) {
              final currentPosition = locationProvider.currentPosition;
              if (currentPosition == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    currentPosition.latitude,
                    currentPosition.longitude,
                  ),
                  zoom: 15,
                ),
                onMapCreated: (controller) => _mapController = controller,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _markers,
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Consumer<RideProvider>(
                  builder: (context, rideProvider, _) {
                    final currentRide = rideProvider.currentRide;
                    if (currentRide == null) return const SizedBox.shrink();

                    return RideStatusCard(
                      ride: currentRide,
                      onComplete: () => rideProvider.completeRide(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
