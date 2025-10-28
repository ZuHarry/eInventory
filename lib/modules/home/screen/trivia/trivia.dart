import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TriviaPage extends StatefulWidget {
  @override
  _TriviaPageState createState() => _TriviaPageState();
}

class _TriviaPageState extends State<TriviaPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Brand', 'Model', 'Type', 'Location', 'Status'];

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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF212529) : const Color(0xFF6C757D),
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
                        color: isSelected ? const Color(0xFFFFC727) : const Color(0xFFDEE2E6),
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
              stream: FirebaseFirestore.instance.collection('devices').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC727)),
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
                final triviaData = _processTriviaData(devices);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: _buildTriviaCards(triviaData),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, int>> _processTriviaData(List<QueryDocumentSnapshot> devices) {
    Map<String, Map<String, int>> data = {
      'Brand': {},
      'Model': {},
      'Type': {},
      'Location': {},
      'Status': {},
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

    final totalCount = items.values.fold(0, (sum, count) => sum + count);

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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              final percentage = (entry.value / totalCount * 100).toStringAsFixed(1);

              return Row(
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
                ],
              );
            },
          ),
        ],
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
      default:
        return Icons.quiz_rounded;
    }
  }
}