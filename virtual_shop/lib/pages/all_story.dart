import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/virtual_closet.dart';
import 'package:virtual_shop/widgets/best_seller_widget.dart';
import 'package:virtual_shop/widgets/categories_widget.dart';
import 'package:virtual_shop/widgets/favorite_stores.dart';
import 'package:virtual_shop/widgets/promotion_widget.dart';
import 'package:virtual_shop/widgets/shop_screenshots_widget.dart';
import 'package:virtual_shop/widgets/story_page.dart';

class StoriesRepository {
  static String get _baseUrl {
    final fromServer = dotenv.env['SERVER_URL']?.trim();
    final fromBackend = dotenv.env['BACKEND_URL']?.trim();
    String raw = (fromServer?.isNotEmpty == true)
        ? fromServer!
        : (fromBackend?.isNotEmpty == true
              ? fromBackend!
              : 'http://127.0.0.1:8000');
    raw = raw.replaceFirst(RegExp(r'^(https?://)\s+'), r'$1');
    String url = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    try {
      // Match ProductRepository behavior for Android emulators/devices
      if (!kIsWeb && Platform.isAndroid) {
        final uri = Uri.parse(url);
        if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
          url = uri
              .replace(host: dotenv.env['hostIp'] ?? '10.103.137.37')
              .toString();
        }
      }
    } catch (_) {}
    return url;
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<List<Map<String, dynamic>>> fetchStories({
    int limit = 50,
  }) async {
    final resp = await http.get(_uri('/stories?limit=$limit'));
    if (resp.statusCode != 200) {
      throw Exception(
        'Failed to fetch stories: ${resp.statusCode} ${resp.body}',
      );
    }
    final List<dynamic> arr = jsonDecode(resp.body) as List<dynamic>;
    return arr.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

class AllStoryPage extends StatefulWidget {
  const AllStoryPage({super.key});

  @override
  State<AllStoryPage> createState() => _AllStoryPageState();
}

class _AllStoryPageState extends State<AllStoryPage> {
  late Future<List<Map<String, dynamic>>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = StoriesRepository.fetchStories();
  }

  @override
  Widget build(BuildContext context) {
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
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _storiesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Row(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.error, color: Colors.redAccent),
                          ),
                          Expanded(
                            child: Text(
                              'Failed to load stories',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      );
                    }
                    final data = snapshot.data ?? const [];
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: EdgeInsets.only(right: 10.0),
                            child: YourStoryItem(
                              onUploaded: () {
                                setState(() {
                                  _storiesFuture =
                                      StoriesRepository.fetchStories();
                                });
                              },
                            ),
                          );
                        }
                        final story = data[index - 1];
                        return StoryItemNet(story: story);
                      },
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
              // const SizedBox(height: 24),
              // SharedClosetsSection(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryItemNet extends StatelessWidget {
  final Map<String, dynamic> story;
  const StoryItemNet({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final avatar = (story['user_avatar'] as String?)?.trim();
    final name = (story['user_name'] as String?)?.trim();
    final display = (name == null || name.isEmpty)
        ? '@user'
        : '@${name.replaceAll(' ', '')}';
    final isNet =
        avatar != null &&
        (avatar.startsWith('http://') || avatar.startsWith('https://'));
    Widget avatarWidget;
    if (isNet) {
      final headers = _headersForUrl(avatar);
      avatarWidget = ClipOval(
        child: Image.network(
          avatar,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          headers: headers,
          errorBuilder: (context, error, stackTrace) => const CircleAvatar(
            backgroundImage: AssetImage('assets/images/profile2.jpg'),
          ),
        ),
      );
    } else {
      avatarWidget = const CircleAvatar(
        backgroundImage: AssetImage('assets/images/profile2.jpg'),
      );
    }
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
                child: avatarWidget,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 72,
              child: Text(
                display,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, String>? _headersForUrl(String url) {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return null;
  if (url.contains('supabase.co') && url.contains('/storage/v1/object/')) {
    return {'Authorization': 'Bearer ${session.accessToken}'};
  }
  return null;
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
  final VoidCallback onUploaded;
  const YourStoryItem({super.key, required this.onUploaded});

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
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to add a story')),
          );
        }
        return;
      }

      final uri = StoriesRepository._uri('/stories');
      final req = http.MultipartRequest('POST', uri);
      req.headers['Authorization'] = 'Bearer ${session.accessToken}';
      req.fields['caption'] = '';
      req.fields['expires_in_hours'] = '24';
      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: pickedFile.name,
        ),
      );
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Story submitted. Pending admin approval.'),
            ),
          );
        }
        widget.onUploaded();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${resp.statusCode}')),
          );
        }
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
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You',
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
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

final List<Product> dummyProducts = List.generate(
  15,
  (index) => Product(
    id: 'dummy_${index + 1}',
    authId: 'dummy_seller_${index + 1}',
    name: 'Product ${index + 1}',
    description: 'This is a description for product ${index + 1}.',
    category: ProductCategory.values[index % ProductCategory.values.length],
    brand: 'Brand ${index + 1}',
    price: (1.0 * index * 10) + 20,
    stock: 10 + index,
    condition: ProductCondition.values[index % ProductCondition.values.length],
    weightKg: 0.5 + (index * 0.1),
    dimensions: '${10 + index}x${10 + index}x${5 + index} cm',
    isFeatured: index % 3 == 0,
    isInStock: true,
    createdAt: DateTime.now().subtract(Duration(days: index)),
    updatedAt: DateTime.now().subtract(Duration(hours: index)),
    image: 'assets/images/demo${(index % 5) + 1}.jpg',
    rating: 4.5,
    isLoved: false,
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
            image: AssetImage(closet.products.first.image),
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
