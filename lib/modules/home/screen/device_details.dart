import 'package:flutter/material.dart';

class DeviceDetailsPage extends StatelessWidget {
  final Map<String, dynamic> device;

  const DeviceDetailsPage({super.key, required this.device});

  Icon _getDeviceIcon(String? type) {
    if (type == 'PC') {
      return const Icon(Icons.computer, color: Colors.blue, size: 100);
    } else if (type == 'Peripheral') {
      return const Icon(Icons.devices_other, color: Colors.green, size: 100);
    } else {
      return const Icon(Icons.device_unknown, color: Colors.grey, size: 100);
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
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(child: _getDeviceIcon(type)),
            const SizedBox(height: 24),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(status),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text('Name: $name', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Type: $type'),
            const SizedBox(height: 8),
            Text('IP Address: $ip'),
            const SizedBox(height: 8),
            Text('MAC Address: $mac'),
          ],
        ),
      ),
    );
  }
}
