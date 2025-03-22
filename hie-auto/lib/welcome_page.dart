import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

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
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
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
                  child: Stack(
                    children: [
                      // Shadow effect
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Auto rickshaw icon with animations
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.electric_rickshaw,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        )
                            .animate(
                                onPlay: (controller) => controller.repeat())
                            .shimmer(
                                duration: 2000.ms,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3))
                            .then()
                            .shake(
                                duration: 2000.ms,
                                hz: 2,
                                curve: Curves.easeInOut)
                            .then()
                            .scale(
                              duration: 2000.ms,
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                            )
                            .then()
                            .scale(
                              duration: 2000.ms,
                              begin: const Offset(1.1, 1.1),
                              end: const Offset(1, 1),
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(
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
                    displayFullTextOnTap: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your premium auto-rickshaw ride partner',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 48),
                _buildAnimatedButton(
                  context: context,
                  label: 'Get Started',
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  isPrimary: true,
                ),
                const SizedBox(height: 16),
                _buildAnimatedButton(
                  context: context,
                  label: 'Create Account',
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/signup'),
                  isPrimary: false,
                ),
                const Spacer(flex: 1),
                Center(
                  child: Text(
                    'Experience the future of auto-rickshaw rides',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .slideY(begin: 0.3, end: 0),
                ),
                const SizedBox(height: 24),
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
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          foregroundColor: isPrimary
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
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
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: isPrimary ? 200.ms : 400.ms)
        .slideY(begin: 0.3, end: 0);
  }
}
