import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FluidCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String illustration;
  final VoidCallback? onButtonTap;
  final bool isLastCard;
  final int index;

  const FluidCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustration,
    this.onButtonTap,
    this.isLastCard = false,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top spacing for better balance
            const Spacer(flex: 1),

            // Illustration with enhanced container
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.green.withOpacity(0.08),
                    AppColors.green.withOpacity(0.03),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.green.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  illustration,
                  width: 200,
                  height: 200,
                  // Remove colorFilter to preserve original SVG colors
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Title with improved typography
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.green, // Solid green color
                height: 1.2,
                letterSpacing: -0.8,
              ),
            ),

            const SizedBox(height: 24),

            // Subtitle with better readability
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey[700],
                fontWeight: FontWeight.w400,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 50),

            // Enhanced page indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.04),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppColors.green.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (dotIndex) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.fastOutSlowIn,
                    width: index == dotIndex ? 28 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: index == dotIndex
                          ? AppColors.green
                          : AppColors.green.withOpacity(0.25),
                      boxShadow: index == dotIndex
                          ? [
                              BoxShadow(
                                color: AppColors.green.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            const Spacer(flex: 2),

            // Enhanced Get Started Button for last card
            if (isLastCard)
              Container(
                width: double.infinity,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(31),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withOpacity(0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onButtonTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(31),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, size: 22),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

