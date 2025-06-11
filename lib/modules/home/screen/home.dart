import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einventorycomputer/services/auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

    final locationsSnapshot = await firestore.collection('locations').get();
    final Map<String, String> locationToBuilding = {};
    for (var doc in locationsSnapshot.docs) {
      final data = doc.data();
      final locationName = data['name'];
      final building = data['building'];
      if (locationName != null && building != null) {
        locationToBuilding[locationName] = building;
      }
    }

    Map<String, Map<String, int>> result = {
      'Right Wing': {'pc': 0, 'peripherals': 0},
      'Left Wing': {'pc': 0, 'peripherals': 0},
    };

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final totalPC = snapshot.data![0] as int;
                  final onlinePC = snapshot.data![1] as int;
                  final totalPeripheral = snapshot.data![2] as int;
                  final onlinePeripheral = snapshot.data![3] as int;
                  final offlinePC = totalPC - onlinePC;
                  final offlinePeripheral = totalPeripheral - onlinePeripheral;
                  final buildingCounts =
                      snapshot.data![4] as Map<String, Map<String, int>>;

                  return Column(
                    children: [
                      _buildDeviceCard(
                        label: "PCs",
                        icon: Icons.computer,
                        total: totalPC,
                        online: onlinePC,
                        offline: offlinePC,
                      ),
                      const SizedBox(height: 16),
                      _buildDeviceCard(
                        label: "Peripherals",
                        icon: Icons.devices_other,
                        total: totalPeripheral,
                        online: onlinePeripheral,
                        offline: offlinePeripheral,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Devices by Building',
                        style: TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBuildingSummary(
                          "Right Wing", buildingCounts["Right Wing"]!),
                      _buildBuildingSummary(
                          "Left Wing", buildingCounts["Left Wing"]!),
                      const SizedBox(height: 24),
                      const Text(
                        'Online vs Offline Devices',
                        style: TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: Color(0xFFFFC727),
                          height: 300,
                          padding: const EdgeInsets.all(16),
                          child: BarChart(
                            BarChartData(
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, _) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text(
                                            'PC',
                                            style: TextStyle(
                                              fontFamily: 'SansRegular',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          );
                                        case 1:
                                          return const Text(
                                            'Peripheral',
                                            style: TextStyle(
                                              fontFamily: 'SansRegular',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          );
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
                                      style: const TextStyle(
                                        fontFamily: 'SansRegular',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [
                                  BarChartRodData(
                                    toY: onlinePC.toDouble(),
                                    color: Colors.yellow,
                                    width: 18,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  BarChartRodData(
                                    toY: offlinePC.toDouble(),
                                    color: Colors.black,
                                    width: 18,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ]),
                                BarChartGroupData(x: 1, barRods: [
                                  BarChartRodData(
                                    toY: onlinePeripheral.toDouble(),
                                    color: Colors.yellow,
                                    width: 18,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  BarChartRodData(
                                    toY: offlinePeripheral.toDouble(),
                                    color: Colors.black,
                                    width: 18,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ]),
                              ],
                              barTouchData: BarTouchData(enabled: false),
                              maxY: [
                                onlinePC,
                                offlinePC,
                                onlinePeripheral,
                                offlinePeripheral
                              ].reduce((a, b) => a > b ? a : b).toDouble() +
                                  5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await _auth.signOut();
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard({
    required String label,
    required IconData icon,
    required int total,
    required int online,
    required int offline,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Color(0xFFFFC727),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFFFC727),
              child: Icon(icon, size: 32, color: Colors.black),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusCount("Total", total),
                      _buildStatusCount("Online", online),
                      _buildStatusCount("Offline", offline),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingSummary(String building, Map<String, int> counts) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Color(0xFFFFC727),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              building,
              style: const TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCount("PC", counts["pc"] ?? 0),
                _buildStatusCount("Peripherals", counts["peripherals"] ?? 0),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCount(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
