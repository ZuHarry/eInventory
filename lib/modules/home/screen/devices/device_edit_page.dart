import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../location/choose_location.dart'; // your custom location selector
import '../../main/staff.dart'; // your home screen
import '../devices/choose_brand.dart';
import '../devices/choose_model.dart';

class DeviceEditPage extends StatefulWidget {
  final String deviceId;
  final Map<String, dynamic> deviceData;

  const DeviceEditPage({super.key, required this.deviceId, required this.deviceData});

  @override
  State<DeviceEditPage> createState() => _DeviceEditPageState();
}

class _DeviceEditPageState extends State<DeviceEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController brandController;
  late TextEditingController modelController;
  late TextEditingController processorController;
  late TextEditingController storageController;
  late TextEditingController nameController;
  late TextEditingController ipController;
  late TextEditingController macController;
  String? selectedLocation;
  String? _selectedBrandId;
  String? _selectedBrandName;
  String? _selectedModel;
  String status = 'Online';
  String type = 'PC';
  String peripheralType = 'Monitor'; // Add peripheral type
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
    peripheralType = widget.deviceData['peripheral_type'] ?? 'Monitor'; // Initialize peripheral type

    // Initialize brand and model from existing data
    _selectedBrandName = widget.deviceData['brand'];
    _selectedModel = widget.deviceData['model'];

    brandController = TextEditingController(text: widget.deviceData['brand'] ?? '');
    modelController = TextEditingController(text: widget.deviceData['model'] ?? '');
    processorController = TextEditingController(text: widget.deviceData['processor'] ?? '');
    storageController = TextEditingController(text: widget.deviceData['storage'] ?? '');

  }

  @override
  void dispose() {
    nameController.dispose();
    ipController.dispose();
    macController.dispose();
    brandController.dispose();
    modelController.dispose();
    processorController.dispose();
    storageController.dispose();
    super.dispose();
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
  
  // CRITICAL: Check if deviceId is valid before querying
  if (widget.deviceId.isEmpty) {
    print('ERROR: deviceId is empty in _checkForDuplicates');
    return duplicates;
  }
  
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

  // Brand is required for both PC and Peripheral
  if (brandController.text.trim().isEmpty) {
    emptyFields.add('Brand');
  }

  // PC-specific field validation
  if (type == 'PC') {
    // Model is required for PC
    if (modelController.text.trim().isEmpty) {
      emptyFields.add('Model');
    }
    if (processorController.text.trim().isEmpty) {
      emptyFields.add('Processor');
    }
    if (storageController.text.trim().isEmpty) {
      emptyFields.add('Storage');
    }
  }

  // If there are empty fields, show error dialog
  if (emptyFields.isNotEmpty) {
    _showErrorDialog(emptyFields);
    return;
  }

  // CRITICAL: Check if deviceId is valid
  if (widget.deviceId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error: Invalid device ID'),
        backgroundColor: Colors.red,
      ),
    );
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
              color: const Color(0xFF81D4FA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit,
              color: Color(0xFF81D4FA),
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
            backgroundColor: const Color(0xFF81D4FA),
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
    // Debug print
    print('Updating device with ID: ${widget.deviceId}');
    print('Type: $type');
    print('Brand: ${brandController.text.trim()}');
    print('Model: ${modelController.text.trim()}');
    
    // Prepare update data - START WITH BASIC REQUIRED FIELDS ONLY
    Map<String, dynamic> updateData = {
      'name': nameController.text.trim(),
      'ip': ipController.text.trim(),
      'mac': macController.text.trim(),
      'location': selectedLocation!,
      'status': status,
      'type': type,
      'brand': brandController.text.trim(),
    };

    // Handle type-specific fields
    if (type == 'PC') {
      // For PC: add all PC fields
      updateData['model'] = modelController.text.trim();
      updateData['processor'] = processorController.text.trim();
      updateData['storage'] = storageController.text.trim();
      updateData['peripheral_type'] = FieldValue.delete();
      
      print('PC Update Data: $updateData');
    } else if (type == 'Peripheral') {
      // For Peripheral: add peripheral type
      updateData['peripheral_type'] = peripheralType;
      updateData['processor'] = FieldValue.delete();
      updateData['storage'] = FieldValue.delete();
      
      // Only add model if it has content
      final modelText = modelController.text.trim();
      if (modelText.isNotEmpty) {
        updateData['model'] = modelText;
      } else {
        updateData['model'] = FieldValue.delete();
      }
      
      print('Peripheral Update Data: $updateData');
    }

    // Perform the update
    print('About to update Firestore...');
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .update(updateData);
    
    print('Update successful!');

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device updated successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Navigate back
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => ScreenPage())
    );
    
  } catch (e) {
    print('ERROR UPDATING DEVICE: $e');
    print('Stack trace: ${StackTrace.current}');
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error updating device: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
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
                    onChanged: isProcessing ? null : (val) {
                      setState(() {
                        type = val!;
                        // Reset fields when switching device type
                        if (type == 'Peripheral') {
                          peripheralType = 'Monitor';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Brand selection (common for both PC and Peripheral)
                  GestureDetector(
                    onTap: isProcessing ? null : () async {
                      final selected = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChooseBrandPage(),
                        ),
                      );
                      if (selected != null && selected is Map) {
                        setState(() {
                          _selectedBrandId = selected['id'];
                          _selectedBrandName = selected['name'];
                          brandController.text = selected['name'];
                          _selectedModel = null; // Reset model when brand changes
                          modelController.clear();
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isProcessing ? Colors.grey[200] : const Color(0xFFF8F9FA),
                        border: Border.all(
                          color: isProcessing ? Colors.grey.shade300 : Colors.black54,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (_selectedBrandName ?? brandController.text).isNotEmpty
                                ? brandController.text 
                                : 'Choose Brand',
                            style: TextStyle(
                              fontFamily: 'SansRegular',
                              color: isProcessing 
                                  ? Colors.grey 
                                  : (_selectedBrandName != null || brandController.text.isNotEmpty)
                                      ? Colors.black87 
                                      : Colors.black54,
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
                  const SizedBox(height: 16),
                  
                  // Conditional fields based on device type
                  // Conditional fields based on device type
                  if (type == 'PC') ...[
                    // Model selection for PC
                    GestureDetector(
                      onTap: isProcessing || _selectedBrandId == null && brandController.text.isEmpty
                          ? null
                          : () async {
                              final selected = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChooseModelPage(
                                    brandId: _selectedBrandId ?? '',
                                    brandName: _selectedBrandName ?? brandController.text,
                                  ),
                                ),
                              );
                              if (selected != null && selected is String) {
                                setState(() {
                                  _selectedModel = selected;
                                  modelController.text = selected;
                                });
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isProcessing || (_selectedBrandId == null && brandController.text.isEmpty)
                                ? Colors.grey.shade300 
                                : Colors.black54,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isProcessing || (_selectedBrandId == null && brandController.text.isEmpty)
                              ? Colors.grey.shade100 
                              : Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (_selectedModel ?? modelController.text).isNotEmpty 
                                ? (_selectedModel ?? modelController.text)
                                : 'Choose Model',
                              style: TextStyle(
                                fontFamily: 'SansRegular',
                                color: isProcessing || (_selectedBrandId == null && brandController.text.isEmpty)
                                    ? Colors.grey.shade400
                                    : (_selectedModel != null || modelController.text.isNotEmpty)
                                        ? Colors.black87
                                        : Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: isProcessing || (_selectedBrandId == null && brandController.text.isEmpty)
                                  ? Colors.grey.shade400 
                                  : Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(processorController, 'Processor'),
                    const SizedBox(height: 16),
                    _buildTextField(storageController, 'Storage'),
                    const SizedBox(height: 16),
                  ] else if (type == 'Peripheral') ...[
                    // Manual model input for Peripheral
                    _buildTextField(modelController, 'Model (Optional)'),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: peripheralType,
                      items: ['Monitor', 'Printer', 'Tablet', 'Others'],
                      onChanged: isProcessing ? null : (val) => setState(() => peripheralType = val!),
                      label: 'Peripheral Type',
                    ),
                    const SizedBox(height: 16),
                  ],
                  
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
                              color: Color(0xFF81D4FA), 
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
                            backgroundColor: isProcessing ? Colors.grey : const Color(0xFF81D4FA),
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
    String? label,
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
        labelText: label,
        labelStyle: label != null ? TextStyle(
          color: isProcessing ? Colors.grey : Colors.black,
          fontFamily: 'SansRegular',
        ) : null,
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