import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class IntroductionPages extends StatefulWidget {
  const IntroductionPages({super.key});

  @override
  State<IntroductionPages> createState() => _IntroductionPagesState();
}

class _IntroductionPagesState extends State<IntroductionPages> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to Hie Auto',
      'description': 'Your trusted ride-hailing partner for safe and comfortable journeys.',
      'image': 'assets/images/intro1.png',
    },
    {
      'title': 'Easy Booking',
      'description': 'Book your ride with just a few taps and get picked up in minutes.',
      'image': 'assets/images/intro2.png',
    },
    {
      'title': 'Track Your Ride',
      'description': 'Know exactly where your ride is and when it will arrive.',
      'image': 'assets/images/intro3.png',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(
                    title: page['title']!,
                    description: page['description']!,
                    image: page['image']!,
                  );
                },
              ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            _currentPage == index ? 1 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ).animate(
                        target: _currentPage == index ? 1 : 0,
                      ).scaleXY(
                        begin: 0.8,
                        end: 1.0,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animate(
                      onPlay: (controller) => controller.repeat(),
                    ).shimmer(
                      duration: const Duration(seconds: 2),
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required String image,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Image.asset(
            image,
            height: 300,
            width: 300,
            fit: BoxFit.contain,
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(
            delay: const Duration(milliseconds: 200),
            duration: const Duration(milliseconds: 600),
          ).slideY(
            begin: 0.3,
            curve: Curves.easeOut,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(
            delay: const Duration(milliseconds: 400),
            duration: const Duration(milliseconds: 600),
          ).slideY(
            begin: 0.3,
            curve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}
