import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ViewBrandPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF81D4FA),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Brands',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF81D4FA),
          ),
        ),
      ),
      body: Column(
        children: [
          // Hint Container
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF81D4FA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF81D4FA).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  color: Color(0xFF81D4FA),
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Hold to View',
                  style: TextStyle(
                    fontFamily: 'SansRegular',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212529),
                  ),
                ),
              ],
            ),
          ),
          // Brands Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('brands')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.red.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading brands',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 16,
                            color: Colors.red.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF81D4FA),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 64,
                          color: const Color(0xFF6C757D).withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No brands found',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            fontSize: 16,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final brands = snapshot.data!.docs;
                
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    final brandData = brand.data() as Map<String, dynamic>;
                    final brandName = brandData['name'] ?? 'Unknown Brand';
                    final brandId = brand.id;
                    final imageUrl = brandData['imageUrl'] as String?;
                    
                    return _buildBrandCard(
                      context: context,
                      brandName: brandName,
                      brandId: brandId,
                      imageUrl: imageUrl,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBrandCard({
    required BuildContext context,
    required String brandName,
    required String brandId,
    String? imageUrl,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewModelPage(
              brandId: brandId,
              brandName: brandName,
            ),
          ),
        );
      },
      onLongPress: () {
        _showBrandOptions(context, brandId, brandName, imageUrl);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF81D4FA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_rounded,
                            color: Color(0xFF81D4FA),
                            size: 40,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF81D4FA),
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.image_rounded,
                        color: Color(0xFF81D4FA),
                        size: 40,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                brandName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to view • Long press for options',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 10,
                color: const Color(0xFF6C757D).withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showBrandOptions(BuildContext context, String brandId, String brandName, String? imageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF6C757D).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Color(0xFF81D4FA)),
              title: const Text(
                'Edit Brand',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditBrandDialog(context, brandId, brandName, imageUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text(
                'Delete Brand',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteBrandConfirmation(context, brandId, brandName);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  void _showEditBrandDialog(BuildContext context, String brandId, String currentName, String? currentImageUrl) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    String? newImageUrl = currentImageUrl;
    bool isUploading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Edit Brand',
            style: TextStyle(
              fontFamily: 'SansRegular',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    
                    if (image != null) {
                      setState(() => isUploading = true);
                      
                      try {
                        final storageRef = FirebaseStorage.instance
                            .ref()
                            .child('brands')
                            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
                        
                        await storageRef.putFile(File(image.path));
                        final downloadUrl = await storageRef.getDownloadURL();
                        
                        setState(() {
                          newImageUrl = downloadUrl;
                          isUploading = false;
                        });
                      } catch (e) {
                        setState(() => isUploading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to upload image: $e')),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF81D4FA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF81D4FA).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: isUploading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF81D4FA),
                            ),
                          )
                        : newImageUrl != null && newImageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  newImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Color(0xFF81D4FA),
                                size: 48,
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Brand Name',
                    labelStyle: const TextStyle(fontFamily: 'SansRegular'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF81D4FA), width: 2),
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'SansRegular'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  color: Color(0xFF6C757D),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a brand name')),
                  );
                  return;
                }
                
                try {
                  await FirebaseFirestore.instance
                      .collection('brands')
                      .doc(brandId)
                      .update({
                    'name': newName,
                    'imageUrl': newImageUrl ?? '',
                  });
                  
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to main page
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Brand updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update brand: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF81D4FA),
                foregroundColor: const Color(0xFF212529),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Update',
                style: TextStyle(
                  fontFamily: 'SansRegular',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteBrandConfirmation(BuildContext context, String brandId, String brandName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Brand',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$brandName"? This will also delete all models under this brand. This action cannot be undone.',
          style: const TextStyle(fontFamily: 'SansRegular'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'SansRegular',
                color: Color(0xFF6C757D),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Delete all models in the subcollection first
                final modelsSnapshot = await FirebaseFirestore.instance
                    .collection('brands')
                    .doc(brandId)
                    .collection('models')
                    .get();
                
                for (var doc in modelsSnapshot.docs) {
                  await doc.reference.delete();
                }
                
                // Delete the brand document
                await FirebaseFirestore.instance
                    .collection('brands')
                    .doc(brandId)
                    .delete();
                
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to main page
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Brand deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete brand: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ViewModelPage extends StatelessWidget {
  final String brandId;
  final String brandName;
  
  const ViewModelPage({
    Key? key,
    required this.brandId,
    required this.brandName,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF81D4FA),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          brandName,
          style: const TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF81D4FA),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('brands')
            .doc(brandId)
            .collection('models')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading models',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 16,
                      color: Colors.red.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF81D4FA),
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    size: 64,
                    color: const Color(0xFF6C757D).withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No models found',
                    style: TextStyle(
                      fontFamily: 'SansRegular',
                      fontSize: 16,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            );
          }
          
          final models = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              final modelData = model.data() as Map<String, dynamic>;
              final modelName = modelData['name'] ?? 'Unknown Model';
              final modelId = model.id;
              final imageUrl = modelData['imageUrl'] as String?;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildModelCard(
                  context: context,
                  modelName: modelName,
                  modelId: modelId,
                  imageUrl: imageUrl,
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildModelCard({
    required BuildContext context,
    required String modelName,
    required String modelId,
    String? imageUrl,
  }) {
    return InkWell(
      onLongPress: () {
        _showDeleteModelConfirmation(context, modelId, modelName);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF81D4FA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.phone_android_rounded,
                              color: Color(0xFF81D4FA),
                              size: 28,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF81D4FA),
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                      : const Icon(
                          Icons.phone_android_rounded,
                          color: Color(0xFF81D4FA),
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modelName,
                      style: const TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212529),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Long press to delete',
                      style: TextStyle(
                        fontFamily: 'SansRegular',
                        fontSize: 12,
                        color: const Color(0xFF6C757D).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.delete_outline_rounded,
                color: const Color(0xFF6C757D).withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDeleteModelConfirmation(BuildContext context, String modelId, String modelName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Model',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$modelName"? This action cannot be undone.',
          style: const TextStyle(fontFamily: 'SansRegular'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'SansRegular',
                color: Color(0xFF6C757D),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('brands')
                    .doc(brandId)
                    .collection('models')
                    .doc(modelId)
                    .delete();
                
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to brand list
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Model deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete model: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}