import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:bus_kahan_hay/data/local/driver_local_data.dart';
import 'package:bus_kahan_hay/screens/authentication/toast_msg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverSignup extends StatefulWidget {
  const DriverSignup({super.key});

  @override
  State<DriverSignup> createState() => _DriverSignupState();
}

class _DriverSignupState extends State<DriverSignup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _busRegController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Create Firebase Collection for drivers
  final drivers = FirebaseFirestore.instance.collection('drivers');

  // Bus Reg Number Regex (JB-4682 followed by 2 digits)
  final RegExp busRegExp = RegExp(r'^JB-46\d{2}$');

  // Phone Number Regex (Pakistani format)
  final RegExp phoneRegExp = RegExp(r'^03[0-9]{9}$');

  // Route Regex (R followed by numbers)
  final RegExp routeRegExp = RegExp(r'^R[0-9]+$');

  // 💨 Driver SignUp Function
  bool loader = false;
  Future<void> regDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loader = true;
    });

    try {
      // Create email from bus reg number (unique identifier)
      String driverEmail = "${_busRegController.text.trim()}@bus.com";

      // 1. Create driver in Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: driverEmail,
            password: _passwordController.text,
          );

      // 2. Save driver details to Firestore with UID as doc ID
      final uid = credential.user!.uid;

      // ADD DRIVER DATA TO THE FIRESTORE DATABASE COLLECTION
      await drivers.doc(uid).set({
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "busRegNumber": _busRegController.text.trim(),
        "route": _routeController.text.trim(),
        "password": _passwordController.text.trim(),
        "role": "driver",
        "isActive": false, // Driver starts as inactive
        "currentLocation": null,
        "speed": 0.0,
        "lastUpdated": FieldValue.serverTimestamp(),
      });

      ToastMsg.showToastMsg('Driver Registration Successful');

      setState(() {
        loader = false;
      });

      // SAVE DRIVER INFORMATION in SHARED PREFERENCES
      DriverLocalData.saveDriverData(
        name: _nameController.text.trim(),
        busRegNumber: _busRegController.text.trim(),
        route: _routeController.text.trim(),
      );

      // Short delay just to show toast
      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacementNamed(context, '/driver-home');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ToastMsg.showToastMsg('The password provided is too weak');
      } else if (e.code == 'email-already-in-use') {
        ToastMsg.showToastMsg(
          'Driver with this Bus Reg Number already exists.',
        );
      } else {
        ToastMsg.showToastMsg('Registration failed: ${e.message}');
      }
    } catch (e) {
      print('Error: $e');
      ToastMsg.showToastMsg('Something went wrong. Please try again.');
    } finally {
      if (loader) {
        setState(() {
          loader = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _busRegController.dispose();
    _routeController.dispose();
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
                    'Driver Sign Up',
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
                          'Create Driver Account',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Sign up as a bus driver',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),

                        // Full Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 15,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            if (value.length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Phone Number Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 15,
                            ),
                            hintText: '03XXXXXXXXX',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (!phoneRegExp.hasMatch(value)) {
                              return 'Please enter a valid Pakistani phone number (03XXXXXXXXX)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

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
                            hintText: 'JB-4600',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter bus registration number';
                            }
                            if (!busRegExp.hasMatch(value)) {
                              return 'Format must be JB-46XX (e.g., JB-4600, JB-4615)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Route Field
                        TextFormField(
                          controller: _routeController,
                          decoration: InputDecoration(
                            labelText: 'Route',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.route),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 15,
                            ),
                            hintText: 'R1, R2, R3, etc.',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your route';
                            }
                            if (!routeRegExp.hasMatch(value)) {
                              return 'Format must be R followed by numbers (e.g., R1)';
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
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // Sign Up Button
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
                            onPressed: regDriver,
                            child: Center(
                              child: loader
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Sign Up as Driver',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Login redirect
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have a driver account?'),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/driver-login');
                              },
                              child: Text(
                                'Driver Login',
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
