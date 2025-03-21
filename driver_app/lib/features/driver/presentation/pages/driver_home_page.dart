import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/ride_provider.dart';
import '../../../../core/providers/location_provider.dart';
import '../widgets/online_toggle_button.dart';
import '../widgets/ride_request_card.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
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
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: OnlineToggleButton(),
                ),
                const Spacer(),
                Consumer<RideProvider>(
                  builder: (context, rideProvider, _) {
                    final currentRide = rideProvider.currentRide;
                    if (currentRide == null) return const SizedBox.shrink();

                    return RideRequestCard(
                      ride: currentRide,
                      onAccept: () => rideProvider.acceptRide(currentRide.id),
                      onReject: () => rideProvider.rejectRide(currentRide.id),
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
