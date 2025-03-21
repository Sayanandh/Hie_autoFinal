import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/ride_provider.dart';
import '../widgets/ride_action_card.dart';
import '../../../core/models/ride.dart';

class ActiveRideScreen extends StatefulWidget {
  final String rideId;

  const ActiveRideScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeLocationUpdates();
  }

  void _initializeLocationUpdates() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.initializeLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapMarkers();
  }

  void _updateMapMarkers() {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final ride = rideProvider.currentRide;
    
    if (ride == null) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: ride.pickup.toLatLng(),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: ride.dropoff.toLatLng(),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Dropoff Location'),
        ),
      };

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            ride.pickup.toLatLng(),
            ride.dropoff.toLatLng(),
          ],
          color: Theme.of(context).colorScheme.primary,
          width: 4,
        ),
      };
    });
  }

  void _updateCameraPosition(LatLng target) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride'),
      ),
      body: Stack(
        children: [
          Consumer<LocationProvider>(
            builder: (context, location, child) {
              final currentPosition = location.currentPosition;
              
              if (currentPosition == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    currentPosition.latitude,
                    currentPosition.longitude,
                  ),
                  zoom: 15,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _markers,
                polylines: _polylines,
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Consumer<RideProvider>(
              builder: (context, ride, child) {
                final currentRide = ride.currentRide;
                
                if (currentRide == null) {
                  return const SizedBox.shrink();
                }

                return RideActionCard(
                  ride: currentRide,
                  onLocationUpdate: _updateCameraPosition,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
} 