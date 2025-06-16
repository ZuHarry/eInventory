import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:einventorycomputer/modules/home/screen/devices/device_details.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _searchQuery = '';
  String _selectedType = 'All';
  String _selectedFloor = 'All';
  String _selectedBuilding = 'All';

  Icon _getDeviceIcon(String? type) {
    if (type == 'PC') return const Icon(Icons.computer_outlined, color: Color(0xFFFFC727), size: 28);
    if (type == 'Peripheral') return const Icon(Icons.devices_other_outlined, color: Color(0xFFFFC727), size: 28);
    return const Icon(Icons.device_unknown_outlined, color: Color(0xFFFFC727), size: 28);
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
    final snapshot = await FirebaseFirestore.instance.collection('locations').get();
    final map = <String, Map<String, String>>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'];
      final floor = data['floor'];
      final building = data['building'];
      if (name != null && floor != null && building != null) {
        map[name] = {'floor': floor, 'building': building};
      }
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
                      hintText: 'Search devices...',
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
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                            const Icon(Icons.category_outlined, size: 18, color: Color(0xFF6C757D)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _selectedType,
                                dropdownColor: Colors.white,
                                underline: const SizedBox(),
                                isExpanded: true,
                                style: const TextStyle(
                                  color: Color(0xFF212529),
                                  fontFamily: 'SansRegular',
                                  fontSize: 14,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All Types')),
                                  DropdownMenuItem(value: 'PC', child: Text('PC')),
                                  DropdownMenuItem(value: 'Peripheral', child: Text('Peripheral')),
                                  DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                                ],
                                onChanged: (value) => setState(() => _selectedType = value!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
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
                            const Icon(Icons.layers_outlined, size: 18, color: Color(0xFF6C757D)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _selectedFloor,
                                dropdownColor: Colors.white,
                                underline: const SizedBox(),
                                isExpanded: true,
                                style: const TextStyle(
                                  color: Color(0xFF212529),
                                  fontFamily: 'SansRegular',
                                  fontSize: 14,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All Floors')),
                                  DropdownMenuItem(value: 'Ground Floor', child: Text('Ground')),
                                  DropdownMenuItem(value: '1st Floor', child: Text('1st Floor')),
                                  DropdownMenuItem(value: '2nd Floor', child: Text('2nd Floor')),
                                  DropdownMenuItem(value: '3rd Floor', child: Text('3rd Floor')),
                                ],
                                onChanged: (value) => setState(() => _selectedFloor = value!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Building Filter
                Container(
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
                      const Icon(Icons.business_outlined, size: 18, color: Color(0xFF6C757D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedBuilding,
                          dropdownColor: Colors.white,
                          underline: const SizedBox(),
                          isExpanded: true,
                          style: const TextStyle(
                            color: Color(0xFF212529),
                            fontFamily: 'SansRegular',
                            fontSize: 14,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Buildings')),
                            DropdownMenuItem(value: 'Left Wing', child: Text('Left Wing')),
                            DropdownMenuItem(value: 'Right Wing', child: Text('Right Wing')),
                          ],
                          onChanged: (value) => setState(() => _selectedBuilding = value!),
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC727)),
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
                  fontSize: 16,
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
                      fontSize: 16,
                    ),
                  ),
                );
              }
              if (deviceSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC727)),
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

                if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) return false;
                if (_selectedType != 'All' && type != _selectedType) return false;
                if (_selectedFloor != 'All' && floor != _selectedFloor) return false;
                if (_selectedBuilding != 'All' && building != _selectedBuilding) return false;
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
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No devices found',
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

              return ListView(
                padding: const EdgeInsets.all(20),
                children: grouped.entries.expand((entry) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 20),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SansRegular',
                          color: Color(0xFF212529),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...entry.value.map((data) => Container(
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
                                    builder: (context) => DeviceDetailsPage(device: data),
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
                                      child: _getDeviceIcon(data['type']),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'] ?? 'No name',
                                            style: const TextStyle(
                                              fontFamily: 'SansRegular',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                              color: Color(0xFFFFC727),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              _buildInfoChip('${data['type'] ?? 'Unknown'}'),
                                              const SizedBox(width: 8),
                                              _buildInfoChip('${data['floor'] ?? 'Unknown'}'),
                                            ],
                                          ),
                                          // Show peripheral_type chip below if it exists and is not empty
                                          if (data['peripheral_type'] != null && 
                                              data['peripheral_type'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _buildInfoChip('${data['peripheral_type']}'),
                                              ],
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Text(
                                            '${data['locationName'] ?? 'Unknown Location'}',
                                            style: const TextStyle(
                                              fontFamily: 'SansRegular',
                                              color: Color(0xFFADB5BD),
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (data['ip'] != null && data['ip'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'IP: ${data['ip']}',
                                              style: const TextStyle(
                                                fontFamily: 'SansRegular',
                                                color: Color(0xFF6C757D),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(data['status'] ?? '').withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
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
                                          fontSize: 11,
                                          letterSpacing: 0.5,
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