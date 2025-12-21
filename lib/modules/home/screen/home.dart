import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einventorycomputer/services/auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:einventorycomputer/services/pdf_export_service.dart';
import 'package:einventorycomputer/modules/home/screen/analytics/pie_chart.dart';

class HomePage extends StatelessWidget {
  final AuthService _auth = AuthService();

  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

  Future<int> getCountByType(String type) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('devices')
        .where('type', isEqualTo: type)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> getOnlineCountByType(String type) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('devices')
        .where('type', isEqualTo: type)
        .where('status', isEqualTo: 'Online')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<Map<String, Map<String, int>>> getDeviceCountsByBuilding() async {
    final firestore = FirebaseFirestore.instance;

    // Get all locations and their buildings
    final locationsSnapshot = await firestore.collection('locations').get();
    final Map<String, String> locationToBuilding = {};
    final Set<String> allBuildings = {};
    
    for (var doc in locationsSnapshot.docs) {
      final data = doc.data();
      final locationName = data['name'];
      final building = data['building'];
      if (locationName != null && building != null) {
        locationToBuilding[locationName] = building;
        allBuildings.add(building);
      }
    }

    // Initialize result map with all buildings found in Firestore
    Map<String, Map<String, int>> result = {};
    for (String building in allBuildings) {
      result[building] = {'pc': 0, 'peripherals': 0};
    }

    // Count devices by building
    final devicesSnapshot = await firestore.collection('devices').get();
    for (var doc in devicesSnapshot.docs) {
      final data = doc.data();
      final locationName = data['location'];
      final type = (data['type'] as String?)?.toLowerCase();

      if (locationName != null &&
          locationToBuilding.containsKey(locationName) &&
          (type == 'pc' || type == 'peripheral' || type == 'peripherals')) {
        final building = locationToBuilding[locationName]!;
        if (result.containsKey(building)) {
          if (type == 'pc') {
            result[building]!['pc'] = result[building]!['pc']! + 1;
          } else {
            result[building]!['peripherals'] =
                result[building]!['peripherals']! + 1;
          }
        }
      }
    }

    return result;
  }

  Future<void> _exportToPDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81D4FA)),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Generating PDF...',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      },
    );

    try {
      await PDFExportService.exportDashboardToPDF();
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generated successfully!', style: TextStyle(fontSize: 13)),
          backgroundColor: Color(0xFF81D4FA),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: const TextStyle(fontSize: 13)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF81D4FA),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _exportToPDF(context),
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            iconSize: 20,
            color: const Color(0xFF81D4FA),
            tooltip: 'Export PDF',
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  getCountByType('PC'),
                  getOnlineCountByType('PC'),
                  getCountByType('Peripheral'),
                  getOnlineCountByType('Peripheral'),
                  getDeviceCountsByBuilding(),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81D4FA)),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6C757D)),
                      ),
                    );
                  }

                  final totalPC = snapshot.data![0] as int;
                  final onlinePC = snapshot.data![1] as int;
                  final totalPeripheral = snapshot.data![2] as int;
                  final onlinePeripheral = snapshot.data![3] as int;
                  final offlinePC = totalPC - onlinePC;
                  final offlinePeripheral = totalPeripheral - onlinePeripheral;
                  final buildingCounts = snapshot.data![4] as Map<String, Map<String, int>>;

                  return Column(
                    children: [
                      // Device Distribution Chart
                      _buildSection(
                        title: 'Device Distribution',
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailedPieChartPage(),
                              ),
                            );
                          },
                          child: Container(
                            height: 200,
                            child: totalPC + totalPeripheral > 0
                                ? Stack(
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          sections: [
                                            PieChartSectionData(
                                              value: totalPC.toDouble(),
                                              title: '${((totalPC / (totalPC + totalPeripheral)) * 100).toStringAsFixed(0)}%',
                                              color: const Color(0xFF81D4FA),
                                              radius: 60,
                                              titleStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF212529),
                                              ),
                                            ),
                                            PieChartSectionData(
                                              value: totalPeripheral.toDouble(),
                                              title: '${((totalPeripheral / (totalPC + totalPeripheral)) * 100).toStringAsFixed(0)}%',
                                              color: Colors.grey[600]!,
                                              radius: 60,
                                              titleStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                          sectionsSpace: 1,
                                          centerSpaceRadius: 30,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF81D4FA),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Tap for details',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF212529),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Center(
                                    child: Text(
                                      'No devices found',
                                      style: TextStyle(fontSize: 13, color: Color(0xFF81D4FA)),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      
                      // Legend
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(color: const Color(0xFF81D4FA), label: "PCs ($totalPC)"),
                            const SizedBox(width: 20),
                            _buildLegendItem(color: Colors.grey[600]!, label: "Peripherals ($totalPeripheral)"),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Device Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactDeviceCard(
                              label: "PCs",
                              icon: Icons.computer,
                              total: totalPC,
                              online: onlinePC,
                              offline: offlinePC,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactDeviceCard(
                              label: "Peripherals",
                              icon: Icons.devices_other,
                              total: totalPeripheral,
                              online: onlinePeripheral,
                              offline: offlinePeripheral,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Building Summary - Now dynamically displays all buildings
                      _buildSection(
                        title: 'By Building',
                        child: buildingCounts.isEmpty 
                          ? const Center(
                              child: Text(
                                'No buildings found',
                                style: TextStyle(fontSize: 13, color: Color(0xFF81D4FA)),
                              ),
                            )
                          : Column(
                              children: buildingCounts.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildCompactBuildingSummary(entry.key, entry.value),
                                );
                              }).toList(),
                            ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Status Chart
                      _buildSection(
                        title: 'Online vs Offline',
                        child: SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, _) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('PC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF81D4FA)));
                                        case 1:
                                          return const Text('Peripheral', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF81D4FA)));
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, _) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF81D4FA)),
                                    ),
                                  ),
                                ),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [
                                  BarChartRodData(toY: onlinePC.toDouble(), color: const Color(0xFF81D4FA), width: 14),
                                  BarChartRodData(toY: offlinePC.toDouble(), color: Colors.grey[600], width: 14),
                                ]),
                                BarChartGroupData(x: 1, barRods: [
                                  BarChartRodData(toY: onlinePeripheral.toDouble(), color: const Color(0xFF81D4FA), width: 14),
                                  BarChartRodData(toY: offlinePeripheral.toDouble(), color: Colors.grey[600], width: 14),
                                ]),
                              ],
                              barTouchData: BarTouchData(enabled: false),
                              maxY: [onlinePC, offlinePC, onlinePeripheral, offlinePeripheral].reduce((a, b) => a > b ? a : b).toDouble() + 3,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF81D4FA),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                              ),
                              onPressed: () => _exportToPDF(context),
                              icon: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF212529)),
                              label: const Text(
                                'Export PDF',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF212529)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF212529),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                              ),
                              onPressed: () async => await _auth.signOut(),
                              child: const Text(
                                'Log Out',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF81D4FA)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212529),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF212529),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF81D4FA),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDeviceCard({
    required String label,
    required IconData icon,
    required int total,
    required int online,
    required int offline,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF212529),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF81D4FA)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF81D4FA),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactStatusCount("Total", total),
              _buildCompactStatusCount("Online", online),
              _buildCompactStatusCount("Offline", offline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBuildingSummary(String building, Map<String, int> counts) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF212529),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              building,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF81D4FA),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              _buildCompactStatusCount("PC", counts["pc"] ?? 0),
              const SizedBox(width: 16),
              _buildCompactStatusCount("Peripherals", counts["peripherals"] ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusCount(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF81D4FA),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF81D4FA),
          ),
        ),
      ],
    );
  }
}