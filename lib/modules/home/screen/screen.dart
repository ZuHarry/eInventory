import 'package:einventorycomputer/modules/home/screen/location.dart';
import 'package:einventorycomputer/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einventorycomputer/modules/home/screen/home.dart';
import 'package:einventorycomputer/modules/home/screen/inventory.dart';
import 'package:einventorycomputer/modules/home/screen/settings.dart';
import 'package:einventorycomputer/modules/home/screen/account.dart';
import 'package:einventorycomputer/modules/home/screen/add_device.dart';

class ScreenPage extends StatefulWidget {
  @override
  _ScreenPageState createState() => _ScreenPageState();
}

class _ScreenPageState extends State<ScreenPage> {
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;
  String? _username;

  final List<String> _titles = [
    "Home",
    "Inventory",
    "Add Device",
    "Settings",
    "Account",
    "Location",
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _username = doc.data()?['username'] ?? 'User';
        });
      }
    }
  }

  void _onSelect(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
    Navigator.pop(context); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      HomePage(),
      InventoryPage(),
      AddDevicePage(),
      SettingsPage(),
      AccountPage(),
      LocationPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontFamily: 'PoetsenOne',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFFFC727),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _username ?? 'Loading...',
                style: const TextStyle(
                  fontFamily: 'PoetsenOne',
                  fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: const TextStyle(
                  fontFamily: 'PoetsenOne',
                  fontSize: 14),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 42, color: Color.fromARGB(255, 0, 0, 0)),
              ),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            _buildDrawerItem(Icons.home, "Home", 0),
            _buildDrawerItem(Icons.inventory, "Inventory", 1),
            _buildDrawerItem(Icons.inventory_2, "Add Device", 2),
            _buildDrawerItem(Icons.settings, "Settings", 3),
            _buildDrawerItem(Icons.person, "Account", 4),
            _buildDrawerItem(Icons.location_city, "Location", 5),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: const Color(0xFFFFC727),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                    await _auth.signOut();
                  },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                label: const Text(
                  "Log Out",
                  style: TextStyle(
                    fontSize: 18,            // Font size
                    fontWeight: FontWeight.bold,  // Font weight
                    color: Color(0xFFFFC727),     // Text color (optional here since foregroundColor handles it)
                    fontFamily: 'PoetsenOne',     // Custom font (optional)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xFF7BAFBB).withOpacity(0.2),
      leading: Icon(icon, color: isSelected ? const Color.fromARGB(255, 0, 2, 4) : Colors.black),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color.fromARGB(255, 0, 0, 0) : Colors.black,
          fontFamily: 'PoetsenOne',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => _onSelect(index),
    );
  }
}
