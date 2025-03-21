import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/ride.dart';
import '../../../core/providers/ride_provider.dart';

class RideRequestCard extends StatelessWidget {
  final Ride ride;

  const RideRequestCard({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ride Request',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Price',
              '₹${ride.price.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Status',
              ride.status,
            ),
            const SizedBox(height: 16),
            if (ride.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Accept ride
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reject ride
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              )
            else if (ride.status == 'accepted')
              Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (otp) {
                      final rideProvider = Provider.of<RideProvider>(
                        context,
                        listen: false,
                      );
                      rideProvider.verifyRideOTP(otp);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final rideProvider = Provider.of<RideProvider>(
                        context,
                        listen: false,
                      );
                      rideProvider.completeRide();
                    },
                    child: const Text('Complete Ride'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
