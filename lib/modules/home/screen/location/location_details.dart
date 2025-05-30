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
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem('Location Name', locationData!['name']),
                        _buildDetailItem('Building', locationData!['building']),
                        _buildDetailItem('Floor', locationData!['floor']),
                        _buildDetailItem('Type', locationData!['type']),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
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
                Expanded(
                  flex: 3,
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

                      final devices = snapshot.data!.docs;

                      if (devices.isEmpty) {
                        return const Center(child: Text('No devices found in this location'));
                      }

                      return ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                device['name'] ?? 'Unnamed Device',
                                style: const TextStyle(fontFamily: 'PoetsenOne', fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${device['type'] ?? 'Type Unknown'} - IP: ${device['ip'] ?? 'N/A'}',
                                style: const TextStyle(fontFamily: 'PoetsenOne'),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'PoetsenOne',
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontFamily: 'PoetsenOne'),
            ),
          ),
        ],
      ),
    );
  }
}
