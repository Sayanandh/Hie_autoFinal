import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'utils/ui_utils.dart';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return UIUtils.wrapWithFullScreen(
      Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Ride Details',
              style: TextStyle(
                fontFamily: 'CustomFont',
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.of(context).viewPadding.top + 24,
                  24,
                  24 + MediaQuery.of(context).viewPadding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationCard(
                    context,
                    title: 'Pickup Location',
                    address: source,
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 24),
                  _buildLocationCard(
                    context,
                    title: 'Dropoff Location',
                    address: destination,
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 32),
                  _buildInfoCard(
                    context,
                    title: 'Trip Details',
                    children: [
                      _buildInfoRow(
                        context,
                        icon: Icons.directions_car,
                        label: 'Distance',
                        value: distance,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        icon: Icons.timer,
                        label: 'Duration',
                        value: duration,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        icon: Icons.currency_rupee,
                        label: 'Price',
                        value: '₹${price}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/driver-selection',
                          arguments: {
                            'source': source,
                            'destination': destination,
                            'distance': distance,
                            'duration': duration,
                            'price': price,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue to Driver Selection',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isDark,
    );
  }

  Widget _buildLocationCard(
    BuildContext context, {
    required String title,
    required String address,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'CustomFont',
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      fontFamily: 'CustomFont',
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'CustomFont',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'CustomFont',
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'CustomFont',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
