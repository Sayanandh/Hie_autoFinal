import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'services/location_api_service.dart';
import 'secrets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'utils/ui_utils.dart';
import 'dart:async';

class SelectSourcePage extends StatefulWidget {
  final String destination;

  const SelectSourcePage({Key? key, required this.destination})
      : super(key: key);

  @override
  _SelectSourcePageState createState() => _SelectSourcePageState();
}

class _SelectSourcePageState extends State<SelectSourcePage> {
  final logger = Logger();
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  final MapController mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  StreamSubscription<List<String>>? _searchSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    // Cancel previous subscription if exists
    await _searchSubscription?.cancel();

    // Subscribe to real-time suggestions
    _searchSubscription =
        LocationApiService.getRealtimeSuggestions(_searchController.text)
            .listen((suggestions) async {
      // Convert suggestions to the required format
      final results = await Future.wait(
        suggestions.map((suggestion) async {
          final coordinates =
              await LocationApiService.getCoordinatesFromAddress(suggestion);
          if (coordinates != null) {
            return {
              'description': suggestion,
              'lat': coordinates['lat'],
              'lng': coordinates['lng'],
            };
          }
          return null;
        }),
      );

      setState(() {
        _searchResults = results.whereType<Map<String, dynamic>>().toList();
        _isSearching = false;
      });
    });
  }

  Future<void> _selectLocation(Map<String, dynamic> location) async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _searchController.text = location['description'];
    });

    try {
      final selectedLocation = LatLng(
        location['lat'],
        location['lng'],
      );
      setState(() {
        _selectedLocation = selectedLocation;
        _selectedAddress = location['description'];
      });
      mapController.move(selectedLocation, 15);
    } catch (e) {
      logger.e('Error selecting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error selecting location')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentLocation;
      });

      // Get address for current location
      final locationDetails = await LocationApiService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (locationDetails != null && locationDetails['address'] != null) {
        setState(() {
          _selectedAddress = locationDetails['address'];
        });
      }

      mapController.move(_currentLocation!, 15);
    } catch (e) {
      logger.e('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error getting current location')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoading = true;
    });

    try {
      final locationDetails = await LocationApiService.reverseGeocode(
        location.latitude,
        location.longitude,
      );

      if (locationDetails != null && locationDetails['address'] != null) {
        setState(() {
          _selectedAddress = locationDetails['address'];
        });
      }
    } catch (e) {
      logger.e('Error getting address: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSearchResultSelected(Map<String, dynamic> result) async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _searchController.text = result['address'] ?? '';
    });

    try {
      final location = LatLng(
        result['location']['lat'],
        result['location']['lng'],
      );
      setState(() {
        _selectedLocation = location;
        _selectedAddress = result['address'];
      });
      mapController.move(location, 15);
    } catch (e) {
      logger.e('Error getting location details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmSelection() async {
    if (_selectedLocation == null || _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup location')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Get ride details including distance, duration, and price
      final routeDetails = await LocationApiService.getLocationDetails(
        _selectedAddress!,
        widget.destination,
      );

      if (routeDetails != null) {
        // The values are already numeric from LocationApiService
        final distance = routeDetails['distance'] as double;
        final duration = routeDetails['duration'] as double;
        final price = routeDetails['price'] as double;

        // Format values for display
        final formattedDistance = '${distance.toStringAsFixed(2)} km';
        final formattedDuration = '${duration.toStringAsFixed(0)} minutes';
        final formattedPrice = '₹${price.toStringAsFixed(2)}';

        logger.i(
            'Formatted ride details - Distance: $formattedDistance, Duration: $formattedDuration, Price: $formattedPrice');

        if (!mounted) return;

        Navigator.pop(context, {
          'source': _selectedAddress,
          'destination': widget.destination,
          'distance': formattedDistance,
          'duration': formattedDuration,
          'price': formattedPrice,
        });
      } else {
        throw Exception('Failed to get route details');
      }
    } catch (e) {
      logger.e('Error getting route details: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating route: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return UIUtils.wrapWithFullScreen(
      Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Select Pickup Location'),
          ),
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter:
                    _currentLocation ?? const LatLng(10.0261, 76.3125),
                initialZoom: 15,
                onTap: _handleMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/${Secrets.mapboxStyleId}/tiles/256/{z}/{x}/{y}@2x?access_token=${Secrets.mapboxAccessToken}',
                  additionalOptions: const {
                    'accessToken': Secrets.mapboxAccessToken,
                    'id': 'mapbox.mapbox-streets-v8',
                  },
                ),
                MarkerLayer(
                  markers: [
                    if (_selectedLocation != null)
                      Marker(
                        point: _selectedLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Search bar and results
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + kToolbarHeight + 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for pickup location',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(result['description']),
                            onTap: () => _selectLocation(result),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Selected location card
            if (_selectedAddress != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAddress!,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _confirmSelection,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Confirm Location'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      isDark,
    );
  }
}
