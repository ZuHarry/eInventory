import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'modify_location.dart';

class LocationDetailsPage extends StatefulWidget {
  final String locationId;
  final String locationName;

  const LocationDetailsPage({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  State<LocationDetailsPage> createState() => _LocationDetailsPageState();
}

class _LocationDetailsPageState extends State<LocationDetailsPage> {
  Map<String, dynamic>? locationData;
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    _fetchLocationDetails();
  }

  Future<void> _fetchLocationDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.locationId)
        .get();
    if (doc.exists) {
      setState(() {
        locationData = doc.data();
      });
    }
  }

  void _navigateToEdit() {
    if (locationData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModifyLocationPage(
            locationId: widget.locationId,
            currentName: locationData!['name'],
            locationData: locationData!,
          ),
        ),
      ).then((_) => _fetchLocationDetails());
    }
  }

  Icon _getDeviceIcon(String? type) {
    if (type == 'PC') return const Icon(Icons.computer, color: Colors.black);
    if (type == 'Peripheral') return const Icon(Icons.devices_other, color: Colors.black);
    return const Icon(Icons.device_unknown, color: Colors.black);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC727),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC727),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Location Details',
          style: TextStyle(
            fontFamily: 'PoetsenOne',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: locationData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationData!['name'],
                              style: const TextStyle(
                                  fontSize: 20, fontFamily: 'PoetsenOne'),
                            ),
                          ),
                          const Icon(Icons.business),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationData!['building'],
                              style: const TextStyle(
                                  fontSize: 20, fontFamily: 'PoetsenOne'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.layers),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationData!['floor'],
                              style: const TextStyle(
                                  fontSize: 20, fontFamily: 'PoetsenOne'),
                            ),
                          ),
                          const Icon(Icons.category),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationData!['type'],
                              style: const TextStyle(
                                  fontSize: 20, fontFamily: 'PoetsenOne'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Devices in this Location',
                      style: TextStyle(
                        fontFamily: 'PoetsenOne',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Type filter dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Text('Type:', style: TextStyle(fontFamily: 'PoetsenOne')),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedType,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                            color: Colors.black, fontFamily: 'PoetsenOne'),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'PC', child: Text('PC')),
                          DropdownMenuItem(value: 'Peripheral', child: Text('Peripheral')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('devices')
                        .where('location', isEqualTo: locationData!['name'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading devices'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final devices = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id;
                        return data;
                      }).where((data) {
                        final type = data['type'] ?? 'Unknown';
                        if (_selectedType != 'All' && type != _selectedType) return false;
                        return true;
                      }).toList();

                      if (devices.isEmpty) {
                        return const Center(
                            child: Text('No devices found in this location'));
                      }

                      return ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: _getDeviceIcon(device['type']),
                              title: Text(
                                device['name'] ?? 'Unnamed Device',
                                style: const TextStyle(
                                    fontFamily: 'PoetsenOne',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type: ${device['type'] ?? 'Unknown'}',
                                    style: const TextStyle(fontFamily: 'PoetsenOne'),
                                  ),
                                  Text(
                                    'IP: ${device['ip'] ?? 'N/A'}',
                                    style: const TextStyle(fontFamily: 'PoetsenOne'),
                                  ),
                                  Text(
                                    'MAC: ${device['mac'] ?? 'N/A'}',
                                    style: const TextStyle(fontFamily: 'PoetsenOne'),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                          device['status'] ?? '')
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (device['status'] ?? 'N/A')
                                      .toString()
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(
                                        device['status'] ?? ''),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'PoetsenOne',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Edit Location',
                        style: TextStyle(
                          color: Color(0xFFFFC727),
                          fontSize: 16,
                          fontFamily: 'PoetsenOne',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
