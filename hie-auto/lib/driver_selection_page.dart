import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DriverSelectionPage extends StatelessWidget {
  const DriverSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the route arguments
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final source = args['source'] as String;
    final destination = args['destination'] as String;
    final distance = args['distance'] as String;
    final duration = args['duration'] as String;
    final price = args['price'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Driver',
          style: TextStyle(
            fontFamily: 'CustomFont',
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildDriverCard(
            context,
            name: 'John Doe',
            rating: 4.8,
            totalTrips: 1250,
            carModel: 'Toyota Camry',
            carNumber: 'ABC-123',
            estimatedArrival: '5 min',
            price: double.parse(price.replaceAll('₹', '')),
            onSelect: () {
              Navigator.pushNamed(
                context,
                '/payment',
                arguments: {
                  'source': source,
                  'destination': destination,
                  'distance': distance,
                  'duration': duration,
                  'price': price,
                  'driver': {
                    'name': 'John Doe',
                    'rating': 4.8,
                    'totalTrips': 1250,
                    'carModel': 'Toyota Camry',
                    'carNumber': 'ABC-123',
                  },
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _buildDriverCard(
            context,
            name: 'Jane Smith',
            rating: 4.9,
            totalTrips: 980,
            carModel: 'Honda Civic',
            carNumber: 'XYZ-789',
            estimatedArrival: '8 min',
            price: double.parse(price.replaceAll('₹', '')),
            onSelect: () {
              Navigator.pushNamed(
                context,
                '/payment',
                arguments: {
                  'source': source,
                  'destination': destination,
                  'distance': distance,
                  'duration': duration,
                  'price': price,
                  'driver': {
                    'name': 'Jane Smith',
                    'rating': 4.9,
                    'totalTrips': 980,
                    'carModel': 'Honda Civic',
                    'carNumber': 'XYZ-789',
                    'estimatedArrival': '8 min',
                  },
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(
    BuildContext context, {
    required String name,
    required double rating,
    required int totalTrips,
    required String carModel,
    required String carNumber,
    required String estimatedArrival,
    required double price,
    required VoidCallback onSelect,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(26),
                  child: Text(
                    name[0],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'CustomFont',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: TextStyle(
                              fontFamily: 'CustomFont',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($totalTrips trips)',
                            style: TextStyle(
                              fontFamily: 'CustomFont',
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(179),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'CustomFont',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$carModel ($carNumber)',
                  style: TextStyle(
                    fontFamily: 'CustomFont',
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.timer,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Arrives in $estimatedArrival',
                  style: TextStyle(
                    fontFamily: 'CustomFont',
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Select Driver',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
