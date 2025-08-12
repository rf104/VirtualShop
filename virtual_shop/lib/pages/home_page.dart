import 'package:flutter/material.dart';
import 'package:virtual_shop/pages/all_product_page.dart';
import 'package:virtual_shop/pages/all_story.dart';
import 'package:virtual_shop/pages/cart_page.dart';
import 'package:virtual_shop/pages/chat_assistant_page.dart';
import 'package:virtual_shop/pages/notification_page.dart';
import 'package:virtual_shop/pages/profile_page.dart';
import 'package:virtual_shop/pages/seller_shell.dart';
import 'package:virtual_shop/widgets/glass_container.dart';
import 'package:virtual_shop/utils/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _bottomNavIndex = 0;
  late TabController _tabController;
  String? _userType; // 'Seller' or 'Normal User'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserType();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserType() async {
    try {
      final email = supabase.auth.currentUser?.email;
      if (email == null || email.isEmpty) return;
      final profile = await SupabaseService.fetchUserProfile(email);
      if (!mounted) return;
      setState(() {
        _userType = (profile?['user_type'] as String?)?.trim();
        // Keep selected tab valid based on role
        final isSeller = _userType == 'Seller';
        if (isSeller && _bottomNavIndex == 6) {
          _bottomNavIndex = 7;
        } else if (!isSeller && _bottomNavIndex == 7) {
          _bottomNavIndex = 6;
        }
      });
    } catch (_) {
      // Silently ignore; default (non-seller) UI will be shown
    }
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _bottomNavIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
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
            padding: const EdgeInsets.all(8),
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
      case 3:
        return const CartPage(key: ValueKey('CartPage'));
      case 4:
        return const ChatAssistantPage(key: ValueKey('ChatAssistantPage'));
      case 5:
        return const NotificationPage(key: ValueKey('NotificationPage'));
      case 6:
        return const ProfilePage(key: ValueKey('ProfilePage'));
      case 7:
        return const SellerShell(key: ValueKey('SellerShell'));
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
          _buildPage(_bottomNavIndex),
          Positioned(
            left: 10,
            right: 10,
            bottom: 20,
            child: GlassContainer(
              width: MediaQuery.of(context).size.width - 20,
              height: 70,
              borderRadius: 30,
              color: Colors.black.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(Icons.home, 0),
                    _buildNavItem(Icons.checkroom, 1),
                    _buildNavItemWithBadge(Icons.shopping_bag_outlined, 3, 4),
                    _buildNavItem(Icons.bubble_chart, 4),
                    _buildNavItem(Icons.notifications, 5),
                    if ((_userType ?? 'Normal User') != 'Seller')
                      _buildNavItem(Icons.person_outline, 6)
                    else
                      _buildNavItem(Icons.store, 7),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
