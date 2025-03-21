import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/location_provider.dart';

class AutoStandPage extends StatefulWidget {
  const AutoStandPage({super.key});

  @override
  State<AutoStandPage> createState() => _AutoStandPageState();
}

class _AutoStandPageState extends State<AutoStandPage> {
  final _formKey = GlobalKey<FormState>();
  final _standNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;

  @override
  void dispose() {
    _standNameController.dispose();
    _descriptionController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Stand'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showNearbyStands,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<LocationProvider>(
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
                  onTap: _onMapTap,
                );
              },
            ),
          ),
          if (_selectedLocation != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _standNameController,
                      decoration: const InputDecoration(
                        labelText: 'Stand Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a stand name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _createStand,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Create Stand'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextButton(
                            onPressed: _clearSelection,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      );
    });
  }

  void _createStand() {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      return;
    }

    // TODO: Implement stand creation API call
    final standData = {
      'name': _standNameController.text,
      'description': _descriptionController.text,
      'location': {
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
      },
    };

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auto stand created successfully')),
    );

    // Clear form
    _clearSelection();
  }

  void _clearSelection() {
    setState(() {
      _selectedLocation = null;
      _markers.clear();
      _standNameController.clear();
      _descriptionController.clear();
    });
  }

  void _showNearbyStands() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const NearbyStandsSheet(),
    );
  }
}

class NearbyStandsSheet extends StatelessWidget {
  const NearbyStandsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nearby Auto Stands',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // TODO: Replace with actual data
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Auto Stand ${index + 1}'),
                  subtitle: Text('${(index + 1) * 100} meters away'),
                  trailing: TextButton(
                    onPressed: () {
                      // TODO: Implement join stand functionality
                    },
                    child: const Text('Join'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
