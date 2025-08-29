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
        backgroundColor: Colors.white, // ✅ White background
        body: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -height * 0.15,
              right: -width * 0.2,
              child: Container(
                width: width * 0.7,
                height: width * 0.7,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.55), // ✅ Soft green
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -height * 0.25,
              left: -width * 0.2,
              child: Container(
                width: width * 0.8,
                height: width * 0.8,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.5), // ✅ Soft red
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main content - Centered properly
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with hero animation
                    Hero(
                      tag: 'app-logo',
                      child: Image.asset(
                        ImagesPath.appLogo,
                        width: width * 0.50,
                        height: width * 0.50,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Description text
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.1),
                      child: Text(
                        "Your smart companion for bus routes\nand hassle-free travel",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.black, // ✅ Dark text
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Login Button
                    SizedBox(
                      width: width * 0.7,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green, // ✅ Green button
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Sign Up Button
                    SizedBox(
                      width: width * 0.7,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: AppColors.black,
                              width: 1.5,
                            ),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
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
