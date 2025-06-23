import 'package:flutter/material.dart';
import 'device_edit_page.dart'; // Make sure this file exists in the same folder or update the import path accordingly.


class DeviceDetailsPage extends StatelessWidget {
  final Map<String, dynamic> device;

  const DeviceDetailsPage({super.key, required this.device});

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

  @override
  Widget build(BuildContext context) {
    final type = device['type'] ?? 'Unknown';
    final name = device['name'] ?? 'No name';
    final ip = device['ip'] ?? 'N/A';
    final mac = device['mac'] ?? 'N/A';
    final status = (device['status'] ?? 'N/A').toString();
    final location = device['location'] ?? 'N/A';
    final floor = device['floor'] ?? 'Unknown';
    final building = device['building'] ?? 'Unknown';
    final deviceId = device['id']?.toString() ?? '';

    // PC-specific fields
    final brand = device['brand'] ?? '';
    final model = device['model'] ?? '';
    final processor = device['processor'] ?? '';
    final storage = device['storage'] ?? '';

    // Peripheral-specific fields
    final peripheralType = device['peripheral_type'] ?? '';

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
                        deviceData: device,
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