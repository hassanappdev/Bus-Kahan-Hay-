import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:bus_kahan_hay/screens/onBoardingFluid/fluid_card.dart';
import 'package:bus_kahan_hay/screens/onBoardingFluid/fluid_carousel.dart';
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
        backgroundColor: AppColors.green,
        body: FluidCarousel(
          onLastPageReached: _handleLastPageReached,
          children: <Widget>[
            FluidCard(
              title: "Find Your Route\nwith Just a Few Taps",
              subtitle: "Easily discover available bus routes in Karachi",
              illustration: 'assets/images/red_bus.png', // Red bus illustration
              backgroundColor: AppColors.green,
              index: 0,
            ),
            FluidCard(
              title: "Track Buses\nLive on the Map",
              subtitle: "Stay updated with real-time bus locations",
              illustration:
                  'assets/images/mobile_map.png', // Mobile with map illustration
              backgroundColor: AppColors.green,
              index: 1,
            ),
            FluidCard(
              title: "Save Time\nand Travel Smart",
              subtitle: "Get estimated fares and travel times",
              illustration:
                  'assets/images/man_dollar.png', // Man with dollar illustration
              backgroundColor: AppColors.green,
              onButtonTap: _completeOnboarding,
              isLastCard: true,
              index: 2,
            ),
          ],
        ),
      ),
    );
  }
}
