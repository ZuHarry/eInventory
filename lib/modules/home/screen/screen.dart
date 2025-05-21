import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:einventorycomputer/modules/home/screen/home.dart';
import 'package:einventorycomputer/modules/home/screen/inventory.dart';
import 'package:einventorycomputer/modules/home/screen/settings.dart';
import 'package:einventorycomputer/modules/home/screen/account.dart';
import 'package:einventorycomputer/modules/home/screen/add_device.dart';
import 'package:einventorycomputer/modules/authentication/screen/login.dart';

class ScreenPage extends StatefulWidget {
  @override
  _ScreenPageState createState() => _ScreenPageState();
}

class _ScreenPageState extends State<ScreenPage> {
  int _selectedIndex = 0;
  String? _username;

  final List<String> _titles = [
    "Home",
    "Inventory",
    "Add Device",
    "Settings",
    "Account",
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
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      HomePage(),
      InventoryPage(),
      AddDevicePage(),
      SettingsPage(),
      AccountPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_username ?? 'Loading...'),
              accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 42, color: Colors.blue),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              title: const Text("Home"),
              leading: const Icon(Icons.home),
              onTap: () => _onSelect(0),
            ),
            ListTile(
              title: const Text("Inventory"),
              leading: const Icon(Icons.inventory),
              onTap: () => _onSelect(1),
            ),
            ListTile(
              title: const Text("Add Device"),
              leading: const Icon(Icons.inventory_2),
              onTap: () => _onSelect(2),
            ),
            ListTile(
              title: const Text("Settings"),
              leading: const Icon(Icons.settings),
              onTap: () => _onSelect(3),
            ),
            ListTile(
              title: const Text("Account"),
              leading: const Icon(Icons.person),
              onTap: () => _onSelect(4),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
