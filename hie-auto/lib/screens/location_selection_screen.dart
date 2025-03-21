import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationSelectionScreen extends StatefulWidget {
  final bool isPickup;
  final Function(LatLng, String) onLocationSelected;

  const LocationSelectionScreen({
    Key? key,
    required this.isPickup,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _searchQuery = '';
  List<String> _recentLocations = [
    'Road To Scms College Of Architecture',
    'Indian Museum',
    'Park Street',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;

      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);

      setState(() => _selectedLocation = location);
      _mapController?.animateCamera(CameraUpdate.newLatLng(location));
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Back button and title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        widget.isPickup ? 'Select pickup' : 'Where to?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText:
                          widget.isPickup ? 'Pickup location' : 'Where to?',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Recent locations
            if (_searchQuery.isEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _recentLocations.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(_recentLocations[index]),
                      onTap: () {
                        // TODO: Get coordinates for the selected location
                        // For now, just pass a dummy location
                        widget.onLocationSelected(
                          const LatLng(0, 0),
                          _recentLocations[index],
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            // Map view
            if (_selectedLocation != null)
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation!,
                        zoom: 15,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      onCameraMove: (position) {
                        setState(() => _selectedLocation = position.target);
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                    // Center marker
                    Center(
                      child: Icon(
                        Icons.location_on,
                        color: Theme.of(context).primaryColor,
                        size: 36,
                      ),
                    ),
                    // Confirm button
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedLocation != null) {
                            widget.onLocationSelected(
                              _selectedLocation!,
                              'Selected Location', // TODO: Get address from coordinates
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Confirm Location'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
