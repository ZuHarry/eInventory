import 'package:flutter/material.dart';

class DeviceDetailsPage extends StatelessWidget {
  final Map<String, dynamic> device;

  const DeviceDetailsPage({super.key, required this.device});

  Icon _getDeviceIcon(String? type) {
    if (type == 'PC') {
      return const Icon(Icons.computer, color: Colors.black, size: 100);
    } else if (type == 'Peripheral') {
      return const Icon(Icons.devices_other, color: Colors.black, size: 100);
    } else {
      return const Icon(Icons.device_unknown, color: Colors.black, size: 100);
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
    final type = device['type'] ?? 'Unknown';
    final name = device['name'] ?? 'No name';
    final ip = device['ip'] ?? 'N/A';
    final mac = device['mac'] ?? 'N/A';
    final status = (device['status'] ?? 'N/A').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFFFC727),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC727),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          name,
          style: const TextStyle(
            fontFamily: 'PoetsenOne',
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(child: _getDeviceIcon(type)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PoetsenOne',
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Name', name),
            const SizedBox(height: 10),
            _buildDetailRow('Type', type),
            const SizedBox(height: 10),
            _buildDetailRow('IP Address', ip),
            const SizedBox(height: 10),
            _buildDetailRow('MAC Address', mac),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'PoetsenOne',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'PoetsenOne',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
