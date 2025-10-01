import 'package:bus_kahan_hay/screens/user/onBoardingFluid/fluid_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleSplashNavigation();
  }

  Future<void> _handleSplashNavigation() async {
    await Future.delayed(
      const Duration(seconds: 3),
    ); // Show splash for 3 seconds

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      final user = FirebaseAuth.instance.currentUser;

      if (!hasSeenOnboarding) {
        // ✅ First time user → show onboarding first
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FluidHome(),
          ),
        );
      } else {
        if (user == null) {
          // ✅ Already seen onboarding but NOT logged in → go to auth
          Navigator.pushReplacementNamed(context, '/auth');
        } else {
          // ✅ Already logged in → go to home
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      // ❌ If anything fails → restart onboarding → auth flow
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FluidHome(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Image.asset(
            'assets/images/busKahanHay_Logo.png',
            width: MediaQuery.of(context).size.width * 0.7,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
