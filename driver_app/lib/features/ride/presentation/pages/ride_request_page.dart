import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/ride_service.dart';
import '../widgets/ride_request_card.dart';

class RideRequestPage extends StatefulWidget {
  const RideRequestPage({Key? key}) : super(key: key);

  @override
  State<RideRequestPage> createState() => _RideRequestPageState();
}

class _RideRequestPageState extends State<RideRequestPage> {
  final RideService _rideService = RideService.instance;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Map<String, dynamic>? _currentRideRequest;

  @override
  void initState() {
    super.initState();
    _setupRideRequestListener();
  }

  void _setupRideRequestListener() {
    _rideService.onRideRequest((data) {
      setState(() {
        _currentRideRequest = data;
        _updateMapWithRideRequest(data);
      });
    });
  }

  void _updateMapWithRideRequest(Map<String, dynamic> data) {
    final pickup = LatLng(
      data['pickup']['lat'].toDouble(),
      data['pickup']['lng'].toDouble(),
    );
    final dropoff = LatLng(
      data['dropoff']['lat'].toDouble(),
      data['dropoff']['lng'].toDouble(),
    );

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [pickup, dropoff],
          color: Colors.blue,
        ),
      };
    });

    _fitBounds(pickup, dropoff);
  }

  void _fitBounds(LatLng pickup, LatLng dropoff) {
    final bounds = _calculateBounds(pickup, dropoff);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
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

  Future<void> _acceptRide() async {
    if (_currentRideRequest == null) return;

    try {
      await _rideService.verifyRideOTP(
        _currentRideRequest!['otp'],
        _currentRideRequest!['rideId'],
        _currentRideRequest!['pickup'],
      );
      // Navigate to ride tracking page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept ride: $e')),
      );
    }
  }

  Future<void> _rejectRide() async {
    setState(() {
      _currentRideRequest = null;
      _markers.clear();
      _polylines.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_currentRideRequest != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RideRequestCard(
                request: _currentRideRequest!,
                onAccept: _acceptRide,
                onReject: _rejectRide,
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
