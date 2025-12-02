import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ModifyLocationPage extends StatefulWidget {
  final String locationId;
  final Map<String, dynamic> locationData;
  final String buildingId; // Add this


  const ModifyLocationPage({
    Key? key,
    required this.locationId,
    required this.locationData,
    required this.buildingId, // Add this
  }) : super(key: key);

  @override
  State<ModifyLocationPage> createState() => _ModifyLocationPageState();
}

class _ModifyLocationPageState extends State<ModifyLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? selectedBuilding;
  String? selectedFloor;
  String? selectedType;
  String? currentImageUrl;
  File? _selectedNewImage;
  bool _isUploading = false;
  bool _imageChanged = false;
  bool _isDeleting = false;

  late String oldLocationName;
  late String buildingId;

  // Replace the existing buildingOptions list declaration with:
  List<String> buildingOptions = []; // Initialize as empty list
  final TextEditingController buildingController = TextEditingController();
  bool isCustomBuilding = false;
  final List<String> floorOptions = [
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
  ];
  final List<String> typeOptions = ['Lab', 'Lecture Room'];

  // Update the initState method to include the building loading:
  @override
  void initState() {
    super.initState();
    nameController.text = widget.locationData['name'] ?? '';
    oldLocationName = widget.locationData['name'] ?? '';
    currentImageUrl = widget.locationData['imageUrl'];
    buildingId = widget.buildingId;

    // Load buildings first, then set selected values
    _loadBuildings().then((_) {
      setState(() {
        if (buildingOptions.contains(widget.locationData['building'])) {
          selectedBuilding = widget.locationData['building'];
          isCustomBuilding = false;
        } else if (widget.locationData['building'] != null && widget.locationData['building'].toString().isNotEmpty) {
          // If building exists but not in list, treat as custom
          buildingController.text = widget.locationData['building'];
          isCustomBuilding = true;
          selectedBuilding = null;
        }
      });
    });

    selectedFloor = floorOptions.contains(widget.locationData['floor'])
        ? widget.locationData['floor']
        : null;

    selectedType = typeOptions.contains(widget.locationData['type'])
        ? widget.locationData['type']
        : null;
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
          _selectedNewImage = File(image.path);
          _imageChanged = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  // Add this method to load buildings from Firestore:
  Future<void> _loadBuildings() async {
  try {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('buildings')
        .orderBy('name') // Sort by building name
        .get();
    
    setState(() {
      buildingOptions = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['name'] as String)
          .toList();
      
      if (selectedBuilding != null && !buildingOptions.contains(selectedBuilding)) {
        buildingController.text = selectedBuilding!;
        isCustomBuilding = true;
        selectedBuilding = null;
      }
    });
  } catch (e) {
    print('Error loading buildings: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error loading buildings: $e")),
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
          _selectedNewImage = File(image.path);
          _imageChanged = true;
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

  void _showDuplicateLocationDialog() {
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
                  Icons.warning_outlined,
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
                'A location with the name "${nameController.text.trim()}" already exists. Please choose a different name.',
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

  void _showSuccessDialog() {
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
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Success',
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
                'Location updated successfully!',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${nameController.text.trim()}" has been updated.',
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
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF212529),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF212529),
          title: const Text(
            'Delete Location',
            style: TextStyle(color: Colors.white, fontFamily: 'SansRegular'),
          ),
          content: Text(
            'Are you sure you want to delete "${nameController.text}"? This action cannot be undone.',
            style: const TextStyle(color: Colors.white, fontFamily: 'SansRegular'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontFamily: 'SansRegular'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteLocation();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red, fontFamily: 'SansRegular'),
              ),
            ),
          ],
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
      String fileName = 'locations/${DateTime.now().millisecondsSinceEpoch}_${nameController.text.replaceAll(' ', '_')}.jpg';
      
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


  Future<void> _saveNewBuildingToFirestore(String buildingName) async {
    try {
      // Check if building already exists
      final QuerySnapshot existingBuilding = await FirebaseFirestore.instance
          .collection('buildings')
          .where('name', isEqualTo: buildingName)
          .get();
      
      if (existingBuilding.docs.isEmpty) {
        // Add new building to Firestore
        await FirebaseFirestore.instance
            .collection('buildings')
            .add({
          'name': buildingName,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving building: $e');
    }
  }


  void _resetToDefaultImage() {
    setState(() {
      _selectedNewImage = null;
      _imageChanged = true;
      // Set default image based on selected type
      if (selectedType == 'Lecture Room') {
        currentImageUrl = 'https://drive.google.com/uc?export=view&id=1VRibpXtVrgUGokLdUrzCSIl8nZ3zanGy';
      } else if (selectedType == 'Lab') {
        currentImageUrl = 'https://drive.google.com/uc?export=view&id=1OOjtYkVwFJEc_zWhw6DADl3WunbqKsfU';
      }
    });
  }

  void _removeNewImage() {
    setState(() {
      _selectedNewImage = null;
      _imageChanged = false;
    });
  }

  Future<bool> _checkLocationNameExists(String locationName) async {
    // If the name hasn't changed, it's valid
    if (locationName == oldLocationName) {
      return false;
    }

    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('locations')
          .where('name', isEqualTo: locationName)
          .get();
      
      return result.docs.isNotEmpty;
    } catch (e) {
      return false; // Assume it doesn't exist if there's an error
    }
  }

  // Update the updateLocation method to handle custom buildings:
  Future<void> updateLocation() async {
    // Get the final building value
    String? finalBuilding;
    if (isCustomBuilding) {
      finalBuilding = buildingController.text.trim();
    } else {
      finalBuilding = selectedBuilding;
    }

    // Check if all required fields are filled
    List<String> emptyFields = [];
    
    if (nameController.text.trim().isEmpty) {
      emptyFields.add('Location Name');
    }
    if (finalBuilding == null || finalBuilding.isEmpty) {
      emptyFields.add('Building');
    }
    if (selectedFloor == null) {
      emptyFields.add('Floor');
    }
    if (selectedType == null) {
      emptyFields.add('Type');
    }

    // If there are empty fields, show error dialog
    if (emptyFields.isNotEmpty) {
      _showErrorDialog(emptyFields);
      return;
    }

    final String newName = nameController.text.trim();

    // Check if location name already exists
    bool locationExists = await _checkLocationNameExists(newName);
    if (locationExists) {
      _showDuplicateLocationDialog();
      return;
    }

    String? finalImageUrl = currentImageUrl;

    try {
      // If user entered a custom building, save it to Firestore first
      if (isCustomBuilding && finalBuilding!.isNotEmpty) {
        await _saveNewBuildingToFirestore(finalBuilding);
      }

      // If user selected a new image, upload it
      if (_selectedNewImage != null) {
        finalImageUrl = await _uploadImageToFirebase(_selectedNewImage!);
        if (finalImageUrl == null) {
          // Upload failed, don't proceed
          return;
        }
      } else if (_imageChanged && _selectedNewImage == null) {
        // User reset to default image
        finalImageUrl = currentImageUrl;
      }

      // Update the location document
      Map<String, dynamic> updateData = {
        'name': newName,
        'building': finalBuilding,
        'floor': selectedFloor,
        'type': selectedType,
      };

      // Only update imageUrl if it changed
      if (_imageChanged || _selectedNewImage != null) {
        updateData['imageUrl'] = finalImageUrl;
        updateData['hasCustomImage'] = _selectedNewImage != null;
      }

      await FirebaseFirestore.instance
    .collection('buildings')
    .doc(buildingId)
    .collection('locations')
    .doc(widget.locationId)
    .update(updateData);

      // Update devices with the new location name if it changed
      if (newName != oldLocationName) {
        final devicesSnapshot = await FirebaseFirestore.instance
            .collection('devices')
            .where('location', isEqualTo: oldLocationName)
            .get();

        for (var doc in devicesSnapshot.docs) {
          await doc.reference.update({'location': newName});
        }
      }

      // Show success dialog
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating location: $e')),
      );
    }
  }

  Future<void> _deleteLocation() async {
    try {
      setState(() {
        _isDeleting = true;
      });

      // First, update all devices that have this location to remove the location reference
      final devicesSnapshot = await FirebaseFirestore.instance
          .collection('devices')
          .where('location', isEqualTo: oldLocationName)
          .get();

      // Update devices to remove location reference or set to null/empty
      for (var doc in devicesSnapshot.docs) {
        await doc.reference.update({'location': ''});
      }


      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingId)
          .collection('locations')
          .doc(widget.locationId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location deleted successfully')),
      );

      // Navigate back to the main screen (skip location details page)
      Navigator.pop(context); // Close modify page
      Navigator.pop(context); // Close location details page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting location: $e')),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F9FA),
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Edit Location',
          style: TextStyle(
            color: Colors.black,
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
                  _buildTextField(nameController, 'Location Name'),
                  const SizedBox(height: 16),
                  _buildDropdown(selectedBuilding, buildingOptions, (val) {
                    setState(() => selectedBuilding = val);
                  }, 'Building'),
                  const SizedBox(height: 16),
                  _buildDropdown(selectedFloor, floorOptions, (val) {
                    setState(() => selectedFloor = val);
                  }, 'Floor'),
                  const SizedBox(height: 16),
                  _buildDropdown(selectedType, typeOptions, (val) {
                    setState(() {
                      selectedType = val;
                      // Update default image when type changes (only if not using custom image)
                      if (!_imageChanged && _selectedNewImage == null) {
                        if (selectedType == 'Lecture Room') {
                          currentImageUrl = 'https://drive.google.com/uc?export=view&id=1VRibpXtVrgUGokLdUrzCSIl8nZ3zanGy';
                        } else if (selectedType == 'Lab') {
                          currentImageUrl = 'https://drive.google.com/uc?export=view&id=1OOjtYkVwFJEc_zWhw6DADl3WunbqKsfU';
                        }
                      }
                    });
                  }, 'Type'),
                  const SizedBox(height: 16),
                  _buildImageSection(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isUploading || _isDeleting) ? null : updateLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isUploading || _isDeleting) ? Colors.grey : const Color(0xFFFFC727),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Color(0xFF212529))
                          : const Text(
                              'Update Location',
                              style: TextStyle(
                                color: Color(0xFF212529),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SansRegular',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isUploading || _isDeleting) ? null : _showDeleteConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isUploading || _isDeleting) ? Colors.grey : Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isDeleting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Delete Location',
                              style: TextStyle(
                                color: Colors.white,
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
        border: Border.all(color: Colors.white54),
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
                fontFamily: 'SansRegular',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Show current/new image preview
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: _selectedNewImage != null
                  ? Image.file(
                      _selectedNewImage!,
                      fit: BoxFit.cover,
                    )
                  : (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                      ? Image.network(
                          currentImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 50,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(_selectedNewImage != null ? 'Change' : 'Update Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC727),
                    foregroundColor: const Color(0xFF212529),
                  ),
                ),
                if (_selectedNewImage != null)
                  ElevatedButton.icon(
                    onPressed: _removeNewImage,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _resetToDefaultImage,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Default'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontFamily: 'SansRegular', fontSize: 16, color: Colors.black),
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black,
          fontFamily: 'SansRegular',
        ),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildDropdown(
    String? value,
    List<String> options,
    void Function(String?) onChanged,
    String hint,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      hint: Text(
        hint,
        style: const TextStyle(
          fontFamily: 'SansRegular',
          color: Colors.black54,
        ),
      ),
      items: options
          .map((option) => DropdownMenuItem(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black),
                ),
              ))
          .toList(),
      decoration: const InputDecoration(
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black),
    );
  }

  // Replace the existing _buildDropdown method with this updated version for buildings:
  Widget _buildBuildingField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle between dropdown and custom input
        Row(
          children: [
            Expanded(
              child: isCustomBuilding
                  ? _buildTextField(buildingController, 'Building Name')
                  : _buildBuildingField(),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  isCustomBuilding = !isCustomBuilding;
                  if (isCustomBuilding) {
                    buildingController.clear();
                    selectedBuilding = null;
                  } else {
                    buildingController.clear();
                  }
                });
              },
              icon: Icon(
                isCustomBuilding ? Icons.list : Icons.add,
                color: Colors.white,
              ),
              tooltip: isCustomBuilding ? 'Select from list' : 'Add custom building',
            ),
          ],
        ),
        if (isCustomBuilding)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Enter a new building name',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'SansRegular',
              ),
            ),
          ),
      ],
    );
  }

}