import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_location.dart';
import 'location_details.dart'; // Import the details page

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String _searchQuery = '';
  String _selectedBuilding = 'All';
  String _selectedFloor = 'All';
  String _selectedType = 'All';

  final List<String> _buildings = ['All', 'Right Wing', 'Left Wing'];
  final List<String> _floors = ['All', 'Ground', '1st Floor', '2nd Floor', '3rd Floor'];
  final List<String> _types = ['All', 'Lecture Room', 'Lab', 'Lecturer Office', 'Other'];

  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

  Future<Map<String, Map<String, int>>> _fetchDeviceCounts() async {
    final snapshot = await FirebaseFirestore.instance.collection('devices').get();
    final Map<String, Map<String, int>> locationCounts = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final location = data['location'] ?? 'Unknown';
      final type = data['type'] ?? 'Unknown';

      locationCounts.putIfAbsent(location, () => {'PC': 0, 'Peripheral': 0});

      if (type == 'PC') {
        locationCounts[location]!['PC'] = locationCounts[location]!['PC']! + 1;
      } else if (type == 'Peripheral') {
        locationCounts[location]!['Peripheral'] = locationCounts[location]!['Peripheral']! + 1;
      }
    }

    return locationCounts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex('FFC727'),
      appBar: AppBar(
        backgroundColor: hex('FFC727'),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Locations',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'PoetsenOne',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('locations')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading locations'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs.where((doc) {
                  final name = doc['name']?.toString().toLowerCase() ?? '';
                  final building = doc['building'] ?? '';
                  final floor = doc['floor'] ?? '';
                  final type = doc['type'] ?? '';

                  final matchesSearch = name.contains(_searchQuery.toLowerCase());
                  final matchesBuilding = _selectedBuilding == 'All' || building == _selectedBuilding;
                  final matchesFloor = _selectedFloor == 'All' || floor == _selectedFloor;
                  final matchesType = _selectedType == 'All' || type == _selectedType;

                  return matchesSearch && matchesBuilding && matchesFloor && matchesType;
                }).toList();

                if (docs.isEmpty) return const Center(child: Text('No locations found'));

                return FutureBuilder<Map<String, Map<String, int>>>(
                  future: _fetchDeviceCounts(),
                  builder: (context, countSnapshot) {
                    if (!countSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final deviceCounts = countSnapshot.data!;

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final locationName = data['name'] ?? 'Unknown';
                        final building = data['building'] ?? '';
                        final floor = data['floor'] ?? '';
                        final type = data['type'] ?? '';

                        final pcCount = deviceCounts[locationName]?['PC'] ?? 0;
                        final peripheralCount = deviceCounts[locationName]?['Peripheral'] ?? 0;

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LocationDetailsPage(
                                    locationId: docs[index].id,
                                    locationName: locationName,
                                  ),
                                ),
                              );
                            },
                            title: Text(
                              locationName,
                              style: const TextStyle(fontFamily: 'PoetsenOne', fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$building - $floor - $type', style: const TextStyle(fontFamily: 'PoetsenOne')),
                                const SizedBox(height: 4),
                                Text(
                                  'Total PCs: $pcCount | Peripherals: $peripheralCount',
                                  style: const TextStyle(fontFamily: 'PoetsenOne'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddLocationPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Location',
                  style: TextStyle(
                    color: Color(0xFFFFC727),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              hintText: 'Search by name...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildDropdown('Building', _selectedBuilding, _buildings, (val) => setState(() => _selectedBuilding = val!))),
              const SizedBox(width: 8),
              Expanded(child: _buildDropdown('Floor', _selectedFloor, _floors, (val) => setState(() => _selectedFloor = val!))),
              const SizedBox(width: 8),
              Expanded(child: _buildDropdown('Type', _selectedType, _types, (val) => setState(() => _selectedType = val!))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
