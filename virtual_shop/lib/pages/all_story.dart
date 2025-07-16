import 'package:flutter/material.dart';
import 'package:virtual_shop/widgets/best_seller_widget.dart';
import 'package:virtual_shop/widgets/categories_widget.dart';
import 'package:virtual_shop/widgets/favorite_stores.dart';
import 'package:virtual_shop/widgets/promotion_widget.dart';
import 'package:virtual_shop/widgets/shop_screenshots_widget.dart';
import 'package:virtual_shop/widgets/story_page.dart';
import 'package:virtual_shop/widgets/stats_widget.dart';

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

class YourStoryItem extends StatelessWidget {
  const YourStoryItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
