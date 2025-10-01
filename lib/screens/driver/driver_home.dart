import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_kahan_hay/data/local/driver_local_data.dart';
import 'package:bus_kahan_hay/core/app_colors.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isTracking = false;
  double _currentSpeed = 0.0;
  String _driverName = '';
  String _busRegNumber = '';
  String _route = '';

  // Map variables
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];

  // Location tracking
  StreamSubscription<Position>? _positionSubscription;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeDriver();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stopLocationTracking();
    super.dispose();
  }

  Future<void> _initializeDriver() async {
    await _loadDriverData();
    await _getCurrentLocation();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadDriverData() async {
    final name = await DriverLocalData.getDriverName();
    final busReg = await DriverLocalData.getDriverBusReg();
    final route = await DriverLocalData.getDriverRoute();

    setState(() {
      _driverName = name ?? 'Driver';
      _busRegNumber = busReg ?? 'Unknown';
      _route = route ?? 'Unknown';
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable location services.',
        );
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied. Please enable them in app settings.',
        );
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _currentSpeed = position.speed * 3.6; // Convert m/s to km/h
      });

      _updateMapCamera(position);
      _addCurrentLocationMarker(position);
      _updateDriverLocationInFirebase(position);
    } catch (e) {
      debugPrint("Error getting location: $e");
      _showErrorDialog("Error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startLocationTracking() {
    if (_isTracking) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _handleLocationUpdate(position);
          },
        );

    setState(() {
      _isTracking = true;
    });

    // Update driver as active in Firebase
    _updateDriverStatus(true);
  }

  void _stopLocationTracking() {
    _positionSubscription?.cancel();
    setState(() {
      _isTracking = false;
    });

    // Update driver as inactive in Firebase
    _updateDriverStatus(false);
  }

  void _handleLocationUpdate(Position position) {
    setState(() {
      _currentPosition = position;
      _currentSpeed = position.speed * 3.6; // Convert to km/h
    });

    _updateMapCamera(position);
    _updateCurrentLocationMarker(position);
    _addToRoutePolyline(position);
    _updateDriverLocationInFirebase(position);
  }

  void _updateMapCamera(Position position) {
    final latLng = LatLng(position.latitude, position.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
  }

  void _addCurrentLocationMarker(Position position) {
    final marker = Marker(
      markerId: const MarkerId('current_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: 'Current Location',
        snippet: 'Speed: ${_currentSpeed.toStringAsFixed(1)} km/h',
      ),
    );

    setState(() {
      _markers.clear();
      _markers.add(marker);
    });
  }

  void _updateCurrentLocationMarker(Position position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Current Location',
            snippet: 'Speed: ${_currentSpeed.toStringAsFixed(1)} km/h',
          ),
        ),
      );
    });
  }

  void _addToRoutePolyline(Position position) {
    final newPoint = LatLng(position.latitude, position.longitude);
    _routePoints.add(newPoint);

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: AppColors.green,
          width: 4,
        ),
      );
    });
  }

  Future<void> _updateDriverLocationInFirebase(Position position) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('drivers').doc(user.uid).update({
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'speed': _currentSpeed,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': true,
        'route': _route,
      });
    } catch (e) {
      print('Error updating Firebase: $e');
    }
  }

  Future<void> _updateDriverStatus(bool isActive) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('drivers').doc(user.uid).update({
        'isActive': isActive,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating driver status: $e');
    }
  }

  Future<void> _logoutDriver() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    _stopLocationTracking();
    await _updateDriverStatus(false);
    await DriverLocalData.clearDriverData();
    await _auth.signOut();

    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint("Error opening app settings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.green))
          : Column(
              children: [
                // Enhanced Header Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.green, Color(0xFF1E8449)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Welcome back, $_driverName',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded, size: 24),
                            color: Colors.white,
                            onPressed: _logoutDriver,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Driver Info Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                color: AppColors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _driverName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_bus_rounded,
                                color: Colors.grey[600],
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bus: $_busRegNumber',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.route_rounded,
                                color: Colors.grey[600],
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Route: $_route',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.green, Color(0xFF1E8449)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_currentSpeed.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'km/h',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Control Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTracking
                                  ? Colors.red
                                  : AppColors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              if (_isTracking) {
                                _stopLocationTracking();
                              } else {
                                _startLocationTracking();
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isTracking
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isTracking
                                      ? 'Stop Tracking'
                                      : 'Start Tracking',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _getCurrentLocation,
                          child: const Icon(Icons.my_location_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Map Section
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: (controller) {
                          setState(() {
                            _mapController = controller;
                          });
                        },
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition != null
                              ? LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                )
                              : const LatLng(
                                  33.6844,
                                  73.0479,
                                ), // Default to Islamabad
                          zoom: 14,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        compassEnabled: true,
                        zoomControlsEnabled: false,
                      ),

                      // Current location button
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          onPressed: _getCurrentLocation,
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.green,
                          child: const Icon(Icons.my_location_rounded),
                        ),
                      ),

                      // Live tracking indicator
                      if (_isTracking)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'LIVE TRACKING',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Settings button for permission issues
                      if (_currentPosition == null)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: FloatingActionButton(
                            onPressed: _openAppSettings,
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.green,
                            child: const Icon(Icons.settings_rounded),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
