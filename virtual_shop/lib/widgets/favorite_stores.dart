import 'package:flutter/material.dart';

class FavoriteStores extends StatelessWidget {
  const FavoriteStores({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> stores = [
      {'logo': 'assets/images/c1.png', 'name': 'company1'},
      {'logo': 'assets/images/c2.png', 'name': 'company2'},
      {'logo': 'assets/images/c3.png', 'name': 'company3'},
      {'logo': 'assets/images/c1.png', 'name': 'company4'},
      {'logo': 'assets/images/c2.png', 'name': 'company5'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your favorite stores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'See all',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[800],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(store['logo']!, height: 30),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store['name']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
