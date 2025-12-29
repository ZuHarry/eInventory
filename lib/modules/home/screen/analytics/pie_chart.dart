import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailedPieChartPage extends StatelessWidget {
  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

  Future<String?> getUserDepartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    return userDoc.data()?['department'] as String?;
  }

  Future<Set<String>> getDepartmentLocations() async {
    final department = await getUserDepartment();
    if (department == null || department.isEmpty) {
      return {};
    }

    final firestore = FirebaseFirestore.instance;

    // Query buildings where 'name' field equals the user's department
    final buildingsSnapshot = await firestore
        .collection('buildings')
        .where('name', isEqualTo: department)
        .get();
    
    if (buildingsSnapshot.docs.isEmpty) {
      return {};
    }

    // Collect all location names from all matching buildings
    final Set<String> departmentLocationNames = {};
    
    for (var buildingDoc in buildingsSnapshot.docs) {
      // Get locations subcollection from this building
      final locationsSnapshot = await firestore
          .collection('buildings')
          .doc(buildingDoc.id)
          .collection('locations')
          .get();
      
      for (var locationDoc in locationsSnapshot.docs) {
        final locationData = locationDoc.data();
        final locationName = locationData['name'];
        
        if (locationName != null) {
          departmentLocationNames.add(locationName);
        }
      }
    }

    return departmentLocationNames;
  }

  Future<int> getCountByType(String type) async {
    final departmentLocations = await getDepartmentLocations();
    
    if (departmentLocations.isEmpty) {
      return 0;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('devices')
        .where('type', isEqualTo: type)
        .get();
    
    // Filter devices that are in department locations
    int count = 0;
    for (var doc in snapshot.docs) {
      final deviceLocation = doc.data()['location'];
      if (deviceLocation != null && departmentLocations.contains(deviceLocation)) {
        count++;
      }
    }
    
    return count;
  }

  Future<Map<String, int>> getDevicesByBrand() async {
    final departmentLocations = await getDepartmentLocations();
    
    if (departmentLocations.isEmpty) {
      return {};
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('devices')
        .get();
    
    Map<String, int> brandCounts = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final deviceLocation = data['location'];
      final brand = data['brand'];

      if (deviceLocation != null &&
          departmentLocations.contains(deviceLocation) &&
          brand != null &&
          brand.toString().trim().isNotEmpty) {
        final brandStr = brand.toString().trim();
        brandCounts[brandStr] = (brandCounts[brandStr] ?? 0) + 1;
      }
    }

    return brandCounts;
  }

  Future<Map<String, int>> getDevicesByFloor() async {
    final department = await getUserDepartment();
    if (department == null || department.isEmpty) {
      return {};
    }

    final firestore = FirebaseFirestore.instance;

    // Get buildings for user's department
    final buildingsSnapshot = await firestore
        .collection('buildings')
        .where('name', isEqualTo: department)
        .get();
    
    if (buildingsSnapshot.docs.isEmpty) {
      return {};
    }

    // Map to store floor -> location names
    Map<String, Set<String>> floorToLocations = {};
    
    for (var buildingDoc in buildingsSnapshot.docs) {
      final locationsSnapshot = await firestore
          .collection('buildings')
          .doc(buildingDoc.id)
          .collection('locations')
          .get();
      
      for (var locationDoc in locationsSnapshot.docs) {
        final locationData = locationDoc.data();
        final locationName = locationData['name'];
        final floor = locationData['floor'];
        
        if (locationName != null && floor != null) {
          final floorStr = floor.toString().trim();
          if (!floorToLocations.containsKey(floorStr)) {
            floorToLocations[floorStr] = {};
          }
          floorToLocations[floorStr]!.add(locationName);
        }
      }
    }

    // Now count devices by floor
    final devicesSnapshot = await firestore
        .collection('devices')
        .get();
    
    Map<String, int> floorCounts = {};
    
    for (var deviceDoc in devicesSnapshot.docs) {
      final deviceData = deviceDoc.data();
      final deviceLocation = deviceData['location'];
      
      if (deviceLocation != null) {
        // Find which floor this location belongs to
        for (var entry in floorToLocations.entries) {
          if (entry.value.contains(deviceLocation)) {
            final floorName = entry.key;
            floorCounts[floorName] = (floorCounts[floorName] ?? 0) + 1;
            break;
          }
        }
      }
    }

    return floorCounts;
  }

  Future<Map<String, int>> getPeripheralCountsByType() async {
    final departmentLocations = await getDepartmentLocations();
    
    if (departmentLocations.isEmpty) {
      return {};
    }

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
      final deviceLocation = data['location'];
      final peripheralType = data['peripheral_type'] as String?;
      
      // Only count if device is in department locations
      if (deviceLocation != null && departmentLocations.contains(deviceLocation)) {
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
    }

    return result;
  }

  // Generate dynamic colors
  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF81D4FA),
      const Color(0xFF28A745),
      const Color(0xFF007BFF),
      const Color(0xFFDC3545),
      const Color(0xFF6F42C1),
      const Color(0xFFFD7E14),
      const Color(0xFF20C997),
      const Color(0xFFE83E8C),
    ];
    return colors[index % colors.length];
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
              getDevicesByBrand(),
              getDevicesByFloor(),
              getPeripheralCountsByType(),
              getUserDepartment(),
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
              final brandCounts = snapshot.data![2] as Map<String, int>;
              final floorCounts = snapshot.data![3] as Map<String, int>;
              final peripheralTypeCounts = snapshot.data![4] as Map<String, int>;
              final userDepartment = snapshot.data![5] as String?;

              // Generate colors for brands
              final brandNames = brandCounts.keys.toList();
              final Map<String, Color> brandColorMap = {};
              for (int i = 0; i < brandNames.length; i++) {
                brandColorMap[brandNames[i]] = _getColorForIndex(i);
              }

              // Generate colors for floors
              final floorNames = floorCounts.keys.toList();
              final Map<String, Color> floorColorMap = {};
              for (int i = 0; i < floorNames.length; i++) {
                floorColorMap[floorNames[i]] = _getColorForIndex(i);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Title with Department
                  Container(
                    margin: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      children: [
                        const Text(
                          'Device Analytics Overview',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212529),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (userDepartment != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF81D4FA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Department: $userDepartment',
                              style: const TextStyle(
                                fontFamily: 'SansRegular',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF212529),
                              ),
                            ),
                          ),
                        ],
                      ],
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
                  
                  // Devices by Brand Chart
                  _buildPieChartSection(
                    title: 'Devices by Brand',
                    data: brandCounts,
                    colors: brandColorMap,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Devices by Floor Chart
                  _buildPieChartSection(
                    title: 'Devices by Floor',
                    data: floorCounts,
                    colors: floorColorMap,
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

          const SizedBox(height: 20),
          
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
          const SizedBox(height: 20),
          
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