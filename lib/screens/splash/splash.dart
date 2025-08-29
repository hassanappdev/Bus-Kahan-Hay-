import 'package:bus_kahan_hay/screens/onBoardingFluid/fluid_home.dart';

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
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3)); // 3 seconds splash

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      if (!hasSeenOnboarding) {
        // First time - show onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FluidHome(title: 'Fluid Splash'),
          ),
        );
      } else {
        // Already seen onboarding - go to appropriate screen
        Navigator.pushNamed(context, '/home');
      }
    } catch (e) {
      // If any error occurs, default to onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FluidHome(title: 'Fluid Splash'),
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
