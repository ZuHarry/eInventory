import 'package:einventorycomputer/modules/home/screen/location/location.dart';
import 'package:einventorycomputer/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einventorycomputer/modules/home/screen/home.dart';
import 'package:einventorycomputer/modules/home/screen/devices/inventory.dart';
import 'package:einventorycomputer/modules/home/screen/settings/settings.dart';
import 'package:einventorycomputer/modules/home/screen/user/account.dart';
import 'package:einventorycomputer/modules/home/screen/devices/add_device.dart';

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

  final List<Widget> _pages = [
    HomePage(),
    InventoryPage(),
    AddDevicePage(),
    SettingsPage(),
    AccountPage(),
    LocationPage(),
  ];

  // Define which indices are in the bottom navigation
  final List<int> _bottomNavIndexes = [0, 1, 4, 5];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
    final isBottomNavPage = _bottomNavIndexes.contains(_selectedIndex);
    final safeCurrentIndex = _bottomNavIndexes.indexWhere((i) => i == _selectedIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontFamily: 'SansRegular',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
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
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 14,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 42, color: Colors.black),
              ),
              decoration: const BoxDecoration(color: Colors.black),
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
                  backgroundColor: Colors.black,
                  foregroundColor: const Color(0xFFFFC727),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await _auth.signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Log Out",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFC727),
                    fontFamily: 'SansRegular',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: isBottomNavPage
          ? Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 16.0),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(24),
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BottomNavigationBar(
                    currentIndex: safeCurrentIndex,
                    selectedItemColor: Colors.yellow,
                    unselectedItemColor: Colors.yellowAccent,
                    backgroundColor: Colors.black,
                    type: BottomNavigationBarType.fixed,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = _bottomNavIndexes[index];
                      });
                    },
                    selectedLabelStyle: const TextStyle(fontFamily: 'SansRegular'),
                    unselectedLabelStyle: const TextStyle(fontFamily: 'SansRegular'),
                    items: const [
                      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                      BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Inventory"),
                      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
                      BottomNavigationBarItem(icon: Icon(Icons.location_city), label: "Location"),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xFF7BAFBB).withOpacity(0.2),
      leading: Icon(icon, color: isSelected ? Colors.black : Colors.black54),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'SansRegular',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => _onSelect(index),
    );
  }
}
