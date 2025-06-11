import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ModifyLocationPage extends StatefulWidget {
  final String locationId;
  final Map<String, dynamic> locationData;

  const ModifyLocationPage({
    Key? key,
    required this.locationId,
    required this.locationData, required currentName,
  }) : super(key: key);

  @override
  State<ModifyLocationPage> createState() => _ModifyLocationPageState();
}

class _ModifyLocationPageState extends State<ModifyLocationPage> {
  final TextEditingController nameController = TextEditingController();
  String? selectedBuilding;
  String? selectedFloor;
  String? selectedType;

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

  Future<void> updateLocation() async {
    final String newName = nameController.text.trim();

    try {
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(widget.locationId)
          .update({
        'name': newName,
        'building': selectedBuilding,
        'floor': selectedFloor,
        'type': selectedType,
      });

      final devicesSnapshot = await FirebaseFirestore.instance
          .collection('devices')
          .where('location', isEqualTo: oldLocationName)
          .get();

      for (var doc in devicesSnapshot.docs) {
        await doc.reference.update({'location': newName});
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
      backgroundColor: const Color(0xFFF8F9FA), // Match the background color
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
              setState(() => selectedType = val);
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF212529), // Dark button color
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Update Location',
                  style: TextStyle(
                    color: Color(0xFFFFC727), // Yellow text color
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