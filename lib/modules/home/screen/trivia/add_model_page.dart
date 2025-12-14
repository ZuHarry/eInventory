import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddModelPage extends StatefulWidget {
  @override
  State<AddModelPage> createState() => _AddModelPageState();
}

class _AddModelPageState extends State<AddModelPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _selectedBrandId;
  List<Map<String, dynamic>> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    final brandsSnapshot = await FirebaseFirestore.instance
        .collection('brands')
        .orderBy('name')
        .get();

    setState(() {
      _brands = brandsSnapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name']})
          .toList();
    });
  }

  Future<void> _saveModel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('brands')
          .doc(_selectedBrandId)
          .collection('models')
          .add({
        'name': _nameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Model added successfully'),
          backgroundColor: Color(0xFF28A745),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFFFFC727)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Model',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFC727),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Brand',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212529),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedBrandId,
                    decoration: InputDecoration(
                      hintText: 'Choose a brand',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFFFC727)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: _brands.map((brand) {
                      return DropdownMenuItem<String>(
                        value: brand['id'] as String,
                        child: Text(
                          brand['name'] as String,
                          style: const TextStyle(
                            fontFamily: 'SansRegular',
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedBrandId = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a brand';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Model Name',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212529),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter model name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFFFC727)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a model name';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveModel,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC727),
                foregroundColor: const Color(0xFF212529),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF212529),
                        ),
                      ),
                    )
                  : const Text(
                      'Save Model',
                      style: TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}