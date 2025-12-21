import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DetailedPieChartPage extends StatelessWidget {
  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

  Future<int> getCountByType(String type) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('devices')
        .where('type', isEqualTo: type)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<Map<String, int>> getDeviceCountsByBuilding() async {
    final firestore = FirebaseFirestore.instance;

    // First, get all buildings from the buildings collection
    final buildingsSnapshot = await firestore.collection('buildings').get();
    Map<String, int> result = {};
    
    // Initialize the result map with building names
    for (var buildingDoc in buildingsSnapshot.docs) {
      final data = buildingDoc.data();
      final buildingName = data['name'] as String?;
      if (buildingName != null) {
        result[buildingName] = 0;
      }
    }

    // Get the mapping from location to building by iterating through nested subcollections
    final Map<String, String> locationToBuilding = {};
    for (var buildingDoc in buildingsSnapshot.docs) {
      final buildingData = buildingDoc.data();
      final buildingName = buildingData['name'] as String?;
      
      if (buildingName != null) {
        // Get locations subcollection for this building
        final locationsSnapshot = await buildingDoc.reference
            .collection('locations')
            .get();
        
        for (var locationDoc in locationsSnapshot.docs) {
          final locationData = locationDoc.data();
          final locationName = locationData['name'] as String?;
          if (locationName != null) {
            locationToBuilding[locationName] = buildingName;
          }
        }
      }
    }

    // Count devices by building
    final devicesSnapshot = await firestore.collection('devices').get();
    for (var doc in devicesSnapshot.docs) {
      final data = doc.data();
      final locationName = data['location'] as String?;

      if (locationName != null && locationToBuilding.containsKey(locationName)) {
        final building = locationToBuilding[locationName]!;
        if (result.containsKey(building)) {
          result[building] = result[building]! + 1;
        }
      }
    }

    return result;
  }

  Future<Map<String, int>> getPeripheralCountsByType() async {
    final firestore = FirebaseFirestore.instance;
    
    Map<String, int> result = {
      'Monitor': 0,
      'Printer': 0,
      'Tablet': 0,
      'Others': 0,
    };

    final devicesSnapshot = await firestore
        .collection('devices')
        .where('type', isEqualTo: 'Peripheral')
        .get();

    for (var doc in devicesSnapshot.docs) {
      final data = doc.data();
      final peripheralType = data['peripheral_type'] as String?;
      
      if (peripheralType != null) {
        if (result.containsKey(peripheralType)) {
          result[peripheralType] = result[peripheralType]! + 1;
        } else {
          result['Others'] = result['Others']! + 1;
        }
      } else {
        result['Others'] = result['Others']! + 1;
      }
    }

    return result;
  }

  // Generate dynamic colors for buildings
  List<Color> _generateBuildingColors(int count) {
    final List<Color> colors = [
      const Color(0xFF81D4FA), // Yellow
      const Color(0xFF28A745), // Green
      const Color(0xFF007BFF), // Blue
      const Color(0xFFDC3545), // Red
      const Color(0xFF6F42C1), // Purple
      const Color(0xFFFD7E14), // Orange
      const Color(0xFF20C997), // Teal
      const Color(0xFFE83E8C), // Pink
    ];
    
    List<Color> result = [];
    for (int i = 0; i < count; i++) {
      result.add(colors[i % colors.length]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        title: const Text(
          'Detailed Analytics',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.bold,
            color: Color(0xFF81D4FA),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF81D4FA)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([
              getCountByType('PC'),
              getCountByType('Peripheral'),
              getDeviceCountsByBuilding(),
              getPeripheralCountsByType(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81D4FA)),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        color: Color(0xFF6C757D),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              final totalPC = snapshot.data![0] as int;
              final totalPeripheral = snapshot.data![1] as int;
              final buildingCounts = snapshot.data![2] as Map<String, int>;
              final peripheralTypeCounts = snapshot.data![3] as Map<String, int>;

              // Generate dynamic colors for buildings
              final buildingNames = buildingCounts.keys.toList();
              final buildingColors = _generateBuildingColors(buildingNames.length);
              final Map<String, Color> buildingColorMap = {};
              for (int i = 0; i < buildingNames.length; i++) {
                buildingColorMap[buildingNames[i]] = buildingColors[i];
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Title
                  Container(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    child: const Text(
                      'Device Analytics Overview',
                      style: TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212529),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // PC vs Peripherals Chart
                  _buildPieChartSection(
                    title: 'PC vs Peripherals Distribution',
                    data: {
                      'PC': totalPC,
                      'Peripherals': totalPeripheral,
                    },
                    colors: {
                      'PC': const Color(0xFF81D4FA),
                      'Peripherals': Colors.grey[600]!,
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Building Distribution Chart (now dynamic)
                  _buildPieChartSection(
                    title: 'Devices by Building',
                    data: buildingCounts,
                    colors: buildingColorMap,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Peripheral Types Chart
                  _buildPieChartSection(
                    title: 'Peripheral Types Distribution',
                    data: peripheralTypeCounts,
                    colors: {
                      'Monitor': const Color(0xFF81D4FA),
                      'Printer': const Color(0xFF28A745),
                      'Tablet': const Color(0xFF007BFF),
                      'Others': Colors.grey[600]!,
                    },
                  ),
                  
                  // Bottom padding for better scroll experience
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPieChartSection({
    required String title,
    required Map<String, int> data,
    required Map<String, Color> colors,
  }) {
    final totalValue = data.values.fold(0, (sum, value) => sum + value);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF212529),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Container(
            margin: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF81D4FA),
              ),
            ),
          ),
          
          // Legend
          Container(
            margin: const EdgeInsets.only(bottom: 32.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 12,
              children: data.entries.map((entry) {
                return _buildLegendItem(
                  color: colors[entry.key]!,
                  label: "${entry.key} (${entry.value})",
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 20),
          
          // Pie Chart
          Container(
            height: 280,
            margin: const EdgeInsets.only(bottom: 22.0),
            child: totalValue > 0
                ? PieChart(
                    PieChartData(
                      sections: data.entries.map((entry) {
                        final percentage = ((entry.value / totalValue) * 100);
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: '${percentage.toStringAsFixed(1)}%',
                          color: colors[entry.key]!,
                          radius: 100,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                    ),
                  )
                : const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(
                        fontFamily: 'SansRegular',
                        color: Color(0xFF81D4FA),
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
          SizedBox(height: 20),
          
          // Data Table
          _buildDataTable(data, colors),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF343A40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF81D4FA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(Map<String, int> data, Map<String, Color> colors) {
    final totalValue = data.values.fold(0, (sum, value) => sum + value);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF343A40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF495057),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            decoration: const BoxDecoration(
              color: Color(0xFF81D4FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Category',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF212529),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Count',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF212529),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Percentage',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF212529),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          // Table Rows
          ...data.entries.map((entry) {
            final percentage = totalValue > 0 ? ((entry.value / totalValue) * 100) : 0.0;
            final isLastItem = entry == data.entries.last;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
              decoration: BoxDecoration(
                border: !isLastItem ? const Border(
                  bottom: BorderSide(
                    color: Color(0xFF495057),
                    width: 1,
                  ),
                ) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colors[entry.key]!,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontFamily: 'SansRegular',
                              fontSize: 15,
                              color: Color(0xFF81D4FA),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF81D4FA),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF81D4FA),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}