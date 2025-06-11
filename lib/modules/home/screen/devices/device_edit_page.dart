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
  late TextEditingController nameController;
  late TextEditingController ipController;
  late TextEditingController macController;
  String? selectedLocation;
  String status = 'Online';
  String type = 'PC';

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

  Future<void> updateDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Update'),
        content: const Text('Are you sure you want to update this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text('Confirm', style: TextStyle(color: Color(0xFFFFC727))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('devices').doc(widget.deviceId).update({
      'name': nameController.text,
      'ip': ipController.text,
      'mac': macController.text,
      'location': selectedLocation,
      'status': status,
      'type': type,
    });

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ScreenPage())); // Replace with your home screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildField('Name', nameController),
            _buildField('IP Address', ipController),
            _buildField('MAC Address', macController),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
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
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black54),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedLocation ?? 'Choose Location',
                      style: const TextStyle(fontFamily: 'SansRegular', fontSize: 16),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdown('Status', status, ['Online', 'Offline'], (val) => setState(() => status = val!)),
            _buildDropdown('Type', type, ['PC', 'Peripheral'], (val) => setState(() => type = val!)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFFFFC727), fontFamily: 'SansRegular', fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: updateDevice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(color: Color(0xFFFFC727), fontFamily: 'SansRegular', fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(fontFamily: 'SansRegular', fontSize: 16),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        style: const TextStyle(fontFamily: 'SansRegular', fontSize: 16, color: Colors.black),
      ),
    );
  }
}
