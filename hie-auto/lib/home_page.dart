import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'select_source_page.dart';
import 'ride_details_page.dart';
import 'utils/ui_utils.dart';
import 'secrets.dart'; // Import the secrets file
import 'ride_nearby_page.dart';
import 'activity_page.dart';
import 'profile_page.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'search_and_select_page.dart'; // Import the new search and select page
import 'package:provider/provider.dart';
import 'providers/location_provider.dart';
import 'providers/theme_provider.dart';
import 'services/location_api_service.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const HomePage({super.key, required this.onThemeToggle});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _logger = Logger();
  String _userName = 'Guest';
  int _selectedIndex = 0;
  String? _error;
  static const LatLng _center = LatLng(10.0261, 76.3125);
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  late AnimationController _animationController;
  final List<String> _searchSuggestions = [];
  final bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Check MapBox token
    if (!Secrets.isValidMapboxToken()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Invalid MapBox token. Please update your token in secrets.dart'),
            duration: Duration(seconds: 10),
          ),
        );
      });
      return;
    }

    // Make app full screen
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    _requestLocationPermission();
    _loadUserProfile();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    LocationApiService.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService.getUserProfile();

      if (response['user'] != null) {
        setState(() {
          _userData = response['user'];
          _userName = response['user']['fullname']['firstname'] ?? 'Guest';
        });
      }
    } catch (e) {
      _logger.e('Error loading profile: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.denied) {
          await _getCurrentLocation();
        }
      } else {
        await _getCurrentLocation();
      }
    } catch (e) {
      _logger.e('Error requesting location permission: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_currentLocation ?? _center, 15.0);
      _logger.i('Current location: $_currentLocation');
    } catch (e) {
      _logger.e('Error getting location: $e');
    }
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search destination',
                        hintStyle: GoogleFonts.poppins(
                          color: Theme.of(context).hintColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        suffixIcon: _isSearching
                            ? Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  Icons.mic,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () {
                                  // TODO: Implement voice search
                                },
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ),
              ),
              // Search results
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream:
                      LocationApiService.getRealtimeSuggestions(_searchQuery),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading suggestions',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || _searchQuery.isEmpty) {
                      return _buildRecentSearches();
                    }

                    final suggestions = snapshot.data!;
                    if (suggestions.isEmpty) {
                      return Center(
                        child: Text(
                          'No locations found',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: suggestions.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            suggestion,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () => _handleLocationSelected(suggestion),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentSearchItem(
            icon: Icons.history,
            title: 'Lulu Mall, Edappally',
            subtitle: 'Edappally, Kochi',
          ),
          _buildRecentSearchItem(
            icon: Icons.history,
            title: 'Kaloor Bus Stand',
            subtitle: 'Kaloor, Kochi',
          ),
          _buildRecentSearchItem(
            icon: Icons.history,
            title: 'Marine Drive',
            subtitle: 'Marine Drive, Kochi',
          ),
        ],
      ),
    );
  }

  void _handleLocationSelected(String location) async {
    // Close search sheet and clear search
    Navigator.pop(context);
    _searchController.clear();
    _searchSuggestions.clear();

    // Navigate to source selection
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectSourcePage(destination: location),
      ),
    );

    // If source is selected, proceed to ride details
    if (result != null && mounted) {
      Navigator.pushNamed(
        context,
        '/ride-details',
        arguments: {
          'source': result['source'],
          'destination': location,
          'distance': result['distance'],
          'duration': result['duration'],
          'price': result['price'].toString(),
        },
      );
    }
  }

  Widget _buildRecentSearchItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      onTap: () {
        // TODO: Handle location selection
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Map View
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? _center,
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/${Secrets.mapboxStyleId}/tiles/256/{z}/{x}/{y}@2x?access_token=${Secrets.mapboxAccessToken}',
                  additionalOptions: const {
                    'accessToken': Secrets.mapboxAccessToken,
                    'id': 'mapbox.mapbox-streets-v8',
                  },
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 50,
                        height: 50,
                        point: _currentLocation!,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Top Bar with Glassmorphism
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 8,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User Avatar and Name with Animation
                    Row(
                      children: [
                        Hero(
                          tag: 'userAvatar',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Text(
                                _userName.isNotEmpty
                                    ? _userName[0].toUpperCase()
                                    : 'G',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate(controller: _animationController)
                            .fadeIn(duration: 600.ms)
                            .slideX(begin: -0.2, end: 0),
                        const SizedBox(width: 12),
                        Text(
                          'Hello, $_userName!',
                          style: GoogleFonts.poppins(
                            textStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        )
                            .animate(controller: _animationController)
                            .fadeIn(duration: 600.ms)
                            .slideX(begin: -0.2, end: 0),
                      ],
                    ),
                    // Animated Theme Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: widget.onThemeToggle,
                        icon: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          color: isDark ? Colors.amber : Colors.orange,
                        ),
                      ),
                    )
                        .animate(controller: _animationController)
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),

            // Bottom Panel with Glassmorphism
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewPadding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Greeting and Search Bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👋 Where are you going?',
                            style: GoogleFonts.poppins(
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          )
                              .animate(controller: _animationController)
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 16),
                          // Animated Search Bar
                          Material(
                            elevation: 0,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[850]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                readOnly: true,
                                onTap: _showSearchBottomSheet,
                                decoration: InputDecoration(
                                  hintText: 'Where to?',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Theme.of(context).hintColor,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                ),
                              ),
                            ),
                          )
                              .animate(controller: _animationController)
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    ),
                    // Modern Floating Navigation Bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        height: 65,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .shadowColor
                                  .withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              icon: Icons.home_rounded,
                              label: 'Home',
                              isSelected: _selectedIndex == 0,
                              onTap: () => _onNavItemTapped(0),
                            ),
                            _buildNavItem(
                              icon: Icons.access_time_rounded,
                              label: 'Activity',
                              isSelected: _selectedIndex == 1,
                              onTap: () => _onNavItemTapped(1),
                            ),
                            _buildNavItem(
                              icon: Icons.person_rounded,
                              label: 'Profile',
                              isSelected: _selectedIndex == 2,
                              onTap: () => _onNavItemTapped(2),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate(controller: _animationController)
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.2, end: 0),
            ],
          ],
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .shimmer(
            duration: 2000.ms,
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
          ),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ActivityPage(onThemeToggle: widget.onThemeToggle),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProfilePage(onThemeToggle: widget.onThemeToggle),
          ),
        );
        break;
    }
  }

  void _onSearchChanged() {
    // Implement search logic here
  }
}
