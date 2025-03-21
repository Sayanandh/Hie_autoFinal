import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/ride_provider.dart';

class OnlineToggleButton extends StatelessWidget {
  const OnlineToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, _) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Online Status:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: rideProvider.isOnline,
                  onChanged: (value) => rideProvider.toggleOnlineStatus(value),
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.grey.withOpacity(0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
