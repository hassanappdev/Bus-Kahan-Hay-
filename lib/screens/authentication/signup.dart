import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:bus_kahan_hay/data/local/user_local_data.dart';
import 'package:bus_kahan_hay/screens/authentication/toast_msg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Create Firebase Collection
  final users = FirebaseFirestore.instance.collection('users');

  // 💨 SignUp / Register Authentication Function
  bool loader = false;
  Future<void> regUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loader = true;
    });

    try {
      // 1. Create user in Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // 2. Save user details to Firestore with UID as doc ID
      final uid = credential.user!.uid;

      // ADD USER DATA TO THE FIRESTORE DATABASE COLLECTION
      await users.doc(uid).set({
        "name": _nameController.text,
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
        "role": "user", // Default role as requested
      });

      ToastMsg.showToastMsg('Registration Successful');

      setState(() {
        loader = false;
      });

      // SAVE USER INFORMATION in SHARED PREFERENCES FOR DRAWER
      UserLocalData.saveUserData(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      // Short delay just to show toast
      await Future.delayed(Duration(seconds: 1));

      Navigator.pushNamed(context, '/select-profile-picture-screen');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ToastMsg.showToastMsg('The password provided is too weak');
      } else if (e.code == 'email-already-in-use') {
        ToastMsg.showToastMsg(
          'Account already exists. Redirecting to login...',
        );

        // ✅ STOP loader immediately before delay
        setState(() {
          loader = false;
        });

        await Future.delayed(Duration(seconds: 3));
        Navigator.pushNamed(context, '/login');
        return; // stop further execution
      } else {
        ToastMsg.showToastMsg('Registration failed: ${e.message}');
      }
    } catch (e) {
      print('Error: $e');
      ToastMsg.showToastMsg('Something went wrong. Please try again.');
    } finally {
      // ✅ Only stop loader if it hasn't already been stopped
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.green,
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 40), // To balance spacing
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: width,
              height: height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Create an Account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email';
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
                          onPressed: regUser,
                          child: Center(
                            child: loader
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Already have an account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}