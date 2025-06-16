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
  final _staffIdController = TextEditingController();
  final _currentPasswordController = TextEditingController(); // For re-authentication
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedStaffType;
  bool _isLoading = false;
  bool _isCurrentPasswordVisible = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isUploadingPhoto = false;
  bool _isEmailChanged = false;
  bool _isPasswordChanged = false;
  
  String? _originalEmail; // Store original email for comparison
  
  File? _imageFile;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _staffTypes = ['Staff', 'Lecturer', 'Technician'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Listen for email changes to show re-authentication fields
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onEmailChanged() {
    final newEmail = _emailController.text.trim();
    setState(() {
      _isEmailChanged = _originalEmail != null && _originalEmail != newEmail;
    });
  }

  void _onPasswordChanged() {
    setState(() {
      _isPasswordChanged = _passwordController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _staffIdController.dispose();
    _currentPasswordController.dispose();
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
            _originalEmail = data['email'] ?? user.email ?? '';
            _telephoneController.text = data['telephone'] ?? '';
            _staffIdController.text = data['staffId'] ?? '';
            _selectedStaffType = data['staffType'];
            _profileImageUrl = data['profileImageUrl'];
          });
        }
      } catch (e) {
        _showErrorDialog('Error loading user data: ${e.toString()}');
      }
    }
  }

  // Re-authenticate user before sensitive operations
  Future<bool> _reauthenticateUser() async {
    if (!_isEmailChanged && !_isPasswordChanged) {
      return true; // No re-authentication needed
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Create credential with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      String errorMessage = 'Re-authentication failed. Please check your current password.';
      
      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Current password is incorrect.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many failed attempts. Please try again later.';
      }
      
      _showErrorDialog(errorMessage);
      return false;
    }
  }

  // Send email notification about account changes
  Future<void> _sendEmailNotification({
    required String newEmail,
    bool emailChanged = false,
    bool passwordChanged = false,
  }) async {
    try {
      // You can implement this using Firebase Functions or a custom email service
      // For now, we'll use Firebase's built-in email verification for new emails
      
      if (emailChanged) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Firebase automatically sends verification email to new address
          await user.sendEmailVerification();
          
          // Optionally, you can also send a notification to the old email
          // This would require a cloud function or third-party email service
          await _sendAccountChangeNotification(
            email: _originalEmail!,
            changeType: 'Email address changed',
            newValue: newEmail,
          );
        }
      }
      
      if (passwordChanged) {
        // Send notification about password change
        await _sendAccountChangeNotification(
          email: newEmail,
          changeType: 'Password changed',
          newValue: 'Your password has been successfully updated',
        );
      }
    } catch (e) {
      print('Error sending email notification: $e');
      // Don't fail the whole operation if email notification fails
    }
  }

  // This would typically be implemented as a Firebase Cloud Function
  Future<void> _sendAccountChangeNotification({
    required String email,
    required String changeType,
    required String newValue,
  }) async {
    // For demonstration purposes - you would implement this using:
    // 1. Firebase Cloud Functions with email service (SendGrid, Mailgun, etc.)
    // 2. Direct integration with email service in your app
    // 3. Custom backend API
    
    try {
      // Example implementation using Firestore to trigger a cloud function
      await FirebaseFirestore.instance.collection('email_notifications').add({
        'to': email,
        'subject': 'Account Information Changed',
        'body': '''
Dear User,

Your account information has been updated:

Change: $changeType
Details: $newValue
Time: ${DateTime.now().toIso8601String()}

If you did not make this change, please contact support immediately.

Best regards,
Your App Team
        ''',
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,
      });
    } catch (e) {
      print('Error queuing email notification: $e');
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
    Navigator.pop(context);
    
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
    Navigator.pop(context);
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

      String fileName = 'profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
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
      // Re-authenticate if email or password is being changed
      if (_isEmailChanged || _isPasswordChanged) {
        final reauthenticated = await _reauthenticateUser();
        if (!reauthenticated) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      String? finalImageUrl;

      // Handle image upload
      if (_imageFile != null) {
        finalImageUrl = await _uploadImageToFirebase(_imageFile!);
        if (finalImageUrl == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        if (_profileImageUrl != null && _profileImageUrl != finalImageUrl) {
          await _deleteOldImage();
        }
      } else if (_profileImageUrl == null) {
        await _deleteOldImage();
        finalImageUrl = null;
      } else {
        finalImageUrl = _profileImageUrl;
      }

      final newEmail = _emailController.text.trim();
      
      // Update Firebase Auth email if changed
      if (_isEmailChanged) {
        await user.updateEmail(newEmail);
      }

      // Update Firebase Auth password if provided
      if (_isPasswordChanged) {
        await user.updatePassword(_passwordController.text);
      }

      // Update Firestore document
      Map<String, dynamic> updateData = {
        'fullname': _fullnameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': newEmail,
        'telephone': _telephoneController.text.trim(),
        'staffId': _staffIdController.text.trim(),
        'staffType': _selectedStaffType,
        'hasCustomImage': _imageFile != null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (finalImageUrl != null) {
        updateData['profileImageUrl'] = finalImageUrl;
      } else {
        updateData['profileImageUrl'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      // Send email notifications
      await _sendEmailNotification(
        newEmail: newEmail,
        emailChanged: _isEmailChanged,
        passwordChanged: _isPasswordChanged,
      );

      setState(() {
        _isLoading = false;
      });

      // Show success message based on what was changed
      String successMessage = 'Account updated successfully!';
      if (_isEmailChanged && _isPasswordChanged) {
        successMessage = 'Account updated successfully! Please verify your new email address and check your email for notifications.';
      } else if (_isEmailChanged) {
        successMessage = 'Account updated successfully! Please verify your new email address.';
      } else if (_isPasswordChanged) {
        successMessage = 'Account updated successfully! Check your email for password change notification.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = 'Error updating account: ${e.toString()}';
      
      if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'For security reasons, please re-enter your current password.';
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

                      // Staff ID Field
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

                      // Show current password field if email or password is being changed
                      if (_isEmailChanged || _isPasswordChanged) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.security, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Security verification required for email or password changes',
                                  style: TextStyle(
                                    fontFamily: 'SansRegular',
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _currentPasswordController,
                          label: 'Current Password',
                          icon: Icons.lock_outline,
                          obscureText: !_isCurrentPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                              });
                            },
                          ),
                          validator: (value) {
                            if ((_isEmailChanged || _isPasswordChanged) && 
                                (value == null || value.isEmpty)) {
                              return 'Current password is required for security';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // New Password Field
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
                      if (_passwordController.text.isNotEmpty) ...[
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
                        const SizedBox(height: 16),
                      ],
                      
                      const SizedBox(height: 16),

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