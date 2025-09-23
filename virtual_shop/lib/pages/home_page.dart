import 'package:flutter/material.dart';
import 'package:virtual_shop/pages/all_product_page.dart';
import 'package:virtual_shop/pages/all_story.dart';
import 'package:virtual_shop/pages/cart_page.dart';
import 'package:virtual_shop/pages/chat_assistant_page.dart';
import 'package:virtual_shop/pages/NotificationPage.dart';
import 'package:virtual_shop/pages/profile_page.dart';
import 'package:virtual_shop/pages/seller_shell.dart';
import 'package:virtual_shop/pages/admin_dashboard_page.dart';
import 'package:virtual_shop/widgets/glass_container.dart';
import 'package:virtual_shop/widgets/animated_tab_glass.dart';
import 'package:virtual_shop/utils/supabase_service.dart';
import 'package:virtual_shop/utils/cart_api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _bottomNavIndex = 0;
  late TabController _tabController;
  String? _userType;
  bool _isAdmin = false;
  bool _shouldAnimateGlass = false;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserType();
    _loadCartCount();
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
        final emailStr = (profile?['email'] as String?)?.trim().toLowerCase();
        _isAdmin = emailStr == 'istiaqueahmedarik@gmail.com';
        final isSeller = _userType == 'Seller';
        if (isSeller && _bottomNavIndex == 6) {
          _bottomNavIndex = 7;
        } else if (!isSeller && _bottomNavIndex == 7) {
          _bottomNavIndex = 6;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadCartCount() async {
    try {
      final cartItems = await CartApi.getCart();
      if (!mounted) return;
      setState(() {
        _cartItemCount = cartItems.length;
      });
    } catch (_) {
      // If error occurs (e.g., not signed in), keep count as 0
      if (mounted) {
        setState(() {
          _cartItemCount = 0;
        });
      }
    }
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _bottomNavIndex == index;
    bool shouldAnimate = _shouldAnimateGlass && isSelected;

    int lastTabIndex = 6;
    if (_isAdmin) {
      lastTabIndex = 7;
    } else if ((_userType ?? 'Normal User') == 'Seller') {
      lastTabIndex = 7;
    }

    EdgeInsets extraPadding = EdgeInsets.zero;
    if (_bottomNavIndex == 0 && index == lastTabIndex) {
      extraPadding = const EdgeInsets.only(right: 20);
    } else if (_bottomNavIndex == lastTabIndex && index == 0) {
      extraPadding = const EdgeInsets.only(left: 20);
    } else if (_bottomNavIndex != 0 && _bottomNavIndex != lastTabIndex) {
      if (index == 0) {
        extraPadding = const EdgeInsets.only(left: 10);
      } else if (index == lastTabIndex) {
        extraPadding = const EdgeInsets.only(right: 10);
      }
    }

    return Padding(
      padding: extraPadding,
      child: GestureDetector(
        onTap: () {
          if (_bottomNavIndex != index) {
            setState(() {
              _bottomNavIndex = index;
              _shouldAnimateGlass = true;
            });
            // Refresh cart count when navigating to any page (in case user added items)
            if (index != 3) {
              // Don't refresh when going to cart page, it has its own callback
              _loadCartCount();
            }
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                setState(() {
                  _shouldAnimateGlass = false;
                });
              }
            });
          }
        },
        child: AnimatedTabGlass(
          isSelected: isSelected,
          shouldAnimate: shouldAnimate,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: isSelected ? const Color(0xFFADFF2F) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(IconData icon, int index, int count) {
    bool isSelected = _bottomNavIndex == index;
    bool shouldAnimate = _shouldAnimateGlass && isSelected;

    // Determine the last tab index based on user type
    int lastTabIndex = 6;
    if (_isAdmin) {
      lastTabIndex = 7;
    } else if ((_userType ?? 'Normal User') == 'Seller') {
      lastTabIndex = 7;
    }

    // Calculate padding based on selected tab
    EdgeInsets extraPadding = EdgeInsets.zero;
    if (_bottomNavIndex == 0 && index == lastTabIndex) {
      extraPadding = const EdgeInsets.only(right: 20);
    } else if (_bottomNavIndex == lastTabIndex && index == 0) {
      extraPadding = const EdgeInsets.only(left: 20);
    } else if (_bottomNavIndex != 0 && _bottomNavIndex != lastTabIndex) {
      if (index == 0) {
        extraPadding = const EdgeInsets.only(left: 10);
      } else if (index == lastTabIndex) {
        extraPadding = const EdgeInsets.only(right: 10);
      }
    }

    return Padding(
      padding: extraPadding,
      child: GestureDetector(
        onTap: () {
          if (_bottomNavIndex != index) {
            setState(() {
              _bottomNavIndex = index;
              _shouldAnimateGlass = true;
            });
            // Refresh cart count when navigating to any page (in case user added items)
            if (index != 3) {
              // Don't refresh when going to cart page, it has its own callback
              _loadCartCount();
            }
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                setState(() {
                  _shouldAnimateGlass = false;
                });
              }
            });
          }
        },
        child: AnimatedTabGlass(
          isSelected: isSelected,
          shouldAnimate: shouldAnimate,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFFADFF2F) : Colors.white,
                ),
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
        ),
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
        return CartPage(
          key: const ValueKey('CartPage'),
          onCartChanged: _loadCartCount,
        );
      case 4:
        return const ChatAssistantPage(key: ValueKey('ChatAssistantPage'));
      case 5:
        return const NotificationPage(key: ValueKey('NotificationPage'));
      case 6:
        return const ProfilePage(key: ValueKey('ProfilePage'));
      case 7:
        if (_isAdmin)
          return const AdminDashboardPage(key: ValueKey('AdminDashboard'));
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
            bottom: 30,
            child: GlassContainer(
              width: MediaQuery.of(context).size.width - 20,
              height: 70,
              borderRadius: 50,
              color: Colors.black.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(Icons.home, 0),
                    _buildNavItem(Icons.checkroom, 1),
                    _buildNavItemWithBadge(
                      Icons.shopping_bag_outlined,
                      3,
                      _cartItemCount,
                    ),
                    _buildNavItem(Icons.bubble_chart, 4),
                    _buildNavItem(Icons.notifications, 5),
                    if (_isAdmin)
                      _buildNavItem(Icons.shield, 7)
                    else if ((_userType ?? 'Normal User') != 'Seller')
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
