import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/ride_provider.dart';
import 'driver_home_page.dart';
import 'ride_tracking_page.dart';

class DriverAppPage extends StatelessWidget {
  const DriverAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, _) {
        return rideProvider.currentRide != null
            ? const RideTrackingPage()
            : const DriverHomePage();
      },
    );
  }
}
