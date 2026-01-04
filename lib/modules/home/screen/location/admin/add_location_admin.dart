import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:einventorycomputer/modules/home/screen/location/add_location_map.dart';


class AddLocationAdminPage extends StatefulWidget {
  const AddLocationAdminPage({super.key});

  @override
  State<AddLocationAdminPage> createState() => _AddLocationAdminPageState();
}

class _AddLocationAdminPageState extends State<AddLocationAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _locationNameController = TextEditingController();
  String _floor = 'Ground Floor';
  String _locationType = 'Lecture Room';
  String? _imageUrl;
  File? _selectedImage;
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;

  // Building selection variables
  String? _selectedBuildingId;
  String? _selectedBuildingName;
  List<Map<String, String>> _buildings = [];
  bool _isLoadingBuildings = true;

  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  // Load all buildings from Firestore
  Future<void> _loadBuildings() async {
    try {
      final buildingsSnapshot = await FirebaseFirestore.instance
          .collection('buildings')
          .orderBy('name')
          .get();
      
      setState(() {
        _buildings = buildingsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc.data()['name'] as String? ?? 'Unknown',
          };
        }).toList();
        _isLoadingBuildings = false;
      });
    } catch (e) {
      print('Error loading buildings: $e');
      setState(() {
        _isLoadingBuildings = false;
      });
    }
  }

  void _showManualCoordinateDialog() {
    final latController = TextEditingController(
      text: _latitude?.toString() ?? ''
    );
    final lngController = TextEditingController(
      text: _longitude?.toString() ?? ''
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212529),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF81D4FA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pin_drop,
                  color: Color(0xFF81D4FA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Enter Coordinates',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g., 2.7253',
                  labelStyle: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'SansRegular',
                  ),
                  hintStyle: TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF81D4FA), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lngController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g., 101.9379',
                  labelStyle: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'SansRegular',
                  ),
                  hintStyle: TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF81D4FA), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
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
                'Cancel',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());
                
                if (lat == null || lng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid coordinates'),
                    ),
                  );
                  return;
                }
                
                if (lat < -90 || lat > 90) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Latitude must be between -90 and 90'),
                    ),
                  );
                  return;
                }
                
                if (lng < -180 || lng > 180) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Longitude must be between -180 and 180'),
                    ),
                  );
                  return;
                }
                
                setState(() {
                  _latitude = lat;
                  _longitude = lng;
                });
                
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Coordinates set: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF81D4FA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Set Coordinates',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(List<String> emptyFields) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Validation Error',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please fill in all required fields:',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 12),
              ...emptyFields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      field,
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 14,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDuplicateNameDialog(String locationName) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Duplicate Location',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location name already exists!',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A location with the name "$locationName" already exists in this building. Please choose a different name.',
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 14,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF81D4FA).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_location,
                color: Color(0xFF81D4FA),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Addition',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to add this location?',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"${_locationNameController.text}" will be added to $_selectedBuildingName, $_floor as a $_locationType.',
              style: const TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 14,
                color: Color(0xFF6C757D),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'SansRegular',
                color: Color(0xFF6C757D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81D4FA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Add Location',
              style: TextStyle(
                fontFamily: 'SansRegular',
                color: Color(0xFF212529),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return confirm ?? false;
  }

  Future<bool> _checkLocationNameExists(String locationName) async {
    try {
      if (_selectedBuildingId == null) {
        return false;
      }
      
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(_selectedBuildingId)
          .collection('locations')
          .where('name', isEqualTo: locationName.trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking location name: $e');
      return false;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error taking photo: $e")),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212529),
          title: const Text(
            'Select Image Source',
            style: TextStyle(color: Colors.white, fontFamily: 'SansRegular'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.white, fontFamily: 'SansRegular'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.white, fontFamily: 'SansRegular'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      setState(() {
        _isUploading = true;
      });

      String fileName = 'locations/${DateTime.now().millisecondsSinceEpoch}_${_locationNameController.text.replaceAll(' ', '_')}.jpg';
      
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _selectLocationOnMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLocationMapPage(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );
    
    if (result != null && result is Map<String, double>) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location set: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
          ),
        ),
      );
    }
  }

  void _submitForm() async {
    List<String> emptyFields = [];
    
    if (_locationNameController.text.trim().isEmpty) {
      emptyFields.add('Location Name');
    }
    
    if (_selectedBuildingId == null) {
      emptyFields.add('Building');
    }

    if (emptyFields.isNotEmpty) {
      _showErrorDialog(emptyFields);
      return;
    }

    String locationName = _locationNameController.text.trim();
    bool nameExists = await _checkLocationNameExists(locationName);
    
    if (nameExists) {
      _showDuplicateNameDialog(locationName);
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    String? finalImageUrl;

    if (_selectedImage != null) {
      finalImageUrl = await _uploadImageToFirebase(_selectedImage!);
      if (finalImageUrl == null) {
        return;
      }
    } else {
      if (_locationType == 'Lecture Room') {
        finalImageUrl = 'https://drive.google.com/uc?export=view&id=1VRibpXtVrgUGokLdUrzCSIl8nZ3zanGy';
      } else if (_locationType == 'Lab') {
        finalImageUrl = 'https://drive.google.com/uc?export=view&id=1OOjtYkVwFJEc_zWhw6DADl3WunbqKsfU';
      }
    }

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? userUid = currentUser?.uid;

      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(_selectedBuildingId)
          .collection('locations')
          .add({
            'name': locationName,
            'building': _selectedBuildingName,
            'floor': _floor,
            'type': _locationType,
            'imageUrl': finalImageUrl,
            'hasCustomImage': _selectedImage != null,
            'handledBy': userUid,
            'latitude': _latitude,
            'longitude': _longitude,
            'created_at': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location added successfully")),
      );

      _locationNameController.clear();
      setState(() {
        _floor = 'Ground Floor';
        _locationType = 'Lecture Room';
        _imageUrl = null;
        _selectedImage = null;
        _latitude = null;
        _longitude = null;
        _selectedBuildingId = null;
        _selectedBuildingName = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      if (_locationType == 'Lecture Room') {
        _imageUrl = 'https://drive.google.com/uc?export=view&id=1VRibpXtVrgUGokLdUrzCSIl8nZ3zanGy';
      } else if (_locationType == 'Lab') {
        _imageUrl = 'https://drive.google.com/uc?export=view&id=1OOjtYkVwFJEc_zWhw6DADl3WunbqKsfU';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBuildings) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81D4FA)),
          ),
        ),
      );
    }

    if (_buildings.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF212529)),
          title: const Text(
            'Add New Location',
            style: TextStyle(
              color: Color(0xFF212529),
              fontFamily: 'SansRegular',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No Buildings Available',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF212529),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please add buildings first',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF6C757D),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF212529)),
        title: const Text(
          'Add New Location',
          style: TextStyle(
            color: Color(0xFF212529),
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF212529),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(_locationNameController, 'Location Name'),
                  const SizedBox(height: 16),
                  _buildBuildingDropdown(),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Floor',
                    value: _floor,
                    items: ['Ground Floor', '1st Floor', '2nd Floor', '3rd Floor'],
                    onChanged: (val) => setState(() => _floor = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Type',
                    value: _locationType,
                    items: ['Lecture Room', 'Lab', 'Lecturer Office', 'Other'],
                    onChanged: (val) {
                      setState(() {
                        _locationType = val!;
                        _selectedImage = null;
                        if (_locationType == 'Lecture Room') {
                          _imageUrl = 'https://drive.google.com/uc?export=view&id=1VRibpXtVrgUGokLdUrzCSIl8nZ3zanGy';
                        } else if (_locationType == 'Lab') {
                          _imageUrl = 'https://drive.google.com/uc?export=view&id=1OOjtYkVwFJEc_zWhw6DADl3WunbqKsfU';
                        } else {
                          _imageUrl = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLocationCoordinateSection(),
                  const SizedBox(height: 16),
                  _buildImageSection(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isUploading ? Colors.grey : const Color(0xFF81D4FA),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Add Location',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SansRegular',
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
  }

  Widget _buildBuildingDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBuildingId,
      onChanged: (value) {
        setState(() {
          _selectedBuildingId = value;
          _selectedBuildingName = _buildings.firstWhere(
            (building) => building['id'] == value,
            orElse: () => {'name': 'Unknown'},
          )['name'];
        });
      },
      dropdownColor: const Color(0xFF212529),
      items: _buildings.map((building) {
        return DropdownMenuItem<String>(
          value: building['id'],
          child: Text(
            building['name']!,
            style: const TextStyle(
              fontFamily: 'SansRegular',
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
      decoration: const InputDecoration(
        labelText: 'Building *',
        labelStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'SansRegular',
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        fillColor: Colors.transparent,
        filled: true,
      ),
      style: const TextStyle(
        fontFamily: 'SansRegular',
        color: Colors.white,
      ),
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Colors.white,
      ),
      hint: const Text(
        'Select a building',
        style: TextStyle(
          fontFamily: 'SansRegular',
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildLocationCoordinateSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Coordinates',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SansRegular',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_latitude != null && _longitude != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF81D4FA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF81D4FA).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF81D4FA),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Coordinates Set',
                          style: TextStyle(
                            color: Color(0xFF81D4FA),
                            fontFamily: 'SansRegular',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_latitude!.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'SansRegular',
                      ),
                    ),
                    Text(
                      'Lng: ${_longitude!.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'SansRegular',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'No coordinates set',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'SansRegular',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectLocationOnMap,
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Select on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81D4FA),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showManualCoordinateDialog,
                    icon: const Icon(Icons.edit_location, size: 18),
                    label: const Text('Manual Entry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Photo',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SansRegular',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedImage != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81D4FA),
                      foregroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _removeSelectedImage,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ] else ...[
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to add photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'SansRegular',
                        ),
                      ),
                      Text(
                        '(Optional - default image will be used)',
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'SansRegular',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontFamily: 'SansRegular', fontSize: 16, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'SansRegular',
        ),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF212529),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontFamily: 'SansRegular',
                    color: Colors.white,
                  ),
                ),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'SansRegular',
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        fillColor: Colors.transparent,
        filled: true,
      ),
      style: const TextStyle(
        fontFamily: 'SansRegular',
        color: Colors.white,
      ),
      icon: const Icon(
        Icons.arrow_drop_down,
        color: Colors.white,
      ),
    );
  }
}