import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'modify_location.dart';
// ...imports remain unchanged

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
    if (type == 'Peripheral') {
      return const Icon(Icons.devices_other, color: Colors.black);
    }
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

  Widget _buildGridItem(String label, IconData icon, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF212529),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Color(0xFFFFC727)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'SansRegular',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFC727),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'SansRegular',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Location Details',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: locationData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (locationData!['imageUrl'] != null)
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(locationData!['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _buildGridItem('Location', Icons.location_on, locationData!['name']),
                        _buildGridItem('Building', Icons.apartment, locationData!['building']),
                        _buildGridItem('Floor', Icons.stairs, locationData!['floor']),
                        _buildGridItem('Type', Icons.category, locationData!['type']),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Devices in this Location',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedType,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black, fontFamily: 'SansRegular'),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(value: 'PC', child: Text('PC')),
                            DropdownMenuItem(value: 'Peripheral', child: Text('Peripheral')),
                          ],
                          onChanged: (value) => setState(() => _selectedType = value!),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('devices')
                        .where('location', isEqualTo: locationData!['name'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('Error loading devices')),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final devices = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id;
                        return data;
                      }).where((device) {
                        if (_selectedType != 'All' && device['type'] != _selectedType) {
                          return false;
                        }
                        return true;
                      }).toList();

                      if (devices.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('No devices found in this location')),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              leading: _getDeviceIcon(device['type']),
                              title: Text(
                                device['name'] ?? 'Unnamed Device',
                                style: const TextStyle(
                                  fontFamily: 'SansRegular',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: ${device['type'] ?? 'Unknown'}', style: const TextStyle(fontFamily: 'SansRegular')),
                                  Text('IP: ${device['ip'] ?? 'N/A'}', style: const TextStyle(fontFamily: 'SansRegular')),
                                  Text('MAC: ${device['mac'] ?? 'N/A'}', style: const TextStyle(fontFamily: 'SansRegular')),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(device['status'] ?? '').withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (device['status'] ?? 'N/A').toString().toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(device['status'] ?? ''),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SansRegular',
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
                            fontFamily: 'SansRegular',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
