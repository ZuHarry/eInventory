import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class AddLocationMapPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const AddLocationMapPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<AddLocationMapPage> createState() => _AddLocationMapPageState();
}

class _AddLocationMapPageState extends State<AddLocationMapPage> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  LatLng _defaultLocation = LatLng(2.7253, 101.9379); // Default: Seremban
  bool _isLoadingLocation = false;
  
  // Map tile providers - you can switch between these
  String _currentTileProvider = 'openstreetmap';
  
  String get _tileUrl {
    switch (_currentTileProvider) {
      case 'openstreetmap':
        // OpenStreetMap - Standard
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'cartodb':
        // CartoDB - Light theme, no registration needed
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
      case 'cartodb_dark':
        // CartoDB - Dark theme
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      default:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
    }
  }
  
  List<String> get _subdomains {
    if (_currentTileProvider.contains('cartodb')) {
      return ['a', 'b', 'c', 'd'];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    // If coordinates were previously set, use them
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _defaultLocation = _selectedLocation!;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedForeverDialog();
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _defaultLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Move map to current location
      _mapController.move(_defaultLocation, 17);
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Please enable location services to use this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is needed to show your current position on the map.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
          title: const Text('Location Permission Denied'),
          content: const Text(
            'Location permission has been permanently denied. Please enable it in app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Map style switcher
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers),
            tooltip: 'Change Map Style',
            onSelected: (String value) {
              setState(() {
                _currentTileProvider = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'cartodb',
                child: Row(
                  children: [
                    Icon(Icons.map, size: 20),
                    SizedBox(width: 8),
                    Text('Light Map'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cartodb_dark',
                child: Row(
                  children: [
                    Icon(Icons.dark_mode, size: 20),
                    SizedBox(width: 8),
                    Text('Dark Map'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'openstreetmap',
                child: Row(
                  children: [
                    Icon(Icons.terrain, size: 20),
                    SizedBox(width: 8),
                    Text('Standard Map'),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoadingLocation)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
              tooltip: 'Get Current Location',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultLocation,
              initialZoom: 17,
              onTap: _onMapTapped,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                subdomains: _subdomains,
                userAgentPackageName: 'com.yourcompany.locationapp', // Change to your package name
                maxZoom: 19,
                maxNativeZoom: 19,
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        size: 50,
                        color: Color(0xFF81D4FA),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Info card at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: const Color(0xFF212529),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF81D4FA),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tap on the map to select location',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'SansRegular',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      Text(
                        'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'SansRegular',
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'SansRegular',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Zoom controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: const Color(0xFF212529),
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: const Color(0xFF212529),
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ],
            ),
          ),
          // Confirm button at bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedLocation != null
                    ? const Color(0xFF81D4FA)
                    : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedLocation != null
                        ? 'Confirm Location'
                        : 'Select a Location',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SansRegular',
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}