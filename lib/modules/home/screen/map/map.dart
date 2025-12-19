import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:einventorycomputer/modules/home/screen/devices/device_details.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _devicesWithLocation = [];
  bool _isLoading = true;
  String? _selectedLocation;
  LatLng? _currentLocation;
  bool _isTrackingLocation = false;
  Map<String, LatLng> _locationCoordinates = {}; // ADD THIS LINE
  
  // Default center (Seremban, Malaysia)
  final LatLng _defaultCenter = LatLng(2.7297, 101.9381);
  final double _defaultZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _loadDevicesWithLocation();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDialog();
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedForeverDialog();
      return;
    }

    // Permission granted, get current location
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isTrackingLocation = true;
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isTrackingLocation = false;
      });

      // Move map to current location
      _mapController.move(_currentLocation!, 15.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location found!'),
          backgroundColor: const Color(0xFF28A745),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isTrackingLocation = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: const Color(0xFFDC3545),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Location Service Disabled',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF212529),
            ),
          ),
          content: const Text(
            'Please enable location services to see your current location on the map.',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 14,
              color: Color(0xFF495057),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF6C757D),
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                foregroundColor: const Color(0xFF212529),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                minimumSize: const Size(80, 36),
              ),
              child: const Text(
                'Open Settings',
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

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Location Permission Required',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF212529),
            ),
          ),
          content: const Text(
            'This app needs location permission to show your current position on the map.',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 14,
              color: Color(0xFF495057),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
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
                _checkLocationPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                foregroundColor: const Color(0xFF212529),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                minimumSize: const Size(80, 36),
              ),
              child: const Text(
                'Grant Permission',
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

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Location Permission Blocked',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF212529),
            ),
          ),
          content: const Text(
            'Location permission has been permanently denied. Please enable it in app settings.',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 14,
              color: Color(0xFF495057),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF6C757D),
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                foregroundColor: const Color(0xFF212529),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                minimumSize: const Size(80, 36),
              ),
              child: const Text(
                'Open Settings',
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

  Future<void> _loadDevicesWithLocation() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Load all locations with coordinates from buildings collection
    final buildingsSnapshot = await FirebaseFirestore.instance
        .collection('buildings')
        .get();

    Map<String, LatLng> locationCoordinates = {};

    for (var buildingDoc in buildingsSnapshot.docs) {
      final locationsSnapshot = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingDoc.id)
          .collection('locations')
          .get();

      for (var locationDoc in locationsSnapshot.docs) {
        final data = locationDoc.data();
        final latitude = data['latitude'] as double?;
        final longitude = data['longitude'] as double?;
        final locationName = data['name'] as String?;

        if (latitude != null && longitude != null && locationName != null) {
          // Create a full location string (Building - Location)
          final fullLocation = '${buildingDoc.data()['name']} - $locationName';
          locationCoordinates[fullLocation] = LatLng(latitude, longitude);
          
          // Also store just the location name for flexibility
          locationCoordinates[locationName] = LatLng(latitude, longitude);
        }
      }
    }

    // Load devices
    final querySnapshot = await FirebaseFirestore.instance
        .collection('devices')
        .get();

    List<Map<String, dynamic>> devicesWithLoc = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final location = data['location'] as String?;
      
      // Only include devices that have a location set and coordinates available
      if (location != null && location.isNotEmpty && location != 'Not specified') {
        devicesWithLoc.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'location': location,
          'category': data['category'] ?? 'Other',
          'status': data['status'] ?? 'Unknown',
          'model': data['model'] ?? '',
          'serialNumber': data['serialNumber'] ?? '',
          'coordinates': locationCoordinates[location], // Add coordinates
          ...data,
        });
      }
    }

    setState(() {
      _devicesWithLocation = devicesWithLoc;
      _locationCoordinates = locationCoordinates;
      _isLoading = false;
    });
  } catch (e) {
    print('Error loading devices: $e');
    setState(() {
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading devices: $e'),
        backgroundColor: const Color(0xFFDC3545),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF007BFF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.my_location,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      );
    }

    // Group devices by location
    Map<String, List<Map<String, dynamic>>> groupedDevices = {};
    
    for (var device in _devicesWithLocation) {
      final location = device['location'] as String;
      if (!groupedDevices.containsKey(location)) {
        groupedDevices[location] = [];
      }
      groupedDevices[location]!.add(device);
    }

    // Create markers for each location
    int locationIndex = 0;

    groupedDevices.forEach((location, devices) {
      final LatLng position = devices.first['coordinates'] ?? _getLocationCoordinates(location, locationIndex);
      locationIndex++;

      markers.add(
        Marker(
          point: position,
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _showLocationDevices(location, devices, position),
            child: Container(
              decoration: BoxDecoration(
                color: _selectedLocation == location 
                    ? const Color(0xFFFFC727) 
                    : const Color(0xFF28A745),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 28,
                    ),
                    if (devices.length > 1)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC3545),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${devices.length}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });

    return markers;
  }

  // Helper method to generate coordinates (replace with actual location coordinates)
  LatLng _getLocationCoordinates(String location, int index) {
  // Try to get actual coordinates from the map
  if (_locationCoordinates.containsKey(location)) {
    return _locationCoordinates[location]!;
  }
  
  // Fallback: distribute markers around the default center if coordinates not found
  final double offsetLat = (index % 3 - 1) * 0.01;
  final double offsetLng = ((index ~/ 3) % 3 - 1) * 0.01;
  
  return LatLng(
    _defaultCenter.latitude + offsetLat,
    _defaultCenter.longitude + offsetLng,
  );
}

  void _showLocationDevices(String location, List<Map<String, dynamic>> devices, LatLng position) {
    setState(() {
      _selectedLocation = location;
    });

    _mapController.move(position, 15.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEE2E6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF28A745),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212529),
                        ),
                      ),
                    ),
                    Text(
                      '${devices.length} ${devices.length == 1 ? 'Device' : 'Devices'}',
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 14,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return _buildDeviceCard(device);
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        _selectedLocation = null;
      });
    });
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    Color statusColor;
    switch (device['status']?.toLowerCase() ?? '') {
      case 'active':
        statusColor = const Color(0xFF28A745);
        break;
      case 'maintenance':
        statusColor = const Color(0xFFFFC107);
        break;
      case 'inactive':
        statusColor = const Color(0xFFDC3545);
        break;
      default:
        statusColor = const Color(0xFF6C757D);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDEE2E6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceDetailsPage(device: device),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(device['category'] ?? ''),
                    color: const Color(0xFF007BFF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212529),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device['model'] ?? 'No model',
                        style: const TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 12,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    device['status'] ?? 'Unknown',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF6C757D),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'laptop':
        return Icons.laptop;
      case 'desktop':
        return Icons.computer;
      case 'monitor':
        return Icons.monitor;
      case 'printer':
        return Icons.print;
      case 'server':
        return Icons.dns;
      case 'networking':
        return Icons.router;
      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC727)),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _currentLocation ?? _defaultCenter,
                    zoom: _defaultZoom,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.einventorycomputer',
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(),
                    ),
                  ],
                ),
                
                // Top Info Card
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF007BFF),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_devicesWithLocation.length} devices with locations',
                            style: const TextStyle(
                              fontFamily: 'SansRegular',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212529),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _loadDevicesWithLocation,
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFF007BFF),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Current Location Button
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _isTrackingLocation ? null : _getCurrentLocation,
                    backgroundColor: const Color(0xFFFFC727),
                    child: _isTrackingLocation
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF212529)),
                            ),
                          )
                        : const Icon(
                            Icons.my_location,
                            color: Color(0xFF212529),
                          ),
                  ),
                ),

                // Empty State
                if (_devicesWithLocation.isEmpty)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(24),
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
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Color(0xFF6C757D),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No devices with locations',
                            style: TextStyle(
                              fontFamily: 'SansRegular',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212529),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add locations to your devices to see them on the map',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SansRegular',
                              fontSize: 14,
                              color: Color(0xFF6C757D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}