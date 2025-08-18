import 'package:bus_kahan_hay/model/bus_routes.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RouteFinder {
  final List<BusRoute> routes;

  RouteFinder(this.routes);

  BusRoute? findBestRoute(LatLng start, LatLng end) {
    if (routes.isEmpty) return null;
    
    BusRoute? bestRoute;
    double bestScore = double.infinity;

    for (final route in routes) {
      final startDistance = _findClosestDistance(start, route.path);
      final endDistance = _findClosestDistance(end, route.path);
      final routeDistance = _calculateRouteDistanceBetween(
        route, 
        findNearestPointOnRoute(start, route),
        findNearestPointOnRoute(end, route),
      );
      
      // Score considers both walking distance and route distance
      final score = startDistance + endDistance + (routeDistance * 0.2);
      
      if (score < bestScore) {
        bestScore = score;
        bestRoute = route;
      }
    }

    return bestRoute;
  }

  BusRoute? findNearestRoute(LatLng location) {
    if (routes.isEmpty) return null;

    BusRoute? nearestRoute;
    double minDistance = double.infinity;

    for (final route in routes) {
      final nearestPoint = findNearestPointOnRoute(location, route);
      final distance = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        nearestPoint.latitude,
        nearestPoint.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestRoute = route;
      }
    }

    return nearestRoute;
  }


  LatLng findNearestPointOnRoute(LatLng point, BusRoute route) {
    LatLng nearestPoint = route.path.first;
    double minDistance = double.infinity;
    
    for (final pathPoint in route.path) {
      final distance = Geolocator.distanceBetween(
        point.latitude, point.longitude,
        pathPoint.latitude, pathPoint.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = pathPoint;
      }
    }
    
    return nearestPoint;
  }

  double _findClosestDistance(LatLng point, List<LatLng> path) {
    double minDistance = double.infinity;
    
    for (final pathPoint in path) {
      final distance = Geolocator.distanceBetween(
        point.latitude, point.longitude,
        pathPoint.latitude, pathPoint.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    return minDistance;
  }

  double _calculateRouteDistanceBetween(BusRoute route, LatLng point1, LatLng point2) {
    return route.distanceBetween(point1, point2);
  }
}