import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:virtual_shop/models/product.dart';
import 'package:virtual_shop/pages/virtual_closet.dart';

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
    name: 'Product ${index + 1}',
    image: 'assets/images/demo${(index % 5) + 1}.jpg',
    rating: 4.5,
    price: (1.0 * index * 10) + 20,
    category: 'Category',
    weather: 'Sunny',
    temp: '25°C',
    event: 'Casual',
    description: 'This is a description for product ${index + 1}.',
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

class SharedClosetsPage extends StatelessWidget {
  const SharedClosetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('View >')),
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
            ),
          ),
        ),
      ),
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
        width: 220,
        margin: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.0),
          image: DecorationImage(
            image: AssetImage(closet.products.first.image),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top right icons
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.bookmark_border,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title and subtitle
            Positioned(
              left: 20,
              bottom: 70,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sun 20',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    closet.closetName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),
            // See more button
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28.0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'See more',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
