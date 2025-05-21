import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einventorycomputer/services/auth.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC727),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontFamily: 'PoetsenOne',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<int>>(
                  future: Future.wait([
                    getCountByType('PC'),               // 0
                    getOnlineCountByType('PC'),         // 1
                    getCountByType('Peripheral'),       // 2
                    getOnlineCountByType('Peripheral'), // 3
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final totalPC = snapshot.data![0];
                    final onlinePC = snapshot.data![1];
                    final offlinePC = totalPC - onlinePC;

                    final totalPeripheral = snapshot.data![2];
                    final onlinePeripheral = snapshot.data![3];
                    final offlinePeripheral = totalPeripheral - onlinePeripheral;

                    return ListView(
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
                      ],
                    );
                  },
                ),
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
                      fontFamily: 'PoetsenOne',
                      fontSize: 16, color: Colors.white),
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
                      fontFamily: 'PoetsenOne',
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

  Widget _buildStatusCount(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontFamily: 'PoetsenOne',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'PoetsenOne',
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
