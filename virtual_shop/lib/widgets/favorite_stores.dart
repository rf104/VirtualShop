import 'package:flutter/material.dart';
import '../models/seller.dart';
import '../utils/api_service.dart';

class FavoriteStores extends StatelessWidget {
  const FavoriteStores({super.key});

  @override
  Widget build(BuildContext context) {
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

        // 👇 FutureBuilder for dynamic sellers
        FutureBuilder<List<Seller>>(
          future: ApiService.getAllSellers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text(
                "No sellers found",
                style: TextStyle(color: Colors.white70),
              );
            }

            final sellers = snapshot.data!;
            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sellers.length,
                itemBuilder: (context, index) {
                  final seller = sellers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: seller.profileImage.isNotEmpty
                              ? NetworkImage(seller.profileImage)
                              : const AssetImage("assets/images/c1.png")
                                  as ImageProvider,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          seller.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
