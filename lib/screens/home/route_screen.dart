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

  // Theme Colors
  final Color primaryColor = const Color(0xFFEC130F); // Red
  final Color secondaryColor = const Color(0xFF009B37); // Green
  final Color darkColor = const Color(0xFF000000); // Black
  final Color lightColor = const Color(0xFFF5F5F5); // Light background

  // Route Colors
  final Color _walkingColor = const Color(0xFF4285F4); // Blue
  final Color _directBusColor = const Color(0xFF009B37); // Green (from theme)
  final Color _alternativeBusColor = const Color(
    0xFFEC130F,
  ); // Red (from theme)
  final Color _noRouteColor = const Color(0xFF9E9E9E); // Grey

  late BitmapDescriptor _startIcon;
  late BitmapDescriptor _endIcon;
  late BitmapDescriptor _busStopIcon;
  late BitmapDescriptor _alternativeStopIcon;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons().then((_) => _findBestRoute());
  }

  Future<void> _loadMarkerIcons() async {
    _startIcon = await _getCustomMarkerIcon(
      'assets/images/user_location.png',
      size: 150,
    );
    _endIcon = await _getCustomMarkerIcon(
      'assets/images/destination.png',
      size: 150,
    );
    _busStopIcon = await _getCustomMarkerIcon(
      'assets/images/bus_stop.png',
      size: 120,
    );
    _alternativeStopIcon = await _getCustomMarkerIcon(
      'assets/images/bus_stop_alt.png',
      size: 140,
    );
  }

  Future<BitmapDescriptor> _getCustomMarkerIcon(
    String iconPath, {
    int size = 80,
  }) async {
    final ImageConfiguration imageConfiguration = ImageConfiguration(
      size: Size.square(size.toDouble()),
    );
    return await BitmapDescriptor.fromAssetImage(imageConfiguration, iconPath);
  }

  void _findBestRoute() {
    final routeFinder = RouteFinder(widget.routes);
    _bestRoute = routeFinder.findBestRoute(
      widget.startLocation,
      widget.endLocation,
    );

    if (_bestRoute != null) {
      _setupDirectRoute(routeFinder);
      return;
    }
    _findAlternativeRoutes(routeFinder);
  }

  void _setupDirectRoute(RouteFinder routeFinder) {
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
      _findAlternativeRoutes(routeFinder);
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

    _updateMap();
    _zoomToFit();
  }

  void _findAlternativeRoutes(RouteFinder routeFinder) {
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

    if (_alternativeStartRoute!.name == _alternativeEndRoute!.name) {
      _routeInstructions =
          'No direct route available. Alternative route:\n\n'
          '1. Walk ${_alternativeWalkingDistanceStart!.toStringAsFixed(0)}m to board ${_alternativeStartRoute!.name} at this stop\n'
          '2. Ride ${_alternativeStartRoute!.name} to the drop-off point\n'
          '3. Walk ${_alternativeWalkingDistanceEnd!.toStringAsFixed(0)}m to your destination';
    } else {
      _routeInstructions =
          'No direct route available. Alternative route:\n\n'
          '1. Walk ${_alternativeWalkingDistanceStart!.toStringAsFixed(0)}m to board ${_alternativeStartRoute!.name} at this stop\n'
          '2. Ride ${_alternativeStartRoute!.name} to a transfer point\n'
          '3. Transfer to ${_alternativeEndRoute!.name}\n'
          '4. Walk ${_alternativeWalkingDistanceEnd!.toStringAsFixed(0)}m to your destination';
    }

    setState(() {
      _hasAlternativeRoute = true;
      _isLoading = false;
    });

    _updateMap();
    _zoomToFit();
  }

  void _zoomToFit() async {
    if (_markers.isEmpty || mapController == null) return;
    final bounds = _boundsFromLatLngList(
      _markers.map((m) => m.position).toList(),
    );
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120));
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

  void _updateMap() {
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
        anchor: const Offset(0.5, 1.0),
        zIndex: 3,
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: widget.endLocation,
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.endAddress,
        ),
        icon: _endIcon,
        anchor: const Offset(0.5, 1.0),
        zIndex: 3,
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
          zIndex: 2,
        ),
        Marker(
          markerId: const MarkerId('nearest_end'),
          position: _nearestEndPoint!,
          infoWindow: InfoWindow(
            title: 'Exit ${_bestRoute!.name} Here',
            snippet:
                '${_walkingDistanceEnd!.toStringAsFixed(0)}m to destination',
          ),
          icon: _busStopIcon,
          zIndex: 2,
        ),
      ]);

      _polylines.addAll([
        Polyline(
          polylineId: const PolylineId('walk_to_bus'),
          points: [widget.startLocation, _nearestStartPoint!],
          color: _walkingColor,
          width: 6,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
        Polyline(
          polylineId: const PolylineId('bus_route'),
          points: _bestRoute!.path,
          color: _directBusColor,
          width: 8,
        ),
        Polyline(
          polylineId: const PolylineId('walk_from_bus'),
          points: [_nearestEndPoint!, widget.endLocation],
          color: _walkingColor,
          width: 6,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      ]);
    } else if (_hasAlternativeRoute) {
      _markers.addAll([
        Marker(
          markerId: const MarkerId('alternative_start'),
          position: _alternativeStartPoint!,
          infoWindow: InfoWindow(
            title: 'Board ${_alternativeStartRoute!.name} Here',
            snippet:
                '${_alternativeWalkingDistanceStart!.toStringAsFixed(0)}m walk',
          ),
          icon: _alternativeStopIcon,
          zIndex: 2,
        ),
        Marker(
          markerId: const MarkerId('alternative_end'),
          position: _alternativeEndPoint!,
          infoWindow: InfoWindow(
            title: 'Exit ${_alternativeEndRoute!.name} Here',
            snippet:
                '${_alternativeWalkingDistanceEnd!.toStringAsFixed(0)}m to destination',
          ),
          icon: _alternativeStopIcon,
          zIndex: 2,
        ),
      ]);

      _polylines.addAll([
        Polyline(
          polylineId: const PolylineId('walk_to_alternative'),
          points: [widget.startLocation, _alternativeStartPoint!],
          color: _walkingColor,
          width: 6,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
        Polyline(
          polylineId: const PolylineId('alternative_route_main'),
          points: [_alternativeStartPoint!, _alternativeEndPoint!],
          color: _alternativeBusColor,
          width: 8,
        ),
        Polyline(
          polylineId: const PolylineId('walk_from_alternative'),
          points: [_alternativeEndPoint!, widget.endLocation],
          color: _walkingColor,
          width: 6,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      ]);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Guidance',
         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white
        ),
      ),
      body: Stack(
        children: [
          // Full screen Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.startLocation,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) => mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Loading indicator
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),

          // Zoom to fit button
          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: primaryColor,
              onPressed: _zoomToFit,
              child: const Icon(Icons.zoom_out_map, color: Colors.white),
            ),
          ),

          // Route info card (sliding up from bottom)
          if (!_isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildRouteInfoCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    if (!_hasDirectRoute && !_hasAlternativeRoute) {
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
            Icon(Icons.warning, color: Colors.orange, size: 40),
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
                  backgroundColor: lightColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Try Again', style: TextStyle(color: darkColor)),
              ),
            ),
          ],
        ),
      );
    }

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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: darkColor.withOpacity(0.2), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Route header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _hasDirectRoute ? secondaryColor : primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _hasDirectRoute ? Icons.directions_bus : Icons.alt_route,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_hasDirectRoute ? 'Direct' : 'Alternative'} Route: ${route.name}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Route instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_hasDirectRoute)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No direct route available - showing alternative',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Text(
                  _routeInstructions,
                  style: TextStyle(
                    fontSize: 15,
                    color: darkColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Time and fare information
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Time',
                style: TextStyle(fontWeight: FontWeight.bold, color: darkColor),
              ),
              Text(
                '${totalTime.toStringAsFixed(0)} minutes',
                style: TextStyle(fontWeight: FontWeight.w600, color: darkColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fare',
                style: TextStyle(fontWeight: FontWeight.bold, color: darkColor),
              ),
              Text(
                'Rs. ${fare.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateFare(double distanceInMeters) {
    return (distanceInMeters / 1000) <= 15 ? 80 : 120;
  }
}
