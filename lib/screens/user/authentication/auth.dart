import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:bus_kahan_hay/core/images_path.dart';
import 'package:flutter/material.dart';

class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -height * 0.1,
              right: -width * 0.15,
              child: Container(
                width: width * 0.6,
                height: width * 0.6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.green.withOpacity(0.6),
                      AppColors.green.withOpacity(0.3),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -height * 0.2,
              left: -width * 0.15,
              child: Container(
                width: width * 0.7,
                height: width * 0.7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF8BBD9).withOpacity(0.4),
                      Color(0xFFE1BEE7).withOpacity(0.3),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo with better spacing
                    Container(
                      margin: EdgeInsets.only(bottom: height * 0.04),
                      child: Hero(
                        tag: 'app-logo',
                        child: Image.asset(
                          ImagesPath.appLogo,
                          width: width * 0.5,
                          height: width * 0.5,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // App Title
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Text(
                        "Bus Kahan Hay",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                          letterSpacing: -0.8,
                          fontFamily: 'LeagueSpartan',
                          height: 1.1,
                        ),
                      ),
                    ),

                    // Main Description - Improved readability
                    Container(
                      margin: EdgeInsets.only(bottom: height * 0.06),
                      padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                      child: Column(
                        children: [
                          Text(
                            "Your smart companion for",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(
                                0xFF424242,
                              ), // Darker gray for better contrast
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "seamless bus travel in Karachi",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF424242),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Buttons Section
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 30),
                      child: Column(
                        children: [
                          // User Sign Up Button
                          Container(
                            width: width * 0.8,
                            height: 56,
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.green.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    'User Sign Up',
                                    style: TextStyle(
                                      fontFamily: 'LeagueSpartan',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Driver Sign Up Button
                          Container(
                            width: width * 0.8,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppColors.green,
                                width: 2,
                              ),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/driver-signup');
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions_bus_rounded, size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    'Driver Sign Up',
                                    style: TextStyle(
                                      fontFamily: 'LeagueSpartan',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Additional info text
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                      child: Text(
                        "Join thousands of commuters navigating Karachi smarter",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    // Bottom spacing
                    SizedBox(height: height * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
