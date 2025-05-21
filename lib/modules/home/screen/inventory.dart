import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:einventorycomputer/modules/home/screen/device_details.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _searchQuery = '';
  String _selectedType = 'All';

  Icon _getDeviceIcon(String? type) {
    if (type == 'PC') {
      return const Icon(Icons.computer, color: Colors.black);
    } else if (type == 'Peripheral') {
      return const Icon(Icons.devices_other, color: Colors.black);
    } else {
      return const Icon(Icons.device_unknown, color: Colors.black);
    }
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
        title: const Text(
          'Device Inventory',
          style: TextStyle(
            fontFamily: 'PoetsenOne',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search device name',
                    prefixIcon: const Icon(Icons.search),
                    hintStyle: const TextStyle(fontFamily: 'PoetsenOne'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontFamily: 'PoetsenOne'),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Dropdown filter for type
                Row(
                  children: [
                    const Text(
                      'Filter by type:',
                      style: TextStyle(fontFamily: 'PoetsenOne'),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedType,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'PoetsenOne',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'PC', child: Text('PC')),
                        DropdownMenuItem(
                            value: 'Peripheral', child: Text('Peripheral')),
                        DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('devices')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading data',
                  style: TextStyle(fontFamily: 'PoetsenOne')),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final filteredDevices = docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .where((data) {
                final name = (data['name'] ?? '').toString().toLowerCase();
                final type = (data['type'] ?? 'Unknown').toString();

                if (_searchQuery.isNotEmpty &&
                    !name.contains(_searchQuery.toLowerCase())) {
                  return false;
                }

                if (_selectedType != 'All' && type != _selectedType) {
                  return false;
                }

                return true;
              })
              .toList();

          final grouped = <String, List<Map<String, dynamic>>>{};
          for (var data in filteredDevices) {
            final name = (data['name'] ?? 'No name').toString();
            final key = name[0].toUpperCase();
            grouped.putIfAbsent(key, () => []).add(data);
          }

          if (filteredDevices.isEmpty) {
            return const Center(
              child: Text(
                'No devices found',
                style: TextStyle(fontFamily: 'PoetsenOne'),
              ),
            );
          }

          return ListView(
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PoetsenOne',
                        color: Colors.black,
                      ),
                    ),
                  ),
                  ...entry.value.map((data) {
                    final type = data['type'] ?? 'Unknown';
                    final status = data['status']?.toString() ?? 'N/A';

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: _getDeviceIcon(type),
                        title: Text(
                          data['name'] ?? 'No name',
                          style: const TextStyle(
                            fontFamily: 'PoetsenOne',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type: $type',
                              style: const TextStyle(fontFamily: 'PoetsenOne'),
                            ),
                            Text(
                              'IP: ${data['ip'] ?? 'N/A'}',
                              style: const TextStyle(fontFamily: 'PoetsenOne'),
                            ),
                            Text(
                              'MAC: ${data['mac'] ?? 'N/A'}',
                              style: const TextStyle(fontFamily: 'PoetsenOne'),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PoetsenOne',
                              fontSize: 13,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DeviceDetailsPage(device: data),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
