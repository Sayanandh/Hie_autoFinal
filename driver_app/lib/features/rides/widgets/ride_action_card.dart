import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/models/ride.dart';
import '../../../core/providers/ride_provider.dart';

class RideActionCard extends StatefulWidget {
  final Ride ride;
  final Function(LatLng) onLocationUpdate;

  const RideActionCard({
    super.key,
    required this.ride,
    required this.onLocationUpdate,
  });

  @override
  State<RideActionCard> createState() => _RideActionCardState();
}

class _RideActionCardState extends State<RideActionCard> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) return;

    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    try {
      await rideProvider.verifyRideOTP(_otpController.text);
      if (!mounted) return;
      _otpController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _completeRide() async {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    try {
      await rideProvider.completeRide();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ride Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.ride.status).withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.ride.status,
                    style: TextStyle(
                      color: _getStatusColor(widget.ride.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLocationInfo(
              context,
              'Pickup Location',
              widget.ride.pickup.toLatLng(),
              Icons.location_on,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildLocationInfo(
              context,
              'Dropoff Location',
              widget.ride.dropoff.toLatLng(),
              Icons.location_on_outlined,
              Colors.red,
            ),
            const Divider(height: 24),
            Text(
              'Price: ₹${widget.ride.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (widget.ride.status == 'accepted')
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _verifyOTP,
                  ),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _verifyOTP(),
              )
            else if (widget.ride.status == 'in_progress')
              ElevatedButton(
                onPressed: _completeRide,
                child: const Text('Complete Ride'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(
    BuildContext context,
    String label,
    LatLng location,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => widget.onLocationUpdate(location),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  '${location.latitude}, ${location.longitude}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
