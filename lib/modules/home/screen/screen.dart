import 'package:flutter/material.dart';
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

  final List<String> _titles = [
    "Home",
    "Inventory",
    "Add Device",
    "Settings",
    "Account",
    "Login",
  ];

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
      HomePage(), // Navigate to Inventory
      InventoryPage(),
      AddDevicePage(),
      SettingsPage(),
      AccountPage(),
      LoginPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: const Text("Menu",
                  style: TextStyle(color: Colors.white, fontSize: 24)),
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
            ListTile(
              title: const Text("Login"),
              leading: const Icon(Icons.login),
              onTap: () => _onSelect(5),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
