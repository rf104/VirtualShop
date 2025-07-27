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
