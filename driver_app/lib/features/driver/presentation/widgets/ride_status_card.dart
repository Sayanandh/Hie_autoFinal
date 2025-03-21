import 'package:flutter/material.dart';
import '../../../../core/models/ride.dart';

class RideStatusCard extends StatelessWidget {
  final Ride ride;
  final VoidCallback onComplete;

  const RideStatusCard({
    super.key,
    required this.ride,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ride Status: ${ride.status}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLocationInfo('Pickup', ride.pickup),
            const SizedBox(height: 8),
            _buildLocationInfo('Dropoff', ride.dropoff),
            const SizedBox(height: 16),
            _buildPriceInfo(),
            const SizedBox(height: 16),
            if (ride.status == 'in_progress')
              ElevatedButton(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Complete Ride'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(String title, Map<String, double> location) {
    return Row(
      children: [
        Text(
          '$title: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            '${location['lat']?.toStringAsFixed(4)}, ${location['lng']?.toStringAsFixed(4)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Price: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '₹${ride.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
