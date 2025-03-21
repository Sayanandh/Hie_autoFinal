import 'package:flutter/material.dart';
import '../../../core/models/captain.dart';

class StatusCard extends StatelessWidget {
  final Captain captain;

  const StatusCard({
    super.key,
    required this.captain,
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
              'Status: ${captain.status}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _getStatusColor(captain.status),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              captain.rating != null 
                ? 'Rating: ${captain.rating!.toStringAsFixed(1)}⭐'
                : 'Rating: Not rated yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vehicle: ${captain.vehicle.type} (${captain.vehicle.number})',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (captain.isUnionMember) ...[
              const SizedBox(height: 8),
              const Text(
                '🏢 Union Member',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'busy':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 