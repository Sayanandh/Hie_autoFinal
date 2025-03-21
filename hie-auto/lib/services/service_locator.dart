import 'package:get_it/get_it.dart';
import 'user_service.dart';
import 'ride_service.dart';
import 'location_service.dart';
import 'socket_service.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register services as singletons
  serviceLocator.registerLazySingleton(() => UserService());
  serviceLocator.registerLazySingleton(() => RideService());
  serviceLocator.registerLazySingleton(() => LocationService());
  serviceLocator.registerLazySingleton(() => SocketService());

  // Initialize services that require async initialization
  await serviceLocator<UserService>().initialize();
  await serviceLocator<RideService>().initialize();
}

// Function to initialize socket after successful login
Future<void> initializeSocketService(String userId) async {
  final socketService = serviceLocator<SocketService>();
  await socketService.initialize(userId);
  await socketService.connect();
}

// Function to cleanup socket on logout
Future<void> cleanupSocketService() async {
  final socketService = serviceLocator<SocketService>();
  // Initialize socket service with user ID from UserService
  final userService = serviceLocator<UserService>();
  if (userService.currentUser != null) {
    await serviceLocator<SocketService>()
        .initialize(userService.currentUser!['id']);
    await serviceLocator<SocketService>().connect();
  }
}
