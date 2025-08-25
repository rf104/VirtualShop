import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

  String _selectedCategory = 'Electronics';
  String _selectedCondition = 'New';
  bool _isFeatured = false;
  bool _isInStock = true;
  final List<dynamic> _selectedImages =
      []; // Can contain both File and String (asset path)
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final Map<String, List<String>> _categoryMap = {
    'Clothing': [
      'Cozy Wear',
      'Regular Wear',
      'Party Wear',
      'Formal Wear',
      'Sports Wear',
    ],
    'Accessories': ['Glasses', 'Hats', 'Bags', 'Jewelry', 'Watches'],
    'Footwear': ['Casual', 'Formal', 'Sports', 'Sandals', 'Boots'],
  };

  late List<String> _categories;
  late String _productType;

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair', 'Poor'];
  final List<String> _weatherOptions = [
    'Sunny',
    'Rainy',
    'Cloudy',
    'Snowy',
    'Windy',
  ];
  final List<String> _tempOptions = [
    '10-12C',
    '20-22C',
    '30-35C',
    '35-40C',
    '1-10C',
  ];
  final List<String> _eventOptions = [
    'Promonde',
    'NewYear',
    'Party',
    'Business',
    'Sports',
    'Beach',
  ];

  late String _selectedWeather;
  late String _selectedTemp;
  late String _selectedEvent;

  String _determineProductType(String name) {
    name = name.toLowerCase();
    if (name.contains('glass') ||
        name.contains('watch') ||
        name.contains('bag') ||
        name.contains('hat')) {
      return 'Accessories';
    } else if (name.contains('shoe') ||
        name.contains('boot') ||
        name.contains('sandal')) {
      return 'Footwear';
    } else {
      return 'Clothing';
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _stockController = TextEditingController(text: "1"); // Default stock
    _brandController = TextEditingController();
    _weightController = TextEditingController();
    _dimensionsController = TextEditingController();

    // Determine product type and set categories
    _productType = _determineProductType(widget.product.name);
    _categories = _categoryMap[_productType] ?? _categoryMap['Clothing']!;
    _selectedCategory = widget.product.category.isNotEmpty
        ? widget.product.category
        : _categories.first;

    // Initialize with safe default values
    _selectedWeather = _weatherOptions.contains(widget.product.weather)
        ? widget.product.weather
        : _weatherOptions.first;

    _selectedTemp = _tempOptions.contains(widget.product.temp)
        ? widget.product.temp
        : _tempOptions.first;

    _selectedEvent = _eventOptions.contains(widget.product.event)
        ? widget.product.event
        : _eventOptions.first;

    // Initialize the first image if product has one
    if (widget.product.image.isNotEmpty) {
      if (widget.product.image.startsWith('assets/')) {
        _selectedImages.add(widget.product.image); // Store asset path as is
      } else {
        _selectedImages.add(
          File(widget.product.image),
        ); // Create File object for local files
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Ensure value exists in items, otherwise use first item
    final safeValue = items.contains(value) ? value : items.first;
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFADFF2F)),
          ),
          child: DropdownButton<String>(
            value: safeValue,
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
            activeColor: const Color(0xFFADFF2F),
            activeTrackColor: const Color(0xFFADFF2F).withOpacity(0.3),
          ),
        ],
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
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xff667eea),
                        size: 48,
                      ),
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
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        _showErrorSnackBar('Please add at least one product image');
        return;
      }

      // Prepare data for saving
      Product updatedProduct = Product(
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        weather: _selectedWeather,
        temp: _selectedTemp,
        event: _selectedEvent,
        image: _selectedImages.isNotEmpty
            ? (_selectedImages.first is File
                  ? (_selectedImages.first as File).path
                  : _selectedImages.first as String)
            : '',
        rating: widget.product.rating, // Preserve the existing rating
      );

      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Implement the actual save functionality here
        await Future.delayed(const Duration(seconds: 2)); // Simulate API call

        // Pass the updated product back to the previous screen
        Navigator.pop(context, updatedProduct);

        _showSuccessSnackBar('Product updated successfully!');
        Navigator.pop(context);
      } catch (e) {
        _showErrorSnackBar('Failed to update product: $e');
      } finally {
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

              // Weather and Event Options
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Weather',
                      value: _selectedWeather,
                      items: _weatherOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedWeather = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Temperature',
                      value: _selectedTemp,
                      items: _tempOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedTemp = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Event Type',
                value: _selectedEvent,
                items: _eventOptions,
                onChanged: (value) {
                  setState(() {
                    _selectedEvent = value!;
                  });
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
}
