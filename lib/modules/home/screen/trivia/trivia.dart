import 'dart:developer';
import 'add_brand_page.dart';
import 'add_model_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TriviaPage extends StatefulWidget {
  @override
  _TriviaPageState createState() => _TriviaPageState();
}

class _TriviaPageState extends State<TriviaPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Brand',
    'Model',
    'Type',
    'Location',
    'Status',
    'Buildings',
    'Users'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF212529)
                            : const Color(0xFF6C757D),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFFFC727),
                    checkmarkColor: const Color(0xFF212529),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFFFFC727)
                            : const Color(0xFFDEE2E6),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                    pressElevation: 0,
                  ),
                );
              },
            ),
          ),

          // Trivia Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('devices')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFC727)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading data',
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        color: Color(0xFF6C757D),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: const Color(0xFFDEE2E6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No devices found',
                          style: const TextStyle(
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

                final devices = snapshot.data!.docs;

                return FutureBuilder<Map<String, Map<String, int>>>(
                  future: _processTriviaData(devices),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFC727)),
                        ),
                      );
                    }

                    if (futureSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error processing data',
                          style: const TextStyle(
                            fontFamily: 'SansRegular',
                            color: Color(0xFF6C757D),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    final triviaData = futureSnapshot.data ?? {};

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: _buildTriviaCards(triviaData),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

          floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        _showAddDataDialog();
      },
      backgroundColor: const Color(0xFFFFC727),
      icon: const Icon(
        Icons.add_rounded,
        color: Color(0xFF212529),
      ),
      label: const Text(
        'Add Data',
        style: TextStyle(
          fontFamily: 'SansRegular',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212529),
        ),
      ),
    ),

    );
  }

  void _showAddDataDialog() {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add New Data',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddBrandPage(),
                  ),
                );
              },
              icon: const Icon(Icons.business_rounded),
              label: const Text('Add Brand'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                foregroundColor: const Color(0xFF212529),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddModelPage(),
                  ),
                );
              },
              icon: const Icon(Icons.devices_rounded),
              label: const Text('Add Model'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                foregroundColor: const Color(0xFF212529),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Future<Map<String, Map<String, int>>> _processTriviaData(
      List<QueryDocumentSnapshot> devices) async {
    Map<String, Map<String, int>> data = {
      'Brand': {},
      'Model': {},
      'Type': {},
      'Location': {},
      'Status': {},
      'Buildings': {},
      'Users': {},
    };

    for (var device in devices) {
      final deviceData = device.data() as Map<String, dynamic>;

      // Count brands
      if (deviceData['brand'] != null) {
        final brand = deviceData['brand'].toString();
        data['Brand']![brand] = (data['Brand']![brand] ?? 0) + 1;
      }

      // Count models
      if (deviceData['model'] != null) {
        final model = deviceData['model'].toString();
        data['Model']![model] = (data['Model']![model] ?? 0) + 1;
      }

      // Count types
      if (deviceData['type'] != null) {
        final type = deviceData['type'].toString();
        data['Type']![type] = (data['Type']![type] ?? 0) + 1;
      }

      // Count locations
      if (deviceData['location'] != null) {
        final location = deviceData['location'].toString();
        data['Location']![location] = (data['Location']![location] ?? 0) + 1;
      }

      // Count status
      if (deviceData['status'] != null) {
        final status = deviceData['status'].toString();
        data['Status']![status] = (data['Status']![status] ?? 0) + 1;
      }

      // Get building name from location reference
      if (deviceData['location'] != null) {
        try {
          final locationId = deviceData['location'].toString();
          final locationDoc = await FirebaseFirestore.instance
              .collection('locations')
              .doc(locationId)
              .get();

          if (locationDoc.exists) {
            final buildingId = locationDoc['building'];
            if (buildingId != null) {
              final buildingDoc = await FirebaseFirestore.instance
                  .collection('buildings')
                  .doc(buildingId)
                  .get();

              if (buildingDoc.exists) {
                final buildingName =
                    buildingDoc['name'] ?? 'Unknown Building';
                data['Buildings']![buildingName] =
                    (data['Buildings']![buildingName] ?? 0) + 1;
              }
            }
          }
        } catch (e) {
          print('Error fetching building: $e');
        }
      }

      // Get user full name from handledBy UID
      if (deviceData['handledBy'] != null) {
        try {
          final userId = deviceData['handledBy'].toString();
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final fullName =
                userDoc['fullname'] ?? userDoc['username'] ?? 'Unknown User';
            data['Users']![fullName] =
                (data['Users']![fullName] ?? 0) + 1;
          }
        } catch (e) {
          print('Error fetching user: $e');
        }
      }
    }

    return data;
  }

  List<Widget> _buildTriviaCards(Map<String, Map<String, int>> triviaData) {
    List<Widget> cards = [];

    if (_selectedCategory == 'All') {
      // Show all categories
      triviaData.forEach((category, items) {
        if (items.isNotEmpty) {
          cards.add(_buildCategoryCard(category, items));
          cards.add(const SizedBox(height: 16));
        }
      });
    } else {
      // Show selected category only
      final items = triviaData[_selectedCategory] ?? {};
      if (items.isNotEmpty) {
        cards.add(_buildCategoryCard(_selectedCategory, items));
      }
    }

    return cards;
  }

  Widget _buildCategoryCard(String category, Map<String, int> items) {
    final sortedItems = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalCount =
        items.values.fold(0, (sum, count) => sum + count);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF212529),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: const Color(0xFFFFC727),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFC727),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC727),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCount',
                    style: const TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212529),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: sortedItems.length,
            separatorBuilder: (context, index) => const Divider(
              height: 16,
              color: Color(0xFFDEE2E6),
            ),
            itemBuilder: (context, index) {
              final entry = sortedItems[index];
              final percentage =
                  (entry.value / totalCount * 100).toStringAsFixed(1);

              return InkWell(
                onTap: () {
                  _navigateToFilteredDevices(category, entry.key);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: index < 3
                              ? const Color(0xFFFFC727).withOpacity(0.2)
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: 'SansRegular',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: index < 3
                                  ? const Color(0xFF212529)
                                  : const Color(0xFF6C757D),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Item name
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF212529),
                          ),
                        ),
                      ),

                      // Count and percentage
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontFamily: 'SansRegular',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212529),
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontFamily: 'SansRegular',
                              fontSize: 11,
                              color: Color(0xFF6C757D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: const Color(0xFF6C757D),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToFilteredDevices(String category, String value) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredDevicesPage(
          category: category,
          value: value,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Brand':
        return Icons.business_rounded;
      case 'Model':
        return Icons.devices_rounded;
      case 'Type':
        return Icons.category_rounded;
      case 'Location':
        return Icons.location_on_rounded;
      case 'Status':
        return Icons.info_rounded;
      case 'Buildings':
        return Icons.apartment_rounded;
      case 'Users':
        return Icons.people_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }
}

// Filtered Devices Page
class FilteredDevicesPage extends StatefulWidget {
  final String category;
  final String value;

  const FilteredDevicesPage({
    Key? key,
    required this.category,
    required this.value,
  }) : super(key: key);

  @override
  State<FilteredDevicesPage> createState() => _FilteredDevicesPageState();
}

class _FilteredDevicesPageState extends State<FilteredDevicesPage> {
  late Future<Map<String, dynamic>> _filterDataFuture;

  @override
  void initState() {
    super.initState();
    _filterDataFuture = _getFilterCriteria();
  }

  Future<Map<String, dynamic>> _getFilterCriteria() async {
    if (widget.category == 'Buildings') {
      // Get location ID from building name
      final buildingsQuery = await FirebaseFirestore.instance
          .collection('buildings')
          .where('name', isEqualTo: widget.value)
          .get();

      if (buildingsQuery.docs.isNotEmpty) {
        final buildingId = buildingsQuery.docs.first.id;
        return {'type': 'building', 'buildingId': buildingId};
      }
    } else if (widget.category == 'Users') {
      // Get user ID from full name
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('fullname', isEqualTo: widget.value)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        final userId = usersQuery.docs.first.id;
        return {'type': 'user', 'userId': userId};
      }
    }

    return {'type': widget.category.toLowerCase(), 'value': widget.value};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFFFFC727)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.value,
              style: const TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFC727),
              ),
            ),
            Text(
              widget.category,
              style: const TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 12,
                color: Color(0xFF6C757D),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _filterDataFuture,
        builder: (context, filterSnapshot) {
          if (filterSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFFFFC727)),
              ),
            );
          }

          return StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: _getFilteredStream(filterSnapshot.data ?? {}),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFC727)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading devices',
                    style: const TextStyle(
                      fontFamily: 'SansRegular',
                      color: Color(0xFF6C757D),
                      fontSize: 14,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.devices_other_rounded,
                        size: 64,
                        color: const Color(0xFFDEE2E6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No devices found',
                        style: const TextStyle(
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

              final devices = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device =
                      devices[index].data() as Map<String, dynamic>;
                  return _buildDeviceCard(device);
                },
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<QueryDocumentSnapshot>> _getFilteredStream(Map<String, dynamic> filterData) {
    final filterType = filterData['type'] ?? '';

    if (filterType == 'building') {
      // Query devices where location's building field matches
      return FirebaseFirestore.instance
          .collection('devices')
          .snapshots()
          .asyncMap((snapshot) async {
        final buildingId = filterData['buildingId'];
        final filtered = <QueryDocumentSnapshot>[];

        for (var doc in snapshot.docs) {
          final deviceData = doc.data() as Map<String, dynamic>;
          if (deviceData['location'] != null) {
            final locationDoc = await FirebaseFirestore.instance
                .collection('locations')
                .doc(deviceData['location'])
                .get();

            if (locationDoc.exists &&
                locationDoc['building'] == buildingId) {
              filtered.add(doc);
            }
          }
        }

        return filtered;
      });
    } else if (filterType == 'user') {
      // Query devices where handledBy matches user ID
      return FirebaseFirestore.instance
          .collection('devices')
          .where('handledBy', isEqualTo: filterData['userId'])
          .snapshots()
          .map((snapshot) => snapshot.docs);
    } else {
      // Default filtering for other categories
      final fieldName = widget.category.toLowerCase();
      return FirebaseFirestore.instance
          .collection('devices')
          .where(fieldName, isEqualTo: widget.value)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    }
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand and Model
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${device['brand'] ?? 'Unknown'} ${device['model'] ?? ''}',
                    style: const TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212529),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(device['status']),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    device['status'] ?? 'Unknown',
                    style: const TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Device details
            if (device['name'] != null) ...[
              _buildDetailRow(
                  Icons.label_rounded, 'Name', device['name']),
              const SizedBox(height: 8),
            ],
            _buildDetailRow(
                Icons.category_rounded, 'Type', device['type']),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.location_on_rounded, 'Location',
                device['location']),
            if (device['serialNumber'] != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(Icons.tag_rounded, 'Serial',
                  device['serialNumber']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6C757D),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 13,
            color: Color(0xFF6C757D),
          ),
        ),
        Expanded(
          child: Text(
            value?.toString() ?? 'N/A',
            style: const TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF212529),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return const Color(0xFF28A745);
      case 'inactive':
        return const Color(0xFF6C757D);
      case 'maintenance':
        return const Color(0xFFC107);
      case 'retired':
        return const Color(0xFFDC3545);
      default:
        return const Color(0xFF6C757D);
    }
  }
}

class AddDataDialog extends StatefulWidget {
  @override
  State<AddDataDialog> createState() => _AddDataDialogState();
}

class _AddDataDialogState extends State<AddDataDialog> {
  String _selectedType = 'Brand';
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _selectedBrandId; // ADD THIS
  List<Map<String, dynamic>> _brands = []; // ADD THIS

  @override
  void initState() {
    super.initState();
    _loadBrands(); // ADD THIS
  }

  Future<void> _loadBrands() async {
    final brandsSnapshot = await FirebaseFirestore.instance
        .collection('brands')
        .orderBy('name')
        .get();
    
    setState(() {
      _brands = brandsSnapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name']})
          .toList();
    });
  }

  Future<void> _saveData() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
      return;
    }

    // ADD THIS VALIDATION
    if (_selectedType == 'Model' && _selectedBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a brand'),
          backgroundColor: Color(0xFFDC3545),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // REPLACE THE ENTIRE TRY BLOCK WITH THIS:
      if (_selectedType == 'Brand') {
        await FirebaseFirestore.instance.collection('brands').add({
          'name': _nameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add model as subcollection under selected brand
        await FirebaseFirestore.instance
            .collection('brands')
            .doc(_selectedBrandId)
            .collection('models')
            .add({
          'name': _nameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedType added successfully'),
          backgroundColor: const Color(0xFF28A745),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Data',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: ['Brand', 'Model'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
            const SizedBox(height: 16),
             // ADD BRAND DROPDOWN FOR MODEL
            if (_selectedType == 'Model') ...[
              DropdownButtonFormField<String>(
                value: _selectedBrandId,
                decoration: InputDecoration(
                  labelText: 'Brand',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: _brands.map((brand) {
                  return DropdownMenuItem<String>(
                    value: brand['id'] as String,
                    child: Text(brand['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedBrandId = value);
                },
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC727),
                    foregroundColor: const Color(0xFF212529),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF212529),
                            ),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}