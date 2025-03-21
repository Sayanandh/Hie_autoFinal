import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/ride_provider.dart';
import '../../../core/models/ride.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';

class RideTrackingPage extends StatefulWidget {
  const RideTrackingPage({Key? key}) : super(key: key);

  @override
  _RideTrackingPageState createState() => _RideTrackingPageState();
}

class _RideTrackingPageState extends State<RideTrackingPage> {
  final _logger = Logger('RideTrackingPage');
  final _otpController = TextEditingController();

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Timer? _locationTimer;
  bool _isVerifyingOtp = false;

  @override
  void initState() {
    super.initState();
    _setupMap();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _mapController?.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  void _setupMap() {
    final ride = context.read<RideProvider>().currentRide;
    if (ride == null) return;

    // Add pickup marker
    _addMarker(
      LatLng(ride.pickup['lat']!, ride.pickup['lng']!),
      'pickup',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      'Pickup Location',
    );

    // Add dropoff marker
    _addMarker(
      LatLng(ride.dropoff['lat']!, ride.dropoff['lng']!),
      'dropoff',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      'Dropoff Location',
    );

    // Draw route polyline
    _updatePolylines();
  }

  void _addMarker(
      LatLng position, String id, BitmapDescriptor icon, String title) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          icon: icon,
          infoWindow: InfoWindow(title: title),
        ),
      );
    });
  }

  void _updateDriverMarker(LatLng position) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: MarkerId('driver'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Driver Location'),
        ),
      );
    });
  }

  void _updatePolylines() {
    final ride = context.read<RideProvider>().currentRide;
    if (ride == null) return;

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: [
            LatLng(ride.pickup['lat']!, ride.pickup['lng']!),
            LatLng(ride.dropoff['lat']!, ride.dropoff['lng']!),
          ],
          color: Colors.blue,
          width: 3,
        ),
      );
    });
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        if (!mounted) return;

        // Update user location on the map
        _updateDriverMarker(LatLng(position.latitude, position.longitude));

        // Location updates are handled automatically by RideProvider
      } catch (e) {
        _logger.severe('Error updating location: $e');
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter OTP')),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      await context.read<RideProvider>().verifyRideOTP(_otpController.text);
      if (!mounted) return;
      _otpController.clear();
    } catch (e) {
      _logger.severe('Error verifying OTP: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error verifying OTP')),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
      }
    }
  }

  Future<void> _completeRide() async {
    try {
      await context.read<RideProvider>().completeRide();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _logger.severe('Error completing ride: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error completing ride')),
      );
    }
  }

  Widget _buildStatusCard(Ride ride) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ride Status: ${ride.status.toUpperCase()}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text('Price: ₹${ride.price.toStringAsFixed(2)}'),
            SizedBox(height: 16),
            if (ride.status == 'accepted' && ride.otp != null)
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  suffixIcon: IconButton(
                    icon: _isVerifyingOtp
                        ? CircularProgressIndicator()
                        : Icon(Icons.check),
                    onPressed: _isVerifyingOtp ? null : _verifyOtp,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            if (ride.status == 'in_progress')
              ElevatedButton(
                onPressed: _completeRide,
                child: Text('Complete Ride'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Ride'),
      ),
      body: Consumer<RideProvider>(
        builder: (context, provider, child) {
          final ride = provider.currentRide;
          if (ride == null) {
            return Center(child: Text('No active ride'));
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(ride.pickup['lat']!, ride.pickup['lng']!),
                  zoom: 15,
                ),
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (controller) => _mapController = controller,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildStatusCard(ride),
              ),
            ],
          );
        },
      ),
    );
  }
}
