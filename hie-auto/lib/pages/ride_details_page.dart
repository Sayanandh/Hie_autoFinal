import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class RideDetailsPage extends StatelessWidget {
  const RideDetailsPage({Key? key}) : super(key: key);

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
        title: const Text('Ride Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pickup Location Card
            _buildLocationCard(
              title: 'Pickup Location',
              location: source,
              icon: Icons.location_on,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // Dropoff Location Card
            _buildLocationCard(
              title: 'Dropoff Location',
              location: destination,
              icon: Icons.location_on,
              color: Colors.blue,
            ),

            const SizedBox(height: 24),

            // Trip Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTripDetailRow(
                    icon: Icons.directions_car,
                    title: 'Distance',
                    value: distance,
                  ),
                  const SizedBox(height: 12),
                  _buildTripDetailRow(
                    icon: Icons.access_time,
                    title: 'Duration',
                    value: duration,
                  ),
                  const SizedBox(height: 12),
                  _buildTripDetailRow(
                    icon: Icons.currency_rupee,
                    title: 'Price',
                    value: price,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/driver-selection',
                      arguments: args);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue to Driver Selection',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required String location,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
