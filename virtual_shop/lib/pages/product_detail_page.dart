import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/chat_page.dart';
import 'package:virtual_shop/pages/edit_product.dart';
import 'package:virtual_shop/pages/virtual_try_on_page.dart';
import 'package:virtual_shop/pages/product_ar_viewer_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:virtual_shop/utils/cart_api.dart';
import 'package:virtual_shop/utils/related_products_service.dart';
import 'package:virtual_shop/utils/review_service.dart';
import 'package:virtual_shop/widgets/glass_container.dart';
import 'package:virtual_shop/utils/like_service.dart';

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
  List<Product> _related = const [];
  bool _loadingRelated = false;
  String? _relatedError;
  bool _paletteReady = false;
  // Reviews state
  List<Map<String, dynamic>> _reviews = const [];
  bool _loadingReviews = false;
  String? _reviewsError;
  double _avgRating = 0;
  int _reviewCount = 0;
  int _selectedStars = 0;
  String? _modelLink;
  bool _loadingModel = false;
  bool _isOwner = false; // whether current user owns the product
  bool _liked = false;
  bool _liking = false;

  Future<void> _loadRelated() async {
    if ((widget.product.id).isEmpty) return;
    setState(() {
      _loadingRelated = true;
      _relatedError = null;
    });
    try {
      final results = await RelatedProductsService.fetchRelatedProducts(
        productId: widget.product.id,
        limit: 8,
      );
      debugPrint('Related products: $results');
      if (mounted) {
        setState(() {
          _related = results;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _relatedError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingRelated = false;
        });
      }
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
      _reviewsError = null;
    });
    try {
      final data = await ReviewService.fetchReviews(
        productId: widget.product.id,
        limit: 20,
      );
      final List<dynamic> arr = (data['reviews'] as List?) ?? const [];
      final List<Map<String, dynamic>> items = [];
      for (final e in arr) {
        if (e is Map<String, dynamic>) {
          items.add(e);
        } else if (e is Map) {
          items.add(e.cast<String, dynamic>());
        }
      }
      final summary = (data['summary'] as Map?)?.cast<String, dynamic>();
      setState(() {
        _reviews = items;
        _avgRating = (summary?['avg'] as num?)?.toDouble() ?? 0;
        _reviewCount = (summary?['count'] as num?)?.toInt() ?? items.length;
      });
    } catch (e) {
      setState(() {
        _reviewsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingReviews = false;
        });
      }
    }
  }

  Widget _buildRelatedProductsSection() {
    final related = _related;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Related Products',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_loadingRelated)
          const Center(child: CircularProgressIndicator())
        else if (_relatedError != null)
          Text(_relatedError!, style: const TextStyle(color: Colors.red))
        else if (related.isEmpty)
          Text('No related products', style: TextStyle(color: Colors.grey[600]))
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, minHeight: 180),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: related.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = related[index];
                debugPrint(product.toString());
                return SizedBox(
                  width: 150,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailPage(product: product),
                        ),
                      );
                    },
                    child: _ProductCardMini(product: product),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _ProductCardMini({required Product product}) {
    debugPrint(_categoryLabel(product.category));
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _AdaptiveImage(
                  image: product.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _categoryLabel(product.category),
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 3,
                child: Text(
                  '৳${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        product.rating.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  late Color _dominantColor;
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
    _loadRelated();
    _loadReviews();
    _load3DModel();
    final user = Supabase.instance.client.auth.currentUser;
    _isOwner = user != null && user.id == widget.product.authId;
    _initLike();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initLike() async {
    try {
      final liked = await LikeService.isLiked(widget.product.id);
      if (mounted) setState(() => _liked = liked);
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    if (_liking) return;
    setState(() => _liking = true);
    try {
      if (_liked) {
        await LikeService.unlikeProduct(widget.product.id);
        if (mounted) setState(() => _liked = false);
      } else {
        final ok = await LikeService.likeProduct(widget.product.id);
        if (mounted && ok) setState(() => _liked = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Like failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _updatePaletteGenerator() async {
    try {
      final String img = widget.product.image;
      final bool isNet =
          img.startsWith('http://') || img.startsWith('https://');
      final ImageProvider baseProvider = isNet
          ? NetworkImage(img)
          : AssetImage(img);
      // Use a resized decode for faster, lighter palette extraction
      final ImageProvider resized = ResizeImage(baseProvider, width: 64);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        resized,
        maximumColorCount: 16,
      );
      if (!mounted) return;
      if (paletteGenerator.dominantColor != null) {
        setState(() {
          _dominantColor = paletteGenerator.dominantColor!.color;
          _paletteReady = true;
        });
      } else {
        setState(() {
          _paletteReady = true; // Avoid waiting forever
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paletteReady = true;
      });
    }
  }

  // comments system replaced by reviews

  @override
  Widget build(BuildContext context) {
    final Color overlayBase = _paletteReady ? _dominantColor : Colors.white;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [overlayBase.withOpacity(0.9), Colors.white],
                center: Alignment.topCenter,
                radius: 1.5,
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                color: overlayBase.withOpacity(0.8),
              ),
            ),
          ),
          Hero(
            tag: widget.product.image,
            child: _AdaptiveImage(
              image: widget.product.image,
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
              fit: BoxFit.cover,
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
                  if (_isOwner) ...[
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
                  ],
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
                        icon: _liking
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : Icon(
                                _liked ? Icons.favorite : Icons.favorite_border,
                                color: _liked ? Colors.redAccent : Colors.black,
                              ),
                        onPressed: _toggleLike,
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
                              builder: (context) =>
                                  ChatPage(product: widget.product),
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
                                  _categoryLabel(widget.product.category),
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
                                      (_avgRating == 0
                                              ? widget.product.rating
                                              : _avgRating)
                                          .toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: rf(context, 16),
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: rf(context, 6)),
                                    Text(
                                      '($_reviewCount)',
                                      style: TextStyle(
                                        fontSize: rf(context, 12),
                                        color: Colors.black87,
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
                  // _buildInfoChips(),
                  // const SizedBox(height: 24),
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
                  _buildRelatedProductsSection(),
                  const SizedBox(height: 32),
                  _buildReviewSection(),
                  const SizedBox(
                    height: 30,
                  ), // Reduced padding to prevent overflow
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _categoryLabel(dynamic category) {
    if (category == null) return '';
    if (category is ProductCategory) {
      switch (category) {
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
          return '';
      }
    }
    // Fallback for raw strings
    String raw = category.toString();
    if (raw.contains('.')) raw = raw.split('.').last; // enum to last part
    final normalized = raw
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z]'), '');
    switch (normalized) {
      case 'electronics':
        return 'Electronics';
      case 'fashion':
        return 'Fashion';
      case 'homeandgarden':
        return 'Home & Garden';
      case 'sports':
        return 'Sports';
      case 'books':
        return 'Books';
      case 'toys':
        return 'Toys';
      case 'beauty':
        return 'Beauty';
      case 'automotive':
        return 'Automotive';
      case 'health':
        return 'Health';
      case 'foodandbeverages':
        return 'Food & Beverages';
      default:
        return '';
    }
  }

  // ignore: unused_element
  Widget _buildInfoChips() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: [
        // _buildInfoChip('Weather', widget.product.weather), // Removed because 'weather' does not exist on Product
        // _buildInfoChip('Temp', widget.product.temp), // Comment out or remove if 'temp' does not exist
        // _buildInfoChip('Event', widget.product.event), // Comment out or remove if 'event' does not exist
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_modelLink != null)
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductARViewerPage(
                      modelUrl: _modelLink!,
                      productName: widget.product.name,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _loadingModel
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.view_in_ar, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                        ],
                      ),
              ),
            ),
          ),
        if (_modelLink != null) const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VirtualTryOnPage(
                    productImage: widget.product.image,
                    productName: widget.product.name,
                    productId: widget.product.id,
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.face_retouching_natural,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  // Text(
                  //   'Virtual Try On',
                  //   style: TextStyle(
                  //     fontSize: rf(context, 16),
                  //     color: Colors.white,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () async {
              try {
                await CartApi.addToCart(
                  productId: widget.product.id,
                  quantity: 1,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Added to cart')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Add to cart failed: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFADFF2F),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: const Icon(
                Icons.shopping_cart_checkout_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _load3DModel() async {
    setState(() {
      _loadingModel = true;
    });
    try {
      print("Loading 3D model for product ID: ${widget.product.id}");
      final envServer = dotenv.env['SERVER_URL'] ?? '';
      String base = envServer.isNotEmpty ? envServer : '';
      print("base is '$base'");
      if (base.endsWith('/rest/v1')) {
        base = base.substring(0, base.length - '/rest/v1'.length);
      }
      if (base.endsWith('/')) base = base.substring(0, base.length - 1);
      if (base.isEmpty) return; // cannot resolve
      final uri = Uri.parse('$base/products/${widget.product.id}/3dmodel');
      final headers = <String, String>{'Content-Type': 'application/json'};
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final map = jsonDecode(resp.body) as Map<String, dynamic>?;
        final link = map?['model_link'] as String?;
        print('3D model response:');
        print(map);
        if (link != null && mounted) setState(() => _modelLink = link);
      }
    } catch (e) {
      // swallow errors silently; AR button just won't show
      print('3D model load error: $e');
    } finally {
      if (mounted) setState(() => _loadingModel = false);
    }
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: TextStyle(
                fontSize: rf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_loadingReviews)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        SizedBox(height: rf(context, 12)),
        if (_reviewsError != null)
          Text(_reviewsError!, style: const TextStyle(color: Colors.red)),
        if (_reviews.isEmpty && _reviewsError == null && !_loadingReviews)
          Text(
            'No reviews yet. Be the first to review!',
            style: TextStyle(color: Colors.grey[700]),
          ),
        if (_reviews.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = _reviews[i];
              final user = (r['user'] as Map?)?.cast<String, dynamic>() ?? {};
              final name = (user['name'] as String?)?.trim();
              final avatar = (user['profile_image'] as String?) ?? '';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: avatar.isNotEmpty
                          ? NetworkImage(avatar)
                          : null,
                      child: avatar.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name?.isNotEmpty == true ? name! : 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    5,
                                    (idx) => Icon(
                                      idx < (r['rating'] ?? 0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (r['review'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 17, 17, 17),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        SizedBox(height: rf(context, 16)),
        _buildAddReviewCard(),
      ],
    );
  }

  Widget _buildAddReviewCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add your review',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (i) {
              final idx = i + 1;
              return IconButton(
                onPressed: () {
                  setState(() => _selectedStars = idx);
                },
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  idx <= _selectedStars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write your review...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  if (_selectedStars < 1 || _selectedStars > 5) {
                    throw Exception('Please select a rating (1-5)');
                  }
                  final text = _commentController.text.trim();
                  if (text.isEmpty) {
                    throw Exception('Please enter a review');
                  }
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) {
                    throw Exception('Please sign in to submit a review');
                  }
                  await ReviewService.submitReview(
                    productId: widget.product.id,
                    rating: _selectedStars,
                    review: text,
                  );
                  _commentController.clear();
                  setState(() => _selectedStars = 0);
                  await _loadReviews();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  const _AdaptiveImage({
    required this.image,
    this.height,
    this.width,
    this.fit,
  });

  bool get _isNetwork =>
      image.startsWith('http://') || image.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      // Estimate cache size based on provided width/height or screen size,
      // guarding against Infinity/NaN widths.
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final double logicalW = (width != null && width!.isFinite && width! > 0)
          ? width!
          : MediaQuery.of(context).size.width;
      final double pxW = logicalW.isFinite && logicalW > 0
          ? logicalW * devicePixelRatio
          : double.nan;
      final int? memW = (pxW.isFinite && pxW > 0) ? pxW.round() : null;
      return CachedNetworkImage(
        imageUrl: image,
        height: height,
        width: width,
        fit: fit,
        memCacheWidth: memW,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => SizedBox(
          height: height,
          width: width,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => SizedBox(
          height: height,
          width: width,
          child: const Center(child: Icon(Icons.broken_image, size: 48)),
        ),
      );
    }
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final double logicalW = (width != null && width!.isFinite && width! > 0)
        ? width!
        : MediaQuery.of(context).size.width;
    final double pxW = logicalW.isFinite && logicalW > 0
        ? logicalW * devicePixelRatio
        : double.nan;
    final int? cacheWidth = (pxW.isFinite && pxW > 0) ? pxW.round() : null;
    return Image.asset(
      image,
      height: height,
      width: width,
      fit: fit,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => SizedBox(
        height: height,
        width: width,
        child: const Center(child: Icon(Icons.broken_image, size: 48)),
      ),
    );
  }
}
