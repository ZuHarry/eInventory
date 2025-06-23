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

  List<String> _buildings = ['All']; // Will be populated from Firestore
  final List<String> _floors = ['All', 'Ground', '1st Floor', '2nd Floor', '3rd Floor'];
  final List<String> _types = ['All', 'Lecture Room', 'Lab', 'Lecturer Office', 'Other'];

  bool _buildingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBuildingsFromFirestore();
  }

  Future<void> _loadBuildingsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('locations').get();
      final Set<String> buildingSet = {'All'};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final building = data['building'];
        if (building != null && building.toString().trim().isNotEmpty) {
          buildingSet.add(building.toString());
        }
      }
      
      setState(() {
        _buildings = buildingSet.toList()..sort((a, b) {
          if (a == 'All') return -1;
          if (b == 'All') return 1;
          return a.compareTo(b);
        });
        _buildingsLoaded = true;
      });
    } catch (e) {
      print('Error loading buildings: $e');
      setState(() {
        _buildingsLoaded = true;
      });
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

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF212529),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        title: Text(
                          locationName,
                          style: const TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 15,
                            color: Color(0xFFFFC727),
                          ),
                        ),
                        subtitle: Text(
                          '$building • $floor • $type',
                          style: const TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
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
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search_outlined, color: Color(0xFF6C757D), size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildingsLoaded 
                  ? _buildFilterDropdown(
                      'Building',
                      _selectedBuilding,
                      _buildings,
                      (val) => setState(() => _selectedBuilding = val!),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C757D)),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading buildings...',
                            style: TextStyle(
                              color: Color(0xFF6C757D),
                              fontFamily: 'SansRegular',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFilterDropdown(
                  'Floor',
                  _selectedFloor,
                  _floors,
                  (val) => setState(() => _selectedFloor = val!),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFilterDropdown(
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

  Widget _buildFilterDropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: items.map((item) => DropdownMenuItem(
          value: item, 
          child: Text(
            item == 'All' ? 'All ${label}s' : item,
            style: const TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          )
        )).toList(),
        underline: const SizedBox(),
        isExpanded: true,
        style: const TextStyle(
          color: Color(0xFF212529),
          fontFamily: 'SansRegular',
          fontSize: 11,
        ),
      ),
    );
  }
}