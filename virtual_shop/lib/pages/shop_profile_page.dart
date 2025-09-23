import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final String _shopCategory = 'Grocery & Daily Essentials';
  String? _phone;
  String? _email;
  String? _address;
  String? _website;
  ImageProvider? _avatarProvider;

  // Stats state
  int? _statProducts;
  int? _statOrders;
  int? _statCustomers;
  double? _statRevenue;
  String? _statsError;
  bool _statsLoading = false;

  String get _baseUrl {
    final fromServer = dotenv.env['SERVER_URL']?.trim();
    final fromBackend = dotenv.env['BACKEND_URL']?.trim();
    String raw = (fromServer?.isNotEmpty == true)
        ? fromServer!
        : (fromBackend?.isNotEmpty == true
              ? fromBackend!
              : 'http://127.0.0.1:8000');
    raw = raw.replaceFirst(RegExp(r'^(https?://)\s+'), r'$1');
    String url = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    try {
      if (!mounted) return url;
      // Map localhost to Android emulator/device IP if needed
      if (!kIsWeb && Platform.isAndroid) {
        final uri = Uri.parse(url);
        if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
          final hostIp = dotenv.env['hostIp'] ?? '192.168.0.154';
          url = uri.replace(host: hostIp).toString();
        }
      }
    } catch (_) {}
    return url;
  }

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
    _loadStats();
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

  Future<void> _loadStats() async {
    setState(() {
      _statsLoading = true;
      _statsError = null;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      String? token = session?.accessToken;
      String? sellerId;

      if (token != null) {
        try {
          final decoded = JwtDecoder.decode(token);
          sellerId = decoded['sub'] ?? decoded['user_id'] ?? decoded['uid'];
        } catch (_) {}
      }
      sellerId ??= Supabase.instance.client.auth.currentUser?.id;

      if (sellerId == null) {
        setState(() {
          _statsError = 'Not signed in';
          _statsLoading = false;
        });
        return;
      }

      final base = _baseUrl;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Fetch products
      final productsResp = await http.get(
        Uri.parse('$base/sellers/$sellerId/products'),
        headers: headers,
      );
      if (productsResp.statusCode != 200) {
        throw Exception('Products fetch failed: ${productsResp.statusCode}');
      }
      final productsData =
          jsonDecode(productsResp.body) as Map<String, dynamic>;
      final List products = (productsData['products'] as List?) ?? const [];

      // Fetch transactions
      final txnResp = await http.get(
        Uri.parse('$base/sellers/$sellerId/transactions'),
        headers: headers,
      );
      if (txnResp.statusCode != 200) {
        throw Exception('Transactions fetch failed: ${txnResp.statusCode}');
      }
      final txnData = jsonDecode(txnResp.body) as Map<String, dynamic>;
      final List txns = (txnData['transactions'] as List?) ?? const [];

      // Compute metrics
      final productCount = products.length;
      final orderIds = <String>{};
      final customerIds = <String>{};
      double revenue = 0;

      for (final t in txns) {
        final map = t as Map<String, dynamic>;
        final orderId = map['order_id']?.toString();
        if (orderId != null) orderIds.add(orderId);
        final buyerInfo = map['buyer_info'] as Map<String, dynamic>?;
        final uid =
            buyerInfo?['id']?.toString() ?? buyerInfo?['auth_id']?.toString();
        if (uid != null) customerIds.add(uid);
        final sellerTotal =
            double.tryParse(map['seller_item_total']?.toString() ?? '0') ?? 0;
        revenue += sellerTotal;
      }

      if (!mounted) return;
      setState(() {
        _statProducts = productCount;
        _statOrders = orderIds.length;
        _statCustomers = customerIds.length;
        _statRevenue = revenue;
        _statsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e.toString();
        _statsLoading = false;
      });
    }
  }

  String _formatCompactCurrency(double? value) {
    if (value == null) return '৳0';
    if (value >= 1000000) {
      return '৳${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '৳${(value / 1000).toStringAsFixed(1)}K';
    }
    return '৳${value.toStringAsFixed(0)}';
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
                    if (_statsError != null)
                      Text(
                        _statsError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    if (_statsLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: const Color(0xff667eea),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    if (!_statsLoading)
                      (isDesktop || isTablet)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildShopStatItem(
                                  "Products",
                                  (_statProducts ?? 0).toString(),
                                  isTablet,
                                ),
                                _buildShopStatItem(
                                  "Orders",
                                  (_statOrders ?? 0).toString(),
                                  isTablet,
                                ),
                                _buildShopStatItem(
                                  "Customers",
                                  (_statCustomers ?? 0).toString(),
                                  isTablet,
                                ),
                                _buildShopStatItem(
                                  "Revenue",
                                  _formatCompactCurrency(_statRevenue ?? 0),
                                  isTablet,
                                ),
                              ],
                            )
                          : Wrap(
                              alignment: WrapAlignment.spaceAround,
                              runSpacing: 16,
                              children: [
                                _buildShopStatItem(
                                  "Products",
                                  (_statProducts ?? 0).toString(),
                                  isTablet,
                                ),
                                _buildShopStatItem(
                                  "Orders",
                                  (_statOrders ?? 0).toString(),
                                  isTablet,
                                ),
                                _buildShopStatItem(
                                  "Customers",
                                  (_statCustomers ?? 0).toString(),
                                  isTablet,
                                ),
                                _buildShopStatItem(
                                  "Revenue",
                                  _formatCompactCurrency(_statRevenue ?? 0),
                                  isTablet,
                                ),
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
