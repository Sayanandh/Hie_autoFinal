import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/captain_provider.dart';
import '../../core/providers/ride_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/socket_service.dart';
import '../../core/config/secrets.dart';
import '../../core/config/app_routes.dart';
import 'widgets/ride_request_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  bool _isOnline = false;
  late final CaptainProvider _captainProvider;
  late final RideProvider _rideProvider;
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _captainProvider = context.read<CaptainProvider>();
    _rideProvider = context.read<RideProvider>();
    _socketService = context.read<SocketService>();
    
    _initializeLocation();
    _initializeSocket();
  }

  void _initializeLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.initializeLocation();
  }

  void _initializeSocket() {
    if (_captainProvider.captain != null) {
      _socketService.initialize(_captainProvider.captain!.id, 'driver');
      
      _socketService.onRideRequest((data) {
        if (!mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => RideRequestDialog(
            rideData: data,
            onAccept: () async {
              await _rideProvider.acceptRide(data['rideId']);
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.rideDetails);
            },
            onReject: () async {
              await _rideProvider.rejectRide(data['rideId']);
              if (!mounted) return;
              Navigator.pop(context);
            },
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver App'),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (value) {
              setState(() {
                _isOnline = value;
              });
              // TODO: Implement online/offline status update
            },
          ),
        ],
      ),
      body: Consumer3<LocationProvider, RideProvider, CaptainProvider>(
        builder: (context, locationProvider, rideProvider, captainProvider, child) {
          final currentPosition = locationProvider.currentPosition;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentPosition != null
                      ? LatLng(currentPosition.latitude, currentPosition.longitude)
                      : const LatLng(10.0261, 76.3125),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://api.mapbox.com/styles/v1/${Secrets.mapboxStyleId}/tiles/256/{z}/{x}/{y}@2x?access_token=${Secrets.mapboxAccessToken}',
                    additionalOptions: const {
                      'accessToken': Secrets.mapboxAccessToken,
                      'id': 'mapbox.mapbox-streets-v8',
                    },
                  ),
                  if (currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40,
                          height: 40,
                          point: LatLng(currentPosition.latitude, currentPosition.longitude),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 26),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.electric_rickshaw,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (rideProvider.currentRide != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Current Ride',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Status: ${rideProvider.currentRide!.status}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to ride details page
                              Navigator.pushNamed(context, '/rideDetails');
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('View Ride Details'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (locationProvider.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
      drawer: Drawer(
        child: Consumer<CaptainProvider>(
          builder: (context, captainProvider, child) {
            final captain = captainProvider.captain;
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    '${captain?.fullname.firstname} ${captain?.fullname.lastname}',
                  ),
                  accountEmail: Text(captain?.email ?? ''),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      captain?.fullname.firstname[0] ?? '',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Ride History'),
                  onTap: () {
                    Navigator.pushNamed(context, '/rideHistory');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_taxi),
                  title: const Text('Auto Stand'),
                  onTap: () {
                    Navigator.pushNamed(context, '/autoStand');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    await captainProvider.logout();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 