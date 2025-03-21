import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withAlpha(204), // 0.8 opacity = 204 alpha
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 1),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          Icons.directions_car_rounded,
                          size: 120,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(flex: 1),
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Welcome to\nHie Auto',
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your premium ride partner for every journey',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(179), // 0.7 opacity = 179 alpha
                  ),
                ),
                const SizedBox(height: 48),
                _buildAnimatedButton(
                  context: context,
                  label: 'Get Started',
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  isPrimary: true,
                ),
                const SizedBox(height: 16),
                _buildAnimatedButton(
                  context: context,
                  label: 'I already have an account',
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  isPrimary: false,
                ),
                const Spacer(flex: 1),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Add terms and conditions navigation
                    },
                    child: Text(
                      'By continuing, you agree to our Terms & Conditions',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153), // 0.6 opacity = 153 alpha
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPrimary 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.transparent,
                  foregroundColor: isPrimary 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isPrimary 
                      ? BorderSide.none 
                      : BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                  elevation: isPrimary ? 4 : 0,
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isPrimary 
                      ? Theme.of(context).colorScheme.onPrimary 
                      : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
