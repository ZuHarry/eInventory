import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            color: Color(0xFFFFC727),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Brands',
          style: TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFC727),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
                color: Color(0xFFFFC727),
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
            padding: const EdgeInsets.all(16),
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
                color: const Color(0xFFFFC727).withOpacity(0.1),
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
                            color: Color(0xFFFFC727),
                            size: 40,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFC727),
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.image_rounded,
                        color: Color(0xFFFFC727),
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
              'Tap to view',
              style: TextStyle(
                fontFamily: 'SansRegular',
                fontSize: 11,
                color: const Color(0xFF6C757D).withOpacity(0.8),
              ),
            ),
          ],
        ),
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
            color: Color(0xFFFFC727),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          brandName,
          style: const TextStyle(
            fontFamily: 'SansRegular',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFC727),
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
                color: Color(0xFFFFC727),
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
              final imageUrl = modelData['imageUrl'] as String?;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildModelCard(
                  context: context,
                  modelName: modelName,
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
    String? imageUrl,
  }) {
    return Container(
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
                color: const Color(0xFFFFC727).withOpacity(0.1),
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
                            color: Color(0xFFFFC727),
                            size: 28,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFC727),
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.phone_android_rounded,
                        color: Color(0xFFFFC727),
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                modelName,
                style: const TextStyle(
                  fontFamily: 'SansRegular',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212529),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}