import 'package:bus_kahan_hay/fluid/fluid_card.dart';
import 'package:bus_kahan_hay/fluid/fluid_carousel.dart';
import 'package:flutter/material.dart';


class FluidHome extends StatefulWidget {
  const FluidHome({super.key, required this.title});

  final String title;

  @override
  State<FluidHome> createState() => _FluidHomeState();
}

class _FluidHomeState extends State<FluidHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FluidCarousel(
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
          ),
        ],
      ),
    );
  }
}
