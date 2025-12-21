import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChooseModelPage extends StatefulWidget {
  final String brandId;
  final String brandName;

  const ChooseModelPage({
    super.key,
    required this.brandId,
    required this.brandName,
  });

  @override
  State<ChooseModelPage> createState() => _ChooseModelPageState();
}

class _ChooseModelPageState extends State<ChooseModelPage> {
  String? _actualBrandId;
  bool _isLoadingBrandId = false;

  @override
  void initState() {
    super.initState();
    _initializeBrandId();
  }

  Future<void> _initializeBrandId() async {
    // If brandId is provided and not empty, use it
    if (widget.brandId.isNotEmpty) {
      setState(() {
        _actualBrandId = widget.brandId;
      });
      return;
    }

    // Otherwise, try to fetch it using the brand name
    setState(() {
      _isLoadingBrandId = true;
    });

    try {
      final brandQuery = await FirebaseFirestore.instance
          .collection('brands')
          .where('name', isEqualTo: widget.brandName)
          .limit(1)
          .get();

      if (brandQuery.docs.isNotEmpty) {
        setState(() {
          _actualBrandId = brandQuery.docs.first.id;
          _isLoadingBrandId = false;
        });
      } else {
        setState(() {
          _isLoadingBrandId = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Brand not found in database'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching brand ID: $e');
      setState(() {
        _isLoadingBrandId = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading brand: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212529),
        title: Text(
          'Choose Model - ${widget.brandName}',
          style: const TextStyle(
            fontFamily: 'SansRegular',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingBrandId
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF212529),
              ),
            )
          : _actualBrandId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load brand information',
                        style: TextStyle(
                          fontFamily: 'SansRegular',
                          fontSize: 16,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF212529),
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontFamily: 'SansRegular',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('brands')
                      .doc(_actualBrandId)
                      .collection('models')
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(
                            fontFamily: 'SansRegular',
                            color: Color(0xFF6C757D),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF212529),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No models available for ${widget.brandName}',
                              style: const TextStyle(
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
                        final modelDoc = models[index];
                        final modelData = modelDoc.data() as Map<String, dynamic>;
                        final modelName = modelData['name'] as String;
                        final imageUrl = modelData['imageUrl'] as String?;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context, modelName);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    // Model Image
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF212529).withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: imageUrl != null && imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.phone_android_rounded,
                                                    color: Color(0xFF6C757D),
                                                    size: 28,
                                                  );
                                                },
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return const Center(
                                                    child: CircularProgressIndicator(
                                                      color: Color(0xFF212529),
                                                      strokeWidth: 2,
                                                    ),
                                                  );
                                                },
                                              )
                                            : const Icon(
                                                Icons.phone_android_rounded,
                                                color: Color(0xFF6C757D),
                                                size: 28,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Model Name
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
                                    // Check Icon
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 20,
                                      color: Color(0xFF6C757D),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}