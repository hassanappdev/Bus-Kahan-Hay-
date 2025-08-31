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

  // Colors
  final Color primaryColor = const Color(0xFFEC130F);
  final Color secondaryColor = const Color(0xFF009B37);
  final Color darkColor = const Color(0xFF000000);
  final Color lightColor = const Color(0xFFF5F5F5);

  final Color _walkingColor = const Color(0xFF4285F4);
  final Color _directBusColor = const Color(0xFF009B37);
  final Color _alternativeBusColor = const Color(0xFFEC130F);
  final Color _noRouteColor = const Color(0xFF9E9E9E);
  final Color _transferColor = const Color(0xFFFF9800);

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

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (_) {}

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10,
          ),
        ).listen((Position pos) {
          if (!mounted) return;
          setState(() {
            _currentPosition = pos;
          });
        });
  }

  Future<void> _loadMarkerIcons() async {
    try {
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
    } catch (e) {
      debugPrint("⚠️ Missing asset: $e");
    }

    _currentStepIcon = await _createCustomIcon(
      Colors.green,
      Icons.directions_walk,
    );
    _nextStepIcon = await _createCustomIcon(Colors.blue, Icons.directions_bus);
  }

  Future<BitmapDescriptor> _createCustomIcon(
    Color color,
    IconData iconData,
  ) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..color = color;

    canvas.drawCircle(const Offset(15, 15), 15, paint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 20,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(5, 5));

    final image = await recorder.endRecording().toImage(30, 30);
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
    } else {
      await _findAlternativeRoutes(routeFinder);
    }
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

    if (_nearestStartPoint == null || _nearestEndPoint == null) {
      await _findAlternativeRoutes(routeFinder);
      return;
    }

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

    const maxWalk = 2000;
    if ((_walkingDistanceStart ?? 0) > maxWalk ||
        (_walkingDistanceEnd ?? 0) > maxWalk) {
      await _findAlternativeRoutes(routeFinder);
      return;
    }

    _routeInstructions =
        '1. Walk ${_walkingDistanceStart?.toStringAsFixed(0) ?? "?"}m to board ${_bestRoute?.name ?? "Bus"}\n'
        '2. Ride ${_bestRoute?.name ?? "Bus"} to drop-off point\n'
        '3. Walk ${_walkingDistanceEnd?.toStringAsFixed(0) ?? "?"}m to destination';

    if (!mounted) return;
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
      if (!mounted) return;
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

    // If points could not be found → stop safely
    if (_alternativeStartPoint == null || _alternativeEndPoint == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasAlternativeRoute = false;
      });
      return;
    }

    _alternativeWalkingDistanceStart = Geolocator.distanceBetween(
      widget.startLocation.latitude,
      widget.startLocation.longitude,
      _alternativeStartPoint?.latitude ?? widget.startLocation.latitude,
      _alternativeStartPoint?.longitude ?? widget.startLocation.longitude,
    );

    _alternativeWalkingDistanceEnd = Geolocator.distanceBetween(
      _alternativeEndPoint?.latitude ?? widget.endLocation.latitude,
      _alternativeEndPoint?.longitude ?? widget.endLocation.longitude,
      widget.endLocation.latitude,
      widget.endLocation.longitude,
    );

    // Prepare steps safely
    _prepareAlternativeSteps();

    _buildAlternativeRouteInstructions();

    if (!mounted) return;
    setState(() {
      _hasAlternativeRoute = true;
      _isLoading = false;
    });

    await _updateMap();
    _zoomToFit();
  }

  void _buildAlternativeRouteInstructions() {
    _routeInstructions = '';

    if (_alternativeSteps.isEmpty) {
      _routeInstructions = 'No alternative route found';
      return;
    }

    for (int i = 0; i < _alternativeSteps.length; i++) {
      final step = _alternativeSteps[i];
      _routeInstructions += '${i + 1}. ${step['instruction'] ?? "Continue"}\n';
    }
  }

  List<LatLng> _getRouteSegment(
    BusRoute? route,
    LatLng? fromPoint,
    LatLng? toPoint,
  ) {
    if (route == null || fromPoint == null || toPoint == null) {
      return [fromPoint ?? widget.startLocation, toPoint ?? widget.endLocation];
    }

    try {
      int fromIndex = 0;
      double fromMinDistance = double.maxFinite;

      int toIndex = 0;
      double toMinDistance = double.maxFinite;

      for (int i = 0; i < route.path.length; i++) {
        final point = route.path[i];
        final fromDistance = Geolocator.distanceBetween(
          fromPoint.latitude,
          fromPoint.longitude,
          point.latitude,
          point.longitude,
        );

        final toDistance = Geolocator.distanceBetween(
          toPoint.latitude,
          toPoint.longitude,
          point.latitude,
          point.longitude,
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
      debugPrint("⚠️ Error getting route segment: $e");
      return [fromPoint, toPoint];
    }
  }

  void _prepareAlternativeSteps() {
    _alternativeSteps.clear();
    _currentStep = 0;

    int stepNumber = 1;

    if (_alternativeStartPoint == null ||
        _alternativeEndPoint == null ||
        _alternativeStartRoute == null ||
        _alternativeEndRoute == null) {
      return; // Don’t crash if missing data
    }

    // Step 1: Walk to first bus stop
    _alternativeSteps.add({
      'type': 'walk',
      'from': widget.startLocation,
      'to': _alternativeStartPoint,
      'path': [widget.startLocation, _alternativeStartPoint!],
      'distance': _alternativeWalkingDistanceStart ?? 0,
      'instruction':
          'Walk ${(_alternativeWalkingDistanceStart ?? 0).toStringAsFixed(0)}m to board ${_alternativeStartRoute?.name ?? "bus"}',
      'stepNumber': stepNumber++,
      'color': _walkingColor,
      'width': 4,
      'pattern': [PatternItem.dash(20), PatternItem.gap(10)],
    });

    if (_alternativeStartRoute?.name == _alternativeEndRoute?.name) {
      // Same route
      final routePath = _getRouteSegment(
        _alternativeStartRoute,
        _alternativeStartPoint,
        _alternativeEndPoint,
      );

      _alternativeSteps.add({
        'type': 'bus',
        'route': _alternativeStartRoute,
        'from': _alternativeStartPoint,
        'to': _alternativeEndPoint,
        'path': routePath,
        'instruction':
            'Ride ${_alternativeStartRoute?.name ?? "bus"} for ${(Geolocator.distanceBetween(_alternativeStartPoint!.latitude, _alternativeStartPoint!.longitude, _alternativeEndPoint!.latitude, _alternativeEndPoint!.longitude) / 1000).toStringAsFixed(1)} km',
        'stepNumber': stepNumber++,
        'color': _alternativeBusColor,
        'width': 6,
      });
    } else {
      // Different routes → need transfer
      final transferPoint = _findTransferPoint(
        _alternativeStartRoute!,
        _alternativeEndRoute!,
      );

      final firstRoutePath = _getRouteSegment(
        _alternativeStartRoute,
        _alternativeStartPoint,
        transferPoint,
      );

      final secondRoutePath = _getRouteSegment(
        _alternativeEndRoute,
        transferPoint,
        _alternativeEndPoint,
      );

      _alternativeSteps.add({
        'type': 'bus',
        'route': _alternativeStartRoute,
        'from': _alternativeStartPoint,
        'to': transferPoint,
        'path': firstRoutePath,
        'instruction':
            'Ride ${_alternativeStartRoute?.name ?? "bus"} to transfer point (${(Geolocator.distanceBetween(_alternativeStartPoint!.latitude, _alternativeStartPoint!.longitude, transferPoint.latitude, transferPoint.longitude) / 1000).toStringAsFixed(1)} km)',
        'stepNumber': stepNumber++,
        'color': _alternativeBusColor,
        'width': 6,
      });

      _alternativeSteps.add({
        'type': 'transfer',
        'fromRoute': _alternativeStartRoute,
        'toRoute': _alternativeEndRoute,
        'point': transferPoint,
        'path': [transferPoint],
        'instruction': 'Transfer to ${_alternativeEndRoute?.name ?? "bus"}',
        'stepNumber': stepNumber++,
        'color': _transferColor,
        'width': 8,
      });

      _alternativeSteps.add({
        'type': 'bus',
        'route': _alternativeEndRoute,
        'from': transferPoint,
        'to': _alternativeEndPoint,
        'path': secondRoutePath,
        'instruction':
            'Ride ${_alternativeEndRoute?.name ?? "bus"} to drop-off point (${(Geolocator.distanceBetween(transferPoint.latitude, transferPoint.longitude, _alternativeEndPoint!.latitude, _alternativeEndPoint!.longitude) / 1000).toStringAsFixed(1)} km)',
        'stepNumber': stepNumber++,
        'color': _alternativeBusColor,
        'width': 6,
      });
    }

    // Final step: Walk to destination
    _alternativeSteps.add({
      'type': 'walk',
      'from': _alternativeEndPoint,
      'to': widget.endLocation,
      'path': [_alternativeEndPoint!, widget.endLocation],
      'distance': _alternativeWalkingDistanceEnd ?? 0,
      'instruction':
          'Walk ${(_alternativeWalkingDistanceEnd ?? 0).toStringAsFixed(0)}m to your destination',
      'stepNumber': stepNumber++,
      'color': _walkingColor,
      'width': 4,
      'pattern': [PatternItem.dash(20), PatternItem.gap(10)],
    });
  }

  LatLng _findTransferPoint(BusRoute? route1, BusRoute? route2) {
    if (route1 == null ||
        route1.path.isEmpty ||
        route2 == null ||
        route2.path.isEmpty) {
      // fallback → return startLocation to avoid crash
      return widget.startLocation;
    }

    double minDistance = double.maxFinite;
    LatLng transferPoint = route1.path.first;

    for (final point1 in route1.path) {
      for (final point2 in route2.path) {
        final distance = Geolocator.distanceBetween(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
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

    final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);

    try {
      await mapController.animateCamera(cameraUpdate);
    } catch (e) {
      final fallback = CameraPosition(target: widget.startLocation, zoom: 14);
      mapController.animateCamera(CameraUpdate.newCameraPosition(fallback));
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) {
      return LatLngBounds(
        northeast: widget.startLocation,
        southwest: widget.endLocation,
      );
    }

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
          snippet: widget.startAddress ?? "",
        ),
        icon: _startIcon,
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: widget.endLocation,
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.endAddress ?? "",
        ),
        icon: _endIcon,
      ),
    ]);

    if (_hasDirectRoute &&
        _nearestStartPoint != null &&
        _nearestEndPoint != null &&
        _bestRoute != null) {
      _markers.addAll([
        Marker(
          markerId: const MarkerId('nearest_start'),
          position: _nearestStartPoint!,
          infoWindow: InfoWindow(
            title: 'Board ${_bestRoute?.name ?? "bus"} Here',
            snippet:
                '${_walkingDistanceStart?.toStringAsFixed(0) ?? "?"}m walk',
          ),
          icon: _busStopIcon,
        ),
        Marker(
          markerId: const MarkerId('nearest_end'),
          position: _nearestEndPoint!,
          infoWindow: InfoWindow(
            title: 'Exit ${_bestRoute?.name ?? "bus"} Here',
            snippet:
                '${_walkingDistanceEnd?.toStringAsFixed(0) ?? "?"}m to destination',
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
          points: _bestRoute?.path ?? [],
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

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _visualizeAlternativeRoute() async {
    if (_alternativeSteps.isEmpty) return;

    _polylines.removeWhere(
      (polyline) => polyline.polylineId.value.startsWith('alt_'),
    );
    _markers.removeWhere(
      (marker) =>
          marker.markerId.value.startsWith('step_') ||
          marker.markerId.value.startsWith('transfer_'),
    );

    if (_currentStep == 0) {
      for (final step in _alternativeSteps) {
        final path = (step['path'] as List<LatLng>?) ?? [];
        if (path.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('alt_${step['stepNumber']}'),
              points: path,
              color: (step['color'] as Color?)?.withOpacity(0.3) ?? Colors.grey,
              width: (step['width'] as int? ?? 4) - 1,
              patterns: (step['pattern'] as List<PatternItem>?) ?? [],
            ),
          );
        }
      }
    } else {
      for (int i = 0; i < _currentStep; i++) {
        final step = _alternativeSteps[i];
        final path = (step['path'] as List<LatLng>?) ?? [];
        if (path.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('alt_${step['stepNumber']}'),
              points: path,
              color: step['color'] ?? Colors.blue,
              width: step['width'] ?? 4,
              patterns: (step['pattern'] as List<PatternItem>?) ?? [],
            ),
          );
        }
      }

      final currentStepData = _alternativeSteps[_currentStep];
      final path = (currentStepData['path'] as List<LatLng>?) ?? [];
      if (path.isNotEmpty) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('current_step'),
            points: path,
            color: currentStepData['color'] ?? Colors.red,
            width: (currentStepData['width'] ?? 4) + 2,
            patterns: (currentStepData['pattern'] as List<PatternItem>?) ?? [],
          ),
        );
      }
    }

    // Markers
    for (int i = 0; i < _alternativeSteps.length; i++) {
      final step = _alternativeSteps[i];
      final LatLng? from = step['from'];
      final LatLng? to = step['to'];

      switch (step['type']) {
        case 'walk':
          if (i == 0 && to != null) {
            _markers.add(
              Marker(
                markerId: MarkerId('walk_start_${step['stepNumber']}'),
                position: to,
                infoWindow: InfoWindow(
                  title: 'Walking Start',
                  snippet: step['instruction'] ?? "",
                ),
                icon: _busStopIcon,
              ),
            );
          }
          break;

        case 'bus':
          if (from != null) {
            _markers.add(
              Marker(
                markerId: MarkerId('bus_stop_${step['stepNumber']}'),
                position: from,
                infoWindow: InfoWindow(
                  title: 'Bus Stop',
                  snippet:
                      'Board ${(step['route'] as BusRoute?)?.name ?? "bus"} here',
                ),
                icon: _busStopIcon,
              ),
            );
          }
          break;

        case 'transfer':
          final LatLng? point = step['point'];
          if (point != null) {
            _markers.add(
              Marker(
                markerId: MarkerId('transfer_${step['stepNumber']}'),
                position: point,
                infoWindow: InfoWindow(
                  title: 'Transfer Point',
                  snippet: step['instruction'] ?? "",
                ),
                icon: _transferIcon,
              ),
            );
          }
          break;
      }
    }

    // Highlight current + next
    if (_currentStep < _alternativeSteps.length) {
      final currentStep = _alternativeSteps[_currentStep];
      final LatLng? to = currentStep['to'];

      if (to != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_step_destination'),
            position: to,
            infoWindow: InfoWindow(
              title: 'Current Destination',
              snippet: currentStep['instruction'] ?? "",
            ),
            icon: _currentStepIcon,
          ),
        );
      }

      if (_currentStep < _alternativeSteps.length - 1) {
        final nextStep = _alternativeSteps[_currentStep + 1];
        final LatLng? toNext = nextStep['to'];
        if (toNext != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('next_step_destination'),
              position: toNext,
              infoWindow: InfoWindow(
                title: 'Next: ${nextStep['type'] == 'walk' ? 'Walk' : 'Bus'}',
                snippet: nextStep['instruction'] ?? "",
              ),
              icon: _nextStepIcon,
            ),
          );
        }
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
          CameraUpdate.newLatLng(step['to'] ?? widget.startLocation),
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
    return SafeArea(
      child: Scaffold(
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
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: darkColor),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),

            // Step navigation for alternative routes
            if (_hasAlternativeRoute &&
                !_isLoading &&
                _alternativeSteps.isNotEmpty)
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
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: darkColor),
                        onPressed: _previousStep,
                      ),
                      Text(
                        'Step ${_currentStep + 1}/${_alternativeSteps.length}',
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward, color: darkColor),
                        onPressed: _nextStep,
                      ),
                    ],
                  ),
                ),
              ),

            // Step indicators for alternative routes
            if (_hasAlternativeRoute &&
                !_isLoading &&
                _alternativeSteps.isNotEmpty)
              Positioned(
                bottom: _showDetails
                    ? MediaQuery.of(context).size.height * 0.6 + 20
                    : 140,
                left: 16,
                right: 16,
                child: SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _alternativeSteps.length,
                    itemBuilder: (context, index) {
                      final step = _alternativeSteps[index];
                      final type = step['type'] ?? '';
                      return GestureDetector(
                        onTap: () => _goToStep(index),
                        child: Container(
                          width: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == _currentStep
                                ? primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type == 'walk'
                                    ? Icons.directions_walk
                                    : type == 'bus'
                                    ? Icons.directions_bus
                                    : Icons.transfer_within_a_station,
                                color: index == _currentStep
                                    ? Colors.white
                                    : darkColor,
                                size: 20,
                              ),
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: index == _currentStep
                                      ? Colors.white
                                      : darkColor,
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
                      offset: const Offset(0, 2),
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
                      offset: const Offset(0, 2),
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
                  duration: const Duration(milliseconds: 300),
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
      ),
    );
  }

  // _buildRouteInfoCard, _buildInfoItem, _buildNoRouteCard, and _calculateFare methods remain the same...
  Widget _buildRouteInfoCard() {
    // Safely pick route or return fallback card if no valid route
    final route = _hasDirectRoute ? _bestRoute : _alternativeStartRoute;
    if (route == null) {
      return _buildNoRouteCard();
    }

    final walkingDistanceStart = _hasDirectRoute
        ? (_walkingDistanceStart ?? 0.0)
        : (_alternativeWalkingDistanceStart ?? 0.0);

    final walkingDistanceEnd = _hasDirectRoute
        ? (_walkingDistanceEnd ?? 0.0)
        : (_alternativeWalkingDistanceEnd ?? 0.0);

    final walkingTimeToBus = (walkingDistanceStart / 5000) * 60;

    final busRouteDistance = _hasDirectRoute
        ? (_nearestStartPoint != null && _nearestEndPoint != null
              ? (_bestRoute?.distanceBetween(
                      _nearestStartPoint!,
                      _nearestEndPoint!,
                    ) ??
                    0.0)
              : 0.0)
        : (_alternativeStartPoint != null && _alternativeEndPoint != null
              ? Geolocator.distanceBetween(
                  _alternativeStartPoint!.latitude,
                  _alternativeStartPoint!.longitude,
                  _alternativeEndPoint!.latitude,
                  _alternativeEndPoint!.longitude,
                )
              : 0.0);

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                            _hasDirectRoute
                                ? 'Direct Route'
                                : 'Alternative Route',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _toggleDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        _showDetails ? 'Hide' : 'Details',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                // Details section
                if (_showDetails) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 16),

                  // Route instructions
                  Text(
                    'Route Instructions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.4,
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _routeInstructions.isNotEmpty
                            ? _routeInstructions
                            : "No instructions available",
                        style: TextStyle(
                          fontSize: 14,
                          color: darkColor.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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

  Widget _buildInfoItem(String? title, String? value) {
    return Column(
      children: [
        Text(
          title ?? "N/A", // fallback if null
          style: TextStyle(fontSize: 12, color: darkColor.withOpacity(0.6)),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? "N/A", // fallback if null
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: darkColor.withOpacity(0.2), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 40),
          const SizedBox(height: 12),
          Text(
            'No Bus Route Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Could not find any suitable bus routes near your location or destination',
            textAlign: TextAlign.center,
            style: TextStyle(color: darkColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
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
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateFare(double? distanceInMeters) {
    final distance = distanceInMeters ?? 0.0; // safe fallback
    return (distance / 1000) <= 15 ? 80 : 120;
  }
}

// import 'package:bus_kahan_hay/model/bus_routes.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:bus_kahan_hay/services/route_finder.dart';

// class RouteScreen extends StatefulWidget {
//   final LatLng startLocation;
//   final LatLng endLocation;
//   final List<BusRoute> routes;
//   final String startAddress;
//   final String endAddress;

//   const RouteScreen({
//     required this.startLocation,
//     required this.endLocation,
//     required this.routes,
//     required this.startAddress,
//     required this.endAddress,
//   });

//   @override
//   _RouteScreenState createState() => _RouteScreenState();
// }

// class _RouteScreenState extends State<RouteScreen> {
//   late GoogleMapController mapController;
//   final Set<Polyline> _polylines = {};
//   final Set<Marker> _markers = {};
//   BusRoute? _bestRoute;
//   BusRoute? _alternativeStartRoute;
//   BusRoute? _alternativeEndRoute;
//   LatLng? _nearestStartPoint;
//   LatLng? _nearestEndPoint;
//   LatLng? _alternativeStartPoint;
//   LatLng? _alternativeEndPoint;
//   double? _walkingDistanceStart;
//   double? _walkingDistanceEnd;
//   double? _alternativeWalkingDistanceStart;
//   double? _alternativeWalkingDistanceEnd;
//   bool _isLoading = true;
//   bool _hasDirectRoute = false;
//   bool _hasAlternativeRoute = false;
//   String _routeInstructions = '';

//   // Theme Colors
//   final Color primaryColor = const Color(0xFFEC130F); // Red
//   final Color secondaryColor = const Color(0xFF009B37); // Green
//   final Color darkColor = const Color(0xFF000000); // Black
//   final Color lightColor = const Color(0xFFF5F5F5); // Light background

//   // Route Colors
//   final Color _walkingColor = const Color(0xFF4285F4); // Blue
//   final Color _directBusColor = const Color(0xFF009B37); // Green (from theme)
//   final Color _alternativeBusColor = const Color(
//     0xFFEC130F,
//   ); // Red (from theme)
//   final Color _noRouteColor = const Color(0xFF9E9E9E); // Grey

//   late BitmapDescriptor _startIcon;
//   late BitmapDescriptor _endIcon;
//   late BitmapDescriptor _busStopIcon;
//   late BitmapDescriptor _alternativeStopIcon;

//   @override
//   void initState() {
//     super.initState();
//     _loadMarkerIcons().then((_) => _findBestRoute());
//   }

//   Future<void> _loadMarkerIcons() async {
//     _startIcon = await _getCustomMarkerIcon(
//       'assets/images/user_location.png',
//       size: 150,
//     );
//     _endIcon = await _getCustomMarkerIcon(
//       'assets/images/destination.png',
//       size: 150,
//     );
//     _busStopIcon = await _getCustomMarkerIcon(
//       'assets/images/bus_stop.png',
//       size: 120,
//     );
//     _alternativeStopIcon = await _getCustomMarkerIcon(
//       'assets/images/bus_stop_alt.png',
//       size: 140,
//     );
//   }

//   Future<BitmapDescriptor> _getCustomMarkerIcon(
//     String iconPath, {
//     int size = 80,
//   }) async {
//     final ImageConfiguration imageConfiguration = ImageConfiguration(
//       size: Size.square(size.toDouble()),
//     );
//     return await BitmapDescriptor.fromAssetImage(imageConfiguration, iconPath);
//   }

//   void _findBestRoute() {
//     final routeFinder = RouteFinder(widget.routes);
//     _bestRoute = routeFinder.findBestRoute(
//       widget.startLocation,
//       widget.endLocation,
//     );

//     if (_bestRoute != null) {
//       _setupDirectRoute(routeFinder);
//       return;
//     }
//     _findAlternativeRoutes(routeFinder);
//   }

//   void _setupDirectRoute(RouteFinder routeFinder) {
//     _nearestStartPoint = routeFinder.findNearestPointOnRoute(
//       widget.startLocation,
//       _bestRoute!,
//     );
//     _nearestEndPoint = routeFinder.findNearestPointOnRoute(
//       widget.endLocation,
//       _bestRoute!,
//     );

//     const maxWalkingDistance = 2000;
//     _walkingDistanceStart = Geolocator.distanceBetween(
//       widget.startLocation.latitude,
//       widget.startLocation.longitude,
//       _nearestStartPoint!.latitude,
//       _nearestStartPoint!.longitude,
//     );
//     _walkingDistanceEnd = Geolocator.distanceBetween(
//       _nearestEndPoint!.latitude,
//       _nearestEndPoint!.longitude,
//       widget.endLocation.latitude,
//       widget.endLocation.longitude,
//     );

//     if (_walkingDistanceStart! > maxWalkingDistance ||
//         _walkingDistanceEnd! > maxWalkingDistance) {
//       _findAlternativeRoutes(routeFinder);
//       return;
//     }

//     _routeInstructions =
//         '1. Walk ${_walkingDistanceStart!.toStringAsFixed(0)}m to board ${_bestRoute!.name} at this stop\n'
//         '2. Ride ${_bestRoute!.name} to the drop-off point\n'
//         '3. Walk ${_walkingDistanceEnd!.toStringAsFixed(0)}m to your destination';

//     setState(() {
//       _hasDirectRoute = true;
//       _isLoading = false;
//     });

//     _updateMap();
//     _zoomToFit();
//   }

//   void _findAlternativeRoutes(RouteFinder routeFinder) {
//     _alternativeStartRoute = routeFinder.findNearestRoute(widget.startLocation);
//     _alternativeEndRoute = routeFinder.findNearestRoute(widget.endLocation);

//     if (_alternativeStartRoute == null || _alternativeEndRoute == null) {
//       setState(() {
//         _isLoading = false;
//         _hasAlternativeRoute = false;
//       });
//       return;
//     }

//     _alternativeStartPoint = routeFinder.findNearestPointOnRoute(
//       widget.startLocation,
//       _alternativeStartRoute!,
//     );
//     _alternativeEndPoint = routeFinder.findNearestPointOnRoute(
//       widget.endLocation,
//       _alternativeEndRoute!,
//     );

//     _alternativeWalkingDistanceStart = Geolocator.distanceBetween(
//       widget.startLocation.latitude,
//       widget.startLocation.longitude,
//       _alternativeStartPoint!.latitude,
//       _alternativeStartPoint!.longitude,
//     );
//     _alternativeWalkingDistanceEnd = Geolocator.distanceBetween(
//       _alternativeEndPoint!.latitude,
//       _alternativeEndPoint!.longitude,
//       widget.endLocation.latitude,
//       widget.endLocation.longitude,
//     );

//     if (_alternativeStartRoute!.name == _alternativeEndRoute!.name) {
//       _routeInstructions =
//           'No direct route available. Alternative route:\n\n'
//           '1. Walk ${_alternativeWalkingDistanceStart!.toStringAsFixed(0)}m to board ${_alternativeStartRoute!.name} at this stop\n'
//           '2. Ride ${_alternativeStartRoute!.name} to the drop-off point\n'
//           '3. Walk ${_alternativeWalkingDistanceEnd!.toStringAsFixed(0)}m to your destination';
//     } else {
//       _routeInstructions =
//           'No direct route available. Alternative route:\n\n'
//           '1. Walk ${_alternativeWalkingDistanceStart!.toStringAsFixed(0)}m to board ${_alternativeStartRoute!.name} at this stop\n'
//           '2. Ride ${_alternativeStartRoute!.name} to a transfer point\n'
//           '3. Transfer to ${_alternativeEndRoute!.name}\n'
//           '4. Walk ${_alternativeWalkingDistanceEnd!.toStringAsFixed(0)}m to your destination';
//     }

//     setState(() {
//       _hasAlternativeRoute = true;
//       _isLoading = false;
//     });

//     _updateMap();
//     _zoomToFit();
//   }

//   void _zoomToFit() async {
//     if (_markers.isEmpty || mapController == null) return;
//     final bounds = _boundsFromLatLngList(
//       _markers.map((m) => m.position).toList(),
//     );
//     mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120));
//   }

//   LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
//     double? x0, x1, y0, y1;
//     for (final latLng in list) {
//       if (x0 == null) {
//         x0 = x1 = latLng.latitude;
//         y0 = y1 = latLng.longitude;
//       } else {
//         if (latLng.latitude > x1!) x1 = latLng.latitude;
//         if (latLng.latitude < x0) x0 = latLng.latitude;
//         if (latLng.longitude > y1!) y1 = latLng.longitude;
//         if (latLng.longitude < y0!) y0 = latLng.longitude;
//       }
//     }
//     return LatLngBounds(
//       northeast: LatLng(x1!, y1!),
//       southwest: LatLng(x0!, y0!),
//     );
//   }

//   void _updateMap() {
//     _markers.clear();
//     _polylines.clear();

//     // Start and end markers
//     _markers.addAll([
//       Marker(
//         markerId: const MarkerId('start'),
//         position: widget.startLocation,
//         infoWindow: InfoWindow(
//           title: 'Your Location',
//           snippet: widget.startAddress,
//         ),
//         icon: _startIcon,
//         anchor: const Offset(0.5, 1.0),
//         zIndex: 3,
//       ),
//       Marker(
//         markerId: const MarkerId('end'),
//         position: widget.endLocation,
//         infoWindow: InfoWindow(
//           title: 'Destination',
//           snippet: widget.endAddress,
//         ),
//         icon: _endIcon,
//         anchor: const Offset(0.5, 1.0),
//         zIndex: 3,
//       ),
//     ]);

//     if (_hasDirectRoute) {
//       _markers.addAll([
//         Marker(
//           markerId: const MarkerId('nearest_start'),
//           position: _nearestStartPoint!,
//           infoWindow: InfoWindow(
//             title: 'Board ${_bestRoute!.name} Here',
//             snippet: '${_walkingDistanceStart!.toStringAsFixed(0)}m walk',
//           ),
//           icon: _busStopIcon,
//           zIndex: 2,
//         ),
//         Marker(
//           markerId: const MarkerId('nearest_end'),
//           position: _nearestEndPoint!,
//           infoWindow: InfoWindow(
//             title: 'Exit ${_bestRoute!.name} Here',
//             snippet:
//                 '${_walkingDistanceEnd!.toStringAsFixed(0)}m to destination',
//           ),
//           icon: _busStopIcon,
//           zIndex: 2,
//         ),
//       ]);

//       _polylines.addAll([
//         Polyline(
//           polylineId: const PolylineId('walk_to_bus'),
//           points: [widget.startLocation, _nearestStartPoint!],
//           color: _walkingColor,
//           width: 6,
//           patterns: [PatternItem.dash(20), PatternItem.gap(10)],
//         ),
//         Polyline(
//           polylineId: const PolylineId('bus_route'),
//           points: _bestRoute!.path,
//           color: _directBusColor,
//           width: 8,
//         ),
//         Polyline(
//           polylineId: const PolylineId('walk_from_bus'),
//           points: [_nearestEndPoint!, widget.endLocation],
//           color: _walkingColor,
//           width: 6,
//           patterns: [PatternItem.dash(20), PatternItem.gap(10)],
//         ),
//       ]);
//     } else if (_hasAlternativeRoute) {
//       _markers.addAll([
//         Marker(
//           markerId: const MarkerId('alternative_start'),
//           position: _alternativeStartPoint!,
//           infoWindow: InfoWindow(
//             title: 'Board ${_alternativeStartRoute!.name} Here',
//             snippet:
//                 '${_alternativeWalkingDistanceStart!.toStringAsFixed(0)}m walk',
//           ),
//           icon: _alternativeStopIcon,
//           zIndex: 2,
//         ),
//         Marker(
//           markerId: const MarkerId('alternative_end'),
//           position: _alternativeEndPoint!,
//           infoWindow: InfoWindow(
//             title: 'Exit ${_alternativeEndRoute!.name} Here',
//             snippet:
//                 '${_alternativeWalkingDistanceEnd!.toStringAsFixed(0)}m to destination',
//           ),
//           icon: _alternativeStopIcon,
//           zIndex: 2,
//         ),
//       ]);

//       _polylines.addAll([
//         Polyline(
//           polylineId: const PolylineId('walk_to_alternative'),
//           points: [widget.startLocation, _alternativeStartPoint!],
//           color: _walkingColor,
//           width: 6,
//           patterns: [PatternItem.dash(20), PatternItem.gap(10)],
//         ),
//         Polyline(
//           polylineId: const PolylineId('alternative_route_main'),
//           points: [_alternativeStartPoint!, _alternativeEndPoint!],
//           color: _alternativeBusColor,
//           width: 8,
//         ),
//         Polyline(
//           polylineId: const PolylineId('walk_from_alternative'),
//           points: [_alternativeEndPoint!, widget.endLocation],
//           color: _walkingColor,
//           width: 6,
//           patterns: [PatternItem.dash(20), PatternItem.gap(10)],
//         ),
//       ]);
//     } else {
//       _polylines.add(
//         Polyline(
//           polylineId: const PolylineId('no_route'),
//           points: [widget.startLocation, widget.endLocation],
//           color: _noRouteColor,
//           width: 3,
//           patterns: [PatternItem.dash(10), PatternItem.gap(5)],
//         ),
//       );
//     }

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Route Guidance',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: primaryColor,
//         elevation: 0,
//         iconTheme: IconThemeData(color: Colors.white),
//       ),
//       body: Stack(
//         children: [
//           // Full screen Google Map
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: widget.startLocation,
//               zoom: 14,
//             ),
//             markers: _markers,
//             polylines: _polylines,
//             onMapCreated: (controller) => mapController = controller,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: false,
//           ),

//           // Loading indicator
//           if (_isLoading)
//             Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//               ),
//             ),

//           // Zoom to fit button
//           Positioned(
//             bottom: 120,
//             right: 16,
//             child: FloatingActionButton(
//               mini: true,
//               backgroundColor: primaryColor,
//               onPressed: _zoomToFit,
//               child: const Icon(Icons.zoom_out_map, color: Colors.white),
//             ),
//           ),

//           // Route info card (sliding up from bottom)
//           if (!_isLoading)
//             Positioned(
//               left: 0,
//               right: 0,
//               bottom: 0,
//               child: _buildRouteInfoCard(),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRouteInfoCard() {
//     if (!_hasDirectRoute && !_hasAlternativeRoute) {
//       return Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//           boxShadow: [
//             BoxShadow(color: darkColor.withOpacity(0.2), blurRadius: 10),
//           ],
//         ),
//         child: Column(
//           children: [
//             Icon(Icons.warning, color: Colors.orange, size: 40),
//             const SizedBox(height: 12),
//             Text(
//               'No Bus Route Available',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: darkColor,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Could not find any suitable bus routes near your location or destination',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: darkColor.withOpacity(0.7)),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: lightColor,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 onPressed: () => Navigator.pop(context),
//                 child: Text('Try Again', style: TextStyle(color: darkColor)),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     final route = _hasDirectRoute ? _bestRoute! : _alternativeStartRoute!;
//     final walkingDistanceStart = _hasDirectRoute
//         ? _walkingDistanceStart!
//         : _alternativeWalkingDistanceStart!;
//     final walkingDistanceEnd = _hasDirectRoute
//         ? _walkingDistanceEnd!
//         : _alternativeWalkingDistanceEnd!;

//     final walkingTimeToBus = (walkingDistanceStart / 5000) * 60;
//     final busRouteDistance = _hasDirectRoute
//         ? _bestRoute!.distanceBetween(_nearestStartPoint!, _nearestEndPoint!)
//         : Geolocator.distanceBetween(
//             _alternativeStartPoint!.latitude,
//             _alternativeStartPoint!.longitude,
//             _alternativeEndPoint!.latitude,
//             _alternativeEndPoint!.longitude,
//           );

//     final busTravelTime = (busRouteDistance / 30000) * 60;
//     final totalTime = walkingTimeToBus + busTravelTime;
//     final fare = _calculateFare(busRouteDistance);

//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         boxShadow: [
//           BoxShadow(color: darkColor.withOpacity(0.2), blurRadius: 10),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Route header with icon
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: _hasDirectRoute ? secondaryColor : primaryColor,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   _hasDirectRoute ? Icons.directions_bus : Icons.alt_route,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   '${_hasDirectRoute ? 'Direct' : 'Alternative'} Route: ${route.name}',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: darkColor,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Route instructions
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: lightColor,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (!_hasDirectRoute)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 8),
//                     child: Text(
//                       'No direct route available - showing alternative',
//                       style: TextStyle(
//                         color: Colors.orange[800],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 Text(
//                   _routeInstructions,
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: darkColor.withOpacity(0.9),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Time and fare information
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Total Time',
//                 style: TextStyle(fontWeight: FontWeight.bold, color: darkColor),
//               ),
//               Text(
//                 '${totalTime.toStringAsFixed(0)} minutes',
//                 style: TextStyle(fontWeight: FontWeight.w600, color: darkColor),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Fare',
//                 style: TextStyle(fontWeight: FontWeight.bold, color: darkColor),
//               ),
//               Text(
//                 'Rs. ${fare.toStringAsFixed(0)}',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w600,
//                   color: secondaryColor,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   double _calculateFare(double distanceInMeters) {
//     return (distanceInMeters / 1000) <= 15 ? 80 : 120;
//   }
// }
