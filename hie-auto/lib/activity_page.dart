import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

class ActivityPage extends StatelessWidget {
  final VoidCallback onThemeToggle;
  static final _logger = Logger();

  const ActivityPage({super.key, required this.onThemeToggle});

  void home(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void profile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Popular Car',
          style: TextStyle(
            fontFamily: 'CustomFont',
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: onThemeToggle,
          ),
          TextButton(
            onPressed: () {
              _logger.i('Sort Ascending/Descending');
            },
            child: Text(
              'Ascending',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'CustomFont',
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          RideCard(
            pickUp: '1901 Thornridge Cir. Shiloh',
            dropOff: '4140 Parker Rd. Allentown',
            dateTime: '16 July 2023, 10:30 PM',
            driverName: 'Jane Cooper',
            carSeats: 4,
            paymentStatus: 'Paid',
          ),
          SizedBox(height: 16),
          RideCard(
            pickUp: '1901 Thornridge Cir. Shiloh',
            dropOff: '4140 Parker Rd. Allentown',
            dateTime: '16 July 2023, 10:30 PM',
            driverName: 'Jane Cooper',
            carSeats: 4,
            paymentStatus: 'Paid',
          ),
        ],
      ),
    );
  }
}

class RideCard extends StatelessWidget {
  final String pickUp;
  final String dropOff;
  final String dateTime;
  final String driverName;
  final int carSeats;
  final String paymentStatus;

  const RideCard({
    super.key,
    required this.pickUp,
    required this.dropOff,
    required this.dateTime,
    required this.driverName,
    required this.carSeats,
    required this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
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
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.map,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickUp,
                        style: TextStyle(
                          fontFamily: 'CustomFont',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dropOff,
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
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Time',
                      style: TextStyle(
                        fontFamily: 'CustomFont',
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(179),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateTime,
                      style: TextStyle(
                        fontFamily: 'CustomFont',
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver',
                      style: TextStyle(
                        fontFamily: 'CustomFont',
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(179),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driverName,
                      style: TextStyle(
                        fontFamily: 'CustomFont',
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_seat,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$carSeats seats',
                      style: TextStyle(
                        fontFamily: 'CustomFont',
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'Paid'
                        ? Colors.green.withAlpha(26)
                        : Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    paymentStatus,
                    style: TextStyle(
                      fontFamily: 'CustomFont',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          paymentStatus == 'Paid' ? Colors.green : Colors.red,
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
}

// Implement local storage for ride history
class RideHistoryService {
  Future<List<Map<String, dynamic>>> getRideHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? historyJson = prefs.getString('ride_history');
    if (historyJson != null) {
      List<dynamic> decoded = json.decode(historyJson);
      return List<Map<String, dynamic>>.from(decoded);
    }
    return [];
  }

  Future<void> saveRide(Map<String, dynamic> rideData) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> history = await getRideHistory();
    history.add(rideData);
    await prefs.setString('ride_history', json.encode(history));
  }
}
