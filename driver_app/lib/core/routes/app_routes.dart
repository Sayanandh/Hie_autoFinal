import 'package:flutter/material.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/otp_verification_page.dart';
import '../../features/home/home_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/ride/ride_details_page.dart';
import '../../features/ride/ride_history_page.dart';
import '../../features/auto_stand/auto_stand_page.dart';
import '../../features/splash/splash_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String rideDetails = '/ride-details';
  static const String rideHistory = '/ride-history';
  static const String autoStand = '/auto-stand';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case otp:
        final args = settings.arguments as Map<String, dynamic>;
        final email = args['email'] as String;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationPage(email: email),
        );
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case rideDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => RideDetailsPage(
            rideId: args['rideId'] as String,
            rideDetails: args['rideDetails'] as Map<String, dynamic>,
          ),
        );
      case rideHistory:
        return MaterialPageRoute(builder: (_) => const RideHistoryPage());
      case autoStand:
        return MaterialPageRoute(builder: (_) => const AutoStandPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
