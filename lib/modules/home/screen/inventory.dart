import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  Icon _getDeviceIcon(String? type) {
    if (type == 'PC') {
      return const Icon(Icons.computer, color: Colors.blue);
    } else if (type == 'Peripheral') {
      return const Icon(Icons.devices_other, color: Colors.green);
    } else {
      return const Icon(Icons.device_unknown, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Inventory')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('devices')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final grouped = <String, List<Map<String, dynamic>>>{};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? 'No name').toString();
            final key = name[0].toUpperCase();

            if (!grouped.containsKey(key)) grouped[key] = [];
            grouped[key]!.add(data);
          }

          return ListView(
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  ...entry.value.map((data) {
                    final type = data['type'] ?? 'Unknown';
                    return ListTile(
                      leading: _getDeviceIcon(type),
                      title: Text(data['name'] ?? 'No name'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: $type'),
                          Text('IP: ${data['ip'] ?? 'N/A'}'),
                          Text('MAC: ${data['mac'] ?? 'N/A'}'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
