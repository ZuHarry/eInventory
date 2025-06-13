import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ModifyLocationPage extends StatefulWidget {
  final String locationId;
  final Map<String, dynamic> locationData;

  const ModifyLocationPage({
    Key? key,
    required this.locationId,
    required this.locationData,
    required currentName,
  }) : super(key: key);

  @override
  State<ModifyLocationPage> createState() => _ModifyLocationPageState();
}

class _ModifyLocationPageState extends State<ModifyLocationPage> {
  final TextEditingController nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? selectedBuilding;
  String? selectedFloor;
  String? selectedType;
  String? currentImageUrl;
  File? _selectedNewImage;
  bool _isUploading = false;
  bool _imageChanged = false;

  late String oldLocationName;

  final List<String> buildingOptions = ['Left Wing', 'Right Wing'];
  final List<String> floorOptions = [
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
  ];
  final List<String> typeOptions = ['Lab', 'Lecture Room'];

  @override
  void initState() {
    super.initState();
    nameController.text = widget.locationData['name'] ?? '';
    oldLocationName = widget.locationData['name'] ?? '';
    currentImageUrl = widget.locationData['imageUrl'];

    selectedBuilding = buildingOptions.contains(widget.locationData['building'])
        ? widget.locationData['building']
        : null;

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

  Future<void> updateLocation() async {
    final String newName = nameController.text.trim();
    String? finalImageUrl = currentImageUrl;

    try {
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
        'building': selectedBuilding,
        'floor': selectedFloor,
        'type': selectedType,
      };

      // Only update imageUrl if it changed
      if (_imageChanged || _selectedNewImage != null) {
        updateData['imageUrl'] = finalImageUrl;
        updateData['hasCustomImage'] = _selectedNewImage != null;
      }

      await FirebaseFirestore.instance
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildLabel('Location Name'),
            _buildTextField(nameController, 'Location Name'),
            const SizedBox(height: 16),
            _buildLabel('Building'),
            _buildDropdown(selectedBuilding, buildingOptions, (val) {
              setState(() => selectedBuilding = val);
            }),
            const SizedBox(height: 16),
            _buildLabel('Floor'),
            _buildDropdown(selectedFloor, floorOptions, (val) {
              setState(() => selectedFloor = val);
            }),
            const SizedBox(height: 16),
            _buildLabel('Type'),
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
            }),
            const SizedBox(height: 16),
            _buildImageSection(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : updateLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUploading ? Colors.grey : const Color(0xFF212529),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Color(0xFFFFC727))
                    : const Text(
                        'Update Location',
                        style: TextStyle(
                          color: Color(0xFFFFC727),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SansRegular',
                        ),
                      ),
              ),
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
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Location Photo'),
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
                    backgroundColor: const Color(0xFF212529),
                    foregroundColor: const Color(0xFFFFC727),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'SansRegular',
        fontSize: 16,
        fontWeight: FontWeight.bold,
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
          value == null || value.isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildDropdown(
    String? value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black),
    );
  }
}