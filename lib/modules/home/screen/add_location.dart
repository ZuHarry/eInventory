import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _locationNameController = TextEditingController();

  String _building = 'Right Wing';
  String _floor = 'Ground';
  String _locationType = 'Lecture Room';

  Color hex(String hexCode) => Color(int.parse('FF$hexCode', radix: 16));

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String locationName = _locationNameController.text;

      try {
        await FirebaseFirestore.instance.collection('locations').add({
          'name': locationName,
          'building': _building,
          'floor': _floor,
          'type': _locationType,
          'created_at': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location added successfully")),
        );

        // Clear form
        _locationNameController.clear();
        setState(() {
          _building = 'Right Wing';
          _floor = 'Ground';
          _locationType = 'Lecture Room';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
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
          'Add New Location',
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
                  _buildTextField(_locationNameController, 'Location Name'),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Building',
                    value: _building,
                    items: ['Right Wing', 'Left Wing'],
                    onChanged: (val) => setState(() => _building = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Floor',
                    value: _floor,
                    items: ['Ground', '1st Floor', '2nd Floor', '3rd Floor'],
                    onChanged: (val) => setState(() => _floor = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Type',
                    value: _locationType,
                    items: ['Lecture Room', 'Lab', 'Lecturer Office', 'Other'],
                    onChanged: (val) => setState(() => _locationType = val!),
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
