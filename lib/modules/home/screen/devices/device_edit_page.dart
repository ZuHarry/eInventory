import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../location/choose_location.dart'; // your custom location selector
import '../../main/screen.dart'; // your home screen

class DeviceEditPage extends StatefulWidget {
  final String deviceId;
  final Map<String, dynamic> deviceData;

  const DeviceEditPage({super.key, required this.deviceId, required this.deviceData});

  @override
  State<DeviceEditPage> createState() => _DeviceEditPageState();
}

class _DeviceEditPageState extends State<DeviceEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController ipController;
  late TextEditingController macController;
  String? selectedLocation;
  String status = 'Online';
  String type = 'PC';
  bool _isDeleting = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.deviceData['name']);
    ipController = TextEditingController(text: widget.deviceData['ip']);
    macController = TextEditingController(text: widget.deviceData['mac']);
    selectedLocation = widget.deviceData['location'];
    status = widget.deviceData['status'] ?? 'Online';
    type = widget.deviceData['type'] ?? 'PC';
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

  void _showDuplicateDialog(List<String> duplicateFields) {
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
                'Duplicate Found',
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
                'The following fields already exist in the system:',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 12),
              ...duplicateFields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: Colors.orange,
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
              const SizedBox(height: 8),
              const Text(
                'Please use different values for these fields.',
                style: TextStyle(
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

  Future<List<String>> _checkForDuplicates() async {
    List<String> duplicates = [];
    
    try {
      final devicesRef = FirebaseFirestore.instance.collection('devices');
      
      // Check for duplicate device name (excluding current device)
      final nameQuery = await devicesRef
          .where('name', isEqualTo: nameController.text.trim())
          .get();
      
      bool nameExists = nameQuery.docs.any((doc) => doc.id != widget.deviceId);
      if (nameExists) {
        duplicates.add('Device Name "${nameController.text.trim()}" already exists');
      }
      
      // Check for duplicate IP address (excluding current device)
      final ipQuery = await devicesRef
          .where('ip', isEqualTo: ipController.text.trim())
          .get();
      
      bool ipExists = ipQuery.docs.any((doc) => doc.id != widget.deviceId);
      if (ipExists) {
        duplicates.add('IP Address "${ipController.text.trim()}" already exists');
      }
      
    } catch (e) {
      print('Error checking for duplicates: $e');
    }
    
    return duplicates;
  }

  Future<void> updateDevice() async {
    // Check if all required fields are filled
    List<String> emptyFields = [];
    
    if (nameController.text.trim().isEmpty) {
      emptyFields.add('Device Name');
    }
    if (ipController.text.trim().isEmpty) {
      emptyFields.add('IP Address');
    }
    if (macController.text.trim().isEmpty) {
      emptyFields.add('MAC Address');
    }
    if (selectedLocation == null || selectedLocation!.trim().isEmpty) {
      emptyFields.add('Location');
    }

    // If there are empty fields, show error dialog
    if (emptyFields.isNotEmpty) {
      _showErrorDialog(emptyFields);
      return;
    }

    // Show loading state
    setState(() {
      _isUpdating = true;
    });

    // Check for duplicates
    final duplicates = await _checkForDuplicates();
    
    if (duplicates.isNotEmpty) {
      setState(() {
        _isUpdating = false;
      });
      _showDuplicateDialog(duplicates);
      return;
    }

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
                Icons.edit,
                color: Color(0xFFFFC727),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Update',
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
              'Are you sure you want to update this device?',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"${nameController.text}" will be updated with the new information.',
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
              'Update',
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

    if (confirm != true) {
      setState(() {
        _isUpdating = false;
      });
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('devices').doc(widget.deviceId).update({
        'name': nameController.text.trim(),
        'ip': ipController.text.trim(),
        'mac': macController.text.trim(),
        'location': selectedLocation,
        'status': status,
        'type': type,
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ScreenPage()));
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating device: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
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
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Device',
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
              'Are you sure you want to delete this device?',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"${nameController.text}" will be permanently removed. This action cannot be undone.',
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
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'SansRegular',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteDevice();
    }
  }

  Future<void> _deleteDevice() async {
    try {
      setState(() {
        _isDeleting = true;
      });

      // Delete the device document from Firestore
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.deviceId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device deleted successfully')),
      );

      // Navigate back to the main screen
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => ScreenPage())
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting device: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isProcessing = _isDeleting || _isUpdating;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Match add device background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA), // Match background
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Edit Device',
          style: TextStyle(
            fontFamily: 'SansRegular',
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF212529), // Dark card background like add device
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
                  _buildTextField(nameController, 'Device Name'),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    value: type,
                    items: ['PC', 'Peripheral'],
                    onChanged: isProcessing ? null : (val) => setState(() => type = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(ipController, 'IP Address'),
                  const SizedBox(height: 16),
                  _buildTextField(macController, 'MAC Address'),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    value: status,
                    items: ['Online', 'Offline'],
                    onChanged: isProcessing ? null : (val) => setState(() => status = val!),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: isProcessing ? null : () async {
                      final selected = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChooseLocationPage()),
                      );
                      if (selected != null) {
                        setState(() {
                          selectedLocation = selected;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54),
                        borderRadius: BorderRadius.circular(8),
                        color: isProcessing ? Colors.grey[200] : Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedLocation ?? 'Choose Location',
                            style: TextStyle(
                              fontFamily: 'SansRegular',
                              color: isProcessing 
                                  ? Colors.grey 
                                  : (selectedLocation != null ? Colors.black87 : Colors.black54),
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios, 
                            size: 16, 
                            color: isProcessing ? Colors.grey : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isProcessing ? Colors.grey : Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFFFFC727), 
                              fontFamily: 'SansRegular', 
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : updateDevice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isProcessing ? Colors.grey : const Color(0xFFFFC727),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isUpdating
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Updating...',
                                      style: TextStyle(
                                        color: Colors.black, 
                                        fontFamily: 'SansRegular', 
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Update',
                                  style: TextStyle(
                                    color: Colors.black, 
                                    fontFamily: 'SansRegular', 
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : _showDeleteConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isProcessing ? Colors.grey : Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isDeleting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Deleting...',
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontFamily: 'SansRegular', 
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Delete Device',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'SansRegular',
                                fontSize: 16,
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
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    bool isProcessing = _isDeleting || _isUpdating;
    
    return TextFormField(
      controller: controller,
      enabled: !isProcessing,
      style: TextStyle(
        fontFamily: 'SansRegular', 
        fontSize: 16,
        color: isProcessing ? Colors.grey : Colors.black,
      ),
      decoration: InputDecoration(
        fillColor: isProcessing ? Colors.grey[200] : Colors.white,
        filled: true,
        labelText: label,
        labelStyle: TextStyle(
          color: isProcessing ? Colors.grey : Colors.black,
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    bool isProcessing = _isDeleting || _isUpdating;
    
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black),
                ),
              ))
          .toList(),
      decoration: InputDecoration(
        fillColor: isProcessing ? Colors.grey[200] : Colors.white,
        filled: true,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      style: TextStyle(
        fontFamily: 'SansRegular', 
        fontSize: 16, 
        color: isProcessing ? Colors.grey : Colors.black,
      ),
    );
  }
}