import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:virtual_shop/models/product.dart'; // Ensure this points to your updated Product model
import 'package:virtual_shop/pages/virtual_closet.dart';
import 'package:virtual_shop/widgets/best_seller_widget.dart';
import 'package:virtual_shop/widgets/categories_widget.dart';
import 'package:virtual_shop/widgets/favorite_stores.dart';
import 'package:virtual_shop/widgets/promotion_widget.dart';
import 'package:virtual_shop/widgets/shop_screenshots_widget.dart';
import 'package:virtual_shop/widgets/story_page.dart';

class AllStoryPage extends StatelessWidget {
  const AllStoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> stories = [
      {'image': 'assets/images/profile.jpg', 'username': '@Aref'},
      {'image': 'assets/images/profile3.jpg', 'username': '@Arik'},
      {'image': 'assets/images/profile4.jpg', 'username': '@rahad'},
      {'image': 'assets/images/profile6.jpg', 'username': '@raisul'},
      {'image': 'assets/images/demo1.jpg', 'username': '@ahmed'},
      {'image': 'assets/images/demo5.jpg', 'username': '@hossain'},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_shopping_cart_outlined,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'VShop',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Story(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 10.0),
                          child: YourStoryItem(),
                        ),
                      );
                    }
                    final story = stories[index - 1];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Story(),
                          ),
                        );
                      },
                      child: StoryItem(story: story),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
              const ShopScreenshotsWidget(),
              const SizedBox(height: 24),
              const PromotionWidget(),
              const SizedBox(height: 24),
              const FavoriteStores(),
              const SizedBox(height: 24),
              const BestSellerWidget(),
              const SizedBox(height: 24),
              const CategoriesWidget(),
              const SizedBox(height: 24),
              const SharedClosetsSection(), // Changed to const as its children are constant for now
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryItem extends StatelessWidget {
  final Map<String, String> story;

  const StoryItem({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Story()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: CircleAvatar(
                  backgroundImage: AssetImage(story['image']!),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story['username']!,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class YourStoryItem extends StatefulWidget {
  const YourStoryItem({super.key});

  @override
  State<YourStoryItem> createState() => _YourStoryItemState();
}

class _YourStoryItemState extends State<YourStoryItem> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      final Uint8List imageBytes = await pickedFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Print the base64 image
      print('Base64 Image: $base64Image');

      // Show a snackbar to confirm the image was processed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image processed and base64 printed to console'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Choose Image Source',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Column(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/profile2.jpg'),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('You', style: TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}

class SharedCloset {
  final String userName;
  final String userAvatar;
  final String closetName;
  final List<Product> products;

  SharedCloset({
    required this.userName,
    required this.userAvatar,
    required this.closetName,
    required this.products,
  });
}

// Updated dummyProducts to match the Product model constructor
final List<Product> dummyProducts = List.generate(
  15,
  (index) => Product(
    id: 'dummy_id_${index + 1}', // Required field
    authId: 'dummy_seller_id', // Required field
    name: 'Product ${index + 1}',
    image:
        'assets/images/demo${(index % 5) + 1}.jpg', // Still using asset paths for dummy
    rating: (index % 5 + 1).toDouble(), // Add required rating field (1.0 - 5.0)
    price: (1.0 * index * 10) + 20,
    category: ProductCategory.regularWear, // Using enum
    stock: 100 - (index * 5), // Dummy stock
    condition: ProductCondition.newCondition, // Using enum
    isFeatured: index % 3 == 0, // Dummy feature status
    isInStock: index % 5 != 0, // Dummy in stock status
    description: 'This is a description for product ${index + 1}.',
    createdAt: DateTime.now(), // Required field
    updatedAt: DateTime.now(), // Required field
  ),
);

final List<SharedCloset> dummyClosets = [
  SharedCloset(
    userName: 'Alice',
    userAvatar: 'assets/images/profile2.jpg',
    closetName: 'Summer Vibes',
    products: dummyProducts.sublist(0, 5),
  ),
  SharedCloset(
    userName: 'Bob',
    userAvatar: 'assets/images/profile3.jpg',
    closetName: 'Winter Collection',
    products: dummyProducts.sublist(5, 10),
  ),
  SharedCloset(
    userName: 'Charlie',
    userAvatar: 'assets/images/profile4.jpg',
    closetName: 'Casual Wear',
    products: dummyProducts.sublist(10, 15),
  ),
];

class SharedClosetsSection extends StatelessWidget {
  const SharedClosetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular Shared Closets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View >',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dummyClosets.length,
            itemBuilder: (context, index) {
              final closet = dummyClosets[index];
              return ClosetCard(closet: closet);
            },
          ),
        ),
      ],
    );
  }
}

class ClosetCard extends StatelessWidget {
  final SharedCloset closet;

  const ClosetCard({super.key, required this.closet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VirtualClosetPage(products: closet.products),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          image: DecorationImage(
            image: AssetImage(
              closet.products.first.image,
            ), // Still using AssetImage for dummy data
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20.0),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    color: Colors.black.withOpacity(0.3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                closet.closetName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by ${closet.userName}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
