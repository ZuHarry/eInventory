import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddBrandPage extends StatefulWidget {
  @override
  State<AddBrandPage> createState() => _AddBrandPageState();
}

class _AddBrandPageState extends State<AddBrandPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking image: $e"),
          backgroundColor: const Color(0xFFDC3545),
        ),
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
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error taking photo: $e"),
          backgroundColor: const Color(0xFFDC3545),
        ),
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

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      // Create a unique filename
      String fileName = 'brands/${DateTime.now().millisecondsSinceEpoch}_${_nameController.text.replaceAll(' ', '_')}.jpg';
      
      // Upload to Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading image: $e"),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
      return null;
    }
  }

  Future<void> _saveBrand() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      
      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToFirebase(_selectedImage!);
        if (imageUrl == null) {
          setState(() => _isLoading = false);
          return; // Upload failed, don't proceed
        }
      }

      // Save brand to Firestore
      await FirebaseFirestore.instance.collection('brands').add({
        'name': _nameController.text.trim(),
        'imageUrl': imageUrl,
        'hasCustomImage': _selectedImage != null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brand added successfully'),
          backgroundColor: Color(0xFF28A745),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Brand Logo',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF212529),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedImage != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDEE2E6)),
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
                    foregroundColor: const Color(0xFF212529),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _removeSelectedImage,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC3545),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFDEE2E6),
                    width: 2,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      color: Color(0xFF6C757D),
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to add brand logo',
                      style: TextStyle(
                        color: Color(0xFF6C757D),
                        fontFamily: 'SansRegular',
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '(Optional)',
                      style: TextStyle(
                        color: Color(0xFF6C757D),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF81D4FA)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Brand',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF81D4FA),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Brand Name',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212529),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter brand name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF81D4FA)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a brand name';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildImageSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveBrand,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF81D4FA),
                foregroundColor: const Color(0xFF212529),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF212529),
                        ),
                      ),
                    )
                  : const Text(
                      'Save Brand',
                      style: TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}