import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:virtual_shop/utils/supabase_service.dart';

import 'edit_shop_profile_page.dart';
import 'share_shop_profile_page.dart';

class ShopProfilePage extends StatefulWidget {
  const ShopProfilePage({super.key});

  @override
  State<ShopProfilePage> createState() => _ShopProfilePageState();
}

class _ShopProfilePageState extends State<ShopProfilePage> {
  // Dynamic data resolved from auth user and profile row
  String _shopName = 'Urban Drift';
  String _shopCategory = 'Grocery & Daily Essentials';
  String? _phone;
  String? _email;
  String? _address;
  String? _website;
  ImageProvider? _avatarProvider;

  Map<String, String>? _headersForUrl(String url) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;
    if (url.contains('supabase.co') && url.contains('/storage/v1/object/')) {
      return {'Authorization': 'Bearer ${session.accessToken}'};
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final email = user.email;
      final meta = user.userMetadata ?? {};

      Map<String, dynamic>? profileRow;
      if (email != null && email.isNotEmpty) {
        profileRow = await SupabaseService.fetchUserProfile(email);
      }

      final nameCandidate = (profileRow?['name'] as String?)?.trim();
      final phoneCandidate = (profileRow?['phone'] as String?)?.trim();
      final imageCandidate =
          (profileRow?['profile_image'] as String?)?.trim() ??
          (meta['avatar_url_custom'] as String?) ??
          (meta['picture'] as String?) ??
          (meta['avatarUrl'] as String?) ??
          (meta['avatar_url'] as String?);

      final resolvedName = (nameCandidate != null && nameCandidate.isNotEmpty)
          ? nameCandidate
          : (meta['shop_name'] as String?)?.trim() ?? _shopName;

      ImageProvider? provider;
      if (imageCandidate != null && imageCandidate.trim().isNotEmpty) {
        final url = imageCandidate.trim();
        provider = CachedNetworkImageProvider(
          url,
          cacheKey: url,
          headers: _headersForUrl(url),
          maxHeight: 160,
        );
        // Warm cache; ignore failures
        // ignore: discarded_futures
        precacheImage(provider, context).catchError((_) {});
      }

      if (!mounted) return;
      setState(() {
        _shopName = resolvedName;
        _phone = phoneCandidate ?? _phone;
        _email = email ?? _email;
        _avatarProvider = provider ?? _avatarProvider;
      });
    } catch (_) {
      // leave defaults on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    // Responsive padding
    final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 30.0 : 20.0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Shop Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Header with avatar and basic info
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
                    Flex(
                      direction: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xff667eea), Color(0xff764ba2)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: isTablet ? 40 : 30,
                            backgroundImage:
                                _avatarProvider ??
                                const AssetImage("assets/images/shopLogo.png"),
                            backgroundColor: Colors.grey[800],
                          ),
                        ),
                        SizedBox(width: isTablet ? 20 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _shopName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _shopCategory,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: isTablet ? 16 : 14,
                                ),
                              ),
                              SizedBox(height: isTablet ? 12 : 8),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "4.8",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    " (1,234 reviews)",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: isTablet ? 14 : 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    // Action buttons
                    Flex(
                      direction: Axis.horizontal,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditShopProfilePage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 16 : 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xff667eea),
                                    Color(0xff764ba2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Edit Profile",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ShareShopProfilePage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 16 : 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[600]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.share,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Share",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Shop Statistics
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Shop Statistics",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    isDesktop || isTablet
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildShopStatItem("Products", "1,245", isTablet),
                              _buildShopStatItem("Orders", "3,567", isTablet),
                              _buildShopStatItem(
                                "Customers",
                                "2,134",
                                isTablet,
                              ),
                              _buildShopStatItem("Revenue", "৳45.2K", isTablet),
                            ],
                          )
                        : Wrap(
                            alignment: WrapAlignment.spaceAround,
                            runSpacing: 16,
                            children: [
                              _buildShopStatItem("Products", "1,245", isTablet),
                              _buildShopStatItem("Orders", "3,567", isTablet),
                              _buildShopStatItem(
                                "Customers",
                                "2,134",
                                isTablet,
                              ),
                              _buildShopStatItem("Revenue", "৳45.2K", isTablet),
                            ],
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contact Information
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contact Information",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildInfoRow(
                      Icons.phone,
                      "Phone",
                      _phone ?? "+880 1700-123456",
                      isVerified: (_phone ?? '').isNotEmpty,
                      isLargeScreen: isTablet,
                    ),
                    _buildInfoRow(
                      Icons.email,
                      "Email",
                      _email ?? "contact@urbanDrift.com",
                      isVerified: (_email ?? '').isNotEmpty,
                      isLargeScreen: isTablet,
                    ),
                    _buildInfoRow(
                      Icons.location_on,
                      "Address",
                      _address ?? "123 Commerce Street, Dhaka 1205",
                      isLargeScreen: isTablet,
                    ),
                    _buildInfoRow(
                      Icons.language,
                      "Website",
                      _website ?? "www.urbandrift.com",
                      isLargeScreen: isTablet,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Business Hours
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Business Hours",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildHoursRow(
                      "Monday - Friday",
                      "9:00 AM - 10:00 PM",
                      isTablet,
                    ),
                    _buildHoursRow("Saturday", "9:00 AM - 11:00 PM", isTablet),
                    _buildHoursRow("Sunday", "10:00 AM - 9:00 PM", isTablet),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Policies
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Shop Policies",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildPolicyItem(
                      Icons.assignment_return,
                      "Return Policy",
                      "7-day return policy for defective items",
                      isTablet,
                    ),
                    _buildPolicyItem(
                      Icons.local_shipping,
                      "Delivery",
                      "Free delivery for orders above ৳500",
                      isTablet,
                    ),
                    _buildPolicyItem(
                      Icons.payment,
                      "Payment",
                      "Cash on delivery & digital payments accepted",
                      isTablet,
                    ),
                  ],
                ),
              ),
              SizedBox(height: isDesktop ? 60 : 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widgets for shop profile
  Widget _buildShopStatItem(
    String label,
    String value, [
    bool isLargeScreen = false,
  ]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isLargeScreen ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isLargeScreen ? 6 : 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: isLargeScreen ? 14 : 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isVerified = false,
    bool isLargeScreen = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLargeScreen ? 20 : 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xff667eea),
            size: isLargeScreen ? 24 : 20,
          ),
          SizedBox(width: isLargeScreen ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isLargeScreen ? 14 : 12,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 4 : 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isLargeScreen ? 16 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isVerified)
                      Icon(
                        Icons.verified,
                        color: const Color(0xff38A169),
                        size: isLargeScreen ? 18 : 16,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursRow(
    String day,
    String hours, [
    bool isLargeScreen = false,
  ]) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLargeScreen ? 12 : 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              day,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isLargeScreen ? 16 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isLargeScreen ? 12 : 8),
          Flexible(
            child: Text(
              hours,
              style: TextStyle(
                color: Colors.white,
                fontSize: isLargeScreen ? 16 : 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(
    IconData icon,
    String title,
    String description, [
    bool isLargeScreen = false,
  ]) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLargeScreen ? 20 : 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xff667eea),
            size: isLargeScreen ? 24 : 20,
          ),
          SizedBox(width: isLargeScreen ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLargeScreen ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 4 : 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isLargeScreen ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
