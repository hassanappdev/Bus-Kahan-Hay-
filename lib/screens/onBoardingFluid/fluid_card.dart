import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:flutter/material.dart';

class FluidCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String illustration;
  final VoidCallback? onButtonTap;
  final bool isLastCard;
  final Color backgroundColor;
  final int index;

  const FluidCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.backgroundColor,
    this.onButtonTap,
    this.isLastCard = false,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Different background colors for each card to show animation
    final List<Color> cardColors = [
      AppColors.green,
      Color(0xFF1E8449), // Darker green
      Color(0xFF2ECC71), // Lighter green
    ];

    return Container(
      color: cardColors[index],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Expanded(
              flex: 3,
              child: Image.asset(
                illustration,
                fit: BoxFit.contain,
                width: 250,
                height: 250,
              ),
            ),

            const SizedBox(height: 30),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 15),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),

            const SizedBox(height: 30),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (dotIndex) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == dotIndex
                        ? AppColors.red
                        : Colors.white.withOpacity(0.1),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Get Started Button for last card
            if (isLastCard)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onButtonTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}


