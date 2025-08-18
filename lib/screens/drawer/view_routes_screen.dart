import 'package:flutter/material.dart';
import 'package:bus_kahan_hay/model/bus_routes.dart';

class ViewRoutesScreen extends StatelessWidget {
  final List<BusRoute> routes;

  const ViewRoutesScreen({super.key, required this.routes});

  @override
  Widget build(BuildContext context) {
    // Theme colors
    final Color primaryColor = const Color(0xFFEC130F); // Red
    final Color secondaryColor = const Color(0xFF009B37); // Green
    final Color darkColor = const Color(0xFF000000); // Black
    final Color lightColor = const Color(0xFFF5F5F5); // Light background

    // Route details data
    final Map<String, Map<String, String>> routeDetails = {
      'Route 1': {
        'length': '28 km',
        'terminals': 'Khokrapar to Dockyard',
        'stops':
            'Khokrapar, Saudabd, RCD Ground, Kalaboard, Malir Halt, Colony Gate, Nata Khan Bridge, Drigh Road Station, PAF Base Faisal, Laal Kothi, Karsaz, Nursery, FTC, Regent Plaza, Metropole, Fawwara Chowk, Arts Council, Shaheen Complex, I.I.Chundrigar, Tower, Fisheries, and Dockyard',
      },
      'Route 2': {
        'length': '30 km',
        'terminals': 'Power House to Indus Hospital',
        'stops':
            'Power House, UP Mor, Nagan Chowrangi, Shafiq Morr, Sohrab Goth, Gulshan Chowrangi, NIPA, Johar Morr, COD, Drigh Road Station, Colony Gate, Shah Faisal Colony, Singer Chowrangi, Khaddi Stop, and Indus Hospital',
      },
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Bus Routes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: lightColor,
        child: Column(
          children: [
            // Header with route count
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${routes.length} routes available',
                    style: TextStyle(
                      color: darkColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Routes list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  final normalizedRouteName = route.name.trim().toLowerCase();

                  // Find matching entry (case-insensitive)
                  final details = routeDetails.entries
                      .firstWhere(
                        (entry) =>
                            entry.key.toLowerCase() == normalizedRouteName,
                        orElse: () => MapEntry('', {
                          'length': 'N/A',
                          'terminals': 'N/A',
                          'stops': 'N/A',
                        }),
                      )
                      .value;

                  return ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_bus,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      route.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${details['length']} • ${details['terminals']}',
                      style: TextStyle(
                        color: darkColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    trailing: Icon(Icons.expand_more, color: secondaryColor),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: darkColor.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              'Route Length:',
                              details['length']!,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Terminals:',
                              details['terminals']!,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('Stops:', '', isMultiLine: true),
                            Text(
                              details['stops']!,
                              style: TextStyle(
                                color: darkColor.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 8),
        if (!isMultiLine)
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
