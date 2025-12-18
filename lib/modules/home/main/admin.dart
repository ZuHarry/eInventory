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
import 'package:einventorycomputer/modules/home/screen/trivia/trivia.dart';
import 'package:image_picker/image_picker.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;
  String? _username;
  String? _profileImageUrl;
  String? _staffType;  // ADD THIS

  final List<String> _titles = [
    "Home",
    "Inventory", 
    "Add Device",
    "Scanner",
    "Trivia",
    "Settings",
    "Account",
    "Location",
  ];

  void _navigateToInventory() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  final List<int> _bottomNavIndexes = [0, 1, 3, 6, 7];

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
          _staffType = data?['staffType'];  // ADD THIS
        });
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
      if (index == 5) {
        _loadUserData();
      }
    }
    Navigator.pop(context);
  }

  Widget _buildProfileImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFFC727),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
            ? Image.network(
                _profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person_rounded,
                  size: 24,
                  color: Color(0xFF212529),
                ),
              )
            : const Icon(
                Icons.person_rounded,
                size: 24,
                color: Color(0xFF212529),
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
      return TriviaPage();  // ADD THIS
    case 5:
      return SettingsPage();
    case 6:
      return AccountPage();
    case 7:
      return LocationPage();  // Index changed from 6 to 7
    default:
      return HomePage();
  }
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
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF212529), size: 20),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        width: 260,
        child: SafeArea(
          child: Column(
            children: [
              // Compact Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF212529),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    _buildProfileImage(),
                    const SizedBox(height: 8),
                    Text(
                      _username ?? 'Loading...',
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFFFFC727),
                      ),
                    ),
                    Text(
                      _staffType ?? 'Staff',  // ADD THIS
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 12,
                        color: Color(0xFFADB5BD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 11,
                        color: Color(0xFFADB5BD),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Compact Navigation Items
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _buildDrawerItem(Icons.home_outlined, Icons.home_rounded, "Home", 0),
                      _buildDrawerItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, "Inventory", 1),
                      _buildDrawerItem(Icons.add_box_outlined, Icons.add_box_rounded, "Add Device", 2),
                      _buildDrawerItem(Icons.qr_code_scanner_outlined, Icons.qr_code_scanner_rounded, "Scan", 3),
                      _buildDrawerItem(Icons.quiz_outlined, Icons.quiz_rounded, "Trivia", 4),  // ADD THIS
                      _buildDrawerItem(Icons.settings_outlined, Icons.settings_rounded, "Settings", 5),  // Index changed from 4 to 5
                      _buildDrawerItem(Icons.person_outline_rounded, Icons.person_rounded, "Account", 6),  // Index changed from 5 to 6
                      _buildDrawerItem(Icons.location_city_outlined, Icons.location_city_rounded, "Location", 7),  // Index changed from 6 to 7
                    ],
                  ),
                ),
              ),
              
              // Compact Logout
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF212529),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await _auth.signOut();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFFFC727),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Sign Out",
                              style: TextStyle(
                                fontSize: 14,
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
      body: _getCurrentPage(),
      bottomNavigationBar: isBottomNavPage
          ? Container(
              margin: const EdgeInsets.all(12),
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF212529),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
                    fontSize: 10,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'SansRegular',
                    fontWeight: FontWeight.w400,
                    fontSize: 10,
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
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFC727).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onSelect(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? const Color(0xFFFFC727) : const Color(0xFF6C757D),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF212529) : const Color(0xFF6C757D),
                      fontFamily: 'SansRegular',
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    ),
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
    final isQRScanner = index == 2;
    
    return Icon(
      icon,
      size: isQRScanner ? 22 : 20,
      color: isSelected 
          ? (isQRScanner ? const Color(0xFF007BFF) : const Color(0xFFFFC727))
          : const Color(0xFF6C757D),
    );
  }
}

// Enhanced QR Scanner Page with Gallery Import
class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
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

  Future<void> _pickImageFromGallery() async {
  try {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    
    if (image != null) {
      setState(() {
        isScanning = false;
      });
      
      // Show loading dialog
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

      // Create a temporary controller for image analysis
      final MobileScannerController tempController = MobileScannerController();
      
      // Set up a listener for barcode detection
      bool barcodeFound = false;
      String? detectedCode;
      
      // Listen for barcode detection
      final subscription = tempController.barcodes.listen((BarcodeCapture capture) {
        if (!barcodeFound && capture.barcodes.isNotEmpty) {
          barcodeFound = true;
          detectedCode = capture.barcodes.first.rawValue;
        }
      });
      
      try {
        // Analyze the image
        await tempController.analyzeImage(image.path);
        
        // Wait a bit for the detection to process
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Clean up
        await subscription.cancel();
        tempController.dispose();
        
        Navigator.of(context).pop(); // Close loading dialog
        
        if (barcodeFound && detectedCode != null) {
          _showScannedDataDialog(detectedCode!);
        } else {
          _showNoQRCodeFoundDialog();
        }
        
      } catch (e) {
        await subscription.cancel();
        tempController.dispose();
        Navigator.of(context).pop(); // Close loading dialog
        _showNoQRCodeFoundDialog();
      }
    }
  } catch (e) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(); // Close loading dialog if open
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error reading image: $e'),
        backgroundColor: const Color(0xFFDC3545),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    
    setState(() {
      isScanning = true;
    });
  }
}

  void _showNoQRCodeFoundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'No QR Code Found',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF212529),
            ),
          ),
          content: const Text(
            'No QR code was detected in the selected image. Please try another image.',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 14,
              color: Color(0xFF495057),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isScanning = true;
                });
              },
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF007BFF),
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImageFromGallery();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                foregroundColor: const Color(0xFF212529),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                minimumSize: const Size(80, 36),
              ),
              child: const Text(
                'Pick Another',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showScannedDataDialog(String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Device Scanned',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF212529),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device: $data',
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 14,
                  color: Color(0xFF495057),
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
                  fontSize: 12,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                minimumSize: const Size(80, 36),
              ),
              child: const Text(
                'Find',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _processDeviceData(String data) async {
    try {
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

      final querySnapshot = await FirebaseFirestore.instance
          .collection('devices')
          .where('name', isEqualTo: data.trim())
          .get();

      Navigator.of(context).pop();

      if (querySnapshot.docs.isNotEmpty) {
        final deviceDoc = querySnapshot.docs.first;
        final deviceData = deviceDoc.data();
        deviceData['id'] = deviceDoc.id;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceDetailsPage(device: deviceData),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found: ${deviceData['name']}'),
            backgroundColor: const Color(0xFF28A745),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        _showDeviceNotFoundDialog(data);
      }
      
      setState(() {
        isScanning = true;
        scannedData = null;
      });
      
    } catch (e) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC3545),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      
      setState(() {
        isScanning = true;
        scannedData = null;
      });
    }
  }

  void _showDeviceNotFoundDialog(String deviceName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Not Found',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF212529),
            ),
          ),
          content: Text(
            'Device "$deviceName" not found.',
            style: const TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 14,
              color: Color(0xFF495057),
            ),
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
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                foregroundColor: const Color(0xFF212529),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                minimumSize: const Size(80, 36),
              ),
              child: const Text(
                'Add Device',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
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
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          
          Container(
            decoration: ShapeDecoration(
              shape: QRScannerOverlayShape(
                borderColor: const Color(0xFFFFC727),
                borderRadius: 12,
                borderLength: 24,
                borderWidth: 3,
                cutOutSize: 220,
              ),
            ),
          ),
          
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Position QR code in frame or import from gallery',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'SansRegular',
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => cameraController.toggleTorch(),
                    icon: const Icon(Icons.flash_on, color: Colors.white, size: 24),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library, color: Colors.white, size: 24),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => cameraController.switchCamera(),
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
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

// Simplified QR Scanner Overlay
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