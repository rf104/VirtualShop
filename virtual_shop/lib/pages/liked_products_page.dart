import 'package:flutter/material.dart';
import 'package:virtual_shop/utils/like_service.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/widgets/glass_container.dart';
import 'product_detail_page.dart';

class LikedProductsPage extends StatefulWidget {
  const LikedProductsPage({super.key});

  @override
  State<LikedProductsPage> createState() => _LikedProductsPageState();
}

class _LikedProductsPageState extends State<LikedProductsPage> {
  bool _loading = true;
  String? _error;
  List<Product> _products = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await LikeService.fetchLikedProducts();
      if (mounted)
        setState(() {
          _products = items;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
        });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Liked Products'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            : _products.isEmpty
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No liked products yet',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                  ),
                ],
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: _products.length,
                itemBuilder: (context, i) {
                  final p = _products[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(product: p),
                      ),
                    ),
                    child: GlassContainer(
                      borderRadius: 24,
                      color: Colors.white.withOpacity(0.06),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image(
                                  image: p.image.startsWith('http')
                                      ? NetworkImage(p.image) as ImageProvider
                                      : AssetImage(p.image),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '৳${p.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
