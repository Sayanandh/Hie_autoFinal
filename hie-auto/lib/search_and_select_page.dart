import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class SearchAndSelectPage extends StatefulWidget {
  const SearchAndSelectPage({super.key});

  @override
  State<SearchAndSelectPage> createState() => _SearchAndSelectPageState();
}

class _SearchAndSelectPageState extends State<SearchAndSelectPage> {
  final MapController _mapController = MapController();
  final LatLng _defaultLocation = const LatLng(10.0261, 76.3125); // Kerala coordinates
  LatLng? _currentLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng location) {
    // Handle map tap event
    debugPrint('Map tapped at: $location');
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation ?? _defaultLocation,
        initialZoom: 15.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        onTap: _handleMapTap,
      ),
      children: [
        // Map layers and markers go here
      ],
    );
  }
} 