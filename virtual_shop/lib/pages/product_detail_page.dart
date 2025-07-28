import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/chat_page.dart';
import 'package:virtual_shop/pages/edit_product.dart';
import 'package:virtual_shop/pages/virtual_try_on_page.dart';

import 'package:virtual_shop/widgets/glass_container.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final Color? dominantColor;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.dominantColor,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Color _dominantColor;
  final List<String> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  double rf(BuildContext context, double size) {
    double baseWidth = 375.0;
    double screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / baseWidth);
  }

  @override
  void initState() {
    super.initState();
    if (widget.dominantColor != null) {
      _dominantColor = widget.dominantColor!;
    } else {
      _dominantColor = Colors.white;
      _updatePaletteGenerator();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updatePaletteGenerator() async {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      AssetImage(widget.product.image),
    );
    if (paletteGenerator.dominantColor != null) {
      if (mounted) {
        setState(() {
          _dominantColor = paletteGenerator.dominantColor!.color;
        });
      }
    }
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        _comments.add(_commentController.text);
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [_dominantColor.withOpacity(0.9), Colors.white],
                center: Alignment.topCenter,
                radius: 1.5,
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: _dominantColor.withOpacity(0.8)),
            ),
          ),
          Hero(
            tag: widget.product.image,
            child: Image.asset(
              widget.product.image,
              fit: BoxFit.cover,
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
            ),
          ),
          _buildTopBar(context),
          _buildProductInfo(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              GlassContainer(
                borderRadius: 20.0,
                width: 40,
                height: 40,
                settings: OCLiquidGlassSettings(
                  blendPx: 10.0,
                  lightbandColor: _dominantColor,
                  specAngle: 0.0,
                  specStrength: 0.0,
                ),
                color: Colors.white.withOpacity(0.4),
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 22,
                  ),
                ),
              ),
              Row(
                children: [
                  // Edit button
                  GlassContainer(
                    borderRadius: 20.0,
                    width: 40,
                    height: 40,
                    color: Colors.white.withOpacity(0.4),
                    settings: OCLiquidGlassSettings(
                      blendPx: 10.0,
                      lightbandColor: _dominantColor,
                      specAngle: 0.0,
                      specStrength: 0.0,
                    ),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProductPage(product: widget.product),
                            ),
                          );
                        },
                        splashRadius: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Favorite button
                  GlassContainer(
                    borderRadius: 20.0,
                    width: 40,
                    height: 40,
                    color: Colors.white.withOpacity(0.4),
                    settings: OCLiquidGlassSettings(
                      blendPx: 10.0,
                      lightbandColor: _dominantColor,
                      specAngle: 0.0,
                      specStrength: 0.0,
                    ),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.favorite_border,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          // TODO: Implement favorite functionality
                        },
                        splashRadius: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Voice chat button
                  GlassContainer(
                    borderRadius: 20.0,
                    width: 40,
                    height: 40,
                    color: Colors.white.withOpacity(0.4),
                    settings: OCLiquidGlassSettings(
                      blendPx: 10.0,
                      lightbandColor: _dominantColor,
                      specAngle: 0.0,
                      specStrength: 0.0,
                    ),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.voice_chat, color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatPage(),
                            ),
                          );
                        },
                        splashRadius: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Share button
                  GlassContainer(
                    borderRadius: 20.0,
                    width: 40,
                    height: 40,
                    color: Colors.white.withOpacity(0.4),
                    settings: OCLiquidGlassSettings(
                      blendPx: 10.0,
                      lightbandColor: _dominantColor,
                      specAngle: 0.0,
                      specStrength: 0.0,
                    ),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          // TODO: Implement share functionality
                        },
                        splashRadius: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return GlassContainer(
          borderRadius: 30.0,
          settings: OCLiquidGlassSettings(
            blendPx: 150,
            blurRadiusPx: 50,
            lightbandColor: _dominantColor,
            specAngle: 0.0,
            specStrength: 0.0,
            lightbandWidthPx: 20.0,
          ),

          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            color: Colors.white.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.product.category,
                                  style: TextStyle(
                                    fontSize: rf(context, 16),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: rf(context, 20),
                                    ),
                                    SizedBox(width: rf(context, 4)),
                                    Text(
                                      widget.product.rating.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: rf(context, 16),
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            color: Colors.white.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.product.name,
                                    style: TextStyle(
                                      fontSize: rf(context, 28),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Text(
                                  '৳${widget.product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: rf(context, 28),
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                      255,
                                      99,
                                      160,
                                      2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoChips(),
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            color: Colors.white.withOpacity(0.5),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: rf(context, 18),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: rf(context, 8)),
                                Text(
                                  widget.product.description,
                                  style: TextStyle(
                                    fontSize: rf(context, 16),
                                    color: const Color.fromARGB(
                                      255,
                                      41,
                                      41,
                                      41,
                                    ),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                  _buildCommentSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChips() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: [
        _buildInfoChip('Weather', widget.product.weather),
        _buildInfoChip('Temp', widget.product.temp),
        _buildInfoChip('Event', widget.product.event),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: rf(context, 12),
          color: const Color.fromARGB(255, 112, 112, 112),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VirtualTryOnPage(
                    productImage: widget.product.image,
                    productName: widget.product.name,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Virtual Try On',
              style: TextStyle(fontSize: rf(context, 16), color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implement Add to cart functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFADFF2F),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Add to cart',
              style: TextStyle(fontSize: rf(context, 16), color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: TextStyle(
            fontSize: rf(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: rf(context, 16)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) => _addComment(),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: _addComment,
              mini: true,
              backgroundColor: const Color(0xFFADFF2F),
              child: const Icon(Icons.send, color: Colors.black),
            ),
          ],
        ),
        SizedBox(height: rf(context, 16)),
        _comments.isEmpty
            ? Center(
                child: Text(
                  'No comments yet. Be the first to share your thoughts!',
                  style: TextStyle(
                    fontSize: rf(context, 14),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _comments[index],
                        style: TextStyle(
                          fontSize: rf(context, 15),
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
        SizedBox(height: rf(context, 24)),
      ],
    );
  }
}
