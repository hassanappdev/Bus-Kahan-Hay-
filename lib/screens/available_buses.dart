import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:geolocator/geolocator.dart';

class AvailableBuses extends StatefulWidget {
  const AvailableBuses({super.key});

  @override
  State<AvailableBuses> createState() => _AvailableBusesState();
}

class _AvailableBusesState extends State<AvailableBuses> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  bool _isLoading = true;

  // Map variables
  final Set<Marker> _driverMarkers = {};
  final Set<Polyline> _polylines = {};

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _driversSubscription;

  // Marker icons cache
  final Map<String, BitmapDescriptor> _markerIcons = {};

  @override
  void initState() {
    super.initState();
    _initializeUserHome();
  }

  @override
  void dispose() {
    _driversSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeUserHome() async {
    await _getUserLocation();
    await _loadMarkerIcons();
    _startDriversListener();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userPosition = position;
      });
    } catch (e) {
      debugPrint("Error getting user location: $e");
      // Use default location if user location fails
      setState(() {
        _userPosition = null;
      });
    }
  }

  Future<void> _loadMarkerIcons() async {
    // Pre-load some common route marker icons
    final routes = [
      'R1',
      'R2',
      'R3',
      'R4',
      'R5',
      'R6',
      'R7',
      'R8',
      'R9',
      'R10',
    ];

    for (String route in routes) {
      await _createRouteMarkerIcon(route);
    }
  }

  Future<void> _createRouteMarkerIcon(String route) async {
    try {
      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final paint = Paint()..color = AppColors.green;
      final textPainter = TextPainter(textDirection: TextDirection.ltr);

      // Draw circle background
      canvas.drawCircle(Offset(25, 25), 20, paint);

      // Draw route text
      textPainter.text = TextSpan(
        text: route,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(25 - textPainter.width / 2, 25 - textPainter.height / 2),
      );

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(50, 50);
      final bytes = await image.toByteData(format: ImageByteFormat.png);

      if (bytes != null) {
        _markerIcons[route] = BitmapDescriptor.fromBytes(
          bytes.buffer.asUint8List(),
        );
      }
    } catch (e) {
      debugPrint("Error creating marker icon for route $route: $e");
    }
  }

  BitmapDescriptor _getMarkerIcon(String route) {
    return _markerIcons[route] ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  void _startDriversListener() {
    _driversSubscription = _firestore
        .collection('drivers')
        .where('isActive', isEqualTo: true)
        .where('currentLocation', isNotEqualTo: null)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
          _updateDriverMarkers(snapshot);
        });
  }

  void _updateDriverMarkers(QuerySnapshot snapshot) {
    final Set<Marker> updatedMarkers = {};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final driverId = doc.id;
      final route = data['route'] ?? 'Unknown';
      final name = data['name'] ?? 'Driver';
      final busRegNumber = data['busRegNumber'] ?? 'Unknown';
      final speed = data['speed'] ?? 0.0;
      final location = data['currentLocation'] as Map<String, dynamic>?;
      final lastUpdated = data['lastUpdated'] as Timestamp?;

      if (location != null) {
        final latitude = location['latitude'] as double;
        final longitude = location['longitude'] as double;

        final marker = Marker(
          markerId: MarkerId(driverId),
          position: LatLng(latitude, longitude),
          icon: _getMarkerIcon(route),
          infoWindow: InfoWindow(
            title: 'Route $route',
            snippet:
                'Driver: $name\nBus: $busRegNumber\nSpeed: ${speed.toStringAsFixed(1)} km/h',
          ),
          onTap: () {
            _showDriverInfo(
              context,
              name,
              busRegNumber,
              route,
              speed,
              lastUpdated,
            );
          },
        );

        updatedMarkers.add(marker);
      }
    }

    setState(() {
      _driverMarkers.clear();
      _driverMarkers.addAll(updatedMarkers);
    });
  }

  void _showDriverInfo(
    BuildContext context,
    String name,
    String busRegNumber,
    String route,
    double speed,
    Timestamp? lastUpdated,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Route $route - Driver Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: $name'),
            Text('Bus: $busRegNumber'),
            Text('Speed: ${speed.toStringAsFixed(1)} km/h'),
            if (lastUpdated != null)
              Text('Last Updated: ${_formatTime(lastUpdated.toDate())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _zoomToUserLocation() {
    if (_userPosition != null) {
      final latLng = LatLng(_userPosition!.latitude, _userPosition!.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
    }
  }

  void _zoomToAllDrivers() {
    if (_driverMarkers.isNotEmpty) {
      final LatLngBounds bounds = _calculateBounds(_driverMarkers);
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  LatLngBounds _calculateBounds(Set<Marker> markers) {
    double? minLat, maxLat, minLng, maxLng;

    for (final marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
    }

    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLng ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.green,
          title: const Text(
            'Available Buses',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _zoomToUserLocation,
              tooltip: 'My Location',
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              onPressed: _zoomToAllDrivers,
              tooltip: 'View All Buses',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) {
                      setState(() {
                        _mapController = controller;
                      });
                    },
                    initialCameraPosition: CameraPosition(
                      target: _userPosition != null
                          ? LatLng(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                            )
                          : const LatLng(
                              33.6844,
                              73.0479,
                            ), // Default to Islamabad
                      zoom: 14,
                    ),
                    markers: _driverMarkers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),

                  // Current location button
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          onPressed: _zoomToUserLocation,
                          child: const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          onPressed: _zoomToAllDrivers,
                          child: const Icon(Icons.zoom_out_map),
                        ),
                      ],
                    ),
                  ),

                  // Driver count indicator
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_bus,
                            color: AppColors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_driverMarkers.length} buses active',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Legend
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Route Legend',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._markerIcons.keys
                              .take(3)
                              .map(
                                (route) => Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Route $route',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                          if (_markerIcons.keys.length > 3)
                            const Text('...', style: TextStyle(fontSize: 10)),
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
