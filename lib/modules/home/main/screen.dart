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

class _ScreenPageState extends State<ScreenPage> with TickerProviderStateMixin {
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;
  String? _username;
  late AnimationController _drawerAnimationController;

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
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontFamily: 'SansRegular',
            color: Color(0xFF212529),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF212529)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF212529),
                size: 20,
              ),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        elevation: 0,
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF212529),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC727),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC727).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: Color(0xFF212529),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _username ?? 'Loading...',
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xFFFFC727),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 14,
                        color: Color(0xFFADB5BD),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Navigation Items
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildDrawerItem(Icons.home_outlined, Icons.home_rounded, "Home", 0),
                      _buildDrawerItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, "Inventory", 1),
                      _buildDrawerItem(Icons.add_box_outlined, Icons.add_box_rounded, "Add Device", 2),
                      _buildDrawerItem(Icons.settings_outlined, Icons.settings_rounded, "Settings", 3),
                      _buildDrawerItem(Icons.person_outline_rounded, Icons.person_rounded, "Account", 4),
                      _buildDrawerItem(Icons.location_city_outlined, Icons.location_city_rounded, "Location", 5),
                    ],
                  ),
                ),
              ),
              
              // Logout Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF212529), Color(0xFF343A40)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await _auth.signOut();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC727).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFFFC727),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Sign Out",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFC727),
                                fontFamily: 'SansRegular',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: isBottomNavPage
          ? Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF212529),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BottomNavigationBar(
                  currentIndex: safeCurrentIndex,
                  selectedItemColor: const Color(0xFFFFC727),
                  unselectedItemColor: const Color(0xFF6C757D),
                  backgroundColor: const Color(0xFF212529),
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = _bottomNavIndexes[index];
                    });
                  },
                  selectedLabelStyle: const TextStyle(
                    fontFamily: 'SansRegular',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'SansRegular',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: _buildBottomNavIcon(Icons.home_outlined, 0, safeCurrentIndex),
                      activeIcon: _buildBottomNavIcon(Icons.home_rounded, 0, safeCurrentIndex),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: _buildBottomNavIcon(Icons.inventory_2_outlined, 1, safeCurrentIndex),
                      activeIcon: _buildBottomNavIcon(Icons.inventory_2_rounded, 1, safeCurrentIndex),
                      label: "Inventory",
                    ),
                    BottomNavigationBarItem(
                      icon: _buildBottomNavIcon(Icons.person_outline_rounded, 2, safeCurrentIndex),
                      activeIcon: _buildBottomNavIcon(Icons.person_rounded, 2, safeCurrentIndex),
                      label: "Account",
                    ),
                    BottomNavigationBarItem(
                      icon: _buildBottomNavIcon(Icons.location_city_outlined, 3, safeCurrentIndex),
                      activeIcon: _buildBottomNavIcon(Icons.location_city_rounded, 3, safeCurrentIndex),
                      label: "Location",
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDrawerItem(IconData icon, IconData activeIcon, String title, int index) {
    final isSelected = _selectedIndex == index;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFC727).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onSelect(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFFFFC727) 
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected 
                        ? const Color(0xFF212529) 
                        : const Color(0xFF6C757D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF212529) 
                          : const Color(0xFF6C757D),
                      fontFamily: 'SansRegular',
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC727),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, int index, int currentIndex) {
    final isSelected = index == currentIndex;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFFFFC727).withOpacity(0.2) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 24,
        color: isSelected 
            ? const Color(0xFFFFC727) 
            : const Color(0xFF6C757D),
      ),
    );
  }
}