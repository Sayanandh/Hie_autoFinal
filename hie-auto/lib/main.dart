import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/ride_provider.dart';
import 'services/service_locator.dart';
import 'introduction_page.dart';
import 'login.dart';
import 'signup.dart';
import 'home_page.dart';
import 'activity_page.dart';
import 'profile_page.dart';
import 'search_and_select_page.dart';
import 'ride_details_page.dart';
import 'driver_selection_page.dart';
import 'utils/ui_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set full screen mode
  UIUtils.setFullScreen();

  // Initialize services
  await setupServiceLocator();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(serviceLocator)),
        ChangeNotifierProvider(create: (_) => LocationProvider(serviceLocator)),
        ChangeNotifierProvider(create: (_) => RideProvider(serviceLocator)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return UIUtils.wrapWithFullScreen(
          MaterialApp(
            title: 'HieAuto',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E88E5),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E88E5),
                brightness: Brightness.dark,
              ),
            ),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isFirstTime) {
                  return const IntroductionPage();
                }
                if (!authProvider.isAuthenticated) {
                  return LoginPage(
                    onThemeToggle: () => themeProvider.toggleTheme(),
                  );
                }
                return HomePage(
                  onThemeToggle: () => themeProvider.toggleTheme(),
                );
              },
            ),
            routes: {
              '/login': (context) => LoginPage(
                    onThemeToggle: () => themeProvider.toggleTheme(),
                  ),
              '/signup': (context) => SignupPage(
                    onThemeToggle: () => themeProvider.toggleTheme(),
                  ),
              '/home': (context) => HomePage(
                    onThemeToggle: () => themeProvider.toggleTheme(),
                  ),
              '/activity': (context) => ActivityPage(
                    onThemeToggle: () => themeProvider.toggleTheme(),
                  ),
              '/profile': (context) => ProfilePage(
                    onThemeToggle: () => themeProvider.toggleTheme(),
                  ),
              '/search-select': (context) => const SearchAndSelectPage(),
              '/ride-details': (context) => const RideDetailsPage(),
              '/driver-selection': (context) => const DriverSelectionPage(),
            },
          ),
          themeProvider.isDarkMode,
        );
      },
    );
  }
}
