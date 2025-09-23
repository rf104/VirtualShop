import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:virtual_shop/models/product.dart';

class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _brandController;
  late TextEditingController _weightController;
  late TextEditingController _dimensionsController;

  late ProductCategory _selectedCategory;
  late ProductCondition _selectedCondition;
  bool _isFeatured = false;
  bool _isInStock = true;
  final List<dynamic> _selectedImages =
      []; // Can contain both File and String (asset path)
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameController = TextEditingController(text: p.name);
    _descriptionController = TextEditingController(text: p.description);
    _priceController = TextEditingController(text: p.price.toStringAsFixed(2));
    _stockController = TextEditingController(text: p.stock.toString());
    _brandController = TextEditingController(text: p.brand ?? '');
    _weightController = TextEditingController(
      text: p.weightKg?.toString() ?? '',
    );
    _dimensionsController = TextEditingController(text: p.dimensions ?? '');

    _selectedCategory = p.category;
    _selectedCondition = p.condition;
    _isFeatured = p.isFeatured;
    _isInStock = p.isInStock;

    // Initialize the first image if product has one (treat as network/local path)
    if (p.image.isNotEmpty) {
      if (p.image.startsWith('assets/')) {
        _selectedImages.add(p.image);
      } else {
        // If it's a path on device we can wrap as File, otherwise keep as URL string
        try {
          _selectedImages.add(File(p.image));
        } catch (_) {
          _selectedImages.add(p.image);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    super.dispose();
  }

  String _categoryToString(ProductCategory c) {
    switch (c) {
      case ProductCategory.electronics:
        return 'Electronics';
      case ProductCategory.fashion:
        return 'Fashion';
      case ProductCategory.homeAndGarden:
        return 'Home & Garden';
      case ProductCategory.sports:
        return 'Sports';
      case ProductCategory.books:
        return 'Books';
      case ProductCategory.toys:
        return 'Toys';
      case ProductCategory.beauty:
        return 'Beauty';
      case ProductCategory.automotive:
        return 'Automotive';
      case ProductCategory.health:
        return 'Health';
      case ProductCategory.foodAndBeverages:
        return 'Food & Beverages';
      case ProductCategory.unspecified:
        return 'Unspecified';
    }
  }

  String _conditionToString(ProductCondition c) {
    switch (c) {
      case ProductCondition.newCondition:
        return 'New';
      case ProductCondition.used:
        return 'Used';
      case ProductCondition.refurbished:
        return 'Refurbished';
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            if (_selectedImages.length < 5) {
              _selectedImages.add(File(image.path));
            }
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('Please add at least one product image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final parsedPrice =
          double.tryParse(_priceController.text) ?? widget.product.price;
      final parsedStock =
          int.tryParse(_stockController.text) ?? widget.product.stock;
      final parsedWeight = double.tryParse(_weightController.text);

      final imagePath = _selectedImages.isNotEmpty
          ? (_selectedImages.first is File
                ? (_selectedImages.first as File).path
                : _selectedImages.first as String)
          : '';

      final updatedProduct = Product(
        id: widget.product.id,
        authId: widget.product.authId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        price: parsedPrice,
        stock: parsedStock,
        condition: _selectedCondition,
        weightKg: parsedWeight,
        dimensions: _dimensionsController.text.trim().isEmpty
            ? null
            : _dimensionsController.text.trim(),
        isFeatured: _isFeatured,
        isInStock: _isInStock,
        createdAt: widget.product.createdAt,
        updatedAt: DateTime.now(),
        image: imagePath,
        rating: widget.product.rating,
        isLoved: widget.product.isLoved,
      );

      // TODO: call your API / backend here to persist the updated product
      // For now, we'll simulate a delay and then pop with the updated product
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context, updatedProduct);
        _showSuccessSnackBar('Product updated successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update product: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = ProductCategory.values
        .where((c) => c != ProductCategory.unspecified)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFADFF2F)),
          ),
          child: DropdownButton<ProductCategory>(
            value: _selectedCategory,
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _selectedCategory = v;
              });
            },
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white),
            items: categories.map((c) {
              return DropdownMenuItem<ProductCategory>(
                value: c,
                child: Text(_categoryToString(c)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionDropdown() {
    final conditions = ProductCondition.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFADFF2F)),
          ),
          child: DropdownButton<ProductCondition>(
            value: _selectedCondition,
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _selectedCondition = v;
              });
            },
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white),
            items: conditions.map((c) {
              return DropdownMenuItem<ProductCondition>(
                value: c,
                child: Text(_conditionToString(c)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Product Images',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedImages.length}/5',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedImages.isEmpty)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFADFF2F).withOpacity(0.5),
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Upload Product Images',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add up to 5 images',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: _selectedImages[index] is File
                                  ? FileImage(_selectedImages[index] as File)
                                  : AssetImage(_selectedImages[index] as String)
                                        as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_selectedImages.length < 5) const SizedBox(height: 16),
                if (_selectedImages.length < 5)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xff667eea).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xff667eea)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add More Images',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFADFF2F)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Edit Product',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: _saveProduct,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFADFF2F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Product Name',
                hint: 'Enter product name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter product description',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Category',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _brandController,
                label: 'Brand',
                hint: 'Enter brand name',
              ),
              const SizedBox(height: 24),

              // Pricing & Stock
              _buildSectionTitle('Pricing & Stock'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price (৳)',
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _stockController,
                      label: 'Stock Quantity',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter stock';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter valid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Condition',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildConditionDropdown(),
              const SizedBox(height: 24),

              // Product Details
              _buildSectionTitle('Product Details'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _weightController,
                label: 'Weight (kg)',
                hint: '0.0',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _dimensionsController,
                label: 'Dimensions (L x W x H cm)',
                hint: 'e.g., 20 x 15 x 10',
              ),
              const SizedBox(height: 16),

              // Settings
              _buildSectionTitle('Settings'),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Featured Product',
                subtitle: 'Highlight this product in featured section',
                value: _isFeatured,
                onChanged: (value) {
                  setState(() {
                    _isFeatured = value;
                  });
                },
              ),
              _buildSwitchTile(
                title: 'In Stock',
                subtitle: 'Product is available for purchase',
                value: _isInStock,
                onChanged: (value) {
                  setState(() {
                    _isInStock = value;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _saveProduct,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFADFF2F),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFADFF2F).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color.fromARGB(
                      255,
                      240,
                      237,
                      237,
                    ).withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFADFF2F),
            activeTrackColor: const Color(0xFFADFF2F).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
