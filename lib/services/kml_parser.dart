import 'package:bus_kahan_hay/model/bus_routes.dart';
import 'package:geolocator/geolocator.dart';
import 'package:xml/xml.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class KmlParser {
  final String name;
  final List<LatLng> path;

  KmlParser({required this.name, required this.path});

  double distanceBetween(LatLng point1, LatLng point2) {
    // Find indices of the points in the path
    int index1 = path.indexWhere((p) => p.latitude == point1.latitude && p.longitude == point1.longitude);
    int index2 = path.indexWhere((p) => p.latitude == point2.latitude && p.longitude == point2.longitude);
    
    if (index1 == -1 || index2 == -1) return 0.0;
    
    // Ensure index1 is smaller
    if (index1 > index2) {
      int temp = index1;
      index1 = index2;
      index2 = temp;
    }
    
    // Calculate cumulative distance
    double distance = 0.0;
    for (int i = index1; i < index2; i++) {
      distance += Geolocator.distanceBetween(
        path[i].latitude, path[i].longitude,
        path[i+1].latitude, path[i+1].longitude,
      );
    }
    
    return distance;
  }
}

List<BusRoute> parseKml(String kmlString) {
  final document = XmlDocument.parse(kmlString);
  final placemarks = document.findAllElements('Placemark');
  
  final routes = <BusRoute>[];
  
  for (final placemark in placemarks) {
    final name = placemark.findElements('name').first.text;
    final coords = placemark
        .findElements('LineString')
        .first
        .findElements('coordinates')
        .first
        .text
        .trim()
        .split(' ')
        .where((coord) => coord.trim().isNotEmpty)
        .toList();
    
    final path = coords.map((coord) {
      final parts = coord.split(',');
      return LatLng(double.parse(parts[1]), double.parse(parts[0]));
    }).toList();
    
    routes.add(BusRoute(name: name, path: path));
  }
  
  return routes;
}
