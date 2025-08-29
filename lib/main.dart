import 'package:bus_kahan_hay/screens/authentication/auth.dart';
import 'package:bus_kahan_hay/screens/authentication/forgot_password.dart';
import 'package:bus_kahan_hay/screens/authentication/login.dart';
import 'package:bus_kahan_hay/screens/authentication/select_profile_picture_screen.dart';
import 'package:bus_kahan_hay/screens/authentication/signup.dart';
import 'package:bus_kahan_hay/screens/drawer/guide_screen.dart';
import 'package:bus_kahan_hay/screens/drawer/help_screen.dart';
import 'package:bus_kahan_hay/screens/drawer/profile_section.dart';
import 'package:bus_kahan_hay/screens/drawer/view_routes_screen.dart';
import 'package:bus_kahan_hay/screens/home/home.dart';
import 'package:bus_kahan_hay/screens/onBoardingFluid/fluid_home.dart';
import 'package:bus_kahan_hay/screens/splash/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // ✅ Initialize binding FIRST
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase AFTER binding is ready
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Set system UI styles after initialization
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const FluidHome(),
      routes: {
        '/onboarding': (context) => const FluidHome(),
        '/my-profile': (context) => const ProfileSection(),
        '/ViewRoutesScreen': (context) => const ViewRoutesScreen(routes: []),

        '/HelpScreen': (context) => const HelpScreen(),
        '/GuideScreen': (context) => const GuideScreen(),

        '/home': (context) => const Home(),
        '/auth': (context) => const Auth(),
        '/forgot-password': (context) => const ForgotPassword(),
        '/login': (context) => const Login(),
        '/select-profile-picture-screen': (context) =>
            const SelectProfilePictureScreen(),
        '/signup': (context) => const Signup(),
        '/splash-screen': (context) => const SplashScreen(),
      },
    );
  }
}
