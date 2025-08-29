// import 'package:bus_kahan_hay/core/app_colors.dart';
// import 'package:bus_kahan_hay/data/local/user_local_data.dart';
// import 'package:bus_kahan_hay/screens/authentication/toast_msg.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class Login extends StatefulWidget {
//   const Login({super.key});

//   @override
//   State<Login> createState() => _LoginState();
// }

// class _LoginState extends State<Login> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   bool loader = false;

//   loginUser() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       loader = true;
//     });

//     try {
//       final userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(
//             email: _emailController.text.trim(),
//             password: _passwordController.text,
//           );

//       final user = FirebaseAuth.instance.currentUser;

//       if (user != null) {
//         final userDoc = await FirebaseFirestore.instance
//             .collection("users")
//             .doc(user.uid)
//             .get();

//         final role = userDoc.data()?['role'];
//         final name = userDoc.data()?['name'] ?? '';
//         final email = user.email ?? '';

//         // ✅ Save to SharedPreferences
//         UserLocalData.saveUserData(name: name, email: email);

//         // Navigate
//         if (role == "admin") {
//           ToastMsg.showToastMsg('Login successful as admin');
//           Navigator.pushReplacementNamed(context, '/admin-home');
//         } else {
//           ToastMsg.showToastMsg('Login successful');
//           Navigator.pushReplacementNamed(context, '/home');
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'user-not-found') {
//         ToastMsg.showToastMsg('No user found for that email.');
//       } else if (e.code == 'wrong-password') {
//         ToastMsg.showToastMsg('Wrong password provided.');
//       } else if (e.code == 'invalid-email') {
//         ToastMsg.showToastMsg('Invalid email address.');
//       } else {
//         ToastMsg.showToastMsg('Login failed: ${e.message}');
//       }
//     } catch (e) {
//       ToastMsg.showToastMsg('Unexpected error: $e');
//     } finally {
//       setState(() {
//         loader = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final height = MediaQuery.of(context).size.height;

//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: AppColors.green,
//         body: Stack(
//           children: [
//             Positioned(
//               top: 60,
//               left: 0,
//               right: 0,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // IconButton(
//                     //   icon: const Icon(Icons.arrow_back),
//                     //   color: Colors.white,
//                     //   onPressed: () => Navigator.pop(context),
//                     // ),
//                     Center(
//                       child: const Text(
//                         textAlign: TextAlign.center,
//                         'Login',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 40), // To balance spacing
//                   ],
//                 ),
//               ),
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Container(
//                 width: width,
//                 height: height * 0.75,
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(30),
//                     topRight: Radius.circular(30),
//                   ),
//                 ),
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const SizedBox(height: 20),
//                         const Text(
//                           'Welcome Back',
//                           style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         const Text(
//                           'Login to your account',
//                           style: TextStyle(fontSize: 16, color: Colors.grey),
//                         ),
//                         const SizedBox(height: 30),
//                         // Email Field
//                         TextFormField(
//                           controller: _emailController,
//                           keyboardType: TextInputType.emailAddress,
//                           decoration: InputDecoration(
//                             labelText: 'Email',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.email),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter your email';
//                             }
//                             if (!RegExp(
//                               r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                             ).hasMatch(value)) {
//                               return 'Please enter a valid email';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         // Password Field
//                         TextFormField(
//                           controller: _passwordController,
//                           obscureText: true,
//                           decoration: InputDecoration(
//                             labelText: 'Password',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             prefixIcon: const Icon(Icons.lock),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter your password';
//                             }
//                             if (value.length < 6) {
//                               return 'Password must be at least 6 characters';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 10),
//                         // Forgot Password
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton(
//                             onPressed: () {
//                               Navigator.pushNamed(context, '/forgot-password');
//                             },
//                             child: Text(
//                               'Forgot Password?',
//                               style: TextStyle(color: AppColors.green),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         // Login Button
//                         SizedBox(
//                           width: double.infinity,
//                           height: 50,
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: AppColors.green,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             onPressed: loginUser,
//                             child: Center(
//                               child: loader
//                                   ? CircularProgressIndicator(
//                                       color: Colors.white,
//                                     )
//                                   : Text(
//                                       'Login',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 18,
//                                       ),
//                                     ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 30),
//                         // Or divider
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Divider(
//                                 color: Colors.grey[300],
//                                 thickness: 1,
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                               ),
//                               child: Text(
//                                 'OR',
//                                 style: TextStyle(color: Colors.grey[600]),
//                               ),
//                             ),
//                             Expanded(
//                               child: Divider(
//                                 color: Colors.grey[300],
//                                 thickness: 1,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 30),

//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text("Don't have an account?"),
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.pushNamed(context, '/signup');
//                               },
//                               child: Text(
//                                 'Sign Up',
//                                 style: TextStyle(
//                                   color: AppColors.green,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:bus_kahan_hay/data/local/user_local_data.dart';
import 'package:bus_kahan_hay/screens/authentication/toast_msg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool loader = false;

  loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loader = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        final role = userDoc.data()?['role'];
        final name = userDoc.data()?['name'] ?? '';
        final email = user.email ?? '';

        // ✅ Save to SharedPreferences
        UserLocalData.saveUserData(name: name, email: email);

        // Navigate
        if (role == "admin") {
          ToastMsg.showToastMsg('Login successful as admin');
          Navigator.pushReplacementNamed(context, '/admin-home');
        } else {
          ToastMsg.showToastMsg('Login successful');
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ToastMsg.showToastMsg('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        ToastMsg.showToastMsg('Wrong password provided.');
      } else if (e.code == 'invalid-email') {
        ToastMsg.showToastMsg('Invalid email address.');
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the row
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
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Login to your account',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),

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
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 15,
                            ),
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
                              Navigator.pushNamed(context, '/forgot-password');
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
                            onPressed: loginUser,
                            child: Center(
                              child: loader
                                  ? CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Or divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Sign up redirect
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: Text(
                                'Sign Up',
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
