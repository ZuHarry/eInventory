import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _customBuildingController = TextEditingController();
  String _building = 'Add Custom Building...';
  String _floor = 'Ground Floor';
  String _locationType = 'Lecture Room';
  String? _imageUrl; // For default images
  File? _selectedImage; // For user-uploaded image
  bool _isUploading = false;
  bool _isCustomBuilding = false; // Track if user selected custom building option

  // 1. Add new state variable to track temporary custom building
  String? _tempCustomBuilding; // Add this line near other state variables

  // Available buildings from Firestore + default options
  List<String> _availableBuildings = ['Add Custom Building...'];
  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

  @override
  void initState() {
    super.initState();
    _loadExistingBuildings();
  }

  // Load existing custom buildings from Firestore
  Future<void> _loadExistingBuildings() async {
    try {
      QuerySnapshot buildingsSnapshot = await FirebaseFirestore.instance
          .collection('buildings')
          .orderBy('name')
          .get();
      
      List<String> customBuildings = buildingsSnapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();
      
      setState(() {
        _availableBuildings = [
          ...customBuildings,
          'Add Custom Building...'
        ];
        // Set default building to first available or empty if none exist
        if (customBuildings.isNotEmpty) {
          _building = customBuildings.first;
        } else {
          _building = 'Add Custom Building...';
        }
      });
    } catch (e) {
      print('Error loading buildings: $e');
      // If error loading, still show the option to add custom building
      setState(() {
        _availableBuildings = ['Add Custom Building...'];
        _building = 'Add Custom Building...';
      });
    }
  }

  // // Save custom building to Firestore
  // Future<void> _saveCustomBuilding(String buildingName) async {
  //   try {
  //     await FirebaseFirestore.instance.collection('buildings').add({
  //       'name': buildingName,
  //       'created_at': FieldValue.serverTimestamp(),
  //     });
      
  //     // Reload buildings list
  //     await _loadExistingBuildings();
      
  //     // Set the new building as selected
  //     setState(() {
  //       _building = buildingName;
  //       _isCustomBuilding = false;
  //       _customBuildingController.clear();
  //     });
      
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Building '$buildingName' added successfully")),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error adding building: $e")),
  //     );
  //   }
  // }

  // 2. Modify _showCustomBuildingDialog() - Remove automatic saving
void _showCustomBuildingDialog() {
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
                color: const Color(0xFFFFC727).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business,
                color: Color(0xFFFFC727),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Custom Building',
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
            const Text(
              'Enter the name of the new building:',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customBuildingController,
              style: const TextStyle(
                fontFamily: 'SansRegular', 
                fontSize: 16, 
                color: Colors.white
              ),
              decoration: const InputDecoration(
                labelText: 'Building Name',
                labelStyle: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'SansRegular',
                ),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFC727), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _customBuildingController.clear();
              Navigator.of(context).pop();
              // Reset dropdown to previous value
              setState(() {
                _building = _availableBuildings.first;
              });
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
              String buildingName = _customBuildingController.text.trim();
              if (buildingName.isNotEmpty) {
                // Check if building already exists in the list OR in temp storage
                if (_availableBuildings.contains(buildingName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Building '$buildingName' already exists")),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                // Just store temporarily, don't save to Firestore yet
                setState(() {
                  _tempCustomBuilding = buildingName;
                  _building = buildingName;
                  _customBuildingController.clear();
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a building name")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC727),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Add Building',
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
      barrierDismissible: false, // User must tap button to dismiss
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
                'A location with the name "$locationName" already exists. Please choose a different name.',
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
                color: const Color(0xFFFFC727).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_location,
                color: Color(0xFFFFC727),
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
              '"${_locationNameController.text}" will be added to $_building, $_floor as a $_locationType.',
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
              backgroundColor: const Color(0xFFFFC727),
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
      // Query Firestore to check if location name already exists
      // Using case-insensitive comparison
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where('name', isEqualTo: locationName.trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // If there's an error checking, we'll allow the submission to proceed
      // and let the actual submission handle any errors
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
          _imageUrl = null; // Clear default image URL when user selects custom image
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
          _imageUrl = null; // Clear default image URL when user takes custom photo
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

      // Create a unique filename
      String fileName = 'locations/${DateTime.now().millisecondsSinceEpoch}_${_locationNameController.text.replaceAll(' ', '_')}.jpg';
      
      // Upload to Firebase Storage
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

  // 4. Modify _submitForm() to save custom building only when location is submitted
void _submitForm() async {
  // Check if all required fields are filled
  List<String> emptyFields = [];
  
  if (_locationNameController.text.trim().isEmpty) {
    emptyFields.add('Location Name');
  }

  // If there are empty fields, show error dialog
  if (emptyFields.isNotEmpty) {
    _showErrorDialog(emptyFields);
    return;
  }

  // Check if location name already exists
  String locationName = _locationNameController.text.trim();
  bool nameExists = await _checkLocationNameExists(locationName);
  
  if (nameExists) {
    _showDuplicateNameDialog(locationName);
    return;
  }

  // Show confirmation dialog
  final confirmed = await _showConfirmationDialog();
  if (!confirmed) return;

  String? finalImageUrl;

  // If user uploaded a custom image, upload it to Firebase Storage
  if (_selectedImage != null) {
    finalImageUrl = await _uploadImageToFirebase(_selectedImage!);
    if (finalImageUrl == null) {
      // Upload failed, don't proceed
      return;
    }
  } else {
    // Use default image based on location type
    if (_locationType == 'Lecture Room') {
      finalImageUrl = 'https://drive.google.com/uc?export=view&id=1VRibpXtVrgUGokLdUrzCSIl8nZ3zanGy';
    } else if (_locationType == 'Lab') {
      finalImageUrl = 'https://drive.google.com/uc?export=view&id=1OOjtYkVwFJEc_zWhw6DADl3WunbqKsfU';
    }
  }

  try {
    // SAVE CUSTOM BUILDING FIRST (if exists)
    if (_tempCustomBuilding != null && _tempCustomBuilding!.isNotEmpty) {
      await FirebaseFirestore.instance.collection('buildings').add({
        'name': _tempCustomBuilding!,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      // Add to available buildings list for future use
      setState(() {
        _availableBuildings.insert(_availableBuildings.length - 1, _tempCustomBuilding!);
      });
    }

    // THEN SAVE THE LOCATION
    await FirebaseFirestore.instance.collection('locations').add({
      'name': locationName,
      'building': _building,
      'floor': _floor,
      'type': _locationType,
      'imageUrl': finalImageUrl,
      'hasCustomImage': _selectedImage != null,
      'created_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Location added successfully")),
    );

    // Clear form INCLUDING temp custom building
    _locationNameController.clear();
    setState(() {
      _building = _availableBuildings.first;
      _floor = 'Ground Floor';
      _locationType = 'Lecture Room';
      _imageUrl = null;
      _selectedImage = null;
      _tempCustomBuilding = null; // Clear temp custom building
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
      // Reset to default image based on location type
      if (_locationType == 'Lecture Room') {
        _imageUrl = 'https://drive.google.com/uc?export=view&id=1VRibpXtVrgUGokLdUrzCSIl8nZ3zanGy';
      } else if (_locationType == 'Lab') {
        _imageUrl = 'https://drive.google.com/uc?export=view&id=1OOjtYkVwFJEc_zWhw6DADl3WunbqKsfU';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildDropdown(
                    label: 'Building',
                    value: _building,
                    items: _availableBuildings,
                    onChanged: (val) {
                      if (val == 'Add Custom Building...') {
                        _showCustomBuildingDialog();
                      } else {
                        setState(() => _building = val!);
                      }
                    },
                  ),
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
                        // Reset images when type changes
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
                  _buildImageSection(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isUploading ? Colors.grey : const Color(0xFFFFC727),
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
                      backgroundColor: const Color(0xFFFFC727),
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

  // 5. Update the building dropdown to show temp custom building
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    // For building dropdown, include temp custom building if it exists
    List<String> displayItems = [...items];
    if (label == 'Building' && _tempCustomBuilding != null && !displayItems.contains(_tempCustomBuilding)) {
      displayItems.insert(displayItems.length - 1, _tempCustomBuilding!);
    }
    
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF212529),
      items: displayItems
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontFamily: 'SansRegular', 
                    color: item == 'Add Custom Building...' 
                        ? const Color(0xFFFFC727)
                        : Colors.white,
                    fontWeight: item == 'Add Custom Building...' 
                        ? FontWeight.bold 
                        : FontWeight.normal,
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