import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final captain = authProvider.captain;

          if (captain == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(
                  Icons.person,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${captain.fullname.firstname} ${captain.fullname.lastname}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                captain.email,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile(
                icon: Icons.phone,
                title: 'Phone',
                value: captain.phone,
              ),
              _InfoTile(
                icon: Icons.star,
                title: 'Rating',
                value: captain.rating != null 
                  ? '${captain.rating!.toStringAsFixed(1)} ⭐'
                  : 'Not rated yet',
              ),
              _InfoTile(
                icon: Icons.circle,
                title: 'Status',
                value: captain.status,
                valueColor: _getStatusColor(captain.status),
              ),
              const Divider(height: 32),
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile(
                icon: Icons.directions_car,
                title: 'Vehicle Type',
                value: captain.vehicle.type,
              ),
              _InfoTile(
                icon: Icons.confirmation_number,
                title: 'Vehicle Number',
                value: captain.vehicle.number,
              ),
              _InfoTile(
                icon: Icons.color_lens,
                title: 'Vehicle Color',
                value: captain.vehicle.color,
              ),
              const Divider(height: 32),
              const Text(
                'Verification Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile(
                icon: Icons.badge,
                title: 'License Number',
                value: captain.verification.licenseNumber,
              ),
              _InfoTile(
                icon: Icons.article,
                title: 'Vehicle Registration',
                value: captain.verification.vehicleRegistrationNumber,
              ),
              _InfoTile(
                icon: Icons.security,
                title: 'Insurance Number',
                value: captain.verification.insuranceNumber,
              ),
              _InfoTile(
                icon: Icons.business,
                title: 'Commercial Registration',
                value: captain.verification.commercialRegistrationNumber,
              ),
              if (captain.isUnionMember) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: Colors.green,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Union Member',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 