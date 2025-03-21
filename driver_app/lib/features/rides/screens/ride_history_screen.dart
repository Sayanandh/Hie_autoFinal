import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/ride_provider.dart';
import '../widgets/ride_history_tile.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }

  Future<void> _loadRideHistory() async {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    await rideProvider.loadRideHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
      ),
      body: Consumer<RideProvider>(
        builder: (context, ride, child) {
          if (ride.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (ride.rideHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No rides yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRideHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ride.rideHistory.length,
              itemBuilder: (context, index) {
                final rideData = ride.rideHistory[index];
                return RideHistoryTile(ride: rideData);
              },
            ),
          );
        },
      ),
    );
  }
} 