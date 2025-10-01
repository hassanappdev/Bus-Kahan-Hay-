import 'package:bus_kahan_hay/screens/user/authentication/auth.dart';
import 'package:bus_kahan_hay/screens/user/authentication/forgot_password.dart';
import 'package:bus_kahan_hay/screens/user/authentication/login.dart';
import 'package:bus_kahan_hay/screens/user/authentication/select_profile_picture_screen.dart';
import 'package:bus_kahan_hay/screens/user/authentication/signup.dart';
import 'package:bus_kahan_hay/screens/user/drawer/guide_screen.dart';
import 'package:bus_kahan_hay/screens/user/drawer/help_screen.dart';
import 'package:bus_kahan_hay/screens/user/drawer/profile_section.dart';
import 'package:bus_kahan_hay/screens/user/drawer/view_routes_screen.dart';
import 'package:bus_kahan_hay/screens/driver/driver_home.dart';
import 'package:bus_kahan_hay/screens/driver/driver_login.dart';
import 'package:bus_kahan_hay/screens/driver/driver_signup.dart';
import 'package:bus_kahan_hay/screens/user/home/route_home.dart';
import 'package:bus_kahan_hay/screens/user/onBoardingFluid/fluid_home.dart';
import 'package:bus_kahan_hay/screens/user/splash/splash.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // ✅ Initialize binding FIRST
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase AFTER binding is ready
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      print("FIREBASE INIT ERROR: $e");
    }
  }

  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // home: const FluidHome(),
      // home: const RouteHome(),
      // home: const SplashScreen(),
      home: const Auth(),

      routes: {
        '/driver-signup': (context) => const DriverSignup(),
        '/driver-login': (context) => const DriverLogin(),
        '/driver-home': (context) => const DriverHomeScreen(),

        '/splash-screen': (context) => const SplashScreen(),
        '/onboarding': (context) => const FluidHome(),
        '/auth': (context) => const Auth(),
        '/forgot-password': (context) => const ForgotPassword(),
        '/login': (context) => const Login(),
        '/select-profile-picture-screen': (context) =>
            const SelectProfilePictureScreen(),
        '/signup': (context) => const Signup(),
        '/my-profile': (context) => const ProfileSection(),
        '/home': (context) => const RouteHome(),
        '/ViewRoutesScreen': (context) => const ViewRoutesScreen(routes: []),
        '/HelpScreen': (context) => const HelpScreen(),
        '/GuideScreen': (context) => const GuideScreen(),
      },
    );
  }
}
