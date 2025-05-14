import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: MinimalHomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

class MinimalHomePage extends StatelessWidget {
  const MinimalHomePage({super.key});

  final List<Map<String, dynamic>> stats = const [
    {
      'title': 'Total PCs',
      'count': 52,
      'icon': Icons.computer,
    },
    {
      'title': 'Peripherals',
      'count': 128,
      'icon': Icons.devices_other,
    },
    {
      'title': 'Online PCs',
      'count': 45,
      'icon': Icons.wifi,
    },
    {
      'title': 'Alerts',
      'count': 3,
      'icon': Icons.warning,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: stats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final item = stats[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'], size: 30, color: Colors.grey[800]),
                  const SizedBox(height: 12),
                  Text(
                    item['count'].toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['title'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
