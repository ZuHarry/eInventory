import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final List<String> _buildings = ['All', 'Right Wing', 'Left Wing'];
  final List<String> _floors = ['All', 'Ground', '1st Floor', '2nd Floor', '3rd Floor'];
  final List<String> _types = ['All', 'Lecture Room', 'Lab', 'Lecturer Office', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC727),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC727),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Select Location',
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
              stream: FirebaseFirestore.instance.collection('locations').orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error loading locations'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

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
                  return const Center(child: Text('No matching locations found'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final locationName = data['name'] ?? 'Unnamed';
                    final building = data['building'] ?? 'Unknown';
                    final floor = data['floor'] ?? 'Unknown';
                    final type = data['type'] ?? 'Unknown';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text(
                          locationName,
                          style: const TextStyle(
                            fontFamily: 'PoetsenOne',
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'Building: $building\nFloor: $floor\nType: $type',
                          style: const TextStyle(
                            fontFamily: 'PoetsenOne',
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        isThreeLine: true,
                        onTap: () => Navigator.pop(context, locationName),
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
