import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/ride_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/ride.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';

class RideRequestPage extends StatefulWidget {
  const RideRequestPage({Key? key}) : super(key: key);

  @override
  State<RideRequestPage> createState() => RideRequestPageState();
}

class RideRequestPageState extends State<RideRequestPage> {
  final _logger = Logger('RideRequestPage');
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  double? _price;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _pickupLocation = LatLng(position.latitude, position.longitude);
        _addMarker(_pickupLocation!, 'pickup',
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_pickupLocation!));
    } catch (e) {
      _logger.severe('Error getting current location: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error getting current location')),
      );
    }
  }

  void _addMarker(LatLng position, String id, BitmapDescriptor icon) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          icon: icon,
        ),
      );
    });
  }

  Future<void> _calculatePrice() async {
    if (_pickupLocation == null || _dropoffLocation == null) return;

    setState(() => _isLoading = true);

    try {
      final pickup =
          '${_pickupLocation!.longitude},${_pickupLocation!.latitude}';
      final dropoff =
          '${_dropoffLocation!.longitude},${_dropoffLocation!.latitude}';

      final response =
          await context.read<ApiService>().getRidePrice(pickup, dropoff);
      setState(() {
        _price = double.parse(response['price']);
      });
    } catch (e) {
      _logger.severe('Error calculating price: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating ride price')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestRide() async {
    if (_pickupLocation == null || _dropoffLocation == null || _price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select pickup and dropoff locations')),
      );
      return;
    }

    final rideData = {
      'pickup': {
        'ltd': _pickupLocation!.latitude,
        'lng': _pickupLocation!.longitude,
      },
      'dropoff': {
        'ltd': _dropoffLocation!.latitude,
        'lng': _dropoffLocation!.longitude,
      },
      'price': _price,
    };

    try {
      final rideProvider = context.read<RideProvider>();
      await rideProvider.acceptRide(rideData['id'].toString());
      if (mounted) {
        Navigator.pushNamed(context, '/ride-tracking');
      }
    } catch (e) {
      _logger.severe('Error requesting ride: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error requesting ride')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Ride'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(0, 0),
                zoom: 15,
              ),
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
              onTap: (position) {
                if (_pickupLocation == null) {
                  setState(() {
                    _pickupLocation = position;
                    _addMarker(
                        position,
                        'pickup',
                        BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen));
                  });
                } else if (_dropoffLocation == null) {
                  setState(() {
                    _dropoffLocation = position;
                    _addMarker(
                        position,
                        'dropoff',
                        BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed));
                  });
                  _calculatePrice();
                }
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _pickupController,
                    decoration: InputDecoration(
                      labelText: 'Pickup Location',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.my_location),
                        onPressed: _getCurrentLocation,
                      ),
                    ),
                    readOnly: true,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _dropoffController,
                    decoration: InputDecoration(
                      labelText: 'Dropoff Location',
                    ),
                    readOnly: true,
                  ),
                  SizedBox(height: 16),
                  if (_price != null)
                    Text(
                      'Estimated Price: ₹${_price!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _requestRide,
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text('Request Ride'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
