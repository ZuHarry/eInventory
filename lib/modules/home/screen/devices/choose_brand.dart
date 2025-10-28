import 'package:flutter/material.dart';

class ChooseBrandPage extends StatelessWidget {
  const ChooseBrandPage({super.key});

  // Hardcoded list of popular brands
  static const List<String> brands = [
    'ASUS',
    'HP',
    'Dell',
    'Lenovo',
    'Acer',
    'Apple',
    'MSI',
    'Samsung',
    'Toshiba',
    'Microsoft',
    'Razer',
    'Alienware',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        title: const Text(
          'Choose Brand',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: brands.length,
        itemBuilder: (context, index) {
          final brand = brands[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                Navigator.pop(context, brand);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(
                    brand,
                    style: const TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212529),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}