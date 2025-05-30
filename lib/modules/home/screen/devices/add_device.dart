import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../location/choose_location.dart'; // Import this

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _macController = TextEditingController();

  String _deviceType = 'PC';
  String _deviceStatus = 'Online';
  String? _selectedLocationName;

  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedLocationName != null) {
      String name = _nameController.text;
      String ip = _ipController.text;
      String mac = _macController.text;

      try {
        await FirebaseFirestore.instance.collection('devices').add({
          'name': name,
          'type': _deviceType,
          'ip': ip,
          'mac': mac,
          'status': _deviceStatus,
          'location': _selectedLocationName,
          'created_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Device added successfully")),
        );

        _nameController.clear();
        _ipController.clear();
        _macController.clear();
        setState(() {
          _deviceType = 'PC';
          _deviceStatus = 'Online';
          _selectedLocationName = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } else if (_selectedLocationName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please choose a location")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex('FFC727'),
      appBar: AppBar(
        backgroundColor: hex('FFC727'),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Add New Device',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'PoetsenOne',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(_nameController, 'Device Name'),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Device Type',
                    value: _deviceType,
                    items: ['PC', 'Peripheral'],
                    onChanged: (val) => setState(() => _deviceType = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_ipController, 'IP Address'),
                  const SizedBox(height: 16),
                  _buildTextField(_macController, 'MAC Address'),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Device Status',
                    value: _deviceStatus,
                    items: ['Online', 'Offline'],
                    onChanged: (val) => setState(() => _deviceStatus = val!),
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
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedLocationName ?? 'Choose Location',
                            style: const TextStyle(
                              fontFamily: 'PoetsenOne',
                              color: Colors.black87,
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
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          color: Color(0xFFFFC727),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PoetsenOne',
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
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontFamily: 'PoetsenOne', fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black87,
          fontFamily: 'PoetsenOne',
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontFamily: 'PoetsenOne'),
                ),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black87,
          fontFamily: 'PoetsenOne',
        ),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      style: const TextStyle(fontFamily: 'PoetsenOne', color: Colors.black),
    );
  }
}
