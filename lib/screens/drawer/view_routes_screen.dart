import 'package:bus_kahan_hay/core/app_colors.dart';
import 'package:bus_kahan_hay/model/bus_routes.dart';
import 'package:flutter/material.dart';

class ViewRoutesScreen extends StatefulWidget {
  const ViewRoutesScreen({super.key, required List<BusRoute> routes});

  @override
  State<ViewRoutesScreen> createState() => _ViewRoutesScreenState();
}

class _ViewRoutesScreenState extends State<ViewRoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final Color primaryColor = const Color(0xFFEC130F); // Red
  final Color secondaryColor = const Color(0xFF009B37); // Green
  final Color darkColor = const Color(0xFF000000); // Black
  final Color lightColor = const Color(0xFFF5F5F5); // Light background

  // ✅ Route details data
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
    'Route 3': {
      'length': '31 km',
      'terminals': 'Power House to Nasir Jump',
      'stops':
          'Power House, UP More, Nagan Chowrangi, Sakhi Hasan, 5 Star Chowrangi, KDA Chowrangi, Board Office, Nazimabad Eid Gah Ground, Liaquatabad 10 Number, Essa Nagri, Civic Centre, National stadium, Karsaz, Nursery, FTC, Korangi Road, KPT Interchange upto Shan Chowrangi, Nasir Jump',
    },
    'Route 4': {
      'length': '21 km',
      'terminals': 'Power House to Keamari',
      'stops':
          'Power House, UP Mor, Nagan Chowrangi, Shafiq Mor, Sohrab Goth, Water Pump, Ayesha Manzil, Karimabad, Liaquatabad 10, Laloo Khait, Teen Hati, Jehangir Road, Numaish, Mobile Market, Urdu Bazar, Civil Hospital, City Court, Light House, Bolton Market, Tower and Keamari',
    },
    'Route 8': {
      'length': '17 km',
      'terminals': 'Yousuf Goth to Tower',
      'stops':
          'Yousuf Goth, Naval Colony, Baldia, Sher Shah, Gulbai, Agra Taj Colony, Daryabad, Jinnah Brige, and Tower',
    },
    'Route 9': {
      'length': '42 km',
      'terminals': 'Gulshan e Hadeed to Tower',
      'stops':
          'Gulsahan e Hadeed, Salah Uddin Ayubi Road, Allah Wali Chowrangi, National Highway 5, Steel Mill More, Port Bin Qasim More, Razzakabad, Abdullah Goth, Chowkundi More, Fast University, Bhains Colony More, Manzil Pump, Quaidabad, Murghi Khana, Prince Aly Boys School, Nadra Center Malir, Malir Session Court, Malir 15, Kalaboard, Malir Halt, Colony Gate, Nata Khan Bridge, Drigh Road Station, PAF Base Faisal, Laal Kothi, Karsaz, Nursery, FTC, Regent Plaza, Metropole, Fawwara Chowk, Arts Council, Shaheen Complex and I.I.Chundrigar and Tower',
    },
    'Route 10': {
      'length': '28 km',
      'terminals': 'Numaish Chowrangi to Ibrahim Hyderi',
      'stops':
          'Numaish Chowrangi, Mobile Market, Metropole, Frere Hall, Teen Talwar, Do Talwar, Abdullah Shah Ghazi, Dolmen Mall, Clock Tower DHA, 26 Street, Masjid-e-Ayesha, Rahat Park, KPT Inter change, Korangi Crossing, CBM University, Parco, Ibrahim Hyderi',
    },
    'Route 11': {
      'length': '19 km',
      'terminals': 'Miran Nakka to Shireen Jinnah Colony',
      'stops':
          'Miran Nakka, Gulistan Colony, Bihar Colony, Agra Taj, Daryabad, Jinnah Brige, Bahria Complex, M.T.Khan Road, PICD, Submarine Chowk, Bahria Complex 3, Khadda Market, Abdullah Shah Ghazi, Bilawal Chowrangi, Ziauddin Hospital, Shireen Jinnah Colony',
    },
    'Route 12': {
      'length': '31 km',
      'terminals': 'Naddi Kinara to Lucky Star',
      'stops':
          'Naddi Kinara, Khokhrapar, Saudabad Chowrangi, RCD Ground, Kalaboard, Malir 15, Malir Mandir, Malir Session Court, Murghi Khana, Quaidabad, Dawood Chowrangi, Babar Market, Landhi Road, Nasir Jump, Indus Hospital, Korangi Crossing, Qayyumabad, Defence Mor, National Medical Center, Gora Qabristan, FTC, Jutt Land, Lines Area, Army Public School, Lucky Star Saddar',
    },
    'Route 13': {
      'length': '20 km',
      'terminals': 'Hawksbay to Tower',
      'stops':
          'Hawksbay, Mauripur, Gulbai, Agra Taj, Daryabad, Jinnah Brige, Tower',
    },
    'EV-1': {
      'length': '28 km',
      'terminals': 'Malir Cantt to Dolmen Mall Clifton',
      'stops':
          'CMH Malir Cantt, Tank Chowk, Model Colony Mor, Jinnah Ave, Airport, Colony Gate, Nata Khan Bridge, Drigh Road Station, PAF Base Faisal, Laal Kothi, Karsaz, Nursery, FTC, Korangi Road, DHA Phase 1, Masjid e Ayesha, Clock Tower DHA, Dolmen Mall Clifton',
    },
    'EV-2': {
      'length': '30 km',
      'terminals': 'Bahria Town to Malir Halt',
      'stops':
          'Bahria Town, Dumba Goth, Toll Plaza, Baqai University, Malir Cantt Gate 5, Malir Cantt Gate 6, Tank Chowk, Model Mor, Jinnah Ave, Malir Halt',
    },
    'EV-3': {
      'length': '20 km',
      'terminals': 'Malir Cantt Check Post 5 to Numaish',
      'stops':
          'Malir Cantt Check Post 5, Rim Jhim Tower, Safoora Chowrangi, Mausamiyat Chowrangi, Kamran Chowrangi, Darul Sehat Hospital, Johar Chowrangi, Johar Mor, Millennium Mall, Dalmia Road, Bahria University, National Stadium, Aga Khan Hospital, Liaquat National Hospital, PIB Colony, Jail Chowrangi, Dawood Engineering University, Islamia College, People Secretariat Chowrangi, Numaish',
    },
    'EV-4': {
      'length': '34 km',
      'terminals': 'Bahria Town to Ayesha Manzil',
      'stops':
          'Bahria Town, Dumba Goth, M9 Toll Plaza, Jamali Pull, New Sabzi Mandi, Al Asif, Sohrab Goth, Water Pump, Ayesha Manzil',
    },
    'EV-5': {
      'length': '41 km',
      'terminals': 'DHA City To Sohrab Goth',
      'stops':
          'DHA City, Bahria Town, Dumba Goth, M9 Toll Plaza, Jamali Pull, New Sabzi Mandi, Al Asif, Sohrab Goth',
    },
  };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // 🔎 Filter routes by search
    final filteredRoutes = routeDetails.entries.where((entry) {
      final query = _searchQuery.toLowerCase();
      final routeName = entry.key.toLowerCase();
      final stops = entry.value['stops']?.toLowerCase() ?? "";
      final terminals = entry.value['terminals']?.toLowerCase() ?? "";
      return routeName.contains(query) ||
          stops.contains(query) ||
          terminals.contains(query);
    }).toList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.green,
        body: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'All Bus Routes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the row
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: Container(
                width: width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // 🔎 Search field
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: "Search routes or stops...",
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.green,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: AppColors.green,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Header with route count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      width: double.infinity,
                      color: AppColors.green.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${filteredRoutes.length} routes found',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Routes list
                    Expanded(
                      child: filteredRoutes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No routes found",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20.0),
                              itemCount: filteredRoutes.length,
                              itemBuilder: (context, index) {
                                final entry = filteredRoutes[index];
                                final routeName = entry.key;
                                final details = entry.value;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.green.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.directions_bus,
                                        color: AppColors.green,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      routeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${details['length']} • ${details['terminals']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.expand_more,
                                      color: AppColors.green,
                                    ),
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(15),
                                            bottomRight: Radius.circular(15),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildDetailRow(
                                              'Route Length:',
                                              details['length'] ?? 'N/A',
                                            ),
                                            const SizedBox(height: 12),
                                            _buildDetailRow(
                                              'Terminals:',
                                              details['terminals'] ?? 'N/A',
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Stops:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              details['stops'] ?? 'N/A',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ),
      ],
    );
  }
}
