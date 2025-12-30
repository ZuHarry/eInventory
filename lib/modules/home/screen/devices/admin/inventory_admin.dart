import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:einventorycomputer/modules/home/screen/devices/device_details.dart';

class InventoryAdminPage extends StatefulWidget {
  const InventoryAdminPage({super.key});

  @override
  _InventoryAdminPageState createState() => _InventoryAdminPageState();
}

class _InventoryAdminPageState extends State<InventoryAdminPage> {
  String _searchQuery = '';
  String _selectedType = 'All';
  String _selectedFloor = 'All';
  String _selectedBuilding = 'All';
  String _selectedStatus = 'All';
  List<String> _buildingOptions = ['All'];
  bool _isBuildingDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBuildingOptions();
  }

  // Load building names from Firestore
  Future<void> _loadBuildingOptions() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('buildings').get();
      final buildingNames = <String>['All'];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'];
        if (name != null && name.toString().isNotEmpty) {
          buildingNames.add(name.toString());
        }
      }
      
      setState(() {
        _buildingOptions = buildingNames;
        _isBuildingDataLoaded = true;
      });
    } catch (e) {
      print('Error loading building options: $e');
      setState(() {
        _buildingOptions = ['All'];
        _isBuildingDataLoaded = true;
      });
    }
  }

  Icon _getDeviceIcon(String? type) {
    if (type == 'PC') return const Icon(Icons.computer_outlined, color: Color(0xFF81D4FA), size: 20);
    if (type == 'Peripheral') return const Icon(Icons.devices_other_outlined, color: Color(0xFF81D4FA), size: 20);
    return const Icon(Icons.device_unknown_outlined, color: Color(0xFF81D4FA), size: 20);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return const Color(0xFF4CAF50);
      case 'offline':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Future<Map<String, Map<String, String>>> _fetchLocationInfoMap() async {
    final map = <String, Map<String, String>>{};

    try {
      // Get all buildings
      final buildingsSnapshot = await FirebaseFirestore.instance
          .collection('buildings')
          .get();

      for (var buildingDoc in buildingsSnapshot.docs) {
        final buildingData = buildingDoc.data();
        final buildingName = buildingData['name'] ?? 'Unknown';

        final locationsSnapshot = await buildingDoc.reference
            .collection('locations')
            .get();

        for (var locationDoc in locationsSnapshot.docs) {
          final locationData = locationDoc.data();
          final locationName = locationData['name'];
          final floor = locationData['floor'];

          if (locationName != null) {
            map[locationName] = {
              'floor': floor ?? 'Unknown',
              'building': buildingName,
            };
          }
        }
      }
    } catch (e) {
      print('Error fetching location info map: $e');
    }

    return map;
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
          'All Devices',
          style: TextStyle(
            fontFamily: 'SansRegular',
            color: Color(0xFF212529),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 40,
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
                      hintText: 'Search devices...',
                      prefixIcon: const Icon(Icons.search_outlined, color: Color(0xFF6C757D), size: 18),
                      hintStyle: const TextStyle(
                        fontFamily: 'SansRegular',
                        color: Color(0xFF6C757D),
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                const SizedBox(height: 12),
                // Filters Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Type Filter
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.category_outlined, size: 14, color: Color(0xFF6C757D)),
                            const SizedBox(width: 6),
                            DropdownButton<String>(
                              value: _selectedType,
                              dropdownColor: Colors.white,
                              underline: const SizedBox(),
                              isDense: true,
                              style: const TextStyle(
                                color: Color(0xFF212529),
                                fontFamily: 'SansRegular',
                                fontSize: 12,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'All', child: Text('All')),
                                DropdownMenuItem(value: 'PC', child: Text('PC')),
                                DropdownMenuItem(value: 'Peripheral', child: Text('Peripheral')),
                                DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                              ],
                              onChanged: (value) => setState(() => _selectedType = value!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Building Filter
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 14, color: Color(0xFF6C757D)),
                            const SizedBox(width: 6),
                            DropdownButton<String>(
                              value: _selectedBuilding,
                              dropdownColor: Colors.white,
                              underline: const SizedBox(),
                              isDense: true,
                              style: const TextStyle(
                                color: Color(0xFF212529),
                                fontFamily: 'SansRegular',
                                fontSize: 12,
                              ),
                              items: _buildingOptions.map((building) {
                                return DropdownMenuItem(
                                  value: building,
                                  child: Text(building),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedBuilding = value!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Floor Filter
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.layers_outlined, size: 14, color: Color(0xFF6C757D)),
                            const SizedBox(width: 6),
                            DropdownButton<String>(
                              value: _selectedFloor,
                              dropdownColor: Colors.white,
                              underline: const SizedBox(),
                              isDense: true,
                              style: const TextStyle(
                                color: Color(0xFF212529),
                                fontFamily: 'SansRegular',
                                fontSize: 12,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'All', child: Text('All')),
                                DropdownMenuItem(value: 'Ground Floor', child: Text('Ground')),
                                DropdownMenuItem(value: '1st Floor', child: Text('1st')),
                                DropdownMenuItem(value: '2nd Floor', child: Text('2nd')),
                                DropdownMenuItem(value: '3rd Floor', child: Text('3rd')),
                              ],
                              onChanged: (value) => setState(() => _selectedFloor = value!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Filter
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_outlined, size: 14, color: Color(0xFF6C757D)),
                            const SizedBox(width: 6),
                            DropdownButton<String>(
                              value: _selectedStatus,
                              dropdownColor: Colors.white,
                              underline: const SizedBox(),
                              isDense: true,
                              style: const TextStyle(
                                color: Color(0xFF212529),
                                fontFamily: 'SansRegular',
                                fontSize: 12,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'All', child: Text('All')),
                                DropdownMenuItem(value: 'Online', child: Text('Online')),
                                DropdownMenuItem(value: 'Offline', child: Text('Offline')),
                              ],
                              onChanged: (value) => setState(() => _selectedStatus = value!),
                            ),
                          ],
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
      body: FutureBuilder<Map<String, Map<String, String>>>(
        future: _fetchLocationInfoMap(),
        builder: (context, locationSnapshot) {
          if (locationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81D4FA)),
              ),
            );
          }
          if (!locationSnapshot.hasData) {
            return const Center(
              child: Text(
                'Failed to load location data',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF6C757D),
                  fontSize: 14,
                ),
              ),
            );
          }

          final locationInfoMap = locationSnapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('devices').orderBy('name').snapshots(),
            builder: (context, deviceSnapshot) {
              if (deviceSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error loading devices',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      color: Color(0xFF6C757D),
                      fontSize: 14,
                    ),
                  ),
                );
              }
              if (deviceSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81D4FA)),
                  ),
                );
              }

              final docs = deviceSnapshot.data!.docs;

              final filteredDevices = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final locationName = data['location'] ?? '';
                final locationInfo = locationInfoMap[locationName];
                data['floor'] = locationInfo?['floor'] ?? 'Unknown';
                data['building'] = locationInfo?['building'] ?? 'Unknown';
                data['locationName'] = locationName;
                data['id'] = doc.id;
                return data;
              }).where((data) {
                final name = (data['name'] ?? '').toString().toLowerCase();
                final type = (data['type'] ?? 'Unknown').toString();
                final floor = (data['floor'] ?? 'Unknown').toString();
                final building = (data['building'] ?? 'Unknown').toString();
                final status = (data['status'] ?? '').toString();

                // Apply filters (no department restriction)
                if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) return false;
                if (_selectedType != 'All' && type != _selectedType) return false;
                if (_selectedBuilding != 'All' && building != _selectedBuilding) return false;
                if (_selectedFloor != 'All' && floor != _selectedFloor) return false;
                if (_selectedStatus != 'All' && status.toLowerCase() != _selectedStatus.toLowerCase()) return false;
                return true;
              }).toList();

              final grouped = <String, List<Map<String, dynamic>>>{};
              for (var data in filteredDevices) {
                final name = (data['name'] ?? 'No name').toString();
                final key = name[0].toUpperCase();
                grouped.putIfAbsent(key, () => []).add(data);
              }

              if (filteredDevices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No devices found',
                        style: TextStyle(
                          fontFamily: 'SansRegular',
                          color: Color(0xFF6C757D),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: grouped.entries.expand((entry) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SansRegular',
                          color: Color(0xFF212529),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...entry.value.map((data) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF212529),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
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
                                    builder: (context) => DeviceDetailsPage(device: data),
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
                                      child: _getDeviceIcon(data['type']),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'] ?? 'No name',
                                            style: const TextStyle(
                                              fontFamily: 'SansRegular',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFF81D4FA),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _buildInfoChip('${data['type'] ?? 'Unknown'}'),
                                              const SizedBox(width: 6),
                                              _buildInfoChip('${data['building'] ?? 'Unknown'}'),
                                              const SizedBox(width: 6),
                                              _buildInfoChip('${data['floor'] ?? 'Unknown'}'),
                                            ],
                                          ),
                                          if (data['peripheral_type'] != null && 
                                              data['peripheral_type'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                _buildInfoChip('${data['peripheral_type']}'),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            '${data['locationName'] ?? 'Unknown Location'}',
                                            style: const TextStyle(
                                              fontFamily: 'SansRegular',
                                              color: Color(0xFFADB5BD),
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (data['ip'] != null && data['ip'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'IP: ${data['ip']}',
                                              style: const TextStyle(
                                                fontFamily: 'SansRegular',
                                                color: Color(0xFF6C757D),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(data['status'] ?? '').withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(data['status'] ?? ''),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        (data['status'] ?? 'N/A').toString().toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(data['status'] ?? ''),
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'SansRegular',
                                          fontSize: 9,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                  ];
                }).toList(),
              );
            },
          );
        },
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