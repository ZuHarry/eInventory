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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search device name',
                    prefixIcon: const Icon(Icons.search),
                    hintStyle: const TextStyle(fontFamily: 'SansRegular'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontFamily: 'SansRegular'),
                  onChanged: (value) => setState(() => _searchQuery = value.trim()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Type:', style: TextStyle(fontFamily: 'SansRegular')),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedType,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black, fontFamily: 'SansRegular'),
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
                    Row(
                      children: [
                        const Text('Floor:', style: TextStyle(fontFamily: 'SansRegular')),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _selectedFloor,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black, fontFamily: 'SansRegular'),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(value: 'Ground', child: Text('Ground')),
                            DropdownMenuItem(value: '1st Floor', child: Text('1st')),
                            DropdownMenuItem(value: '2nd Floor', child: Text('2nd')),
                            DropdownMenuItem(value: '3rd Floor', child: Text('3rd')),
                          ],
                          onChanged: (value) => setState(() => _selectedFloor = value!),
                        ),
                      ],
                    ),
                  ],
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
            return const Center(child: CircularProgressIndicator());
          }
          if (!locationSnapshot.hasData) {
            return const Center(child: Text('Failed to load location data', style: TextStyle(fontFamily: 'SansRegular')));
          }

          final locationInfoMap = locationSnapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('devices').orderBy('name').snapshots(),
            builder: (context, deviceSnapshot) {
              if (deviceSnapshot.hasError) {
                return const Center(child: Text('Error loading devices', style: TextStyle(fontFamily: 'SansRegular')));
              }
              if (deviceSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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

                if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) return false;
                if (_selectedType != 'All' && type != _selectedType) return false;
                if (_selectedFloor != 'All' && floor != _selectedFloor) return false;
                return true;
              }).toList();

              final grouped = <String, List<Map<String, dynamic>>>{};
              for (var data in filteredDevices) {
                final name = (data['name'] ?? 'No name').toString();
                final key = name[0].toUpperCase();
                grouped.putIfAbsent(key, () => []).add(data);
              }

              if (filteredDevices.isEmpty) {
                return const Center(child: Text('No devices found', style: TextStyle(fontFamily: 'SansRegular')));
              }

              return ListView(
                children: grouped.entries.expand((entry) {
                  return [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(entry.key, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'SansRegular', color: Colors.black)),
                    ),
                    ...entry.value.map((data) => Card(
                          color: const Color(0xFFFFC727),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: _getDeviceIcon(data['type']),
                            title: Text(data['name'] ?? 'No name', style: const TextStyle(fontFamily: 'SansRegular', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Type: ${data['type'] ?? 'Unknown'}', style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black)),
                                Text('IP: ${data['ip'] ?? 'N/A'}', style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black)),
                                Text('MAC: ${data['mac'] ?? 'N/A'}', style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black)),
                                Text('Location: ${data['locationName'] ?? 'Unknown'}', style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black)),
                                Text('Floor: ${data['floor'] ?? 'Unknown'}', style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black)),
                                Text('Building: ${data['building'] ?? 'Unknown'}', style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black)),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(data['status'] ?? '').withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (data['status'] ?? 'N/A').toString().toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(data['status'] ?? ''),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SansRegular',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeviceDetailsPage(device: data),
                                ),
                              );
                            },
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
}
