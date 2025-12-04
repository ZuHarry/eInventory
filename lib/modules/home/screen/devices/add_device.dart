import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:flutter/material.dart';
import '../location/choose_location.dart';
import '../devices/choose_brand.dart';
import '../devices/choose_model.dart';

class AddDevicePage extends StatefulWidget {
  final VoidCallback? onNavigateToInventory;
  
  const AddDevicePage({super.key, this.onNavigateToInventory});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _macController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _processorController = TextEditingController();
  final TextEditingController _storageController = TextEditingController();

  String _deviceType = 'PC';
  String _deviceStatus = 'Online';
  String _peripheralType = 'Monitor';
  String? _selectedLocationName;
  String? _selectedBrand;
  String? _selectedBrandId;  // Add this line
  String? _selectedModel;     // Add this line

  Future<List<String>> _checkDuplicates(String name) async {
    List<String> duplicateFields = [];
    
    try {
      QuerySnapshot nameQuery = await FirebaseFirestore.instance
          .collection('devices')
          .where('name', isEqualTo: name)
          .get();
      
      if (nameQuery.docs.isNotEmpty) {
        duplicateFields.add('Device Name: "$name"');
      }
    } catch (e) {
      print('Error checking duplicates: $e');
    }
    
    return duplicateFields;
  }

  void _submitForm() async {
    List<String> emptyFields = [];
    
    if (_nameController.text.trim().isEmpty) {
      emptyFields.add('Device Name');
    }
    if (_selectedLocationName == null) {
      emptyFields.add('Location');
    }

    if (emptyFields.isNotEmpty) {
      _showErrorDialog(emptyFields);
      return;
    }

    if (_formKey.currentState!.validate()) {
      String name = _nameController.text.trim();

      List<String> duplicateFields = await _checkDuplicates(name);
      
      if (duplicateFields.isNotEmpty) {
        _showDuplicateDialog(duplicateFields);
        return;
      }

      try {
        // Get current user UID
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: No user logged in")),
          );
          return;
        }

        Map<String, dynamic> deviceData = {
          'name': name,
          'type': _deviceType,
          'status': _deviceStatus,
          'location': _selectedLocationName,
          'assigned_by': currentUser.uid, // Add current user's UID
          'created_at': FieldValue.serverTimestamp(),
        };

        if (_ipController.text.trim().isNotEmpty) {
          deviceData['ip'] = _ipController.text.trim();
        }
        if (_macController.text.trim().isNotEmpty) {
          deviceData['mac'] = _macController.text.trim();
        }

        if (_deviceType == 'PC') {
          if (_selectedBrand != null) {
            deviceData['brand'] = _selectedBrand;
          }
          if (_modelController.text.trim().isNotEmpty) {
            deviceData['model'] = _modelController.text.trim();
          }
          if (_processorController.text.trim().isNotEmpty) {
            deviceData['processor'] = _processorController.text.trim();
          }
          if (_storageController.text.trim().isNotEmpty) {
            deviceData['storage'] = _storageController.text.trim();
          }
        } else if (_deviceType == 'Peripheral') {
          deviceData['peripheral_type'] = _peripheralType;
          if (_selectedBrand != null) {
            deviceData['brand'] = _selectedBrand;
          }
          if (_selectedModel != null) {
            deviceData['model'] = _selectedModel;
          }
        }

        await FirebaseFirestore.instance.collection('devices').add(deviceData);

        _showSuccessDialog(name);

        _nameController.clear();
        _ipController.clear();
        _macController.clear();
        _modelController.clear();
        _processorController.clear();
        _storageController.clear();
        setState(() {
          _deviceType = 'PC';
          _deviceStatus = 'Online';
          _peripheralType = 'Monitor';
          _selectedLocationName = null;
          _selectedBrand = null;
          _selectedBrandId = null;
          _selectedModel = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
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
              )),
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
              )),
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

  void _showSuccessDialog(String deviceName) {
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
                'Device added successfully!',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"$deviceName" has been added to your inventory.',
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Add Another',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF6C757D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (widget.onNavigateToInventory != null) {
                  widget.onNavigateToInventory!();
                }
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

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _macController.dispose();
    _modelController.dispose();
    _processorController.dispose();
    _storageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                  _buildTextField(_nameController, 'Device Name', isRequired: true),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    value: _deviceType,
                    items: ['PC', 'Peripheral'],
                    onChanged: (val) => setState(() => _deviceType = val!),
                    label: 'Device Type',
                  ),
                  const SizedBox(height: 16),
                  
                  if (_deviceType == 'PC') ...[
                    GestureDetector(
                      onTap: () async {
                        final selected = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChooseBrandPage(),
                          ),
                        );
                        if (selected != null) {
                          setState(() {
                            _selectedBrand = selected;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black54),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedBrand ?? 'Choose Brand',
                              style: TextStyle(
                                fontFamily: 'SansRegular',
                                color: _selectedBrand != null ? Colors.black87 : Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_modelController, 'Model'),
                    const SizedBox(height: 16),
                    _buildTextField(_processorController, 'Processor'),
                    const SizedBox(height: 16),
                    _buildTextField(_storageController, 'Storage (GB)', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                  ] else if (_deviceType == 'Peripheral') ...[
                    _buildDropdown(
                      value: _peripheralType,
                      items: ['Monitor', 'Printer', 'Tablet', 'Others'],
                      onChanged: (val) => setState(() => _peripheralType = val!),
                      label: 'Peripheral Type',
                    ),
                    const SizedBox(height: 16),
                    // Replace the existing brand GestureDetector with this
                    GestureDetector(
                      onTap: () async {
                        final selectedBrand = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChooseBrandPage(),
                          ),
                        );
                        if (selectedBrand != null) {
                          // Get the brand document ID
                          final brandQuery = await FirebaseFirestore.instance
                              .collection('brands')
                              .where('name', isEqualTo: selectedBrand)
                              .limit(1)
                              .get();
                          
                          setState(() {
                            _selectedBrand = selectedBrand;
                            _selectedBrandId = brandQuery.docs.isNotEmpty ? brandQuery.docs.first.id : null;
                            _selectedModel = null; // Reset model when brand changes
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black54),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedBrand ?? 'Choose Brand',
                              style: TextStyle(
                                fontFamily: 'SansRegular',
                                color: _selectedBrand != null ? Colors.black87 : Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Add this after the Brand GestureDetector and SizedBox
                    if (_selectedBrand != null && _selectedBrandId != null) ...[
                      GestureDetector(
                        onTap: () async {
                          final selected = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChooseModelPage(
                                brandId: _selectedBrandId!,
                                brandName: _selectedBrand!,
                              ),
                            ),
                          );
                          if (selected != null) {
                            setState(() {
                              _selectedModel = selected;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedModel ?? 'Choose Model',
                                style: TextStyle(
                                  fontFamily: 'SansRegular',
                                  color: _selectedModel != null ? Colors.black87 : Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Remove the old _buildTextField(_modelController, 'Model') line
                    const SizedBox(height: 16),
                  ],
                  
                  _buildTextField(_ipController, 'IP Address (Optional)', keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildTextField(_macController, 'MAC Address (Optional)'),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    value: _deviceStatus,
                    items: ['Online', 'Offline'],
                    onChanged: (val) => setState(() => _deviceStatus = val!),
                    label: 'Device Status',
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final selected = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChooseLocationPage(),
                        ),
                      );
                      if (selected != null) {
                        setState(() {
                          _selectedLocationName = selected;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedLocationName ?? 'Choose Location *',
                            style: TextStyle(
                              fontFamily: 'SansRegular',
                              color: _selectedLocationName != null ? Colors.black87 : Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC727),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit',
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

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: 'SansRegular', fontSize: 16, color: Colors.black),
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        labelText: isRequired ? '$label *' : label,
        labelStyle: const TextStyle(
          color: Colors.black,
          fontFamily: 'SansRegular',
        ),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      validator: isRequired ? (value) =>
          value == null || value.trim().isEmpty ? 'Enter $label' : null : null,
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? label,
  }) {
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
      style: const TextStyle(fontFamily: 'SansRegular', color: Colors.black),
    );
  }
}