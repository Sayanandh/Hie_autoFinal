import 'package:flutter/material.dart';

class RideRequestDialog extends StatelessWidget {
  final Map<String, dynamic> rideData;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideRequestDialog({
    super.key,
    required this.rideData,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Ride Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pickup: ${rideData['pickup']['address']}'),
          const SizedBox(height: 8),
          Text('Dropoff: ${rideData['dropoff']['address']}'),
          const SizedBox(height: 8),
          Text('Price: ₹${rideData['price']}'),
          const SizedBox(height: 8),
          Text('Distance: ${rideData['distance']} km'),
          const SizedBox(height: 8),
          Text('Duration: ${rideData['duration']} min'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: onAccept,
          child: const Text('Accept'),
        ),
      ],
    );
  }
} 