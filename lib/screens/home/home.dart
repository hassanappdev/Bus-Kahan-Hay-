import 'dart:convert';
import 'package:bus_kahan_hay/model/bus_routes.dart';
import 'package:bus_kahan_hay/screens/drawer/guide_screen.dart';
import 'package:bus_kahan_hay/screens/drawer/help_screen.dart';
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

  // Color Theme
  final Color primaryColor = const Color(0xFFEC130F); // Red
  final Color secondaryColor = const Color(0xFF009B37); // Green
  final Color darkColor = const Color(0xFF000000); // Black

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

    const String ACCESS_TOKEN = "";
    String baseURL = '';
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text(
            'Bus Kahan Hay',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        drawer: _buildDrawer(),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan your journey',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find the best bus route for your trip',
                    style: TextStyle(
                      fontSize: 16,
                      color: darkColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _currentLocationController,
                            focusNode: _currentLocationFocus,
                            decoration: InputDecoration(
                              labelText: 'Current location',
                              hintText: 'Enter your starting point',
                              labelStyle: TextStyle(color: darkColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: darkColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: primaryColor),
                              ),
                              prefixIcon: Icon(
                                Icons.location_on,
                                color: primaryColor,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_currentLocationController
                                      .text
                                      .isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _currentLocationController.clear();
                                        setState(() {
                                          _currentLocationSuggestions = [];
                                        });
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.my_location,
                                      size: 20,
                                    ),
                                    onPressed: _getCurrentLocation,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showCurrentLocationSuggestions &&
                              _currentLocationSuggestions.isNotEmpty)
                            _buildSuggestionsList(
                              _currentLocationSuggestions,
                              true,
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _destinationController,
                            focusNode: _destinationFocus,
                            decoration: InputDecoration(
                              labelText: 'Destination',
                              hintText: 'Where do you want to go?',
                              labelStyle: TextStyle(color: darkColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: darkColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: primaryColor),
                              ),
                              prefixIcon: Icon(Icons.flag, color: primaryColor),
                              suffixIcon: _destinationController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _destinationController.clear();
                                        setState(() {
                                          _destinationSuggestions = [];
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          if (_showDestinationSuggestions &&
                              _destinationSuggestions.isNotEmpty)
                            _buildSuggestionsList(
                              _destinationSuggestions,
                              false,
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
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
                                          const SnackBar(
                                            content: Text(
                                              'Please enter both locations',
                                            ),
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
                                          ),
                                        );
                                      } finally {
                                        setState(() => _isLoading = false);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'Find Bus Route',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Drawer
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Bus Kahan Hay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.directions_bus, color: darkColor),
            title: Text('Find Route', style: TextStyle(color: darkColor)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.map, color: darkColor),
            title: Text('View Routes', style: TextStyle(color: darkColor)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewRoutesScreen(routes: _routes),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help_outline, color: darkColor),
            title: Text('Guide', style: TextStyle(color: darkColor)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GuideScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help, color: darkColor),
            title: Text('Help', style: TextStyle(color: darkColor)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info, color: darkColor),
            title: Text('About', style: TextStyle(color: darkColor)),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Bus Kahan Hay',
                applicationVersion: '1.0.0',
                children: [Text('Public transport route finder app')],
              );
            },
          ),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              color: primaryColor,
            ),
            title: Text(
              place["display_name"] ?? 'Unknown location',
              style: TextStyle(fontSize: 14, color: darkColor),
            ),
            dense: true,
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
