import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class ChooseLocationPage extends StatefulWidget {
  const ChooseLocationPage({super.key});

  @override
  State<ChooseLocationPage> createState() => _ChooseLocationPageState();
}

class _ChooseLocationPageState extends State<ChooseLocationPage> {
  String _searchQuery = '';
  String _selectedBuilding = 'All';
  String _selectedFloor = 'All';
  String _selectedType = 'All';

  List<String> _buildings = ['All'];
  final List<String> _floors = ['All', 'Ground Floor', '1st Floor', '2nd Floor', '3rd Floor'];
  final List<String> _types = ['All', 'Lecture Room', 'Lab', 'Lecturer Office', 'Other'];

  bool _buildingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBuildingsFromFirestore();
  }

  Future<void> _loadBuildingsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('buildings').get();
      final List<String> buildingList = ['All'];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'];
        if (name != null && name.toString().trim().isNotEmpty) {
          buildingList.add(name.toString());
        }
      }
      
      buildingList.sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        return a.compareTo(b);
      });
      
      setState(() {
        _buildings = buildingList;
        _buildingsLoaded = true;
      });
    } catch (e) {
      print('Error loading buildings: $e');
      setState(() {
        _buildingsLoaded = true;
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _getAllLocationsStream() async* {
    final db = FirebaseFirestore.instance;
    
    try {
      final buildingsSnapshot = await db.collection('buildings').get();
      
      if (buildingsSnapshot.docs.isEmpty) {
        yield [];
        return;
      }
      
      List<Stream<QuerySnapshot>> locationStreams = [];
      
      for (var buildingDoc in buildingsSnapshot.docs) {
        locationStreams.add(
          buildingDoc.reference.collection('locations').snapshots()
        );
      }
      
      if (locationStreams.isEmpty) {
        yield [];
        return;
      }
      
      yield* CombineLatestStream.list(locationStreams).map((snapshots) {
        List<Map<String, dynamic>> allLocations = [];
        for (var snapshot in snapshots) {
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            allLocations.add({
              'id': doc.id,
              'buildingId': doc.reference.parent.parent!.id,
              'name': data['name'],
              'building': data['building'],
              'floor': data['floor'],
              'type': data['type'],
            });
          }
        }
        // Sort by name
        allLocations.sort((a, b) {
          final aName = (a['name'] ?? '').toString().toLowerCase();
          final bName = (b['name'] ?? '').toString().toLowerCase();
          return aName.compareTo(bName);
        });
        return allLocations;
      });
    } catch (e) {
      print('Error fetching locations: $e');
      yield [];
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
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: Color(0xFF212529),
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getAllLocationsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading locations',
                      style: TextStyle(
                        fontFamily: 'SansRegular',
                        color: Color(0xFF6C757D),
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

                final allLocations = snapshot.data ?? [];
                
                final filteredLocations = allLocations.where((location) {
                  final name = location['name']?.toString().toLowerCase() ?? '';
                  final building = location['building'] ?? '';
                  final floor = location['floor'] ?? '';
                  final type = location['type'] ?? '';

                  final matchesSearch = name.contains(_searchQuery.toLowerCase());
                  final matchesBuilding = _selectedBuilding == 'All' || building == _selectedBuilding;
                  final matchesFloor = _selectedFloor == 'All' || floor == _selectedFloor;
                  final matchesType = _selectedType == 'All' || type == _selectedType;

                  return matchesSearch && matchesBuilding && matchesFloor && matchesType;
                }).toList();

                if (filteredLocations.isEmpty) {
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
                          'No matching locations found',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            color: Color(0xFF6C757D),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = filteredLocations[index];
                    final locationName = location['name'] ?? 'Unnamed';
                    final building = location['building'] ?? 'Unknown';
                    final floor = location['floor'] ?? 'Unknown';
                    final type = location['type'] ?? 'Unknown';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF212529),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context, locationName),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC727).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _getLocationTypeIcon(type),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        locationName,
                                        style: const TextStyle(
                                          fontFamily: 'SansRegular',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFFFC727),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          _buildInfoChip(building),
                                          _buildInfoChip(floor),
                                          _buildInfoChip(type),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFFFFC727),
                                  size: 16,
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
          Container(
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
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search_outlined, color: Color(0xFF6C757D), size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                hintStyle: const TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF6C757D),
                  fontSize: 14,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildingsLoaded 
                  ? _buildFilterDropdown(
                      Icons.business_outlined,
                      'Building',
                      _selectedBuilding,
                      _buildings,
                      (val) => setState(() => _selectedBuilding = val!),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C757D)),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: Color(0xFF6C757D),
                              fontFamily: 'SansRegular',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterDropdown(
                  Icons.layers_outlined,
                  'Floor',
                  _selectedFloor,
                  _floors,
                  (val) => setState(() => _selectedFloor = val!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterDropdown(
                  Icons.category_outlined,
                  'Type',
                  _selectedType,
                  _types,
                  (val) => setState(() => _selectedType = val!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(IconData icon, String label, String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6C757D)),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: items.map((item) => DropdownMenuItem(
                value: item, 
                child: Text(
                  item == 'All' ? 'All' : item,
                  style: const TextStyle(
                    fontFamily: 'SansRegular',
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              )).toList(),
              underline: const SizedBox(),
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Color(0xFF212529),
                fontFamily: 'SansRegular',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC727).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'SansRegular',
          color: Color(0xFFFFC727),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Icon _getLocationTypeIcon(String type) {
    switch (type) {
      case 'Lecture Room':
        return const Icon(Icons.school_outlined, color: Color(0xFFFFC727), size: 20);
      case 'Lab':
        return const Icon(Icons.science_outlined, color: Color(0xFFFFC727), size: 20);
      case 'Lecturer Office':
        return const Icon(Icons.person_outline, color: Color(0xFFFFC727), size: 20);
      default:
        return const Icon(Icons.room_outlined, color: Color(0xFFFFC727), size: 20);
    }
  }
}