import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/ride_provider.dart';
import 'core/providers/captain_provider.dart';
import 'core/services/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/services/api_service.dart';
import 'core/services/socket_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: ApiService.instance),
        Provider<SocketService>.value(value: SocketService.instance),
        ChangeNotifierProvider(
            create: (_) =>
                AuthProvider(ApiService.instance, SocketService.instance)),
        ChangeNotifierProvider(
            create: (_) => LocationProvider(ApiService.instance)),
        ChangeNotifierProvider(
          create: (context) => RideProvider(
            context.read<ApiService>(),
            context.read<SocketService>(),
          ),
        ),
        ChangeNotifierProvider(
            create: (_) =>
                CaptainProvider(ApiService.instance, SocketService.instance)),
      ],
      child: MaterialApp(
        title: 'Driver App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: NavigationService.navigatorKey,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: AppRoutes.splash,
      ),
    );
  }
}
