import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LocationsOverviewPage extends StatefulWidget {
  const LocationsOverviewPage({super.key});

  @override
  State<LocationsOverviewPage> createState() => _LocationsOverviewPageState();
}

class _LocationsOverviewPageState extends State<LocationsOverviewPage> {
  Map<String, int> buildingData = {};
  Map<String, int> floorData = {};
  Map<String, int> typeData = {};
  bool isLoading = true;
  int totalLocations = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final buildingsSnapshot = await firestore.collection('buildings').get();

      Map<String, int> buildings = {};
      Map<String, int> floors = {};
      Map<String, int> types = {};
      int totalCount = 0;

      // Iterate through each building
      for (var buildingDoc in buildingsSnapshot.docs) {
        final buildingName = buildingDoc.data()['name'] ?? 'Unknown';
        final buildingUid = buildingDoc.id;

        // Fetch locations subcollection for this building
        final locationsSnapshot = await firestore
            .collection('buildings')
            .doc(buildingUid)
            .collection('locations')
            .get();

        // Count locations in this building
        final locationCount = locationsSnapshot.docs.length;
        buildings[buildingName] = (buildings[buildingName] ?? 0) + locationCount;
        totalCount += locationCount;

        // Process each location document
        for (var locationDoc in locationsSnapshot.docs) {
          final data = locationDoc.data();
          final floor = data['floor'] ?? 'Unknown';
          final type = data['type'] ?? 'Unknown';

          // Count floors
          floors[floor] = (floors[floor] ?? 0) + 1;

          // Count types
          types[type] = (types[type] ?? 0) + 1;
        }
      }

      setState(() {
        buildingData = buildings;
        floorData = floors;
        typeData = types;
        totalLocations = totalCount;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching analytics data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212529)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Locations Overview',
          style: TextStyle(
            color: Color(0xFF212529),
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC727)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Locations Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF212529),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFFFC727),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$totalLocations',
                          style: const TextStyle(
                            color: Color(0xFFFFC727),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SansRegular',
                          ),
                        ),
                        const Text(
                          'Total Locations',
                          style: TextStyle(
                            color: Color(0xFFADB5BD),
                            fontSize: 16,
                            fontFamily: 'SansRegular',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buildings Analytics
                  _buildAnalyticsSection(
                    'Locations by Building',
                    buildingData,
                    Icons.business_outlined,
                    [
                      const Color(0xFFFFC727),
                      const Color(0xFF28A745),
                      const Color(0xFF007BFF),
                      const Color(0xFFDC3545),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Floors Analytics
                  _buildAnalyticsSection(
                    'Locations by Floor',
                    floorData,
                    Icons.layers_outlined,
                    [
                      const Color(0xFF6F42C1),
                      const Color(0xFF20C997),
                      const Color(0xFFFD7E14),
                      const Color(0xFFE83E8C),
                      const Color(0xFF6C757D),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Types Analytics
                  _buildAnalyticsSection(
                    'Locations by Type',
                    typeData,
                    Icons.category_outlined,
                    [
                      const Color(0xFF007BFF),
                      const Color(0xFF28A745),
                      const Color(0xFFFFC107),
                      const Color(0xFFDC3545),
                      const Color(0xFF17A2B8),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalyticsSection(
    String title,
    Map<String, int> data,
    IconData icon,
    List<Color> colors,
  ) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF6C757D), size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212529),
                    fontFamily: 'SansRegular',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Text(
              'No data available',
              style: TextStyle(
                color: Color(0xFF6C757D),
                fontFamily: 'SansRegular',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6C757D), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529),
                  fontFamily: 'SansRegular',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Pie Chart
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _generatePieChartSections(data, colors),
                      sectionsSpace: 1,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _generateLegend(data, colors),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(Map<String, int> data, List<Color> colors) {
    final total = data.values.fold(0, (sum, value) => sum + value);
    final entries = data.entries.toList();
    
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final percentage = (entry.value / total * 100);
      final color = colors[index % colors.length];
      
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'SansRegular',
        ),
      );
    });
  }

  List<Widget> _generateLegend(Map<String, int> data, List<Color> colors) {
    final entries = data.entries.toList();
    
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final color = colors[index % colors.length];
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212529),
                      fontFamily: 'SansRegular',
                    ),
                  ),
                  Text(
                    '${entry.value} location${entry.value == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C757D),
                      fontFamily: 'SansRegular',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}