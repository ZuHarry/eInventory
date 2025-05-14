import 'package:flutter/material.dart';
import 'package:einventorycomputer/services/auth.dart';


class HomePage extends StatelessWidget {
  // final VoidCallback onAddDevice;

  // const HomePage({super.key, required this.onAddDevice});
  final AuthService _auth = AuthService();

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

  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex('7BAFBB'),
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
        backgroundColor: hex('7BAFBB'),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
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
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: hex('153B6D')),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hex('153B6D'),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async{
                  await _auth.signOut();

                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
