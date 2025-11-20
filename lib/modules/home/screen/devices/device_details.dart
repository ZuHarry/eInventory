import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'device_edit_page.dart';
import 'device_staff_page.dart';

class DeviceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> device;

  const DeviceDetailsPage({super.key, required this.device});

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  String? assignedByFullName;
  bool isLoadingStaffName = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignedByFullName();
  }

  Future<void> _fetchAssignedByFullName() async {
    final assignedByUid = widget.device['assigned_by'];
    
    if (assignedByUid == null || assignedByUid.toString().isEmpty) {
      setState(() {
        assignedByFullName = 'Unassigned';
        isLoadingStaffName = false;
      });
      return;
    }

    try {
      // Query users collection to find the user with matching uid
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: assignedByUid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final fullName = userData['fullname'] ?? 'Unknown User';
        setState(() {
          assignedByFullName = fullName;
          isLoadingStaffName = false;
        });
      } else {
        setState(() {
          assignedByFullName = 'Unknown User';
          isLoadingStaffName = false;
        });
      }
    } catch (e) {
      print('Error fetching assigned by user: $e');
      setState(() {
        assignedByFullName = 'Error loading name';
        isLoadingStaffName = false;
      });
    }
  }

  Icon _getDeviceIcon(String? type) {
    if (type == 'PC') {
      return const Icon(Icons.computer_outlined, color: Color(0xFFFFC727), size: 80);
    } else if (type == 'Peripheral') {
      return const Icon(Icons.devices_other_outlined, color: Color(0xFFFFC727), size: 80);
    } else {
      return const Icon(Icons.device_unknown_outlined, color: Color(0xFFFFC727), size: 80);
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

  void _handleAssignedByTap(BuildContext context) {
    final assignedBy = assignedByFullName ?? 'Unassigned';
    final assignedByUid = widget.device['assigned_by'] ?? '';
    
    if (assignedBy == 'Unassigned' || assignedBy.isEmpty || assignedByUid.isEmpty) {
      // Show dialog for unassigned devices
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC727).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFFC727),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'No Staff Assigned',
                  style: TextStyle(
                    fontFamily: 'SansRegular',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: const Text(
              'This device is currently not assigned to any staff member.',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 16,
                color: Color(0xFF6C757D),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF212529),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'SansRegular',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Navigate to staff details page with the UID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceStaffPage(
            staffId: assignedByUid,
            staffName: assignedBy,
            device: widget.device,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.device['type'] ?? 'Unknown';
    final name = widget.device['name'] ?? 'No name';
    final ip = widget.device['ip'] ?? 'N/A';
    final mac = widget.device['mac'] ?? 'N/A';
    final status = (widget.device['status'] ?? 'N/A').toString();
    final location = widget.device['location'] ?? 'N/A';
    final floor = widget.device['floor'] ?? 'Unknown';
    final building = widget.device['building'] ?? 'Unknown';
    final deviceId = widget.device['id']?.toString() ?? '';

    // PC-specific fields
    final brand = widget.device['brand'] ?? '';
    final model = widget.device['model'] ?? '';
    final processor = widget.device['processor'] ?? '';
    final storage = widget.device['storage'] ?? '';

    // Peripheral-specific fields
    final peripheralType = widget.device['peripheral_type'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF212529)),
        title: Text(
          name,
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
            // Device Icon Card
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC727).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _getDeviceIcon(type),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212529),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SansRegular',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Device Information Card
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
                    'Device Information',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212529),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Common fields
                  _buildDetailRow(Icons.category_outlined, 'Type', type),
                  
                  // Brand and Model (common for both PC and Peripheral)
                  if (brand.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.business_outlined, 'Brand', brand),
                  ],
                  if (model.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.info_outline, 'Model', model),
                  ],
                  
                  // PC-specific fields
                  if (type.toLowerCase() == 'pc') ...[
                    if (processor.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.memory_outlined, 'Processor', processor),
                    ],
                    if (storage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.storage_outlined, 'Storage', storage),
                    ],
                  ],
                  
                  // Peripheral-specific fields
                  if (type.toLowerCase() == 'peripheral' && peripheralType.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.devices_other_outlined, 'Peripheral Type', peripheralType),
                  ],
                  
                  // Network Information
                  if (ip != 'N/A' && ip.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.wifi_outlined, 'IP Address', ip),
                  ],
                  if (mac != 'N/A' && mac.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.router_outlined, 'MAC Address', mac),
                  ],
                  
                  // Location Information
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on_outlined, 'Location', location),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.layers_outlined, 'Floor', floor),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.business_outlined, 'Building', building),
                  
                  // Clickable Assigned By Information
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _handleAssignedByTap(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC727).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Color(0xFFFFC727),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assigned By',
                                  style: TextStyle(
                                    fontFamily: 'SansRegular',
                                    fontSize: 12,
                                    color: Color(0xFF6C757D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: isLoadingStaffName
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Color(0xFFFFC727),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              assignedByFullName ?? 'Unassigned',
                                              style: TextStyle(
                                                fontFamily: 'SansRegular',
                                                fontSize: 16,
                                                color: (assignedByFullName == 'Unassigned' || 
                                                        assignedByFullName == null)
                                                    ? const Color(0xFF6C757D)
                                                    : const Color(0xFF212529),
                                                fontWeight: FontWeight.w500,
                                                decoration: (assignedByFullName != 'Unassigned' && 
                                                            assignedByFullName != null)
                                                    ? TextDecoration.underline
                                                    : TextDecoration.none,
                                              ),
                                            ),
                                    ),
                                    if (!isLoadingStaffName && 
                                        assignedByFullName != 'Unassigned' &&
                                        assignedByFullName != null)
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Color(0xFF6C757D),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Modify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeviceEditPage(
                        deviceId: deviceId,
                        deviceData: widget.device,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF212529),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Modify Device',
                  style: TextStyle(
                    fontFamily: 'SansRegular',
                    color: Color(0xFFFFC727),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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