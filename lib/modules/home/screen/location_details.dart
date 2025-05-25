import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LocationDetailsPage extends StatelessWidget {
  final String locationId;
  final String locationName;

  const LocationDetailsPage({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex('FFC727'),
      appBar: AppBar(
        backgroundColor: hex('FFC727'),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        title: const Text(
          'Location Details',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'PoetsenOne',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('locations').doc(locationId).get(),
        builder: (context, locationSnapshot) {
          if (locationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!locationSnapshot.hasData || !locationSnapshot.data!.exists) {
            return const Center(child: Text('Location not found'));
          }

          final locationData = locationSnapshot.data!.data() as Map<String, dynamic>;
          final building = locationData['building'] ?? 'N/A';
          final floor = locationData['floor'] ?? 'N/A';
          final type = locationData['type'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard('Name', locationName),
                _buildInfoCard('Building', building),
                _buildInfoCard('Floor', floor),
                _buildInfoCard('Type', type),
                const SizedBox(height: 16),
                const Text(
                  'Devices in this Location:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PoetsenOne',
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('devices')
                        .where('location', isEqualTo: locationName)
                        .snapshots(),
                    builder: (context, deviceSnapshot) {
                      if (deviceSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final devices = deviceSnapshot.data?.docs ?? [];

                      if (devices.isEmpty) {
                        return const Text('No devices found.');
                      }

                      return ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final data = devices[index].data() as Map<String, dynamic>;
                          final deviceName = data['name'] ?? 'Unnamed Device';
                          final type = data['type'] ?? 'Unknown';
                          final ip = data['ip'] ?? 'N/A';

                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(
                                deviceName,
                                style: const TextStyle(
                                  fontFamily: 'PoetsenOne',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Type: $type | IP: $ip',
                                style: const TextStyle(fontFamily: 'PoetsenOne'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFC727),
            fontWeight: FontWeight.bold,
            fontFamily: 'PoetsenOne',
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'PoetsenOne',
          ),
        ),
      ),
    );
  }
}
