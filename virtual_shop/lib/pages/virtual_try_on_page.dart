import 'package:flutter/material.dart';

class VirtualTryOnPage extends StatefulWidget {
  final String productImage;
  final String productName;

  const VirtualTryOnPage({
    super.key,
    required this.productImage,
    required this.productName,
  });

  @override
  State<VirtualTryOnPage> createState() => _VirtualTryOnPageState();
}

class _VirtualTryOnPageState extends State<VirtualTryOnPage> {
  late final List<String> _productViews;
  late String _currentMainImage;
  int _selectedThumbnailIndex = 0;

  @override
  void initState() {
    super.initState();
    _productViews = [
      widget.productImage,
      widget.productImage,
      widget.productImage,
      widget.productImage,
    ];
    _currentMainImage = _productViews[0];
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _cycleMainImage() {
    setState(() {
      _selectedThumbnailIndex =
          (_selectedThumbnailIndex + 1) % _productViews.length;
      _currentMainImage = _productViews[_selectedThumbnailIndex];
    });
  }

  void _onThumbnailTapped(int index) {
    setState(() {
      _selectedThumbnailIndex = index;
      _currentMainImage = _productViews[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.productName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // TODO: Implement more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            flex: 5,
            child: Center(
              child: Image.asset(
                _currentMainImage,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Could not load image asset',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _cycleMainImage,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: const Icon(Icons.threesixty, color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _productViews.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onThumbnailTapped(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedThumbnailIndex == index
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          _productViews[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement actual online fitting logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Online Fitting',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
