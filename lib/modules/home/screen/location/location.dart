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

  Icon _getLocationTypeIcon(String type) {
    switch (type) {
      case 'Lecture Room':
        return const Icon(Icons.school_outlined, color: Color(0xFFFFC727), size: 28);
      case 'Lab':
        return const Icon(Icons.science_outlined, color: Color(0xFFFFC727), size: 28);
      case 'Lecturer Office':
        return const Icon(Icons.person_outline, color: Color(0xFFFFC727), size: 28);
      default:
        return const Icon(Icons.room_outlined, color: Color(0xFFFFC727), size: 28);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF212529)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search locations...',
                      prefixIcon: const Icon(Icons.search_outlined, color: Color(0xFF6C757D)),
                      hintStyle: const TextStyle(
                        fontFamily: 'SansRegular',
                        color: Color(0xFF6C757D),
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 16,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
                  ),
                ),
                const SizedBox(height: 16),
                // Filters Row 1
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        Icons.business_outlined,
                        'Building',
                        _selectedBuilding,
                        _buildings,
                        (value) => setState(() => _selectedBuilding = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDropdown(
                        Icons.layers_outlined,
                        'Floor',
                        _selectedFloor,
                        _floors,
                        (value) => setState(() => _selectedFloor = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filters Row 2
                _buildFilterDropdown(
                  Icons.category_outlined,
                  'Type',
                  _selectedType,
                  _types,
                  (value) => setState(() => _selectedType = value!),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('locations')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading locations',
                      style: TextStyle(
                        fontFamily: 'SansRegular',
                        color: Color(0xFF6C757D),
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC727)),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final building = data['building'] ?? '';
                  final floor = data['floor'] ?? '';
                  final type = data['type'] ?? '';

                  final matchesSearch = name.contains(_searchQuery.toLowerCase());
                  final matchesBuilding = _selectedBuilding == 'All' || building == _selectedBuilding;
                  final matchesFloor = _selectedFloor == 'All' || floor == _selectedFloor;
                  final matchesType = _selectedType == 'All' || type == _selectedType;

                  return matchesSearch && matchesBuilding && matchesFloor && matchesType;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No locations found',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            color: Color(0xFF6C757D),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<Map<String, Map<String, int>>>(
                  future: _fetchDeviceCounts(),
                  builder: (context, countSnapshot) {
                    if (countSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC727)),
                        ),
                      );
                    }
                    if (!countSnapshot.hasData) {
                      return const Center(
                        child: Text(
                          'Failed to load device counts',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            color: Color(0xFF6C757D),
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    final deviceCounts = countSnapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final locationName = data['name'] ?? 'Unknown';
                        final building = data['building'] ?? '';
                        final floor = data['floor'] ?? '';
                        final type = data['type'] ?? '';

                        final pcCount = deviceCounts[locationName]?['PC'] ?? 0;
                        final peripheralCount = deviceCounts[locationName]?['Peripheral'] ?? 0;
                        final totalDevices = pcCount + peripheralCount;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF212529),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
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
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFC727).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: _getLocationTypeIcon(type),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            locationName,
                                            style: const TextStyle(
                                              fontFamily: 'SansRegular',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                              color: Color(0xFFFFC727),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Building and Floor on first row
                                          Row(
                                            children: [
                                              _buildInfoChip(building),
                                              const SizedBox(width: 8),
                                              _buildInfoChip(floor),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Type on second row to prevent overflow
                                          Row(
                                            children: [
                                              _buildInfoChip(type),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'PCs: $pcCount • Peripherals: $peripheralCount',
                                            style: const TextStyle(
                                              fontFamily: 'SansRegular',
                                              color: Color(0xFFADB5BD),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFC727).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$totalDevices',
                                            style: const TextStyle(
                                              fontFamily: 'SansRegular',
                                              color: Color(0xFFFFC727),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Text(
                                            'Devices',
                                            style: TextStyle(
                                              fontFamily: 'SansRegular',
                                              color: Color(0xFFFFC727),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
          // Add Location Button
          Padding(
            padding: const EdgeInsets.all(20),
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
                  backgroundColor: const Color(0xFF212529),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add Location',
                  style: TextStyle(
                    color: Color(0xFFFFC727),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SansRegular',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(IconData icon, String label, String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6C757D)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              isExpanded: true,
              style: const TextStyle(
                color: Color(0xFF212529),
                fontFamily: 'SansRegular',
                fontSize: 14,
              ),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item == 'All' ? 'All ${label}s' : item),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC727).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'SansRegular',
          color: Color(0xFFFFC727),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}