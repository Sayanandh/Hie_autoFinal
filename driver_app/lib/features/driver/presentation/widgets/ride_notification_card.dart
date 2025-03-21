import 'package:flutter/material.dart';
import '../../../../core/models/ride.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideNotificationCard extends StatefulWidget {
  final Ride ride;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final Duration timeout;

  const RideNotificationCard({
    super.key,
    required this.ride,
    required this.onAccept,
    required this.onReject,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  State<RideNotificationCard> createState() => _RideNotificationCardState();
}

class _RideNotificationCardState extends State<RideNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.timeout,
      vsync: this,
    );
    _animation = Tween<double>(begin: 1, end: 0).animate(_controller);
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onReject();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isExpanded ? 400 : 200,
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBasicInfo(),
                    if (_isExpanded) ...[
                      const Divider(),
                      _buildDetailedInfo(),
                    ],
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          const Text(
            'New Ride Request',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: _animation.value,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _animation.value > 0.3 ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }

  Widget _buildBasicInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLocationInfo(
            'Pickup',
            widget.ride.pickup,
            Icons.location_on,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildLocationInfo(
            'Dropoff',
            widget.ride.dropoff,
            Icons.location_off,
            Colors.red,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.currency_rupee, color: Colors.green),
              Text(
                widget.ride.price.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoRow('Distance', '2.5 km'),
          _buildInfoRow('Estimated Time', '15 mins'),
          _buildInfoRow('Payment Method', 'Cash'),
          _buildInfoRow('User Rating', '4.5 ⭐'),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(
    String title,
    Map<String, double> location,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${location['lat']?.toStringAsFixed(4)}, ${location['lng']?.toStringAsFixed(4)}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onReject,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Accept'),
            ),
          ),
        ],
      ),
    );
  }
}
