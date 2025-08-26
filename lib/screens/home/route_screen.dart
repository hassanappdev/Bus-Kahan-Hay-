import 'dart:async';
import 'dart:ui' as ui;

import 'package:bus_kahan_hay/model/bus_routes.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bus_kahan_hay/services/route_finder.dart';

class RouteScreen extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final List<BusRoute> routes;
  final String startAddress;
  final String endAddress;

  const RouteScreen({
    required this.startLocation,
    required this.endLocation,
    required this.routes,
    required this.startAddress,
    required this.endAddress,
  });

  @override
  _RouteScreenState createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  late GoogleMapController mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  BusRoute? _bestRoute;
  BusRoute? _alternativeStartRoute;
  BusRoute? _alternativeEndRoute;
  LatLng? _nearestStartPoint;
  LatLng? _nearestEndPoint;
  LatLng? _alternativeStartPoint;
  LatLng? _alternativeEndPoint;
  double? _walkingDistanceStart;
  double? _walkingDistanceEnd;
  double? _alternativeWalkingDistanceStart;
  double? _alternativeWalkingDistanceEnd;
  bool _isLoading = true;
  bool _hasDirectRoute = false;
  bool _hasAlternativeRoute = false;
  String _routeInstructions = '';
  bool _showDetails = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  // For step-by-step visualization
  int _currentStep = 0;
  List<Map<String, dynamic>> _alternativeSteps = [];

  // Theme Colors
  final Color primaryColor = const Color(0xFFEC130F); // Red
  final Color secondaryColor = const Color(0xFF009B37); // Green
  final Color darkColor = const Color(0xFF000000); // Black
  final Color lightColor = const Color(0xFFF5F5F5); // Light background

  // Route Colors
  final Color _walkingColor = const Color(0xFF4285F4); // Blue
  final Color _directBusColor = const Color(0xFF009B37); // Green (from theme)
  final Color _alternativeBusColor = const Color(0xFFEC130F); // Red (from theme)
  final Color _noRouteColor = const Color(0xFF9E9E9E); // Grey
  final Color _transferColor = const Color(0xFFFF9800); // Orange for transfers

  late BitmapDescriptor _startIcon;
  late BitmapDescriptor _endIcon;
  late BitmapDescriptor _busStopIcon;
  late BitmapDescriptor _alternativeStopIcon;
  late BitmapDescriptor _transferIcon;
  late BitmapDescriptor _currentStepIcon;
  late BitmapDescriptor _nextStepIcon;

@override
void initState() {
  super.initState();
  _loadMarkerIcons().then((_) async {
    await _findBestRoute();
    _startLocationTracking();
  });
}

    void dispose() {
  _positionStream?.cancel();
  super.dispose();
}

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get current position once
    _currentPosition = await Geolocator.getCurrentPosition();

    // Start listening to location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  Future<void> _loadMarkerIcons() async {
    _startIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(40, 40)),
      'assets/images/user_location.png',
    );
    _endIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(40, 40)),
      'assets/images/destination.png',
    );
    _busStopIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/images/bus_stop.png',
    );
    _alternativeStopIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/images/bus_stop_alt.png',
    );
    _transferIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/images/transfer.png',
    );
    
    // Create custom icons for current and next steps
    _currentStepIcon = await _createCustomIcon(Colors.green, Icons.directions_walk);
    _nextStepIcon = await _createCustomIcon(Colors.blue, Icons.directions_bus);
  }

  Future<BitmapDescriptor> _createCustomIcon(Color color, IconData iconData) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw circle background
    canvas.drawCircle(Offset(15, 15), 15, paint);

    // Draw icon
    final iconStr = String.fromCharCode(iconData.codePoint);
    textPainter.text = TextSpan(
      text: iconStr,
      style: TextStyle(
        fontSize: 20,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, 5));

    final image = await pictureRecorder.endRecording().toImage(30, 30);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _findBestRoute() async {
    final routeFinder = RouteFinder(widget.routes);
    _bestRoute = routeFinder.findBestRoute(
      widget.startLocation,
      widget.endLocation,
    );

    if (_bestRoute != null) {
      await _setupDirectRoute(routeFinder);
      return;
    }
    await _findAlternativeRoutes(routeFinder);
  }

  Future<void> _setupDirectRoute(RouteFinder routeFinder) async {
    _nearestStartPoint = routeFinder.findNearestPointOnRoute(
      widget.startLocation,
      _bestRoute!,
    );
    _nearestEndPoint = routeFinder.findNearestPointOnRoute(
      widget.endLocation,
      _bestRoute!,
    );

    const maxWalkingDistance = 2000;
    _walkingDistanceStart = Geolocator.distanceBetween(
      widget.startLocation.latitude,
      widget.startLocation.longitude,
      _nearestStartPoint!.latitude,
      _nearestStartPoint!.longitude,
    );
    _walkingDistanceEnd = Geolocator.distanceBetween(
      _nearestEndPoint!.latitude,
      _nearestEndPoint!.longitude,
      widget.endLocation.latitude,
      widget.endLocation.longitude,
    );

    if (_walkingDistanceStart! > maxWalkingDistance ||
        _walkingDistanceEnd! > maxWalkingDistance) {
      await _findAlternativeRoutes(routeFinder);
      return;
    }

    _routeInstructions =
        '1. Walk ${_walkingDistanceStart!.toStringAsFixed(0)}m to board ${_bestRoute!.name} at this stop\n'
        '2. Ride ${_bestRoute!.name} to the drop-off point\n'
        '3. Walk ${_walkingDistanceEnd!.toStringAsFixed(0)}m to your destination';

    setState(() {
      _hasDirectRoute = true;
      _isLoading = false;
    });

    await _updateMap();
    _zoomToFit();
  }

  Future<void> _findAlternativeRoutes(RouteFinder routeFinder) async {
    _alternativeStartRoute = routeFinder.findNearestRoute(widget.startLocation);
    _alternativeEndRoute = routeFinder.findNearestRoute(widget.endLocation);

    if (_alternativeStartRoute == null || _alternativeEndRoute == null) {
      setState(() {
        _isLoading = false;
        _hasAlternativeRoute = false;
      });
      return;
    }

    _alternativeStartPoint = routeFinder.findNearestPointOnRoute(
      widget.startLocation,
      _alternativeStartRoute!,
    );
    _alternativeEndPoint = routeFinder.findNearestPointOnRoute(
      widget.endLocation,
      _alternativeEndRoute!,
    );

    _alternativeWalkingDistanceStart = Geolocator.distanceBetween(
      widget.startLocation.latitude,
      widget.startLocation.longitude,
      _alternativeStartPoint!.latitude,
      _alternativeStartPoint!.longitude,
    );
    _alternativeWalkingDistanceEnd = Geolocator.distanceBetween(
      _alternativeEndPoint!.latitude,
      _alternativeEndPoint!.longitude,
      widget.endLocation.latitude,
      widget.endLocation.longitude,
    );

    // Prepare alternative steps for visualization
    _prepareAlternativeSteps();

    // Build route instructions
    _buildAlternativeRouteInstructions();

    setState(() {
      _hasAlternativeRoute = true;
      _isLoading = false;
    });

    await _updateMap();
    _zoomToFit();
  }

  void _buildAlternativeRouteInstructions() {
    _routeInstructions = '';
    
    for (int i = 0; i < _alternativeSteps.length; i++) {
      final step = _alternativeSteps[i];
      _routeInstructions += '${i + 1}. ${step['instruction']}\n';
    }
  }

  List<LatLng> _getRouteSegment(BusRoute route, LatLng fromPoint, LatLng toPoint) {
    try {
      // Find the closest points in the route path
      int fromIndex = 0;
      double fromMinDistance = double.maxFinite;
      
      int toIndex = 0;
      double toMinDistance = double.maxFinite;
      
      for (int i = 0; i < route.path.length; i++) {
        final point = route.path[i];
        final fromDistance = Geolocator.distanceBetween(
          fromPoint.latitude, fromPoint.longitude,
          point.latitude, point.longitude
        );
        
        final toDistance = Geolocator.distanceBetween(
          toPoint.latitude, toPoint.longitude,
          point.latitude, point.longitude
        );
        
        if (fromDistance < fromMinDistance) {
          fromMinDistance = fromDistance;
          fromIndex = i;
        }
        
        if (toDistance < toMinDistance) {
          toMinDistance = toDistance;
          toIndex = i;
        }
      }
      
      if (fromIndex < toIndex) {
        return route.path.sublist(fromIndex, toIndex + 1);
      } else {
        return route.path.sublist(toIndex, fromIndex + 1).reversed.toList();
      }
    } catch (e) {
      print("Error getting route segment: $e");
    }
    
    return [fromPoint, toPoint];
  }

  void _prepareAlternativeSteps() {
    _alternativeSteps.clear();
    _currentStep = 0;

    int stepNumber = 1;

    // Step 1: Walk to first bus stop
    _alternativeSteps.add({
      'type': 'walk',
      'from': widget.startLocation,
      'to': _alternativeStartPoint!,
      'path': [widget.startLocation, _alternativeStartPoint!],
      'distance': _alternativeWalkingDistanceStart!,
      'instruction': 'Walk ${_alternativeWalkingDistanceStart!.toStringAsFixed(0)}m to board ${_alternativeStartRoute!.name}',
      'stepNumber': stepNumber++,
      'color': _walkingColor,
      'width': 4,
      'pattern': [PatternItem.dash(20), PatternItem.gap(10)],
    });

    if (_alternativeStartRoute!.name == _alternativeEndRoute!.name) {
      // Same route - just ride to destination
      final routePath = _getRouteSegment(
        _alternativeStartRoute!,
        _alternativeStartPoint!,
        _alternativeEndPoint!,
      );

      _alternativeSteps.add({
        'type': 'bus',
        'route': _alternativeStartRoute!,
        'from': _alternativeStartPoint!,
        'to': _alternativeEndPoint!,
        'path': routePath,
        'instruction': 'Ride ${_alternativeStartRoute!.name} for ${(Geolocator.distanceBetween(_alternativeStartPoint!.latitude, _alternativeStartPoint!.longitude, _alternativeEndPoint!.latitude, _alternativeEndPoint!.longitude) / 1000).toStringAsFixed(1)}km',
        'stepNumber': stepNumber++,
        'color': _alternativeBusColor,
        'width': 6,
        'pattern': null,
      });
    } else {
      // Different routes - need transfer
      final transferPoint = _findTransferPoint(_alternativeStartRoute!, _alternativeEndRoute!);

      final firstRoutePath = _getRouteSegment(
        _alternativeStartRoute!,
        _alternativeStartPoint!,
        transferPoint,
      );
      final secondRoutePath = _getRouteSegment(
        _alternativeEndRoute!,
        transferPoint,
        _alternativeEndPoint!,
      );

      _alternativeSteps.add({
        'type': 'bus',
        'route': _alternativeStartRoute!,
        'from': _alternativeStartPoint!,
        'to': transferPoint,
        'path': firstRoutePath,
        'instruction': 'Ride ${_alternativeStartRoute!.name} to transfer point (${(Geolocator.distanceBetween(_alternativeStartPoint!.latitude, _alternativeStartPoint!.longitude, transferPoint.latitude, transferPoint.longitude) / 1000).toStringAsFixed(1)}km)',
        'stepNumber': stepNumber++,
        'color': _alternativeBusColor,
        'width': 6,
        'pattern': null,
      });

      _alternativeSteps.add({
        'type': 'transfer',
        'fromRoute': _alternativeStartRoute!,
        'toRoute': _alternativeEndRoute!,
        'point': transferPoint,
        'path': [transferPoint],
        'instruction': 'Transfer to ${_alternativeEndRoute!.name}',
        'stepNumber': stepNumber++,
        'color': _transferColor,
        'width': 8,
        'pattern': null,
      });

      _alternativeSteps.add({
        'type': 'bus',
        'route': _alternativeEndRoute!,
        'from': transferPoint,
        'to': _alternativeEndPoint!,
        'path': secondRoutePath,
        'instruction': 'Ride ${_alternativeEndRoute!.name} to drop-off point (${(Geolocator.distanceBetween(transferPoint.latitude, transferPoint.longitude, _alternativeEndPoint!.latitude, _alternativeEndPoint!.longitude) / 1000).toStringAsFixed(1)}km)',
        'stepNumber': stepNumber++,
        'color': _alternativeBusColor,
        'width': 6,
        'pattern': null,
      });
    }

    // Final step: Walk to destination
    _alternativeSteps.add({
      'type': 'walk',
      'from': _alternativeEndPoint!,
      'to': widget.endLocation,
      'path': [_alternativeEndPoint!, widget.endLocation],
      'distance': _alternativeWalkingDistanceEnd!,
      'instruction': 'Walk ${_alternativeWalkingDistanceEnd!.toStringAsFixed(0)}m to your destination',
      'stepNumber': stepNumber++,
      'color': _walkingColor,
      'width': 4,
      'pattern': [PatternItem.dash(20), PatternItem.gap(10)],
    });
  }

  LatLng _findTransferPoint(BusRoute route1, BusRoute route2) {
    // Find the closest point between the two routes
    double minDistance = double.maxFinite;
    LatLng transferPoint = route1.path[0];
    
    for (final point1 in route1.path) {
      for (final point2 in route2.path) {
        final distance = Geolocator.distanceBetween(
          point1.latitude, point1.longitude,
          point2.latitude, point2.longitude
        );
        
        if (distance < minDistance) {
          minDistance = distance;
          transferPoint = point1;
        }
      }
    }
    
    return transferPoint;
  }

  void _zoomToFit() async {
    if (_markers.isEmpty) return;
    
    final bounds = _boundsFromLatLngList(
      _markers.map((m) => m.position).toList(),
    );
    
    // Add some padding
    final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);
    
    try {
      await mapController.animateCamera(cameraUpdate);
    } catch (e) {
      // Sometimes bounds are too small, use fallback
      final cameraPosition = CameraPosition(
        target: widget.startLocation,
        zoom: 14,
      );
      mapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (final latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  Future<void> _updateMap() async {
    _markers.clear();
    _polylines.clear();

    // Start and end markers
    _markers.addAll([
      Marker(
        markerId: const MarkerId('start'),
        position: widget.startLocation,
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: widget.startAddress,
        ),
        icon: _startIcon,
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: widget.endLocation,
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.endAddress,
        ),
        icon: _endIcon,
      ),
    ]);

    if (_hasDirectRoute) {
      _markers.addAll([
        Marker(
          markerId: const MarkerId('nearest_start'),
          position: _nearestStartPoint!,
          infoWindow: InfoWindow(
            title: 'Board ${_bestRoute!.name} Here',
            snippet: '${_walkingDistanceStart!.toStringAsFixed(0)}m walk',
          ),
          icon: _busStopIcon,
        ),
        Marker(
          markerId: const MarkerId('nearest_end'),
          position: _nearestEndPoint!,
          infoWindow: InfoWindow(
            title: 'Exit ${_bestRoute!.name} Here',
            snippet: '${_walkingDistanceEnd!.toStringAsFixed(0)}m to destination',
          ),
          icon: _busStopIcon,
        ),
      ]);

      _polylines.addAll([
        Polyline(
          polylineId: const PolylineId('walk_to_bus'),
          points: [widget.startLocation, _nearestStartPoint!],
          color: _walkingColor,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
        Polyline(
          polylineId: const PolylineId('bus_route'),
          points: _bestRoute!.path,
          color: _directBusColor,
          width: 6,
        ),
        Polyline(
          polylineId: const PolylineId('walk_from_bus'),
          points: [_nearestEndPoint!, widget.endLocation],
          color: _walkingColor,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      ]);
    } else if (_hasAlternativeRoute) {
      await _visualizeAlternativeRoute();
    } else {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('no_route'),
          points: [widget.startLocation, widget.endLocation],
          color: _noRouteColor,
          width: 3,
          patterns: [PatternItem.dash(10), PatternItem.gap(5)],
        ),
      );
    }

    setState(() {});
  }

  Future<void> _visualizeAlternativeRoute() async {
  print("Visualizing alternative route, current step: $_currentStep");
  
  // Clear existing polylines and markers for alternative route
  _polylines.removeWhere((polyline) => polyline.polylineId.value.startsWith('alt_'));
  _markers.removeWhere((marker) => marker.markerId.value.startsWith('step_') || 
                                  marker.markerId.value.startsWith('transfer_'));
  
  if (_currentStep == 0) {
    // Show complete route overview (all steps faintly)
    for (final step in _alternativeSteps) {
      if (step['path'] != null) {
        // Create polyline with the correct patterns
        final polyline = Polyline(
          polylineId: PolylineId('alt_${step['stepNumber']}'),
          points: List<LatLng>.from(step['path']),
          color: step['color'].withOpacity(0.3),
          width: step['width'] - 1,
          patterns: step['pattern'] != null ? step['pattern'] : [],
        );
        
        _polylines.add(polyline);
      }
    }
  } else {
    // Show the current step highlighted and previous steps normally
    for (int i = 0; i < _currentStep; i++) {
      final step = _alternativeSteps[i];
      if (step['path'] != null) {
        final polyline = Polyline(
          polylineId: PolylineId('alt_${step['stepNumber']}'),
          points: List<LatLng>.from(step['path']),
          color: step['color'],
          width: step['width'],
          patterns: step['pattern'] != null ? step['pattern'] : [],
        );
        
        _polylines.add(polyline);
      }
    }
    
    // Highlight current step
    final currentStepData = _alternativeSteps[_currentStep];
    if (currentStepData['path'] != null) {
      final polyline = Polyline(
        polylineId: PolylineId('current_step'),
        points: List<LatLng>.from(currentStepData['path']),
        color: currentStepData['color'],
        width: currentStepData['width'] + 2, // Thicker line for current step
        patterns: currentStepData['pattern'] != null ? currentStepData['pattern'] : [],
      );
      
      _polylines.add(polyline);
    }
  }
  
  // Add markers for all important points
  for (int i = 0; i < _alternativeSteps.length; i++) {
    final step = _alternativeSteps[i];
    
    if (step['type'] == 'walk' && i == 0) {
      // Start walking point
      _markers.add(Marker(
        markerId: MarkerId('walk_start_${step['stepNumber']}'),
        position: step['to'],
        infoWindow: InfoWindow(
          title: 'Walking Start',
          snippet: step['instruction'],
        ),
        icon: _busStopIcon,
      ));
    } 
    else if (step['type'] == 'bus') {
      // Bus stop
      _markers.add(Marker(
        markerId: MarkerId('bus_stop_${step['stepNumber']}'),
        position: step['from'],
        infoWindow: InfoWindow(
          title: 'Bus Stop',
          snippet: 'Board ${step['route'].name} here',
        ),
        icon: _busStopIcon,
      ));
    }
    else if (step['type'] == 'transfer') {
      // Transfer point
      _markers.add(Marker(
        markerId: MarkerId('transfer_${step['stepNumber']}'),
        position: step['point'],
        infoWindow: InfoWindow(
          title: 'Transfer Point',
          snippet: step['instruction'],
        ),
        icon: _transferIcon,
      ));
    }
  }
  
  // Add special markers for current and next steps
  if (_currentStep < _alternativeSteps.length) {
    final currentStep = _alternativeSteps[_currentStep];
    
    // Marker for current step destination
    _markers.add(Marker(
      markerId: const MarkerId('current_step_destination'),
      position: currentStep['to'],
      infoWindow: InfoWindow(
        title: 'Current Destination',
        snippet: currentStep['instruction'],
      ),
      icon: _currentStepIcon,
    ));
    
    // If there's a next step, show where to go next
    if (_currentStep < _alternativeSteps.length - 1) {
      final nextStep = _alternativeSteps[_currentStep + 1];
      _markers.add(Marker(
        markerId: const MarkerId('next_step_destination'),
        position: nextStep['to'],
        infoWindow: InfoWindow(
          title: 'Next: ${nextStep['type'] == 'walk' ? 'Walk' : 'Bus'}',
          snippet: nextStep['instruction'],
        ),
        icon: _nextStepIcon,
      ));
    }
  }
}

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  void _zoomToCurrentStep() {
    if (_currentStep < _alternativeSteps.length) {
      final step = _alternativeSteps[_currentStep];
      final points = List<LatLng>.from(step['path']);
      
      // Add start and end points to ensure they're visible
      points.add(widget.startLocation);
      points.add(widget.endLocation);
      
      final bounds = _boundsFromLatLngList(points);
      
      try {
        mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      } catch (e) {
        // Fallback if bounds are too small
        mapController.animateCamera(
          CameraUpdate.newLatLng(step['to'] ?? widget.startLocation)
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _alternativeSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _updateMap();
      _zoomToCurrentStep();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _updateMap();
      _zoomToCurrentStep();
    }
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _alternativeSteps.length) {
      setState(() {
        _currentStep = step;
      });
      _updateMap();
      _zoomToCurrentStep();
    }
  }

  // Rest of the build method remains the same...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.startLocation,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              mapController = controller;
              if (!_isLoading) _zoomToFit();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: false,
          ),

          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: darkColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Step navigation for alternative routes
          if (_hasAlternativeRoute && !_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: darkColor),
                      onPressed: _previousStep,
                    ),
                    Text('Step ${_currentStep + 1}/${_alternativeSteps.length}'),
                    IconButton(
                      icon: Icon(Icons.arrow_forward, color: darkColor),
                      onPressed: _nextStep,
                    ),
                  ],
                ),
              ),
            ),

          // Step indicators for alternative routes
          if (_hasAlternativeRoute && !_isLoading)
            Positioned(
              bottom: _showDetails ? MediaQuery.of(context).size.height * 0.6 + 20 : 140,
              left: 16,
              right: 16,
              child: Container(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _alternativeSteps.length,
                  itemBuilder: (context, index) {
                    final step = _alternativeSteps[index];
                    return GestureDetector(
                      onTap: () => _goToStep(index),
                      child: Container(
                        width: 50,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _currentStep ? primaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              step['type'] == 'walk' 
                                ? Icons.directions_walk 
                                : step['type'] == 'bus' 
                                  ? Icons.directions_bus 
                                  : Icons.transfer_within_a_station,
                              color: index == _currentStep ? Colors.white : darkColor,
                              size: 20,
                            ),
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index == _currentStep ? Colors.white : darkColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Zoom to fit button
          Positioned(
            bottom: _hasDirectRoute || _hasAlternativeRoute ? 150 : 100,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.zoom_out_map, color: darkColor),
                onPressed: _zoomToFit,
              ),
            ),
          ),

          // Current location button
          Positioned(
            bottom: _hasDirectRoute || _hasAlternativeRoute ? 210 : 160,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.my_location, color: darkColor),
                onPressed: () {
                  if (_currentPosition != null) {
                    mapController.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          // Route info card
          if (!_isLoading && (_hasDirectRoute || _hasAlternativeRoute))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: _showDetails
                    ? MediaQuery.of(context).size.height * 0.6
                    : 120,
                child: _buildRouteInfoCard(),
              ),
            ),

          // No route available message
          if (!_isLoading && !_hasDirectRoute && !_hasAlternativeRoute)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildNoRouteCard(),
            ),
        ],
      ),
    );
  }

  // _buildRouteInfoCard, _buildInfoItem, _buildNoRouteCard, and _calculateFare methods remain the same...
  Widget _buildRouteInfoCard() {
    final route = _hasDirectRoute ? _bestRoute! : _alternativeStartRoute!;
    final walkingDistanceStart = _hasDirectRoute
        ? _walkingDistanceStart!
        : _alternativeWalkingDistanceStart!;
    final walkingDistanceEnd = _hasDirectRoute
        ? _walkingDistanceEnd!
        : _alternativeWalkingDistanceEnd!;

    final walkingTimeToBus = (walkingDistanceStart / 5000) * 60;
    final busRouteDistance = _hasDirectRoute
        ? _bestRoute!.distanceBetween(_nearestStartPoint!, _nearestEndPoint!)
        : Geolocator.distanceBetween(
            _alternativeStartPoint!.latitude,
            _alternativeStartPoint!.longitude,
            _alternativeEndPoint!.latitude,
            _alternativeEndPoint!.longitude,
          );

    final busTravelTime = (busRouteDistance / 30000) * 60;
    final totalTime = walkingTimeToBus + busTravelTime;
    final fare = _calculateFare(busRouteDistance);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: darkColor.withOpacity(0.2), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Route summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _hasDirectRoute ? 'Direct Route' : 'Alternative Route',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${totalTime.toStringAsFixed(0)} min • Rs. ${fare.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: darkColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _toggleDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        _showDetails ? 'Hide' : 'Details',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),

                // Details section
                if (_showDetails) ...[
                  SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey[300]),
                  SizedBox(height: 16),

                  // Route instructions
                  Text(
                    'Route Instructions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.4,
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _routeInstructions,
                        style: TextStyle(
                          fontSize: 14,
                          color: darkColor.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Additional route info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        'Walking',
                        '${(walkingDistanceStart + walkingDistanceEnd).toStringAsFixed(0)}m',
                      ),
                      _buildInfoItem(
                        'Bus Ride',
                        '${(busRouteDistance / 1000).toStringAsFixed(1)}km',
                      ),
                      _buildInfoItem(
                        'Total',
                        '${((walkingDistanceStart + walkingDistanceEnd + busRouteDistance) / 1000).toStringAsFixed(1)}km',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12, color: darkColor.withOpacity(0.6)),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: darkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNoRouteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: darkColor.withOpacity(0.2), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 40),
          SizedBox(height: 12),
          Text(
            'No Bus Route Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Could not find any suitable bus routes near your location or destination',
            textAlign: TextAlign.center,
            style: TextStyle(color: darkColor.withOpacity(0.7)),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateFare(double distanceInMeters) {
    return (distanceInMeters / 1000) <= 15 ? 80 : 120;
  }
}