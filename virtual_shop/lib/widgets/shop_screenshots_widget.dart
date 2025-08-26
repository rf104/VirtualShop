import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/designs/frosted_glass/frosted_glass.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:virtual_shop/utils/image_search_service.dart';

import '../models/product.dart';
import '../pages/related_products_page.dart';

typedef OnImagePicked = void Function(Uint8List imageBytes);

class ShopScreenshotsWidget extends StatefulWidget {
  final OnImagePicked? onImagePicked;
  const ShopScreenshotsWidget({super.key, this.onImagePicked});

  @override
  State<ShopScreenshotsWidget> createState() => _ShopScreenshotsWidgetState();
}

class _ShopScreenshotsWidgetState extends State<ShopScreenshotsWidget> {
  List<Product> _dummyProducts() {
    return [
      Product(
        id: 'screenshot_product_1',
        authId: 'screenshot_seller_1',
        name: 'Winter Shearling Jacket',
        description:
            'Elevate your winter wardrobe with this luxurious white shearling jacket, paired with a chic black turtleneck and matching skirt. Perfect for a stylish day out, this outfit combines comfort and high fashion, ensuring you stay warm and turn heads wherever you go.',
        category: ProductCategory.cozyWear,
        brand: 'Fashion Elite',
        price: 120.00,
        stock: 15,
        condition: ProductCondition.newCondition,
        weightKg: 0.8,
        dimensions: '60x40x5 cm',
        isFeatured: true,
        isInStock: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        image: 'assets/images/hoodie.jpg',
        rating: 4.1,
        isLoved: false,
      ),
      Product(
        id: 'screenshot_product_2',
        authId: 'screenshot_seller_2',
        name: 'Casual Chic Ensemble',
        description:
            'Step out in style with this casual chic ensemble featuring a trendy hat.',
        category: ProductCategory.regularWear,
        brand: 'Urban Style',
        price: 85.50,
        stock: 25,
        condition: ProductCondition.newCondition,
        weightKg: 0.2,
        dimensions: '30x30x15 cm',
        isFeatured: false,
        isInStock: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        image: 'assets/images/hat1.jpg',
        rating: 4.1,
        isLoved: false,
      ),
      Product(
        id: 'screenshot_product_3',
        authId: 'screenshot_seller_3',
        name: 'Urban Explorer Outfit',
        description:
            'Gear up for your next adventure with this urban explorer outfit, featuring a rugged jacket, durable boots, and practical cargo pants. Designed for comfort and functionality, this outfit is perfect for exploring the city or enjoying a weekend getaway.',
        category: ProductCategory.footwear,
        brand: 'Adventure Gear',
        price: 215.00,
        stock: 8,
        condition: ProductCondition.newCondition,
        weightKg: 1.2,
        dimensions: '35x25x15 cm',
        isFeatured: true,
        isInStock: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        image: 'assets/images/shoe.jpg',
        rating: 4.9,
        isLoved: false,
      ),
      Product(
        id: 'screenshot_product_4',
        authId: 'screenshot_seller_4',
        name: 'Classic glasses',
        description:
            'Elevate your style with these classic glasses, perfect for any occasion. Their timeless design and high-quality material make them a must-have accessory for those who appreciate both fashion and functionality.',
        category: ProductCategory.regularWear,
        brand: 'Vision Pro',
        price: 215.00,
        stock: 12,
        condition: ProductCondition.newCondition,
        weightKg: 0.05,
        dimensions: '15x5x2 cm',
        isFeatured: false,
        isInStock: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        image: 'assets/images/glass1.jpg',
        rating: 4.9,
        isLoved: false,
      ),
    ];
  }

  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  Future<void> _pickAndEditImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    final Uint8List imageBytes = await pickedFile.readAsBytes();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.memory(
          imageBytes,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List editedBytes) async {
              if (widget.onImagePicked != null) {
                widget.onImagePicked!(editedBytes);
              }
              if (!mounted) return;
              setState(() => _loading = true);
              try {
                final products = await ImageSearchService.searchProductsByImage(
                  imageBytes: editedBytes,
                  limit: 6,
                );
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => RelatedProductsPage(
                      products: products.isNotEmpty
                          ? products
                          : _dummyProducts(),
                    ),
                  ),
                  (route) => route.isFirst,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Image search failed: $e')),
                );
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        RelatedProductsPage(products: _dummyProducts()),
                  ),
                  (route) => route.isFirst,
                );
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
          configs: ProImageEditorConfigs(
            designMode: platformDesignMode,
            theme: Theme.of(context).copyWith(
              iconTheme: Theme.of(
                context,
              ).iconTheme.copyWith(color: Colors.white),
            ),
            mainEditor: MainEditorConfigs(
              widgets: MainEditorWidgets(
                closeWarningDialog: (editor) async {
                  if (!context.mounted) return false;
                  return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) =>
                            FrostedGlassCloseDialog(editor: editor),
                      ) ??
                      false;
                },
                appBar: (editor, rebuildStream) => null,
                bottomBar: (editor, rebuildStream, key) => null,
                bodyItems: _buildMainBodyWidgets,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openStickerEditor(ProImageEditorState editor) async {
    Layer? layer = await editor.openPage(
      FrostedGlassStickerPage(
        configs: editor.configs,
        callbacks: editor.callbacks,
      ),
    );

    if (layer == null || !mounted) return;

    if (layer.runtimeType != WidgetLayer) {
      layer.scale = editor.configs.emojiEditor.initScale;
    }

    editor.addLayer(layer);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        children: [
          const Text(
            'Shop Your Screenshots',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'UPLOAD YOUR PHOTOS TO FIND A STYLE MATCH',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          if (_loading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _pickAndEditImage(ImageSource.camera),
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Camera',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _pickAndEditImage(ImageSource.gallery),
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Photos',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<ReactiveWidget> _buildMainBodyWidgets(
    ProImageEditorState editor,
    Stream<dynamic> rebuildStream,
  ) {
    return [
      if (editor.selectedLayerIndex < 0)
        ReactiveWidget(
          stream: rebuildStream,
          builder: (_) => FrostedGlassActionBar(
            editor: editor,
            openStickerEditor: () => _openStickerEditor(editor),
          ),
        ),
    ];
  }
}
