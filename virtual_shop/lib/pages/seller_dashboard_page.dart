import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
// Pages are pushed via named routes inside SellerShell's nested Navigator.
import 'package:virtual_shop/pages/my_products_sheet.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  String _selectedPeriod = "Monthly";
  String _displayName = 'Seller';
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
    _loadAuthUser();
  }

  Future<void> _loadAuthUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final meta = user.userMetadata ?? {};
      final dynamic nameCandidate =
          meta['name'] ?? meta['fullName'] ?? user.email;
      final dynamic avatarCandidate =
          meta['avatar_url_custom'] ?? meta['picture'] ?? meta['avatarUrl'];

      String resolvedName =
          nameCandidate is String && nameCandidate.trim().isNotEmpty
          ? nameCandidate.trim()
          : 'Seller';

      if (avatarCandidate is String && avatarCandidate.trim().isNotEmpty) {
        final url = avatarCandidate.trim();
        final provider = CachedNetworkImageProvider(
          url,
          cacheKey: url,
          headers: _headersForUrl(url),
          maxHeight: 150,
        );
        if (!mounted) return;
        setState(() {
          _displayName = resolvedName;
          _avatarProvider = provider;
        });
        // Warm the image cache; ignore failures silently
        // (e.g., if headers are invalid or URL is unreachable).
        // This keeps build fast and avoids jank when first painting avatar.
        // ignore: discarded_futures
        precacheImage(provider, context).catchError((_) {});
      } else {
        if (!mounted) return;
        setState(() {
          _displayName = resolvedName;
        });
      }
    } catch (_) {
      // Leave defaults on error
    }
  }

  String _getCurrentDateFormatted() {
    final now = DateTime.now();
    final formatter = DateFormat('EEE, dd MMMM');
    return formatter.format(now).toUpperCase();
  }

  Widget _buildSellerDashboard() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with dark theme
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        _getCurrentDateFormatted(), // Use actual date
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Hi, $_displayName",
                        softWrap: true,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize:
                              MediaQuery.of(context).size.width *
                              0.075, // Responsive font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Sign out button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => _handleSignOut(context),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('shop_profile');
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundImage:
                          _avatarProvider ??
                          const AssetImage('assets/images/profile2.jpg'),
                      backgroundColor: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Analytics Title & Select with dark theme
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Analytics",
                          style: TextStyle(
                            fontSize:
                                MediaQuery.of(context).size.width *
                                0.05, // Responsive font size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff667eea), Color(0xff764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff667eea).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 18,
                          ),
                          dropdownColor: Colors.grey[800],
                          value: _selectedPeriod,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize:
                                MediaQuery.of(context).size.width *
                                0.03, // Responsive font size
                          ),
                          items: [
                            DropdownMenuItem(
                              value: "Monthly",
                              child: Text(
                                "Monthly",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.03, // Responsive font size
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "Weekly",
                              child: Text(
                                "Weekly",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.03, // Responsive font size
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "Daily",
                              child: Text(
                                "Daily",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.03, // Responsive font size
                                ),
                              ),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedPeriod = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Display selected period info with dark theme
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xff667eea).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedPeriod == "Daily"
                              ? Icons.today
                              : _selectedPeriod == "Weekly"
                              ? Icons.date_range
                              : Icons.calendar_month,
                          color: const Color(0xff667eea),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Showing $_selectedPeriod Analytics",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  MediaQuery.of(context).size.width *
                                  0.04, // Responsive font size
                            ),
                            softWrap: true,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff667eea),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedPeriod.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  MediaQuery.of(context).size.width *
                                  0.025, // Responsive font size
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Analytics Cards
                  Row(
                    children: [
                      _AnalyticsCard(
                        key: const ValueKey('analytics1'),
                        color: const Color(0xff667eea),
                        percent: _getSuccessRate(),
                        value: _getTransactionCount(),
                        label: "Transactions success",
                        up: true,
                      ),
                      const SizedBox(width: 8),
                      _AnalyticsCard(
                        key: const ValueKey('analytics2'),
                        color: const Color(0xff764ba2),
                        percent: _getResponseRate(),
                        value: _getResponseTime(),
                        label: "Response rate",
                        up: _selectedPeriod != "Daily",
                      ),
                      const SizedBox(width: 8),
                      _AnalyticsCard(
                        key: const ValueKey('analytics3'),
                        color: const Color(0xff4facfe),
                        percent: _getFeedbackRate(),
                        value: _getFeedbackCount(),
                        label: "Happy feedbacks",
                        up: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            // Earnings section with dark theme
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$_selectedPeriod Earnings",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                MediaQuery.of(context).size.width *
                                0.055, // Responsive font size
                            color: Colors.white,
                          ),
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _getTotalEarnings(),
                          style: TextStyle(
                            fontSize:
                                MediaQuery.of(context).size.width *
                                0.06, // Responsive font size
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff667eea),
                          ),
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total balance",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize:
                          MediaQuery.of(context).size.width *
                          0.035, // Responsive font size
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('analytics_details');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xff667eea).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            "Earning in ",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              fontSize:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.035, // Responsive font size
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              _getPeriodText(),
                                              style: TextStyle(
                                                color: const Color(0xff667eea),
                                                fontWeight: FontWeight.w600,
                                                fontSize:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.035, // Responsive font size
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: Color(0xff667eea),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _getPeriodEarnings(),
                                        softWrap: true,
                                        maxLines: 2,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.06, // Responsive font size
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _getEarningsChange(),
                                        softWrap: true,
                                        maxLines: 2,
                                        style: TextStyle(
                                          color: const Color(0xff38A169),
                                          fontSize:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.035, // Responsive font size
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Tap to view detailed analytics",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.03, // Responsive font size
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Mini bar chart
                          Container(
                            height: 40,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ...(_getChartData().map<Widget>(
                                  (h) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1.5,
                                    ),
                                    child: Container(
                                      width: 5,
                                      height: h,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xff667eea),
                                            Color(0xff764ba2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.analytics_outlined,
                            color: Color(0xff667eea),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Recent Transaction",
                          softWrap: true,
                          maxLines: 2,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                MediaQuery.of(context).size.width *
                                0.045, // Responsive font size
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _showAllTransactions(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff667eea),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "See all",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.03, // Responsive font size
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // First Transaction
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xff667eea),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Payment from Ibnu",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.04, // Responsive font size
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Friday, 21 March",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.0325, // Responsive font size
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "৳2,000",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                MediaQuery.of(context).size.width *
                                0.04, // Responsive font size
                            color: const Color(0xff38A169),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Second Transaction
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xff764ba2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Payment from Sarah",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.04, // Responsive font size
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Thursday, 20 March",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.0325, // Responsive font size
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "৳1,500",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                MediaQuery.of(context).size.width *
                                0.04, // Responsive font size
                            color: const Color(0xff38A169),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            // My Products header with dark theme and Add Product button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // My Products Row
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const MyProductsSheet(),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff667eea), Color(0xff764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "My Products",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.05, // Responsive font size
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Manage your inventory",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize:
                                      MediaQuery.of(context).size.width *
                                      0.035, // Responsive font size
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff667eea),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "10",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  MediaQuery.of(context).size.width *
                                  0.04, // Responsive font size
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add Product Button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('add_product');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff38A169), Color(0xff2F855A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff38A169).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_business_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Add New Product",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  MediaQuery.of(context).size.width *
                                  0.04, // Responsive font size
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            // Recent Reviews section with dark theme
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xffFFD700),
                                    Color(0xffFFA500),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Recent Reviews",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Customer feedback",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _showAllReviews(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffFFD700),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "See all",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.black,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Overall Rating Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xffFFD700).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "4.8",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                          0.07, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: List.generate(
                                            5,
                                            (index) => Icon(
                                              index < 5
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                              color: const Color(0xffFFD700),
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "Based on 1,247 reviews",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff38A169),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Excellent",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  MediaQuery.of(context).size.width *
                                  0.025, // Responsive font size
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recent Review 1
                  _buildReviewItem(_getReviewData(0)),
                  const SizedBox(height: 12),

                  // Recent Review 2
                  _buildReviewItem(_getReviewData(1)),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [_buildSellerDashboard()]),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  // Show all transactions method
  void _showAllTransactions(BuildContext context) {
    Navigator.of(context).pushNamed('transactions');
  }

  // Show all reviews method
  void _showAllReviews(BuildContext context) {
    Navigator.of(context).pushNamed('reviews');
  }

  // Helper methods for analytics data
  String _getSuccessRate() {
    switch (_selectedPeriod) {
      case "Daily":
        return "94.2%";
      case "Weekly":
        return "96.1%";
      case "Monthly":
        return "97.7%";
      default:
        return "97.7%";
    }
  }

  String _getTransactionCount() {
    switch (_selectedPeriod) {
      case "Daily":
        return "850";
      case "Weekly":
        return "5,420";
      case "Monthly":
        return "20,237";
      default:
        return "20,237";
    }
  }

  String _getResponseRate() {
    switch (_selectedPeriod) {
      case "Daily":
        return "85%";
      case "Weekly":
        return "88%";
      case "Monthly":
        return "90%";
      default:
        return "90%";
    }
  }

  String _getResponseTime() {
    switch (_selectedPeriod) {
      case "Daily":
        return "45 min";
      case "Weekly":
        return "1.2 hours";
      case "Monthly":
        return "2 hours";
      default:
        return "2 hours";
    }
  }

  String _getFeedbackRate() {
    switch (_selectedPeriod) {
      case "Daily":
        return "82.1%";
      case "Weekly":
        return "76.5%";
      case "Monthly":
        return "78.9%";
      default:
        return "78.9%";
    }
  }

  String _getFeedbackCount() {
    switch (_selectedPeriod) {
      case "Daily":
        return "89";
      case "Weekly":
        return "412";
      case "Monthly":
        return "1,730";
      default:
        return "1,730";
    }
  }

  String _getTotalEarnings() {
    switch (_selectedPeriod) {
      case "Daily":
        return "৳25,300";
      case "Weekly":
        return "৳1,47,200";
      case "Monthly":
        return "৳5,89,200";
      default:
        return "৳5,89,200";
    }
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case "Daily":
        return "Today";
      case "Weekly":
        return "This Week";
      case "Monthly":
        return "March";
      default:
        return "March";
    }
  }

  String _getPeriodEarnings() {
    switch (_selectedPeriod) {
      case "Daily":
        return "৳25,300";
      case "Weekly":
        return "৳1,47,200";
      case "Monthly":
        return "৳1,68,000";
      default:
        return "৳1,68,000";
    }
  }

  String _getEarningsChange() {
    switch (_selectedPeriod) {
      case "Daily":
        return "+ ৳2,100";
      case "Weekly":
        return "+ ৳12,400";
      case "Monthly":
        return "+ ৳34,500";
      default:
        return "+ ৳34,500";
    }
  }

  List<double> _getChartData() {
    switch (_selectedPeriod) {
      case "Daily":
        return [8.0, 15.0, 12.0, 22.0, 18.0, 30.0];
      case "Weekly":
        return [15.0, 25.0, 20.0, 35.0, 28.0, 40.0];
      case "Monthly":
        return [12.0, 20.0, 16.0, 28.0, 10.0, 36.0];
      default:
        return [12.0, 20.0, 16.0, 28.0, 10.0, 36.0];
    }
  }

  // Helper method to get review data
  Map<String, dynamic> _getReviewData(int index) {
    final reviewers = [
      {
        'name': 'Ibnu Rahman',
        'avatar': 'https://randomuser.me/api/portraits/men/2.jpg',
        'rating': 5,
        'date': 'March 21, 2024',
        'review':
            'Great product quality and fast delivery! The wireless headphones exceeded my expectations.',
        'verified': true,
      },
      {
        'name': 'Sarah Ahmed',
        'avatar': 'https://randomuser.me/api/portraits/women/3.jpg',
        'rating': 4,
        'date': 'March 20, 2024',
        'review':
            'Good service overall, but packaging could be improved. The product arrived safely.',
        'verified': true,
      },
      {
        'name': 'John Doe',
        'avatar': 'https://randomuser.me/api/portraits/men/4.jpg',
        'rating': 5,
        'date': 'March 19, 2024',
        'review':
            'Amazing experience! Will definitely order again. The customer service was outstanding.',
        'verified': true,
      },
    ];
    return reviewers[index % reviewers.length];
  }

  // Helper method to build a review item
  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(review['avatar'] ?? ''),
            onBackgroundImageError: (exception, stackTrace) {
              // Handle image loading error
            },
            child: review['avatar'] == null
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review['name'] ?? 'Anonymous',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < (review['rating'] ?? 0)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xffFFD700),
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  review['date'] ?? 'No date',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  review['review'] ?? 'No review text',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (review['verified'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Color(0xff38A169),
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "Verified Purchase",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

// Analytics Card with same styling
class _AnalyticsCard extends StatelessWidget {
  final Color color;
  final String percent;
  final String value;
  final String label;
  final bool up;

  const _AnalyticsCard({
    super.key,
    required this.color,
    required this.percent,
    required this.value,
    required this.label,
    required this.up,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    percent,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize:
                          MediaQuery.of(context).size.width *
                          0.04, // Responsive font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: up ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    up ? Icons.trending_up : Icons.trending_down,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize:
                    MediaQuery.of(context).size.width *
                    0.045, // Responsive font size
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize:
                    MediaQuery.of(context).size.width *
                    0.03, // Responsive font size
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Sales Chart - Place outside of the _SellerDashboardPageState class
class SalesChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;

  SalesChartPainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (data.length * 2);
    final barSpacing = barWidth;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xff667eea), Color(0xff764ba2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, barWidth, size.height))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxValue) * size.height;
      final x = i * (barWidth + barSpacing) + barSpacing / 2;
      final y = size.height - barHeight;
      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SalesChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}
