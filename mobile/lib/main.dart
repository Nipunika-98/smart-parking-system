import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/screens/add_vehicle_screen.dart';
import 'package:mobile/screens/bottom_navigation.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/logo_screen.dart';
import 'package:mobile/screens/registration_screen.dart';
import 'package:mobile/screens/forgot_password_screen.dart';
import 'package:mobile/screens/notifications_screen.dart';
import 'package:mobile/screens/global_screens/global_notification_listener.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/vehicle_provider.dart';
import 'package:mobile/providers/parking_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/pricing_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Firebase initialized successfully!");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, auth, previous) => previous!..updateUserId(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PricingProvider>(
          create: (_) => PricingProvider(),
          update: (_, auth, previous) =>
              previous!..updateAuth(auth.isAuthenticated),
        ),
        ChangeNotifierProxyProvider<AuthProvider, VehicleProvider>(
          create: (_) => VehicleProvider(),
          update: (_, auth, previous) => previous!..updateUserId(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ParkingProvider>(
          create: (_) => ParkingProvider(),
          update: (_, auth, previous) => previous!..updateUserId(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, UserProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, userProv, previous) => previous!..updateUserId(auth.user?.uid, userProv.user?.registrationDate),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,

      initialRoute: '/',
      routes: {
        '/': (context) => const LogoScreen(),
        '/signIn': (context) => const SignInScreen(),
        '/signUp': (context) => const RegisterScreen(),
        '/add-vehicle': (context) => const AddVehicleScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/home': (context) => const BottomNavigation(),
      },
      builder: (context, child) => GlobalNotificationListener(
        navigatorKey: navigatorKey,
        child: child!,
      ),
    );
  }
}
