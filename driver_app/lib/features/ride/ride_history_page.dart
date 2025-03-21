import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/ride_provider.dart';
import 'package:intl/intl.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }

  Future<void> _loadRideHistory() async {
    final rideProvider = context.read<RideProvider>();
    await rideProvider.loadRideHistory();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM d, y h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
      ),
      body: Consumer<RideProvider>(
        builder: (context, rideProvider, child) {
          if (rideProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (rideProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${rideProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: _loadRideHistory,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (rideProvider.rideHistory.isEmpty) {
            return const Center(
              child: Text('No ride history available'),
            );
          }

          return ListView.builder(
            itemCount: rideProvider.rideHistory.length,
            itemBuilder: (context, index) {
              final ride = rideProvider.rideHistory[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text('Ride #${ride.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${ride.status}'),
                      Text('Price: ₹${ride.price}'),
                      Text('Date: ${_formatDateTime(ride.createdAt)}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 