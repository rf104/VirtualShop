import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ProductARViewerPage extends StatelessWidget {
  final String modelUrl;
  final String productName;
  const ProductARViewerPage({
    super.key,
    required this.modelUrl,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$productName AR')),
      body: Center(
        child: ModelViewer(
          src:
              "https://wnaqfhqvghulydvnpcsw.supabase.co/storage/v1/object/public/tdmodel/combat_shirt_-_gameready_-_rigged_-_metahuman.glb",
          alt: '3D model for $productName',
          ar: true,
          autoRotate: true,
          cameraControls: true,
          backgroundColor: const Color(0xFFEFEFEF),
        ),
      ),
    );
  }
}
