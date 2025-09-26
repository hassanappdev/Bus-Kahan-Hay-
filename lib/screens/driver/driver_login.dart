import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:bus_kahan_hay/data/local/driver_local_data.dart';
import 'package:bus_kahan_hay/screens/authentication/toast_msg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverLogin extends StatefulWidget {
  const DriverLogin({super.key});

  @override
  State<DriverLogin> createState() => _DriverLoginState();
}

class _DriverLoginState extends State<DriverLogin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _busRegController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Bus Reg Number Regex
  final RegExp busRegExp = RegExp(r'^JB-46\d{2}$');

  bool loader = false;

  Future<void> loginDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loader = true;
    });

    try {
      // Convert bus reg number to email format
      String driverEmail = "${_busRegController.text.trim()}@bus.com";

      // Sign in with Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: driverEmail,
        password: _passwordController.text,
      );

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Check if user exists in drivers collection
        final driverDoc = await FirebaseFirestore.instance
            .collection("drivers")
            .doc(user.uid)
            .get();

        if (driverDoc.exists) {
          final driverData = driverDoc.data()!;
          final role = driverData['role'];
          final name = driverData['name'] ?? '';
          final busRegNumber = driverData['busRegNumber'] ?? '';
          final route = driverData['route'] ?? '';

          if (role == "driver") {
            // ✅ Save to SharedPreferences
            DriverLocalData.saveDriverData(
              name: name,
              busRegNumber: busRegNumber,
              route: route,
            );

            ToastMsg.showToastMsg('Driver login successful');

            // Update driver as active
            await FirebaseFirestore.instance
                .collection("drivers")
                .doc(user.uid)
                .update({
                  "isActive": true,
                  "lastUpdated": FieldValue.serverTimestamp(),
                });

            Navigator.pushReplacementNamed(context, '/driver-home');
          } else {
            ToastMsg.showToastMsg('Access denied. Not a driver account.');
            await FirebaseAuth.instance.signOut();
          }
        } else {
          ToastMsg.showToastMsg('Driver account not found.');
          await FirebaseAuth.instance.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ToastMsg.showToastMsg(
          'No driver found with this bus registration number.',
        );
      } else if (e.code == 'wrong-password') {
        ToastMsg.showToastMsg('Wrong password provided.');
      } else {
        ToastMsg.showToastMsg('Login failed: ${e.message}');
      }
    } catch (e) {
      ToastMsg.showToastMsg('Unexpected error: $e');
    } finally {
      setState(() {
        loader = false;
      });
    }
  }

  @override
  void dispose() {
    _busRegController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.green,
        body: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Driver Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Form Section
            Expanded(
              child: Container(
                width: width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Driver Login',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Login to your driver account',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),

                        // Bus Reg Number Field
                        TextFormField(
                          controller: _busRegController,
                          decoration: InputDecoration(
                            labelText: 'Bus Registration Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.directions_bus),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 15,
                            ),
                            hintText: 'JB-4682',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter bus registration number';
                            }
                            if (!busRegExp.hasMatch(value)) {
                              return 'Format must be JB-4682 (e.g., JB-4682)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 15,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to driver forgot password screen
                              // Navigator.pushNamed(context, '/driver-forgot-password');
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: AppColors.green),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: loginDriver,
                            child: Center(
                              child: loader
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Driver Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Sign up redirect
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have a driver account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/driver-signup');
                              },
                              child: Text(
                                'Driver Sign Up',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
