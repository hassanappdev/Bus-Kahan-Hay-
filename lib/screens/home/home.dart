import 'dart:convert';
import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:bus_kahan_hay/model/bus_routes.dart';
import 'package:bus_kahan_hay/screens/drawer/custom_drawer.dart';
import 'package:bus_kahan_hay/screens/drawer/guide_screen.dart';
import 'package:bus_kahan_hay/screens/home/route_screen.dart';
import 'package:bus_kahan_hay/screens/drawer/view_routes_screen.dart';
import 'package:bus_kahan_hay/services/kml_parser.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _currentLocationController =
      TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _currentLocationFocus = FocusNode();
  final FocusNode _destinationFocus = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<dynamic> _currentLocationSuggestions = [];
  List<dynamic> _destinationSuggestions = [];
  var uuid = Uuid();
  String sessionToken = '';
  bool _isLoading = false;
  bool _showCurrentLocationSuggestions = false;
  bool _showDestinationSuggestions = false;
  List<BusRoute> _routes = [];

  @override
  void initState() {
    super.initState();
    _currentLocationController.addListener(_onCurrentLocationChanged);
    _destinationController.addListener(_onDestinationChanged);

    _currentLocationFocus.addListener(() {
      setState(() {
        _showCurrentLocationSuggestions = _currentLocationFocus.hasFocus;
        _showDestinationSuggestions = false;
      });
    });

    _destinationFocus.addListener(() {
      setState(() {
        _showDestinationSuggestions = _destinationFocus.hasFocus;
        _showCurrentLocationSuggestions = false;
      });
    });

    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final kmlString = await rootBundle.loadString(
        'assets/PBS_Operational_Routes.kml',
      );
      setState(() {
        _routes = parseKml(kmlString);
      });
    } catch (e) {
      debugPrint("Error loading routes: $e");
    }
  }

  void _onCurrentLocationChanged() {
    if (sessionToken.isEmpty) {
      setState(() {
        sessionToken = uuid.v4();
      });
    }
    _getSuggestions(_currentLocationController.text, true);
  }

  void _onDestinationChanged() {
    if (sessionToken.isEmpty) {
      setState(() {
        sessionToken = uuid.v4();
      });
    }
    _getSuggestions(_destinationController.text, false);
  }

  Future<void> _getSuggestions(String input, bool isCurrentLocation) async {
    if (input.isEmpty) {
      setState(() {
        if (isCurrentLocation) {
          _currentLocationSuggestions = [];
        } else {
          _destinationSuggestions = [];
        }
      });
      return;
    }

    const String ACCESS_TOKEN = "pk.0fe15ec580cd466ef8f4070a94b58f16";
    String baseURL = 'https://api.locationiq.com/v1/autocomplete';
    String request =
        '$baseURL?key=$ACCESS_TOKEN&q=$input&limit=5&countrycodes=pk&format=json';

    try {
      setState(() => _isLoading = true);
      var response = await http.get(Uri.parse(request));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          if (isCurrentLocation) {
            _currentLocationSuggestions = data;
          } else {
            _destinationSuggestions = data;
          }
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      debugPrint("Exception: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String street = placemark.street ?? '';
        String locality = placemark.locality ?? '';
        String administrativeArea = placemark.administrativeArea ?? '';

        String formattedAddress = '$street, $locality, $administrativeArea';

        setState(() {
          _currentLocationController.text = formattedAddress;
          _currentLocationSuggestions = [];
        });
      } else {
        throw Exception('No address found for these coordinates');
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSuggestionTap(dynamic place, bool isCurrentLocation) {
    String displayName = place["display_name"] ?? '';
    if (isCurrentLocation) {
      _currentLocationController.text = displayName;
      _currentLocationFocus.unfocus();
    } else {
      _destinationController.text = displayName;
      _destinationFocus.unfocus();
    }

    setState(() {
      _currentLocationSuggestions = [];
      _destinationSuggestions = [];
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Bus Kahan Hay',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.green,
        leading: IconButton(
          icon: Icon(Icons.menu, color: AppColors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Text(
                    'Plan Your Journey',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find the best bus route for your trip across the city',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Input Card
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.containerColor,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Current Location Input
                          TextField(
                            controller: _currentLocationController,
                            focusNode: _currentLocationFocus,
                            decoration: InputDecoration(
                              labelText: 'Current Location',
                              hintText: 'Enter your starting point',
                              labelStyle: TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: AppColors.black.withOpacity(0.5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.containerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.green,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.containerColor,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.containerColor,
                              prefixIcon: Icon(
                                Icons.location_on,
                                color: AppColors.green,
                                size: 24,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_currentLocationController
                                      .text
                                      .isNotEmpty)
                                    IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 20,
                                        color: AppColors.black.withOpacity(0.6),
                                      ),
                                      onPressed: () {
                                        _currentLocationController.clear();
                                        setState(() {
                                          _currentLocationSuggestions = [];
                                        });
                                      },
                                    ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      Icons.my_location,
                                      size: 20,
                                      color: AppColors.green,
                                    ),
                                    onPressed: _getCurrentLocation,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),

                          if (_showCurrentLocationSuggestions &&
                              _currentLocationSuggestions.isNotEmpty)
                            _buildSuggestionsList(
                              _currentLocationSuggestions,
                              true,
                            ),

                          const SizedBox(height: 20),

                          // Destination Input
                          TextField(
                            controller: _destinationController,
                            focusNode: _destinationFocus,
                            decoration: InputDecoration(
                              labelText: 'Destination',
                              hintText: 'Where do you want to go?',
                              labelStyle: TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: AppColors.black.withOpacity(0.5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.containerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.green,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.containerColor,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.containerColor,
                              prefixIcon: Icon(
                                Icons.flag,
                                color: AppColors.green,
                                size: 24,
                              ),
                              suffixIcon: _destinationController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        size: 20,
                                        color: AppColors.black.withOpacity(0.6),
                                      ),
                                      onPressed: () {
                                        _destinationController.clear();
                                        setState(() {
                                          _destinationSuggestions = [];
                                        });
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),

                          if (_showDestinationSuggestions &&
                              _destinationSuggestions.isNotEmpty)
                            _buildSuggestionsList(
                              _destinationSuggestions,
                              false,
                            ),

                          const SizedBox(height: 32),

                          // Find Route Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _routes.isEmpty
                                  ? null
                                  : () async {
                                      if (_currentLocationController
                                              .text
                                              .isEmpty ||
                                          _destinationController.text.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please enter both locations',
                                            ),
                                            backgroundColor: AppColors.green,
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => _isLoading = true);

                                      try {
                                        final startPlacemarks =
                                            await locationFromAddress(
                                              _currentLocationController.text,
                                            );
                                        final endPlacemarks =
                                            await locationFromAddress(
                                              _destinationController.text,
                                            );

                                        if (startPlacemarks.isEmpty ||
                                            endPlacemarks.isEmpty) {
                                          throw Exception(
                                            'Could not find locations',
                                          );
                                        }

                                        // Use the simple version first for testing
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RouteScreen(
                                              startLocation: LatLng(
                                                startPlacemarks.first.latitude,
                                                startPlacemarks.first.longitude,
                                              ),
                                              endLocation: LatLng(
                                                endPlacemarks.first.latitude,
                                                endPlacemarks.first.longitude,
                                              ),
                                              routes: _routes,
                                              startAddress:
                                                  _currentLocationController
                                                      .text,
                                              endAddress:
                                                  _destinationController.text,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: ${e.toString()}',
                                            ),
                                            backgroundColor: AppColors.green,
                                          ),
                                        );
                                      } finally {
                                        setState(() => _isLoading = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text('Find Bus Route'),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Additional Info Text
                          Text(
                            'We\'ll find the most efficient bus routes for your journey',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.black.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions Section
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.route,
                          title: 'View All Routes',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ViewRoutesScreen(routes: _routes),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.help,
                          title: 'Help Guide',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GuideScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                    strokeWidth: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.containerColor.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.green),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(
    List<dynamic> suggestions,
    bool isCurrentLocation,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.containerColor),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          var place = suggestions[index];
          return ListTile(
            leading: Icon(
              isCurrentLocation ? Icons.location_on : Icons.place,
              color: AppColors.green,
              size: 22,
            ),
            title: Text(
              place["display_name"] ?? 'Unknown location',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () => _onSuggestionTap(place, isCurrentLocation),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _currentLocationController.dispose();
    _destinationController.dispose();
    _currentLocationFocus.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }
}
