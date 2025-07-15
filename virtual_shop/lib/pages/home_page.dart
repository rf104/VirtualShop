import 'package:flutter/material.dart';
import 'package:virtual_shop/pages/all_product_page.dart';
import 'package:virtual_shop/pages/all_story.dart';
import 'package:virtual_shop/pages/cart_page.dart';
import 'package:virtual_shop/pages/chat_assistant_page.dart';
import 'package:virtual_shop/pages/notification_page.dart';
import 'package:virtual_shop/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _bottomNavIndex = 0;

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _bottomNavIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFADFF2F) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isSelected ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildNavItemWithBadge(IconData icon, int index, int count) {
    bool isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _bottomNavIndex = index;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFADFF2F) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isSelected ? Colors.black : Colors.white),
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const AllStoryPage(key: ValueKey('AllStoryPage'));
      case 1:
        return const AllProductPage(key: ValueKey('AllProductPage'));
      case 2:
        return const CartPage(key: ValueKey('CartPage'));
      case 3:
        return const ChatAssistantPage(key: ValueKey('ChatAssistantPage'));
      case 4:
        return const NotificationPage(key: ValueKey('NotificationPage'));
      case 5:
        return const ProfilePage(key: ValueKey('ProfilePage'));
      default:
        return const Center(
          key: ValueKey('ComingSoonDefault'),
          child: Text("Coming soon"),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildPage(_bottomNavIndex),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(Icons.home, 0),
                  _buildNavItem(Icons.checkroom, 1),
                  _buildNavItemWithBadge(Icons.shopping_bag_outlined, 2, 4),
                  _buildNavItem(Icons.bubble_chart, 3),
                  _buildNavItem(Icons.notifications, 4),
                  _buildNavItem(Icons.person_outline, 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
