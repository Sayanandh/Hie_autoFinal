import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'api_service.dart'; // Import the ApiService

class ProfilePage extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const ProfilePage({super.key, required this.onThemeToggle});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _firstName;
  String? _lastName;
  String? _email;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch user profile when the page is initialized
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profileData = await ApiService.getUserProfile();
      setState(() {
        // Extract first name and last name from the response
        _firstName = profileData['user']['fullname']['firstname'];
        _lastName = profileData['user']['fullname']['lastname'];
        _email = profileData['user']['email'];
        _isLoading = false; // Set loading to false after fetching data
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false; // Set loading to false on error
      });
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          floating: true,
                          leading: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          actions: [
                            IconButton(
                              onPressed: widget.onThemeToggle,
                              icon: Icon(
                                Theme.of(context).brightness == Brightness.light
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          ],
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        child: Text(
                                          '${_firstName?[0].toUpperCase() ?? ''}${_lastName?[0].toUpperCase() ?? ''}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      )
                                          .animate()
                                          .fadeIn(duration: 600.ms)
                                          .scale(delay: 200.ms),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.camera_alt,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        )
                                            .animate()
                                            .fadeIn(
                                                duration: 600.ms, delay: 400.ms)
                                            .scale(delay: 600.ms),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildSection(
                                  title: 'Personal Information',
                                  children: [
                                    _buildProfileField(
                                      label: 'First Name',
                                      value: _firstName ?? '',
                                      icon: Icons.person_outline,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildProfileField(
                                      label: 'Last Name',
                                      value: _lastName ?? '',
                                      icon: Icons.person_outline,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildProfileField(
                                      label: 'Email',
                                      value: _email ?? '',
                                      icon: Icons.email_outlined,
                                      isVerified: true,
                                    ),
                                  ],
                                )
                                    .animate()
                                    .fadeIn(duration: 600.ms, delay: 600.ms)
                                    .slideX(begin: -0.2, end: 0),
                                const SizedBox(height: 32),
                                _buildSection(
                                  title: 'Preferences',
                                  children: [
                                    _buildSettingTile(
                                      icon: Icons.notifications_outlined,
                                      title: 'Notifications',
                                      onTap: () {},
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSettingTile(
                                      icon: Icons.security_outlined,
                                      title: 'Privacy',
                                      onTap: () {},
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSettingTile(
                                      icon: Icons.help_outline,
                                      title: 'Help & Support',
                                      onTap: () {},
                                    ),
                                  ],
                                )
                                    .animate()
                                    .fadeIn(duration: 600.ms, delay: 800.ms)
                                    .slideX(begin: -0.2, end: 0),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isLoading ? null : _handleSignOut,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.error,
                                      foregroundColor:
                                          Theme.of(context).colorScheme.onError,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    icon: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onError,
                                            ),
                                          )
                                        : const Icon(Icons.logout),
                                    label: const Text(
                                      'Sign Out',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 600.ms, delay: 1000.ms)
                                    .slideY(begin: 0.2, end: 0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required IconData icon,
    bool isVerified = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
