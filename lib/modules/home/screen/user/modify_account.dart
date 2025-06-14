import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ModifyAccountPage extends StatefulWidget {
  const ModifyAccountPage({super.key});

  @override
  State<ModifyAccountPage> createState() => _ModifyAccountPageState();
}

class _ModifyAccountPageState extends State<ModifyAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _staffIdController = TextEditingController(); // Added Staff ID controller
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedStaffType;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isUploadingPhoto = false;
  
  File? _imageFile;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _staffTypes = ['Staff', 'Lecturer', 'Technician'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _staffIdController.dispose(); // Dispose Staff ID controller
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _fullnameController.text = data['fullname'] ?? '';
            _usernameController.text = data['username'] ?? '';
            _emailController.text = data['email'] ?? user.email ?? '';
            _telephoneController.text = data['telephone'] ?? '';
            _staffIdController.text = data['staffId'] ?? ''; // Load Staff ID
            _selectedStaffType = data['staffType'];
            _profileImageUrl = data['profileImageUrl'];
            // Don't populate password field for security
          });
        }
      } catch (e) {
        _showErrorDialog('Error loading user data: ${e.toString()}');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Profile Picture',
                  style: TextStyle(
                    fontFamily: 'SansRegular',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => _getImage(ImageSource.camera),
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => _getImage(ImageSource.gallery),
                    ),
                    if (_profileImageUrl != null || _imageFile != null)
                      _buildImageSourceOption(
                        icon: Icons.delete,
                        label: 'Remove',
                        onTap: _removeImage,
                        color: Colors.red,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showErrorDialog('Error opening image picker: ${e.toString()}');
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFFFFC727)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: color ?? const Color(0xFFFFC727),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color ?? const Color(0xFFFFC727),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 14,
              color: color ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet
    
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking image: ${e.toString()}');
    }
  }

  void _removeImage() {
    Navigator.pop(context); // Close bottom sheet
    setState(() {
      _imageFile = null;
      _profileImageUrl = null;
    });
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      setState(() {
        _isUploadingPhoto = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Create a unique filename
      String fileName = 'profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      _showErrorDialog('Error uploading image: ${e.toString()}');
      return null;
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  Future<void> _deleteOldImage() async {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(_profileImageUrl!);
        await ref.delete();
      } catch (e) {
        // Ignore error if image doesn't exist
        print('Error deleting old image: $e');
      }
    }
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if passwords match when password is being updated
    if (_passwordController.text.isNotEmpty && 
        _passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('No user is signed in');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      String? finalImageUrl;

      // Handle image upload similar to add_location.dart
      if (_imageFile != null) {
        // User selected a new image - upload it
        finalImageUrl = await _uploadImageToFirebase(_imageFile!);
        if (finalImageUrl == null) {
          // Upload failed, don't proceed
          setState(() {
            _isLoading = false;
          });
          return;
        }
        // Delete old image after successful upload
        if (_profileImageUrl != null && _profileImageUrl != finalImageUrl) {
          await _deleteOldImage();
        }
      } else if (_profileImageUrl == null) {
        // Image was removed - delete from storage if there was an old one
        await _deleteOldImage();
        finalImageUrl = null;
      } else {
        // No change to image - keep existing
        finalImageUrl = _profileImageUrl;
      }

      // Update Firebase Auth email if changed
      final currentEmail = user.email;
      final newEmail = _emailController.text.trim();
      
      if (currentEmail != newEmail) {
        await user.updateEmail(newEmail);
      }

      // Update Firebase Auth password if provided
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text);
      }

      // Update Firestore document
      Map<String, dynamic> updateData = {
        'fullname': _fullnameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': newEmail,
        'telephone': _telephoneController.text.trim(),
        'staffId': _staffIdController.text.trim(), // Include Staff ID in update
        'staffType': _selectedStaffType,
        'hasCustomImage': _imageFile != null, // Track if it's a custom image
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Handle profile image URL
      if (finalImageUrl != null) {
        updateData['profileImageUrl'] = finalImageUrl;
      } else {
        // Remove profile image URL if image was deleted
        updateData['profileImageUrl'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      setState(() {
        _isLoading = false;
      });

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentEmail != newEmail 
                ? 'Account updated successfully! Please verify your new email address.'
                : 'Account updated successfully!'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Handle specific Firebase Auth errors
      String errorMessage = 'Error updating account: ${e.toString()}';
      
      if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'For security reasons, please sign out and sign back in before changing your email or password.';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email address is already in use by another account.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak. Please choose a stronger password.';
      }
      
      _showErrorDialog(errorMessage);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFC727),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: _imageFile != null
                ? Image.file(
                    _imageFile!,
                    fit: BoxFit.cover,
                  )
                : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? Image.network(
                        _profileImageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.black,
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFFFFC727),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.black,
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFFFFC727),
                        ),
                      ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC727),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isUploadingPhoto
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 18,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Modify Account',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Image with Upload Button
                      _buildProfileImage(),
                      const SizedBox(height: 12),
                      Text(
                        'Tap camera icon to change photo',
                        style: TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Full Name Field
                      _buildTextField(
                        controller: _fullnameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Username Field
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.account_circle,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email address';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Telephone Field
                      _buildTextField(
                        controller: _telephoneController,
                        label: 'Telephone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your telephone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Staff ID Field - Added this new field
                      _buildTextField(
                        controller: _staffIdController,
                        label: 'Staff ID',
                        icon: Icons.badge,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your staff ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Staff Type Dropdown
                      _buildDropdownField(),
                      const SizedBox(height: 16),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'New Password (optional)',
                        icon: Icons.lock,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 6) {
                            return 'Password should be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        icon: Icons.lock_outline,
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isUploadingPhoto ? null : _updateAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isUploadingPhoto ? Colors.grey : const Color(0xFFFFC727),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isUploadingPhoto
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text(
                                  'Update Account',
                                  style: TextStyle(
                                    fontFamily: 'SansRegular',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'SansRegular',
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'SansRegular',
          color: Colors.black54,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC727),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.black, size: 20),
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFC727), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedStaffType,
      decoration: InputDecoration(
        labelText: 'Staff Type',
        labelStyle: const TextStyle(
          fontFamily: 'SansRegular',
          color: Colors.black54,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC727),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.work, color: Colors.black, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFC727), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _staffTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            style: const TextStyle(
              fontFamily: 'SansRegular',
              fontSize: 16,
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedStaffType = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a staff type';
        }
        return null;
      },
    );
  }
}