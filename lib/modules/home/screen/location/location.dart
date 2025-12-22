import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_location.dart';
import 'location_details.dart';
import 'location_overview.dart';
import 'package:rxdart/rxdart.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String _searchQuery = '';
  String _selectedFloor = 'All';
  String _selectedType = 'All';
  String _selectedSort = 'Total Devices (High-Low)';
  
  String? _userDepartment;
  String? _userBuildingId;
  bool _isLoadingUserData = true;

  final List<String> _floors = ['All', 'Ground Floor', '1st Floor', '2nd Floor', '3rd Floor'];
  final List<String> _types = ['All', 'Lecture Room', 'Lab', 'Lecturer Office', 'Other'];
  final List<String> _sortOptions = [
    'Total Devices (High-Low)',
    'PC Count (High-Low)',
    'Peripheral Count (High-Low)',
    'Name (A-Z)',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserDepartment();
  }

  Future<void> _loadUserDepartment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          final department = userData?['department'] as String?;
          
          if (department != null && department.isNotEmpty) {
            // Find the building that matches the user's department
            final buildingsSnapshot = await FirebaseFirestore.instance
                .collection('buildings')
                .where('name', isEqualTo: department)
                .get();
            
            if (buildingsSnapshot.docs.isNotEmpty) {
              setState(() {
                _userDepartment = department;
                _userBuildingId = buildingsSnapshot.docs.first.id;
                _isLoadingUserData = false;
              });
            } else {
              setState(() {
                _isLoadingUserData = false;
              });
            }
          } else {
            setState(() {
              _isLoadingUserData = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user department: $e');
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Stream<List<QueryDocumentSnapshot>> _getDepartmentLocationsStream() async* {
    if (_userBuildingId == null) {
      yield [];
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      
      yield* db
          .collection('buildings')
          .doc(_userBuildingId)
          .collection('locations')
          .snapshots()
          .map((snapshot) => snapshot.docs);
    } catch (e) {
      print('Error fetching locations: $e');
      yield [];
    }
  }

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

  List<QueryDocumentSnapshot> _sortLocations(List<QueryDocumentSnapshot> docs, Map<String, Map<String, int>> deviceCounts) {
    List<QueryDocumentSnapshot> sortedDocs = List.from(docs);

    switch (_selectedSort) {
      case 'Total Devices (High-Low)':
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aName = aData['name'] ?? 'Unknown';
          final bName = bData['name'] ?? 'Unknown';
          
          final aTotalDevices = (deviceCounts[aName]?['PC'] ?? 0) + (deviceCounts[aName]?['Peripheral'] ?? 0);
          final bTotalDevices = (deviceCounts[bName]?['PC'] ?? 0) + (deviceCounts[bName]?['Peripheral'] ?? 0);
          
          return bTotalDevices.compareTo(aTotalDevices);
        });
        break;
      case 'PC Count (High-Low)':
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aName = aData['name'] ?? 'Unknown';
          final bName = bData['name'] ?? 'Unknown';
          
          final aPcCount = deviceCounts[aName]?['PC'] ?? 0;
          final bPcCount = deviceCounts[bName]?['PC'] ?? 0;
          
          return bPcCount.compareTo(aPcCount);
        });
        break;
      case 'Peripheral Count (High-Low)':
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aName = aData['name'] ?? 'Unknown';
          final bName = bData['name'] ?? 'Unknown';
          
          final aPeripheralCount = deviceCounts[aName]?['Peripheral'] ?? 0;
          final bPeripheralCount = deviceCounts[bName]?['Peripheral'] ?? 0;
          
          return bPeripheralCount.compareTo(aPeripheralCount);
        });
        break;
      case 'Name (A-Z)':
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aName = aData['name'] ?? 'Unknown';
          final bName = bData['name'] ?? 'Unknown';
          
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
        break;
    }

    return sortedDocs;
  }

  Icon _getLocationTypeIcon(String type) {
    switch (type) {
      case 'Lecture Room':
        return const Icon(Icons.school_outlined, color: Color(0xFF81D4FA), size: 20);
      case 'Lab':
        return const Icon(Icons.science_outlined, color: Color(0xFF81D4FA), size: 20);
      case 'Lecturer Office':
        return const Icon(Icons.person_outline, color: Color(0xFF81D4FA), size: 20);
      default:
        return const Icon(Icons.room_outlined, color: Color(0xFF81D4FA), size: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81D4FA)),
          ),
        ),
      );
    }

    if (_userDepartment == null || _userBuildingId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No Department Assigned',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF212529),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please contact your administrator',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF6C757D),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF212529)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(190),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
            child: Column(
              children: [
                // Department Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF81D4FA).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        color: Color(0xFF81D4FA),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _userDepartment!,
                        style: const TextStyle(
                          fontFamily: 'SansRegular',
                          color: Color(0xFF81D4FA),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Search Bar
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
                    decoration: InputDecoration(
                      hintText: 'Search locations...',
                      prefixIcon: const Icon(Icons.search_outlined, color: Color(0xFF6C757D), size: 20),
                      hintStyle: const TextStyle(
                        fontFamily: 'SansRegular',
                        color: Color(0xFF6C757D),
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 14,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
                  ),
                ),
                const SizedBox(height: 10),
                // Filters (Floor and Type only)
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        Icons.layers_outlined,
                        'Floor',
                        _selectedFloor,
                        _floors,
                        (value) => setState(() => _selectedFloor = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        Icons.category_outlined,
                        'Type',
                        _selectedType,
                        _types,
                        (value) => setState(() => _selectedType = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterDropdown(
                        Icons.sort_outlined,
                        'Sort',
                        _selectedSort,
                        _sortOptions,
                        (value) => setState(() => _selectedSort = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LocationsOverviewPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF81D4FA),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              color: Color(0xFF212529),
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Overview',
                              style: TextStyle(
                                color: Color(0xFF212529),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SansRegular',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddLocationPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF212529),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_location_outlined,
                              color: Color(0xFF81D4FA),
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Add Location',
                              style: TextStyle(
                                color: Color(0xFF81D4FA),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SansRegular',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _getDepartmentLocationsStream(),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81D4FA)),
                    ),
                  );
                }

                final allDocs = snapshot.data ?? [];
                
                allDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aName = (aData['name'] ?? '').toString().toLowerCase();
                  final bName = (bData['name'] ?? '').toString().toLowerCase();
                  return aName.compareTo(bName);
                });

                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final floor = data['floor'] ?? '';
                  final type = data['type'] ?? '';

                  final matchesSearch = name.contains(_searchQuery.toLowerCase());
                  final matchesFloor = _selectedFloor == 'All' || floor == _selectedFloor;
                  final matchesType = _selectedType == 'All' || type == _selectedType;

                  return matchesSearch && matchesFloor && matchesType;
                }).toList();

                if (filteredDocs.isEmpty) {
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
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81D4FA)),
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
                    final sortedDocs = _sortLocations(filteredDocs, deviceCounts);

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedDocs.length,
                      itemBuilder: (context, index) {
                        final data = sortedDocs[index].data() as Map<String, dynamic>;
                        final locationName = data['name'] ?? 'Unknown';
                        final floor = data['floor'] ?? '';
                        final type = data['type'] ?? '';

                        final pcCount = deviceCounts[locationName]?['PC'] ?? 0;
                        final peripheralCount = deviceCounts[locationName]?['Peripheral'] ?? 0;
                        final totalDevices = pcCount + peripheralCount;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF212529),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LocationDetailsPage(
                                      buildingId: _userBuildingId!,
                                      locationId: sortedDocs[index].id,
                                      locationName: locationName,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF81D4FA).withOpacity(0.1),
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
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Color(0xFF81D4FA),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              _buildInfoChip(floor),
                                              _buildInfoChip(type),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'PCs: $pcCount • Peripherals: $peripheralCount',
                                            style: const TextStyle(
                                              fontFamily: 'SansRegular',
                                              color: Color(0xFFADB5BD),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF81D4FA).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$totalDevices',
                                            style: const TextStyle(
                                              fontFamily: 'SansRegular',
                                              color: Color(0xFF81D4FA),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Text(
                                            'Devices',
                                            style: TextStyle(
                                              fontFamily: 'SansRegular',
                                              color: Color(0xFF81D4FA),
                                              fontSize: 9,
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
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              isExpanded: true,
              style: const TextStyle(
                color: Color(0xFF212529),
                fontFamily: 'SansRegular',
                fontSize: 12,
              ),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item == 'All' ? 'All' : item,
                  overflow: TextOverflow.ellipsis,
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF81D4FA).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'SansRegular',
          color: Color(0xFF81D4FA),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}