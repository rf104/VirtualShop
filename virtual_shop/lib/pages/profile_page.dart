import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:palette_generator/palette_generator.dart';
import 'package:virtual_shop/pages/virtual_closet.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/models/closet.dart';
import 'edit_profile_final.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Color> _gradientColors = [const Color(0xFF8E9EAB), Colors.black];

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  Future<void> _updatePalette() async {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      const AssetImage('assets/images/profile6.jpg'),
    );
    if (paletteGenerator.colors.length >= 2) {
      if (mounted) {
        setState(() {
          _gradientColors = [
            paletteGenerator.colors.elementAt(0),
            paletteGenerator.colors.elementAt(1),
          ];
        });
      }
    } else if (paletteGenerator.colors.isNotEmpty) {
      if (mounted) {
        setState(() {
          _gradientColors = [paletteGenerator.colors.first, Colors.black];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Frosted glass effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileInfo(context),
                const SizedBox(height: 30),
                _buildThreadsSection(),
                const SizedBox(height: 30),
                _buildClosetsSection(),
                const SizedBox(height: 30),
                _buildMyPostsSection(context),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Closet model

  List<Closet> _closets = [
    Closet(
      name: "Summer Outfits",
      image: "assets/images/hat.jpg",
      products: List<Product>.from(dummyProducts),
    ),
    Closet(
      name: "Winter Wear",
      image: "assets/images/hoodie.jpg",
      products: List<Product>.from(dummyProducts),
    ),
    Closet(
      name: "Eyewear",
      image: "assets/images/eyeglass.png",
      products: List<Product>.from(dummyProducts),
    ),
    Closet(
      name: "Shoes",
      image: "assets/images/glass1.jpg",
      products: List<Product>.from(dummyProducts),
    ),
    Closet(
      name: "Accessories",
      image: "assets/images/love.png",
      products: List<Product>.from(dummyProducts),
    ),
  ];

  Widget _buildClosetsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Closets',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _showCreateClosetDialog,
                tooltip: 'Create Closet',
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _closets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 15),
              itemBuilder: (context, index) {
                final closet = _closets[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VirtualClosetPage(products: closet.products),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          closet.image,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          closet.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateClosetDialog() async {
    String closetName = '';
    String? selectedImage;
    List<Product> selectedProducts = [];
    final List<String> closetImages = [
      "assets/images/hat.jpg",
      "assets/images/hoodie.jpg",
      "assets/images/eyeglass.png",
      "assets/images/glass1.jpg",
      "assets/images/love.png",
    ];
    // For demo, use dummyProducts from virtual_closet.dart
    final List<Product> allProducts = List<Product>.from(dummyProducts);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Create Closet',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Closet Name',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      onChanged: (val) => closetName = val,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Image:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: closetImages.map((img) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() => selectedImage = img),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selectedImage == img
                                        ? Colors.greenAccent
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    img,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Products:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: allProducts.map((prod) {
                            final isSelected = selectedProducts.contains(prod);
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedProducts.remove(prod);
                                    } else {
                                      selectedProducts.add(prod);
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.greenAccent
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      prod.image,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (closetName.isNotEmpty &&
                        selectedImage != null &&
                        selectedProducts.isNotEmpty) {
                      setState(() {
                        _closets.add(
                          Closet(
                            name: closetName,
                            image: selectedImage!,
                            products: List<Product>.from(selectedProducts),
                          ),
                        );
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.withOpacity(0.8),
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {}); // Refresh closets list
  }

  Widget _buildMyPostsSection(BuildContext context) {
    final List<String> postImages = [
      'assets/images/demo1.jpg',
      'assets/images/demo2.jpg',
      'assets/images/demo3.jpg',
      'assets/images/demo4.jpg',
      'assets/images/demo5.jpg',
      'assets/images/couple.jpg',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Posts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: postImages.length,
            itemBuilder: (context, index) {
              final imagePath = postImages[index];
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(10),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: InteractiveViewer(
                          child: Image.asset(imagePath, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(imagePath, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: Image.asset(
            'assets/images/profile2.jpg',
            height: MediaQuery.of(context).size.height * 0.8,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 10),
        const Text('24.978 Followers', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        const Text(
          'Alice Eve',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const EditProfileFinal(),
              barrierDismissible: false,
            );
          },
          icon: const Icon(Icons.edit, color: Colors.white),
          label: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FittedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTag('Coach'),
              _buildTag('Architecture'),
              _buildTag('Personal Growth'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildThreadsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard('Purchases', '2000TK'),
                _buildStatCard('Age', '32 y.o'),
                _buildStatCard('Likes', '25,899'),
                _buildStatCard('Photos', '6'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return SizedBox(
      width: 120,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
