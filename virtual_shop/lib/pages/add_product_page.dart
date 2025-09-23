import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:virtual_shop/utils/product_api.dart';

class _TaggedImage {
  final File file;
  final String tag;
  const _TaggedImage({required this.file, required this.tag});
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();

  String _selectedCategory = 'Electronics';
  String _selectedCondition = 'New';
  bool _isFeatured = false;
  bool _isInStock = true;
  // Legacy storage retained for hot-reload migration (could be List<File> in older builds)
  final List _selectedImages = [];
  // New authoritative typed images list with unique tags
  final List<_TaggedImage> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _categories = [
    'Electronics',
    'Fashion',
    'Home & Garden',
    'Sports',
    'Books',
    'Toys',
    'Beauty',
    'Automotive',
    'Health',
    'Food & Beverages',
  ];

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];

  String _generateImageTag() {
    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final salt = random.nextInt(0x7fffffff);
    return 'img_${timestamp}_$salt';
  }

  void _migrateLegacyImagesIfNeeded() {
    if (_images.isNotEmpty) return;
    if (_selectedImages.isEmpty) return;
    final first = _selectedImages.first;
    if (first is File) {
      for (final item in List<File>.from(_selectedImages)) {
        _images.add(_TaggedImage(file: item, tag: _generateImageTag()));
      }
      _selectedImages.clear();
    } else if (first is _TaggedImage) {
      _images.addAll(List<_TaggedImage>.from(_selectedImages));
      _selectedImages.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _migrateLegacyImagesIfNeeded();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Called on hot reload; migrate any legacy state.
    _migrateLegacyImagesIfNeeded();
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
        title: Text(
          'Add New Product',
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width > 600 ? 22 : 20,
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
                  gradient: const LinearGradient(
                    colors: [Color(0xff667eea), Color(0xff764ba2)],
                  ),
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
                          color: Colors.white,
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
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width > 768
                ? MediaQuery.of(context).size.width * 0.2
                : 20,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Images Section
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWideScreen = constraints.maxWidth > 600;
                    return isWideScreen
                        ? Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  label: 'Category',
                                  value: _selectedCategory,
                                  items: _categories,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _brandController,
                                  label: 'Brand',
                                  hint: 'Enter brand name',
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildDropdown(
                                label: 'Category',
                                value: _selectedCategory,
                                items: _categories,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _brandController,
                                label: 'Brand',
                                hint: 'Enter brand name',
                              ),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 24),

                // Pricing & Stock
                _buildSectionTitle('Pricing & Stock'),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWideScreen = constraints.maxWidth > 600;
                    return isWideScreen
                        ? Row(
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
                          )
                        : Column(
                            children: [
                              _buildTextField(
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
                              const SizedBox(height: 16),
                              _buildTextField(
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
                            ],
                          );
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Condition',
                  value: _selectedCondition,
                  items: _conditions,
                  onChanged: (value) {
                    setState(() {
                      _selectedCondition = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Product Details
                _buildSectionTitle('Product Details'),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWideScreen = constraints.maxWidth > 600;
                    return isWideScreen
                        ? Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _weightController,
                                  label: 'Weight (kg)',
                                  hint: '0.0',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _dimensionsController,
                                  label: 'Dimensions (L x W x H cm)',
                                  hint: 'e.g., 20 x 15 x 10',
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
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
                            ],
                          );
                  },
                ),
                const SizedBox(height: 24),

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
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width > 600
                        ? 400
                        : double.infinity,
                  ),
                  child: GestureDetector(
                    onTap: _saveProduct,
                    child: Container(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width > 600 ? 18 : 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff667eea), Color(0xff764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff667eea).withOpacity(0.3),
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
                          : Text(
                              'Add Product',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    MediaQuery.of(context).size.width > 600
                                    ? 18
                                    : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 72),
              ],
            ),
          ),
        ),
      ),
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
                '${_images.length}/5',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_images.isEmpty)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: MediaQuery.of(context).size.width > 600 ? 250 : 200,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xff667eea).withOpacity(0.5),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: const Color(0xff667eea),
                        size: MediaQuery.of(context).size.width > 600 ? 56 : 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upload Product Images',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width > 600
                              ? 18
                              : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add up to 5 images',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: MediaQuery.of(context).size.width > 600
                              ? 16
                              : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 3;
                    if (constraints.maxWidth > 600) {
                      crossAxisCount = 5;
                    } else if (constraints.maxWidth > 400) {
                      crossAxisCount = 4;
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        final tagged = _images[index];
                        return Stack(
                          key: ValueKey(tagged.tag),
                          children: [
                            Hero(
                              tag: tagged.tag,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(tagged.file),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: GestureDetector(
                                onTap: () => _editImageTag(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 4,
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tagged.tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                    );
                  },
                ),
                if (_images.length < 5) const SizedBox(height: 16),
                if (_images.length < 5)
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
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xff667eea),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add More Images',
                            style: TextStyle(
                              color: Color(0xff667eea),
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: MediaQuery.of(context).size.width > 600 ? 22 : 20,
        fontWeight: FontWeight.bold,
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
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
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
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xff667eea)),
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white),
            items: items.map((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
          ),
        ),
      ],
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xff667eea),
            activeTrackColor: const Color(0xff667eea).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            if (_images.length < 5) {
              _images.add(
                _TaggedImage(file: File(image.path), tag: _generateImageTag()),
              );
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
      if (index >= 0 && index < _images.length) {
        _images.removeAt(index);
      }
    });
  }

  Future<void> _editImageTag(int index) async {
    if (index < 0 || index >= _images.length) return;
    final current = _images[index];
    final controller = TextEditingController(text: current.tag);
    String? error;

    String? validate(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 'Tag cannot be empty';
      if (!RegExp(r'^[A-Za-z0-9_\-\.]+$').hasMatch(trimmed)) {
        return 'Use letters, numbers, _ - . only';
      }
      final exists = _images.any((e) => e.tag == trimmed && e != current);
      if (exists) return 'Tag must be unique';
      return null;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            error ??= validate(controller.text);
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Edit Image Tag',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter unique tag',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      errorText: error,
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (v) {
                      setLocalState(() {
                        error = validate(v);
                      });
                    },
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final value = controller.text;
                    final err = validate(value);
                    if (err == null) {
                      Navigator.pop(context, value.trim());
                    } else {
                      setLocalState(() {
                        error = err;
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    final newTag = result.trim();
    if (newTag == current.tag) return;
    final err = RegExp(r'^[A-Za-z0-9_\-\.]+$').hasMatch(newTag)
        ? null
        : 'invalid';
    if (err == null && !_images.any((e) => e.tag == newTag && e != current)) {
      setState(() {
        _images[index] = _TaggedImage(file: current.file, tag: newTag);
      });
    } else {
      _showErrorSnackBar('Invalid or duplicate tag');
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_images.isEmpty) {
        _showErrorSnackBar('Please add at least one product image');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final images = _images.map((e) => e.file).toList(growable: false);
        final tags = _images.map((e) => e.tag).toList(growable: false);
        await ProductApi.createProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          brand: _brandController.text.trim().isEmpty
              ? null
              : _brandController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          stock: int.parse(_stockController.text.trim()),
          condition: _selectedCondition,
          weightKg: _weightController.text.trim().isEmpty
              ? null
              : double.tryParse(_weightController.text.trim()),
          dimensions: _dimensionsController.text.trim().isEmpty
              ? null
              : _dimensionsController.text.trim(),
          isFeatured: _isFeatured,
          isInStock: _isInStock,
          images: images,
          imageTags: tags,
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to add product: $e');
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showSuccessSnackBar('Submitted! Waiting for admin approval.');
      Navigator.pop(context);
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
}
