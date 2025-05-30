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

  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

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
      backgroundColor: hex('FFC727'),
      appBar: AppBar(
        backgroundColor: hex('FFC727'),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Edit Location',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'PoetsenOne',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildLabel('Location Name'),
            TextField(
              controller: nameController,
              style: const TextStyle(fontFamily: 'PoetsenOne'),
              decoration: _inputDecoration(),
            ),
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
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Update Location',
                  style: TextStyle(
                    color: Color(0xFFFFC727),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PoetsenOne',
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
        fontFamily: 'PoetsenOne',
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
      decoration: _inputDecoration(),
      style: const TextStyle(fontFamily: 'PoetsenOne', color: Colors.black),
    );
  }
}
