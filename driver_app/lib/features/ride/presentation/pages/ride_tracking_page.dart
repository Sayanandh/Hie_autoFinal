import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/ride_service.dart';

class RideTrackingPage extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideDetails;

  const RideTrackingPage({
    Key? key,
    required this.rideId,
    required this.rideDetails,
  }) : super(key: key);

  @override
  State<RideTrackingPage> createState() => _RideTrackingPageState();
}

class _RideTrackingPageState extends State<RideTrackingPage> {
  final RideService _rideService = RideService.instance;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  String _rideStatus = 'accepted';

  @override
  void initState() {
    super.initState();
    _setupLocationUpdates();
    _setupStatusUpdates();
  }

  void _setupLocationUpdates() {
    _rideService.startLocationUpdates(
      widget.rideId,
      (location) {
        setState(() {
          _currentLocation = location;
          _updateMarkers();
        });
      },
    );
  }

  void _setupStatusUpdates() {
    _rideService.onRideStatusUpdate(
      widget.rideId,
      (data) {
        setState(() {
          _rideStatus = data['status'];
        });
      },
    );
  }

  void _updateMarkers() {
    if (_currentLocation == null) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('driver'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            widget.rideDetails['pickup']['lat'].toDouble(),
            widget.rideDetails['pickup']['lng'].toDouble(),
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(
            widget.rideDetails['dropoff']['lat'].toDouble(),
            widget.rideDetails['dropoff']['lng'].toDouble(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            _currentLocation!,
            LatLng(
              widget.rideDetails['dropoff']['lat'].toDouble(),
              widget.rideDetails['dropoff']['lng'].toDouble(),
            ),
          ],
          color: Colors.blue,
        ),
      };
    });
  }

  Future<void> _completeRide() async {
    if (_currentLocation == null) return;

    try {
      await _rideService.completeRide(widget.rideId, _currentLocation!);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete ride: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ??
                  LatLng(
                    widget.rideDetails['pickup']['lat'].toDouble(),
                    widget.rideDetails['pickup']['lng'].toDouble(),
                  ),
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Status: ${_rideStatus.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pickup: ${widget.rideDetails['pickup']['address'] ?? 'Unknown location'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dropoff: ${widget.rideDetails['dropoff']['address'] ?? 'Unknown location'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_rideStatus == 'accepted') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _completeRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Complete Ride'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rideService.stopLocationUpdates(widget.rideId);
    _mapController?.dispose();
    super.dispose();
  }
}
