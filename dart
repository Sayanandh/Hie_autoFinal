import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'api_service.dart';

class SearchAndSelectPage extends StatefulWidget {
  @override
  _SearchAndSelectPageState createState() => _SearchAndSelectPageState();
}

class _SearchAndSelectPageState extends State<SearchAndSelectPage> {
  List<String> suggestions = [];
  String? selectedDestination;
  LatLng? destinationCoordinates;

  void _fetchSuggestions(String query) async {
    final results = await ApiService.getSuggestions(query);
    setState(() {
      suggestions = results;
    });
  }

  void _selectDestination(String destination) async {
    setState(() {
      selectedDestination = destination;
    });

    // Fetch coordinates for the selected destination
    LatLng? coordinates = await ApiService.getCoordinatesFromAddress(destination);
    
    if (coordinates != null) {
      setState(() {
        destinationCoordinates = coordinates; // Update the coordinates
      });
    } else {
      print('Could not fetch coordinates for $destination');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Destination')),
      body: Column(
        children: [
          TextField(
            onChanged: _fetchSuggestions,
            decoration: InputDecoration(labelText: 'Search for a location'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(suggestions[index]),
                  onTap: () => _selectDestination(suggestions[index]),
                );
              },
            ),
          ),
          if (selectedDestination != null && destinationCoordinates != null)
            Container(
              height: 300, // Set a height for the map
              child: FlutterMap(
                options: MapOptions(
                  center: destinationCoordinates,
                  zoom: 13.0,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                    additionalOptions: {
                      'accessToken': 'YOUR_MAPBOX_ACCESS_TOKEN', // Replace with your access token
                      'id': 'mapbox/streets-v11', // Replace with your style ID
                    },
                  ),
                  MarkerLayerOptions(
                    markers: [
                      Marker(
                        point: destinationCoordinates!,
                        builder: (ctx) => Container(
                          child: Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 