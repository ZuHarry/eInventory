import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceStaffPage extends StatelessWidget {
  final String staffId;
  final String staffName;
  final Map<String, dynamic> device;

  const DeviceStaffPage({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.device,
  });

  Future<Map<String, dynamic>?> _fetchStaffData() async {
    try {
      if (staffId.isEmpty) return null;
      
      // Fetch staff data from Firestore
      final staffDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(staffId)
          .get();
      
      if (staffDoc.exists) {
        return staffDoc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching staff data: $e');
      return null;
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
          'Staff Information',
          style: TextStyle(
            fontFamily: 'SansRegular',
            color: Color(0xFF212529),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchStaffData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFC727),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading staff information',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          
          final staffData = snapshot.data;
          
          if (staffData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC727).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: Color(0xFFFFC727),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Staff Information',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212529),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Staff information not found',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Extract staff information
          final fullName = staffData['fullname'] ?? staffName;
          final telephone = staffData['telephone'] ?? 'Not provided';
          final staffType = staffData['staffType'] ?? 'Not specified';
          final profilePicture = staffData['profilePicture'] ?? '';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Picture
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFC727).withOpacity(0.1),
                          border: Border.all(
                            color: const Color(0xFFFFC727),
                            width: 3,
                          ),
                        ),
                        child: profilePicture.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.network(
                                  profilePicture,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Color(0xFFFFC727),
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Color(0xFFFFC727),
                              ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Staff Name
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212529),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      // Staff ID
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC727).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: $staffId',
                          style: const TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF212529),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Staff Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff Details',
                        style: TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212529),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Telephone
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'Telephone',
                        telephone,
                      ),
                      const SizedBox(height: 16),
                      
                      // Staff Type
                      _buildInfoRow(
                        Icons.badge_outlined,
                        'Staff Type',
                        staffType,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Assigned Device Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Device',
                        style: TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212529),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC727).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFC727).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC727).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                device['type'] == 'PC'
                                    ? Icons.computer_outlined
                                    : device['type'] == 'Peripheral'
                                        ? Icons.devices_other_outlined
                                        : Icons.device_unknown_outlined,
                                color: const Color(0xFFFFC727),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device['name'] ?? 'Unknown Device',
                                    style: const TextStyle(
                                      fontFamily: 'SansRegular',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF212529),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${device['type'] ?? 'Unknown'} • ${device['location'] ?? 'No location'}',
                                    style: const TextStyle(
                                      fontFamily: 'SansRegular',
                                      fontSize: 14,
                                      color: Color(0xFF6C757D),
                                    ),
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
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC727).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFFFFC727),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  color: Color(0xFF212529),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}