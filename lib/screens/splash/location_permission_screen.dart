// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../home/home.dart';

// class LocationPermissionScreen extends StatefulWidget {
//   const LocationPermissionScreen({Key? key}) : super(key: key);

//   @override
//   _LocationPermissionScreenState createState() =>
//       _LocationPermissionScreenState();
// }

// class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
//   bool _isLoading = false;

//   // LOCATION ENABLE POPUP
//   Future<void> _handlePermission() async {
//     setState(() => _isLoading = true);

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.whileInUse ||
//         permission == LocationPermission.always) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool('locationAllowed', true);
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const Home()),
//       );
//     } else {
//       setState(() => _isLoading = false);
//       _showPermissionDeniedDialog();
//     }
//   }

//   // IF USER DENY THE LOCATION PERMISSION
//   void _showPermissionDeniedDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Permission Required'),
//         content: const Text('Please allow location access to use this app.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _handlePermission();
//             },
//             child: const Text('Try Again'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(
//               minHeight: screenHeight - MediaQuery.of(context).padding.vertical,
//             ),
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: screenWidth * 0.05,
//                 vertical: 20,
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.location_pin,
//                     size: screenHeight * 0.12,
//                     color: const Color(0xFFED130F),
//                   ),
//                   SizedBox(height: screenHeight * 0.03),
//                   Text(
//                     'Track Buses in Real-Time',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: screenWidth * 0.065,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.02),
//                   Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: screenWidth * 0.05,
//                     ),
//                     child: Text(
//                       'Enable location access to find nearby buses, stops, and get accurate arrival times.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: screenWidth * 0.04,
//                         color: Colors.grey[700],
//                         height: 1.5,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.06),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _isLoading ? null : _handlePermission,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF009B37),
//                         padding: EdgeInsets.symmetric(
//                           vertical: screenHeight * 0.02,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 3,
//                       ),
//                       child: _isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : Text(
//                               'Allow Location Access',
//                               style: TextStyle(
//                                 fontSize: screenWidth * 0.045,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.white,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
