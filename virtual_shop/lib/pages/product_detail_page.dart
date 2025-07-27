import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/chat_page.dart';
import 'package:virtual_shop/pages/virtual_try_on_page.dart';

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
                colors: [_dominantColor.withOpacity(0.5), Colors.white],
                center: Alignment.topCenter,
                radius: 1.5,
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.white.withOpacity(0.1)),
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
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.black),
                onPressed: () {
                  // TODO: Implement favorite functionality
                },
              ),
              IconButton(
                icon: const Icon(Icons.voice_chat, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.black),
                onPressed: () {
                  // TODO: Implement share functionality
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.product.category,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          widget.product.rating.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      '৳${widget.product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFADFF2F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoChips(),
                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.product.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 41, 41, 41),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 32),
                _buildCommentSection(),
              ],
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
        style: const TextStyle(
          fontSize: 12,
          color: Color.fromARGB(255, 112, 112, 112),
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
            child: const Text(
              'Virtual Try On',
              style: TextStyle(fontSize: 16, color: Colors.white),
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
            child: const Text(
              'Add to cart',
              style: TextStyle(fontSize: 16, color: Colors.black),
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
        const Text(
          'Comments',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        _comments.isEmpty
            ? Center(
                child: Text(
                  'No comments yet. Be the first to share your thoughts!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: 24),
      ],
    );
  }
}
