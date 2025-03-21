import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/socket_service.dart';

class RideDetailsPage extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> rideDetails;

  const RideDetailsPage({
    Key? key,
    required this.rideId,
    required this.rideDetails,
  }) : super(key: key);

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  final SocketService _socketService = SocketService.instance;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _setupLocationUpdates();
  }

  void _setupLocationUpdates() {
    _socketService.onLocationUpdate(widget.rideId, (data) {
      setState(() {
        _currentLocation = LatLng(
          data['location']['ltd'].toDouble(),
          data['location']['lng'].toDouble(),
        );
        _updateMap();
      });
    });
  }

  void _updateMap() {
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

    _fitBounds(
      LatLng(
        widget.rideDetails['pickup']['lat'].toDouble(),
        widget.rideDetails['pickup']['lng'].toDouble(),
      ),
      LatLng(
        widget.rideDetails['dropoff']['lat'].toDouble(),
        widget.rideDetails['dropoff']['lng'].toDouble(),
      ),
    );
  }

  LatLngBounds _calculateBounds(LatLng pickup, LatLng dropoff) {
    final southwest = LatLng(
      pickup.latitude < dropoff.latitude ? pickup.latitude : dropoff.latitude,
      pickup.longitude < dropoff.longitude
          ? pickup.longitude
          : dropoff.longitude,
    );
    final northeast = LatLng(
      pickup.latitude > dropoff.latitude ? pickup.latitude : dropoff.latitude,
      pickup.longitude > dropoff.longitude
          ? pickup.longitude
          : dropoff.longitude,
    );
    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  void _fitBounds(LatLng pickup, LatLng dropoff) {
    final bounds = _calculateBounds(pickup, dropoff);
    final center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: center,
          zoom: 15,
        ),
      ),
    );
  }

  Widget _buildOverlay(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildStatusIndicator(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color.withAlpha(200),
        shape: BoxShape.circle,
      ),
    );
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
                      'Ride Details',
                      style: Theme.of(context).textTheme.titleLarge,
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
                    const SizedBox(height: 8),
                    Text(
                      'Price: ₹${widget.rideDetails['price']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
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
    _mapController?.dispose();
    super.dispose();
  }
}
