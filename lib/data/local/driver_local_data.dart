import 'package:shared_preferences/shared_preferences.dart';

class DriverLocalData {
  static const String _driverNameKey = 'driver_name';
  static const String _driverBusRegKey = 'driver_bus_reg';
  static const String _driverRouteKey = 'driver_route';
  static const String _driverIdKey = 'driver_id';

  // Save driver data
  static Future<void> saveDriverData({
    required String name,
    required String busRegNumber,
    required String route,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_driverNameKey, name);
    await prefs.setString(_driverBusRegKey, busRegNumber);
    await prefs.setString(_driverRouteKey, route);
  }

  // Get driver name
  static Future<String?> getDriverName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_driverNameKey);
  }

  // Get bus reg number
  static Future<String?> getDriverBusReg() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_driverBusRegKey);
  }

  // Get route
  static Future<String?> getDriverRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_driverRouteKey);
  }

  // Clear driver data (logout)
  static Future<void> clearDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_driverNameKey);
    await prefs.remove(_driverBusRegKey);
    await prefs.remove(_driverRouteKey);
    await prefs.remove(_driverIdKey);
  }

  // Check if driver is logged in
  static Future<bool> isDriverLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_driverBusRegKey) != null;
  }
}