import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeviceStaffPage extends StatefulWidget {
  final String staffId; // This is the UID
  final String staffName;
  final Map<String, dynamic> device;

  const DeviceStaffPage({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.device,
  });

  @override
  State<DeviceStaffPage> createState() => _DeviceStaffPageState();
}

class _DeviceStaffPageState extends State<DeviceStaffPage> {
  late Future<Map<String, dynamic>> _staffDataFuture;
  late Future<List<Map<String, dynamic>>> _assignedDevicesFuture;

  @override
  void initState() {
    super.initState();
    _staffDataFuture = _fetchStaffData();
    _assignedDevicesFuture = _fetchAssignedDevices();
  }

  Future<Map<String, dynamic>> _fetchStaffData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: widget.staffId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      } else {
        return {'error': 'Staff member not found'};
      }
    } catch (e) {
      print('Error fetching staff data: $e');
      return {'error': 'Error loading staff data'};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAssignedDevices() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('devices')
          .where('assigned_by', isEqualTo: widget.staffId)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'docId': doc.id,
              })
          .toList();
    } catch (e) {
      print('Error fetching assigned devices: $e');
      return [];
    }
  }

  Icon _getDeviceIcon(String? type) {
    if (type == 'PC') {
      return const Icon(Icons.computer_outlined, color: Color(0xFF81D4FA), size: 40);
    } else if (type == 'Peripheral') {
      return const Icon(Icons.devices_other_outlined, color: Color(0xFF81D4FA), size: 40);
    } else {
      return const Icon(Icons.device_unknown_outlined, color: Color(0xFF81D4FA), size: 40);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF212529)),
        title: Text(
          'Staff Details',
          style: const TextStyle(
            fontFamily: 'SansRegular',
            color: Color(0xFF212529),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Staff Information Card
            FutureBuilder<Map<String, dynamic>>(
              future: _staffDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
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
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF81D4FA),
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
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
                    child: Text(
                      'Error loading staff details',
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 16,
                        color: Color(0xFFF44336),
                      ),
                    ),
                  );
                }

                final staffData = snapshot.data!;

                if (staffData.containsKey('error')) {
                  return Container(
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
                    child: Text(
                      staffData['error'] ?? 'Unknown error',
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 16,
                        color: Color(0xFFF44336),
                      ),
                    ),
                  );
                }

                final fullName = staffData['fullname'] ?? 'Unknown';
                final email = staffData['email'] ?? 'N/A';
                final staffType = staffData['staffType'] ?? 'N/A';
                final telephone = staffData['telephone'] ?? 'N/A';
                final staffId = staffData['staffId'] ?? 'N/A';

                return Container(
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
                      // Header with name and icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF81D4FA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF81D4FA).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF81D4FA),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontFamily: 'SansRegular',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF212529),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    staffType,
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
                      const SizedBox(height: 24),

                      // Staff Information
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212529),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.email_outlined, 'Email', email),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.phone_outlined, 'Telephone', telephone),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.badge_outlined, 'Staff ID', staffId),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Assigned Devices Section
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
                    'Assigned Devices',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212529),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _assignedDevicesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF81D4FA),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          'Error loading devices',
                          style: const TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 14,
                            color: Color(0xFFF44336),
                          ),
                        );
                      }

                      final devices = snapshot.data ?? [];

                      if (devices.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF81D4FA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF81D4FA).withOpacity(0.3),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'No devices assigned',
                              style: TextStyle(
                                fontFamily: 'SansRegular',
                                fontSize: 14,
                                color: Color(0xFF6C757D),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          final deviceName = device['name'] ?? 'Unknown Device';
                          final deviceType = device['type'] ?? 'Unknown';
                          final status = (device['status'] ?? 'N/A').toString();
                          final location = device['location'] ?? 'N/A';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                _getDeviceIcon(deviceType),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        deviceName,
                                        style: const TextStyle(
                                          fontFamily: 'SansRegular',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF212529),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Type: $deviceType • Location: $location',
                                        style: const TextStyle(
                                          fontFamily: 'SansRegular',
                                          fontSize: 12,
                                          color: Color(0xFF6C757D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStatusColor(status),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'SansRegular',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF81D4FA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF81D4FA),
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
                  fontSize: 14,
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