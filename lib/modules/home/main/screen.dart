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
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:einventorycomputer/modules/home/screen/devices/device_details.dart';

class ScreenPage extends StatefulWidget {
  @override
  _ScreenPageState createState() => _ScreenPageState();
}

class _ScreenPageState extends State<ScreenPage> with TickerProviderStateMixin {
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;
  String? _username;
  String? _profileImageUrl;
  late AnimationController _drawerAnimationController;
  late AnimationController _fabAnimationController;

  final List<String> _titles = [
    "Home",
    "Inventory",
    "Add Device",
    "QR Scanner",
    "Settings",
    "Account",
    "Location",
  ];

  // Method to navigate to inventory page
  void _navigateToInventory() {
    setState(() {
      _selectedIndex = 1; // Inventory page index
    });
  }

  // Define which indices are in the bottom navigation
  
  // Update your _bottomNavIndexes to include the QR Scanner in the middle
  final List<int> _bottomNavIndexes = [0, 1, 3, 5, 6]; // Added QR Scanner (index 3) in the middle

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data();
          setState(() {
            _username = data?['username'] ?? 'User';
            _profileImageUrl = data?['profileImageUrl'];
          });
          print('Profile image URL: $_profileImageUrl');
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  void _onSelect(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      // Refresh user data when navigating to Account page
      if (index == 5) { // Account page index (updated)
        _loadUserData();
      }
    }
    Navigator.pop(context); // Close drawer
  }

  void _onFabPressed() {
    // Add a small animation when pressed
    _fabAnimationController.reverse().then((_) {
      _fabAnimationController.forward();
    });
    
    setState(() {
      _selectedIndex = 2; // Navigate to Add Device page (index 2)
    });
  }

  // New method to handle QR scanner FAB press
  void _onQRScannerPressed() {
    _fabAnimationController.reverse().then((_) {
      _fabAnimationController.forward();
    });
    
    setState(() {
      _selectedIndex = 3; // Navigate to QR Scanner page (index 3)
    });
  }

  Widget _buildProfileImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC727).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 80,
          height: 80,
          color: const Color(0xFFFFC727),
          child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
              ? Image.network(
                  _profileImageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: Color(0xFF212529),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF212529)),
                        strokeWidth: 2,
                      ),
                    );
                  },
                )
              : const Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: Color(0xFF212529),
                ),
        ),
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return HomePage();
      case 1:
        return InventoryPage();
      case 2:
        return AddDevicePage(onNavigateToInventory: _navigateToInventory);
      case 3:
        return QRScannerPage();
      case 4:
        return SettingsPage();
      case 5:
        return AccountPage();
      case 6:
        return LocationPage();
      default:
        return HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBottomNavPage = _bottomNavIndexes.contains(_selectedIndex);
    final safeCurrentIndex = _bottomNavIndexes.indexWhere((i) => i == _selectedIndex);
    final isQRScannerPage = _selectedIndex == 3;

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
                    _buildProfileImage(),
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
                      _buildDrawerItem(Icons.qr_code_scanner_outlined, Icons.qr_code_scanner_rounded, "QR Scanner", 3),
                      _buildDrawerItem(Icons.settings_outlined, Icons.settings_rounded, "Settings", 4),
                      _buildDrawerItem(Icons.person_outline_rounded, Icons.person_rounded, "Account", 5),
                      _buildDrawerItem(Icons.location_city_outlined, Icons.location_city_rounded, "Location", 6),
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
      // Replace the existing Stack with floating action buttons in your build method with this:

      // Remove the FAB positioning code from the Stack in your build method:
      body: Stack(
        children: [
          _getCurrentPage(),
          // Only keep the Add Device FAB in the top-right corner
          if (isBottomNavPage && _selectedIndex != 3) // Don't show when QR scanner is active
            Positioned(
              bottom: 5,
              right: 24,
              child: ScaleTransition(
                scale: _fabAnimationController,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC727), Color(0xFFFFD54F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC727).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _onFabPressed,
                      child: Container(
                        width: 56,
                        height: 56,
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF212529),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),


      // Update your bottom navigation bar to include QR Scanner as the middle item:
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
                    // QR Scanner in the middle
                    BottomNavigationBarItem(
                      icon: _buildBottomNavIcon(Icons.qr_code_scanner_outlined, 2, safeCurrentIndex),
                      activeIcon: _buildBottomNavIcon(Icons.qr_code_scanner_rounded, 2, safeCurrentIndex),
                      label: "Scan",
                    ),
                    BottomNavigationBarItem(
                      icon: _buildBottomNavIcon(Icons.person_outline_rounded, 3, safeCurrentIndex),
                      activeIcon: _buildBottomNavIcon(Icons.person_rounded, 3, safeCurrentIndex),
                      label: "Account",
                    ),
                    BottomNavigationBarItem(
                      icon: _buildBottomNavIcon(Icons.location_city_outlined, 4, safeCurrentIndex),
                      activeIcon: _buildBottomNavIcon(Icons.location_city_rounded, 4, safeCurrentIndex),
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

  // Optional: You can also create a special styling for the QR Scanner icon to make it stand out
  Widget _buildBottomNavIcon(IconData icon, int index, int currentIndex) {
    final isSelected = index == currentIndex;
    final isQRScanner = index == 2; // QR Scanner is at index 2 in bottom nav
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected 
            ? (isQRScanner ? const Color(0xFF007BFF).withOpacity(0.2) : const Color(0xFFFFC727).withOpacity(0.2))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: isQRScanner ? 26 : 24, // Make QR scanner icon slightly larger
        color: isSelected 
            ? (isQRScanner ? const Color(0xFF007BFF) : const Color(0xFFFFC727))
            : const Color(0xFF6C757D),
      ),
    );
  }
}

// QR Scanner Page Widget
class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  String? scannedData;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          isScanning = false;
          scannedData = code;
        });
        _showScannedDataDialog(code);
      }
    }
  }

  // Also modify the _showScannedDataDialog method to make the Process button more intuitive
void _showScannedDataDialog(String data) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC727).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_rounded,
                color: Color(0xFF212529),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'QR Code Scanned',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF212529),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Name:',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF212529),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE9ECEF),
                  width: 1,
                ),
              ),
              child: Text(
                data,
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF495057),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap "Find Device" to search for this device in your inventory.',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 14,
                color: Color(0xFF6C757D),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isScanning = true;
                scannedData = null;
              });
            },
            child: const Text(
              'Scan Again',
              style: TextStyle(
                fontFamily: 'SansRegular',
                color: Color(0xFF6C757D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processDeviceData(data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC727),
              foregroundColor: const Color(0xFF212529),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Find Device',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}

  // Replace the _processDeviceData method in your QRScannerPage class
void _processDeviceData(String data) async {
  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC727)),
          ),
        );
      },
    );

    // Search for device in Firestore
    final querySnapshot = await FirebaseFirestore.instance
        .collection('devices')
        .where('name', isEqualTo: data.trim())
        .get();

    // Close loading dialog
    Navigator.of(context).pop();

    if (querySnapshot.docs.isNotEmpty) {
      // Device found - get the first matching device
      final deviceDoc = querySnapshot.docs.first;
      final deviceData = deviceDoc.data();
      deviceData['id'] = deviceDoc.id; // Add document ID to the data

      // Navigate to device details page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceDetailsPage(device: deviceData),
        ),
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device found: ${deviceData['name']}'),
          backgroundColor: const Color(0xFF28A745),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      // Device not found
      _showDeviceNotFoundDialog(data);
    }
    
    // Reset scanner state
    setState(() {
      isScanning = true;
      scannedData = null;
    });
    
  } catch (e) {
    // Close loading dialog if still open
    Navigator.of(context).pop();
    
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error searching for device: $e'),
        backgroundColor: const Color(0xFFDC3545),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    
    // Reset scanner state
    setState(() {
      isScanning = true;
      scannedData = null;
    });
  }
}



// Add this new method to show device not found dialog
void _showDeviceNotFoundDialog(String deviceName) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDC3545).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFDC3545),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Device Not Found',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF212529),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No device found with the name "$deviceName".',
              style: const TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 16,
                color: Color(0xFF495057),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please check the QR code or make sure the device is registered in the system.',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 14,
                color: Color(0xFF6C757D),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Scan Again',
              style: TextStyle(
                fontFamily: 'SansRegular',
                color: Color(0xFF007BFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to Add Device page with pre-filled name
              // You can modify this based on your app's navigation structure
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC727),
              foregroundColor: const Color(0xFF212529),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add Device',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          
          // Overlay with scanning frame
          Container(
            decoration: ShapeDecoration(
              shape: QRScannerOverlayShape(
                borderColor: const Color(0xFFFFC727),
                borderRadius: 16,
                borderLength: 30,
                borderWidth: 4,
                cutOutSize: 250,
              ),
            ),
          ),
          
          // Top instruction
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Position the QR code within the frame to scan device details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Flash toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    onPressed: () => cameraController.toggleTorch(),
                    icon: const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                
                // Switch camera
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    onPressed: () => cameraController.switchCamera(),
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom QR Scanner Overlay Shape
class QRScannerOverlayShape extends ShapeBorder {
  const QRScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path outerPath = Path()..addRect(rect);
    Path innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
        Radius.circular(borderRadius),
      ));
    return Path.combine(PathOperation.difference, outerPath, innerPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    // Draw border corners
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final double halfBorderLength = borderLength / 2;
    final Rect cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.top + halfBorderLength)
        ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)
        ..quadraticBezierTo(cutOutRect.left, cutOutRect.top, cutOutRect.left + borderRadius, cutOutRect.top)
        ..lineTo(cutOutRect.left + halfBorderLength, cutOutRect.top),
      borderPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - halfBorderLength, cutOutRect.top)
        ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
        ..quadraticBezierTo(cutOutRect.right, cutOutRect.top, cutOutRect.right, cutOutRect.top + borderRadius)
        ..lineTo(cutOutRect.right, cutOutRect.top + halfBorderLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.bottom - halfBorderLength)
        ..lineTo(cutOutRect.left, cutOutRect.bottom - borderRadius)
        ..quadraticBezierTo(cutOutRect.left, cutOutRect.bottom, cutOutRect.left + borderRadius, cutOutRect.bottom)
        ..lineTo(cutOutRect.left + halfBorderLength, cutOutRect.bottom),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - halfBorderLength, cutOutRect.bottom)
        ..lineTo(cutOutRect.right - borderRadius, cutOutRect.bottom)
        ..quadraticBezierTo(cutOutRect.right, cutOutRect.bottom, cutOutRect.right, cutOutRect.bottom - borderRadius)
        ..lineTo(cutOutRect.right, cutOutRect.bottom - halfBorderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => QRScannerOverlayShape(
        borderColor: borderColor,
        borderWidth: borderWidth,
        overlayColor: overlayColor,
        borderRadius: borderRadius,
        borderLength: borderLength,
        cutOutSize: cutOutSize,
      );
}