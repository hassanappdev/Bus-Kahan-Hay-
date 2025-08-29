import 'package:bus_kahan_hay/screens/authentication/auth.dart';
import 'package:bus_kahan_hay/screens/authentication/forgot_password.dart';
import 'package:bus_kahan_hay/screens/authentication/login.dart';
import 'package:bus_kahan_hay/screens/authentication/select_profile_picture_screen.dart';
import 'package:bus_kahan_hay/screens/authentication/signup.dart';
import 'package:bus_kahan_hay/screens/home/home.dart';
import 'package:bus_kahan_hay/screens/splash/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  WidgetsFlutterBinding.ensureInitialized();
  // For full screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // initialRoute: '/splash-screen',
      home: SplashScreen(),
      routes: {
        // AUTHENTICATION - 2
        '/home': (context) => const Home(),
        '/auth': (context) => const Auth(),
        '/forgot-password': (context) => const ForgotPassword(),
        '/login': (context) => const Login(),
        '/select-profile-picture-screen': (context) =>
            const SelectProfilePictureScreen(),
        '/signup': (context) => const Signup(),

        // SPLASH SCREEN
        '/splash-screen': (context) => const SplashScreen(),
      },
    );
  }
}
