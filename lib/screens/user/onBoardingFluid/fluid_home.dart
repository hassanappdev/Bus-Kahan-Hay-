import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:bus_kahan_hay/screens/user/onBoardingFluid/fluid_card.dart';
import 'package:bus_kahan_hay/screens/user/onBoardingFluid/fluid_carousel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FluidHome extends StatefulWidget {
  const FluidHome({super.key});

  @override
  State<FluidHome> createState() => _FluidHomeState();
}

class _FluidHomeState extends State<FluidHome> {
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    Navigator.pushNamed(context, '/auth');
  }

  void _handleLastPageReached() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            FluidCarousel(
              onLastPageReached: _handleLastPageReached,

              children: <Widget>[
                FluidCard(
                  title: "Find Your Route\nwith Just a Few Taps",
                  subtitle: "Easily discover available bus routes in Karachi",
                  illustration: 'assets/images/route_finder.svg',
                  index: 0,
                ),
                FluidCard(
                  title: "Track Buses\nLive on the Map",
                  subtitle: "Stay updated with real-time bus locations",
                  illustration: 'assets/images/live_tracking.svg',
                  index: 1,
                ),
                FluidCard(
                  title: "Save Time\nand Travel Smart",
                  subtitle: "Get estimated fares and travel times",
                  illustration: 'assets/images/smart_travel.svg',
                  onButtonTap: _completeOnboarding,
                  isLastCard: true,
                  index: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
