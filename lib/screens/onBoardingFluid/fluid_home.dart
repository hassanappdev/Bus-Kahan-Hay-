import 'package:bus_kahan_hay/screens/onBoardingFluid/fluid_card.dart';
import 'package:bus_kahan_hay/screens/onBoardingFluid/fluid_carousel.dart';
import 'package:bus_kahan_hay/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FluidHome extends StatefulWidget {
  const FluidHome({super.key, required this.title});

  final String title;

  @override
  State<FluidHome> createState() => _FluidHomeState();
}

class _FluidHomeState extends State<FluidHome> {
  final FluidCarouselState _carouselState = FluidCarouselState();
  int _currentPage = 0;

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
    return Scaffold(
      body: Stack(
        children: [
          FluidCarousel(
            onLastPageReached: _handleLastPageReached,
            children: <Widget>[
              FluidCard(
                color: 'Red',
                altColor: Color(0xFF4259B2),
                title: "Find Your Route \nwith Just a Few Taps",
                subtitle: "Easily discover available bus routes...",
              ),
              FluidCard(
                color: 'Yellow',
                altColor: Color(0xFF904E93),
                title: "Track Buses \nLive on the Map",
                subtitle: "Stay updated with real-time bus locations...",
              ),
              FluidCard(
                color: 'Blue',
                altColor: Color(0xFFFFB138),
                title: "Save Time \nand Travel Smart",
                subtitle: "Get estimated fares and travel times...",
                onButtonTap: _completeOnboarding,
                isLastCard: true,
              ),
            ],
          ),

          // Page indicator
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
