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

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/driver-login',
      (route) => false,
    );
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
      appBar: AppBar(
        backgroundColor: AppColors.green,
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logoutDriver),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Driver Info Card
                _buildDriverInfoCard(),
                const SizedBox(height: 8),

                // Control Buttons
                _buildControlButtons(),
                const SizedBox(height: 8),

                // Map Section
                Expanded(child: _buildMapSection()),
              ],
            ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Bus: $_busRegNumber'),
                Text('Route: $_route'),
              ],
            ),
            Column(
              children: [
                const Text('Current Speed'),
                Text(
                  '${_currentSpeed.toStringAsFixed(1)} km/h',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _currentSpeed > 0 ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.red : AppColors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_isTracking) {
                  _stopLocationTracking();
                } else {
                  _startLocationTracking();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Stack(
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
                : const LatLng(33.6844, 73.0479), // Default to Islamabad
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
          child: FloatingActionButton.small(
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ),

        // Loading overlay when tracking
        if (_isTracking)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'LIVE TRACKING',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
            child: FloatingActionButton.small(
              onPressed: _openAppSettings,
              child: const Icon(Icons.settings),
            ),
          ),
      ],
    );
  }
}
