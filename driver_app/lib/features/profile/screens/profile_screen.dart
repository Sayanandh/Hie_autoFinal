import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/navigation_service.dart';
import '../widgets/profile_info_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                NavigationService.navigateToAndRemoveUntil(AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final captain = auth.captain;

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
                captain.fullname.toString(),
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
              ProfileInfoTile(
                icon: Icons.star,
                title: 'Rating',
                value: captain.rating != null
                    ? '${captain.rating!.toStringAsFixed(1)} ⭐'
                    : 'Not rated yet',
              ),
              ProfileInfoTile(
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
              ProfileInfoTile(
                icon: Icons.directions_car,
                title: 'Vehicle Type',
                value: captain.vehicle.type,
              ),
              ProfileInfoTile(
                icon: Icons.palette,
                title: 'Color',
                value: captain.vehicle.color,
              ),
              ProfileInfoTile(
                icon: Icons.confirmation_number,
                title: 'Vehicle Number',
                value: captain.vehicle.number,
              ),
              ProfileInfoTile(
                icon: Icons.directions_car,
                title: 'Vehicle Model',
                value: captain.vehicle.model,
              ),
              const Divider(height: 32),
              const Text(
                'Verification Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ProfileInfoTile(
                icon: Icons.card_membership,
                title: 'License',
                value: captain.verification.license.isNotEmpty
                    ? 'Verified'
                    : 'Not Verified',
                valueColor: captain.verification.license.isNotEmpty
                    ? Colors.green
                    : Colors.red,
              ),
              ProfileInfoTile(
                icon: Icons.security,
                title: 'Insurance',
                value: captain.verification.insurance.isNotEmpty
                    ? 'Verified'
                    : 'Not Verified',
                valueColor: captain.verification.insurance.isNotEmpty
                    ? Colors.green
                    : Colors.red,
              ),
              ProfileInfoTile(
                icon: Icons.verified_user,
                title: 'Permit',
                value: captain.verification.permit.isNotEmpty
                    ? 'Verified'
                    : 'Not Verified',
                valueColor: captain.verification.permit.isNotEmpty
                    ? Colors.green
                    : Colors.red,
              ),
              ProfileInfoTile(
                icon: Icons.person_pin,
                title: 'Identity',
                value: captain.verification.identity.isNotEmpty
                    ? 'Verified'
                    : 'Not Verified',
                valueColor: captain.verification.identity.isNotEmpty
                    ? Colors.green
                    : Colors.red,
              ),
              if (captain.isUnionMember)
                const ProfileInfoTile(
                  icon: Icons.business_center,
                  title: 'Union Status',
                  value: 'Member',
                  valueColor: Colors.green,
                ),
            ],
          );
        },
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
