import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Recent transactions state
  List<dynamic> _recentTransactions = [];
  List<dynamic> _allTransactions = [];
  bool _txLoading = false;
  String? _txError;
  String? _sellerAuthId;

  // Recent reviews state
  List<Map<String, dynamic>> _recentReviews = [];
  // Keep all reviews for analytics
  List<Map<String, dynamic>> _allReviews = [];
  bool _rvLoading = false;
  String? _rvError;
  double _avgRating = 0.0;
  int _totalReviews = 0;

  Map<String, String>? _headersForUrl(String url) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;
    if (url.contains('supabase.co') && url.contains('/storage/v1/object/')) {
      return {'Authorization': 'Bearer ${session.accessToken}'};
    }
    return null;
  }

  static String get _baseUrl {
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

  @override
  void initState() {
    super.initState();
    _loadAuthUser();
  }

  Future<void> _loadAuthUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      _sellerAuthId = user.id;
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
    // Fetch recent transactions after loading auth user
    _fetchRecentTransactions();
    _fetchRecentReviews();
  }

  Future<void> _fetchRecentTransactions() async {
    if (_sellerAuthId == null) return;
    setState(() {
      _txLoading = true;
      _txError = null;
    });
    try {
      final uri = Uri.parse('$_baseUrl/sellers/$_sellerAuthId/transactions');
      final headers = <String, String>{'Content-Type': 'application/json'};
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null)
        headers['Authorization'] = 'Bearer ${session.accessToken}';
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        final list = (body['transactions'] as List<dynamic>? ?? []);
        setState(() {
          _allTransactions = list;
          _recentTransactions = list.take(2).toList();
          _txLoading = false;
        });
      } else {
        setState(() {
          _txError = 'Failed (${resp.statusCode})';
          _txLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _txError = 'Error: $e';
        _txLoading = false;
      });
    }
  }

  Future<void> _fetchRecentReviews() async {
    if (_sellerAuthId == null) return;
    setState(() {
      _rvLoading = true;
      _rvError = null;
    });
    try {
      final uri = Uri.parse('$_baseUrl/sellers/$_sellerAuthId/reviews');
      final headers = <String, String>{'Content-Type': 'application/json'};
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null)
        headers['Authorization'] = 'Bearer ${session.accessToken}';
      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final reviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
        // Normalize rating and safe fields
        for (final r in reviews) {
          final raw = r['rating'];
          if (raw is double) r['rating'] = raw.round();
          if (raw is String) r['rating'] = int.tryParse(raw) ?? 0;
          r['name'] ??= 'Anonymous';
          r['verified'] ??= true;
        }
        setState(() {
          _allReviews = reviews;
          _recentReviews = reviews.take(2).toList();
          _avgRating = (data['average_rating'] is num)
              ? (data['average_rating'] as num).toDouble()
              : 0.0;
          _totalReviews = data['total_reviews'] is int
              ? data['total_reviews']
              : reviews.length;
          _rvLoading = false;
        });
      } else {
        setState(() {
          _rvError = 'Failed (${resp.statusCode})';
          _rvLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _rvError = 'Timeout fetching reviews';
        _rvLoading = false;
      });
    } catch (e) {
      setState(() {
        _rvError = 'Error: $e';
        _rvLoading = false;
      });
    }
  }

  String _getCurrentDateFormatted() {
    final now = DateTime.now();
    final formatter = DateFormat('EEE, dd MMMM');
    return formatter.format(now).toUpperCase();
  }

  String _formatAmount(num? amount) {
    if (amount == null) return '৳0';
    return '৳${amount.toStringAsFixed(0)}';
  }

  String _formatTxDate(String? dateString) {
    if (dateString == null) return '';
    try {
      return DateFormat('MMM d').format(DateTime.parse(dateString).toLocal());
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'succeeded':
        return const Color(0xff38A169);
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'refunded':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTxSkeleton() => Container(
    height: 56,
    decoration: BoxDecoration(
      color: Colors.grey[800],
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 10, width: 110, color: Colors.grey[700]),
              const SizedBox(height: 6),
              Container(height: 8, width: 70, color: Colors.grey[700]),
            ],
          ),
        ),
        Container(height: 12, width: 50, color: Colors.grey[700]),
      ],
    ),
  );

  Widget _buildRecentTxItem(Map<String, dynamic> tx) {
    final method = (tx['payment_method'] ?? 'Pay').toString();
    final amountStr = _formatAmount(
      double.tryParse(tx['seller_item_total']?.toString() ?? '0') ?? 0,
    );
    final name =
        tx['buyer_display_name'] ??
        tx['buyer_info']?['full_name'] ??
        'Customer';
    final status = (tx['payment_status'] ?? '').toString();
    final dateStr = _formatTxDate(tx['paid_at'] ?? tx['created_at']);
    final code = tx['transaction_code'] ?? '';
    final color = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            ),
            child: const Icon(Icons.payment, color: Colors.white, size: 20),
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
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (code.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      method.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    if (_txLoading) {
      return Column(
        children: [
          _buildTxSkeleton(),
          const SizedBox(height: 8),
          _buildTxSkeleton(),
        ],
      );
    }
    if (_txError != null) {
      return Text(
        _txError!,
        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
      );
    }
    if (_recentTransactions.isEmpty) {
      return const Text(
        'No recent transactions yet',
        style: TextStyle(color: Colors.white54, fontSize: 13),
      );
    }
    return Column(
      children: _recentTransactions
          .map<Widget>((tx) => _buildRecentTxItem(tx as Map<String, dynamic>))
          .toList(),
    );
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
                  _buildRecentTransactionsSection(),
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
                        builder: (_) {
                          final user =
                              Supabase.instance.client.auth.currentUser;
                          final sellerId = user?.id ?? '';
                          return MyProductsSheet(sellerId: sellerId);
                        },
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Recent Reviews",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _totalReviews > 0
                                        ? "Based on $_totalReviews reviews"
                                        : "Customer feedback",
                                    style: const TextStyle(
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
                      if (!_rvLoading && _rvError == null && _totalReviews > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffFFD700),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.black,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showAllReviews(context),
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
                  if (_rvLoading)
                    Column(
                      children: [
                        _buildReviewSkeleton(),
                        const SizedBox(height: 12),
                        _buildReviewSkeleton(),
                      ],
                    )
                  else if (_rvError != null)
                    Text(
                      _rvError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    )
                  else if (_recentReviews.isEmpty)
                    const Text(
                      'No reviews yet',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    )
                  else ...[
                    for (int i = 0; i < _recentReviews.length; i++) ...[
                      _buildDynamicReviewItem(_recentReviews[i]),
                      if (i < _recentReviews.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 25),
            // 3D Model Upload Section
            if (_sellerAuthId != null)
              _ThreeDModelUploadCard(sellerAuthId: _sellerAuthId!),
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
      // Ensure we pop on the root navigator to exit the nested SellerShell
      // so AuthGate at the app root can rebuild to the signed-out UI.
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
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
  // Percent format helper
  String _formatPercent(num value) => '${value.toStringAsFixed(1)}%';

  bool _isInRange(DateTime dt, DateTime start, DateTime end) =>
      !dt.isBefore(start) && !dt.isAfter(end);

  List<Map<String, dynamic>> _transactionsInRange(
    DateTime start,
    DateTime end,
  ) {
    return _allTransactions.whereType<Map<String, dynamic>>().where((t) {
      final dt = _txDate(t);
      return dt != null && _isInRange(dt, start, end);
    }).toList();
  }

  // Success metrics
  String _getSuccessRate() {
    final r = _currentRange();
    final txs = _transactionsInRange(r.start, r.end);
    if (txs.isEmpty) return '0.0%';
    final total = txs.length;
    final success = txs
        .where((t) => _isSuccess(t['payment_status']?.toString()))
        .length;
    final pct = (success / total) * 100.0;
    return _formatPercent(pct);
  }

  String _getTransactionCount() {
    final r = _currentRange();
    final txs = _transactionsInRange(r.start, r.end);
    final success = txs
        .where((t) => _isSuccess(t['payment_status']?.toString()))
        .length;
    return success.toString();
  }

  // Response time metrics (from order created_at to payment paid_at for successful payments)
  DateTime? _orderCreatedAt(Map<String, dynamic> tx) {
    final created = tx['order_info']?['created_at']?.toString();
    if (created == null || created.isEmpty) return null;
    try {
      return DateTime.parse(created).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime? _paidAt(Map<String, dynamic> tx) {
    final paid = tx['paid_at']?.toString();
    if (paid == null || paid.isEmpty) return null;
    try {
      return DateTime.parse(paid).toLocal();
    } catch (_) {
      return null;
    }
  }

  Duration? _averageResponseTime(List<Map<String, dynamic>> txs) {
    int count = 0;
    int totalMs = 0;
    for (final t in txs) {
      if (!_isSuccess(t['payment_status']?.toString())) continue;
      final c = _orderCreatedAt(t);
      final p = _paidAt(t);
      if (c == null || p == null) continue;
      final diff = p.difference(c);
      if (diff.isNegative) continue;
      totalMs += diff.inMilliseconds;
      count++;
    }
    if (count == 0) return null;
    return Duration(milliseconds: (totalMs / count).round());
  }

  Duration _responseThreshold() {
    switch (_selectedPeriod) {
      case 'Daily':
        return const Duration(hours: 2);
      case 'Weekly':
        return const Duration(hours: 24);
      case 'Monthly':
      default:
        return const Duration(hours: 48);
    }
  }

  String _formatDurationShort(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final hours = d.inMinutes / 60.0;
    return '${hours.toStringAsFixed(1)} h';
  }

  String _getResponseRate() {
    final r = _currentRange();
    final txs = _transactionsInRange(
      r.start,
      r.end,
    ).where(_isSuccessTx).toList();
    if (txs.isEmpty) return '0.0%';
    final th = _responseThreshold();
    int withDuration = 0;
    int within = 0;
    for (final t in txs) {
      final c = _orderCreatedAt(t);
      final p = _paidAt(t);
      if (c == null || p == null) continue;
      withDuration++;
      final diff = p.difference(c);
      if (!diff.isNegative && diff <= th) within++;
    }
    if (withDuration == 0) return '0.0%';
    return _formatPercent(within * 100.0 / withDuration);
  }

  bool _isSuccessTx(Map<String, dynamic> t) =>
      _isSuccess(t['payment_status']?.toString());

  String _getResponseTime() {
    final r = _currentRange();
    final txs = _transactionsInRange(r.start, r.end);
    final avg = _averageResponseTime(txs);
    if (avg == null) return '—';
    return _formatDurationShort(avg);
  }

  // Feedback metrics (happy = rating >= 4)
  int _ratingOf(dynamic raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    return int.tryParse(raw?.toString() ?? '0') ?? 0;
  }

  List<Map<String, dynamic>> _reviewsInRange(DateTime start, DateTime end) {
    return _allReviews.where((r) {
      final s = r['date']?.toString();
      if (s == null || s.isEmpty) return false;
      try {
        final dt = DateTime.parse(s).toLocal();
        return _isInRange(dt, start, end);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  String _getFeedbackRate() {
    final r = _currentRange();
    final revs = _reviewsInRange(r.start, r.end);
    if (revs.isEmpty) {
      if (_totalReviews == 0) return '0.0%';
      // Fallback: overall happy rate from all reviews
      final happyAll = _allReviews
          .where((e) => _ratingOf(e['rating']) >= 4)
          .length;
      return _formatPercent(
        _totalReviews == 0 ? 0 : (happyAll * 100.0 / _totalReviews),
      );
    }
    final happy = revs.where((e) => _ratingOf(e['rating']) >= 4).length;
    return _formatPercent(happy * 100.0 / revs.length);
  }

  String _getFeedbackCount() {
    final r = _currentRange();
    final revs = _reviewsInRange(r.start, r.end);
    if (revs.isEmpty) {
      final happyAll = _allReviews
          .where((e) => _ratingOf(e['rating']) >= 4)
          .length;
      return happyAll.toString();
    }
    final happy = revs.where((e) => _ratingOf(e['rating']) >= 4).length;
    return happy.toString();
  }

  String _formatCurrency(num v) => '৳${v.toStringAsFixed(0)}';

  // Replace hardcoded earnings with computed sums
  String _getTotalEarnings() {
    final r = _currentRange();
    final sum = _sumForRange(r.start, r.end);
    return _formatCurrency(sum);
  }

  String _getPeriodEarnings() {
    final r = _currentRange();
    final sum = _sumForRange(r.start, r.end);
    return _formatCurrency(sum);
  }

  String _getEarningsChange() {
    final cur = _currentRange();
    final prev = _previousRange();
    final curSum = _sumForRange(cur.start, cur.end);
    final prevSum = _sumForRange(prev.start, prev.end);
    final delta = curSum - prevSum;
    final sign = delta >= 0 ? '+' : '-';
    return '$sign ${_formatCurrency(delta.abs())}';
  }

  // Keep period text helper for UI labels
  String _getPeriodText() {
    switch (_selectedPeriod) {
      case 'Daily':
        return 'Today';
      case 'Weekly':
        return 'This Week';
      case 'Monthly':
      default:
        final now = DateTime.now();
        final monthName = DateFormat('MMMM').format(now);
        return monthName;
    }
  }

  // Mini chart sample data (UI decoration)
  List<double> _getChartData() {
    switch (_selectedPeriod) {
      case 'Daily':
        return [8.0, 15.0, 12.0, 22.0, 18.0, 30.0];
      case 'Weekly':
        return [15.0, 25.0, 20.0, 35.0, 28.0, 40.0];
      case 'Monthly':
      default:
        return [12.0, 20.0, 16.0, 28.0, 10.0, 36.0];
    }
  }

  ({DateTime start, DateTime end}) _currentRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Daily':
        final start = DateTime(now.year, now.month, now.day);
        return (start: start, end: now);
      case 'Weekly':
        // Assumption: last 7 days including today
        final sevenDaysAgo = now.subtract(const Duration(days: 6));
        final start = DateTime(
          sevenDaysAgo.year,
          sevenDaysAgo.month,
          sevenDaysAgo.day,
        );
        return (start: start, end: now);
      case 'Monthly':
      default:
        final start = DateTime(now.year, now.month, 1);
        return (start: start, end: now);
    }
  }

  ({DateTime start, DateTime end}) _previousRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Daily':
        final todayStart = DateTime(now.year, now.month, now.day);
        final yStart = todayStart.subtract(const Duration(days: 1));
        final yEnd = todayStart.subtract(const Duration(microseconds: 1));
        return (start: yStart, end: yEnd);
      case 'Weekly':
        final cur = _currentRange();
        final prevEnd = cur.start.subtract(const Duration(microseconds: 1));
        final prevStart = cur.start.subtract(const Duration(days: 7));
        return (start: prevStart, end: prevEnd);
      case 'Monthly':
      default:
        final firstThis = DateTime(now.year, now.month, 1);
        final firstPrev = DateTime(firstThis.year, firstThis.month - 1, 1);
        final endPrev = firstThis.subtract(const Duration(microseconds: 1));
        return (start: firstPrev, end: endPrev);
    }
  }

  double _amountForTx(Map<String, dynamic> tx) {
    final raw = tx['seller_item_total'] ?? tx['amount'];
    if (raw == null) return 0.0;
    try {
      return double.parse(raw.toString());
    } catch (_) {
      return 0.0;
    }
  }

  DateTime? _txDate(Map<String, dynamic> tx) {
    final s = (tx['paid_at'] ?? tx['created_at'])?.toString();
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _isSuccess(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    return s == 'completed' || s == 'paid' || s == 'succeeded';
  }

  double _sumForRange(DateTime start, DateTime end) {
    double total = 0.0;
    for (final t in _allTransactions) {
      if (t is! Map<String, dynamic>) continue;
      if (!_isSuccess(t['payment_status']?.toString())) continue;
      final dt = _txDate(t);
      if (dt == null) continue;
      if (!dt.isBefore(start) && !dt.isAfter(end)) {
        total += _amountForTx(t);
      }
    }
    return total;
  }

  String _formatReviewDate(dynamic raw) {
    if (raw == null) return 'Unknown date';
    try {
      final dt = DateTime.parse(raw.toString());
      return DateFormat('MMM d, yyyy').format(dt.toLocal());
    } catch (_) {
      return raw.toString();
    }
  }

  // Dynamic review item using fetched data
  Widget _buildDynamicReviewItem(Map<String, dynamic> review) {
    final avatar = review['profile_image'] ?? review['avatar'];
    final rating = (review['rating'] is int)
        ? review['rating']
        : (review['rating'] is double)
        ? (review['rating'] as double).round()
        : int.tryParse(review['rating']?.toString() ?? '0') ?? 0;
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
            backgroundColor: Colors.grey[700],
            backgroundImage: (avatar is String && avatar.trim().isNotEmpty)
                ? NetworkImage(avatar)
                : null,
            child: (avatar is! String || avatar.trim().isEmpty)
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
                        (review['name'] ?? 'Anonymous').toString(),
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
                          index < rating
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
                  _formatReviewDate(review['date']),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (review['review'] ?? '').toString(),
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

  Widget _buildReviewSkeleton() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[800],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[700]!),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 10, width: 120, color: Colors.grey[700]),
              const SizedBox(height: 6),
              Container(height: 8, width: 180, color: Colors.grey[700]),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ThreeDModelUploadCard extends StatefulWidget {
  final String sellerAuthId;
  const _ThreeDModelUploadCard({required this.sellerAuthId});

  @override
  State<_ThreeDModelUploadCard> createState() => _ThreeDModelUploadCardState();
}

class _ThreeDModelUploadCardState extends State<_ThreeDModelUploadCard> {
  bool _uploading = false;
  String? _status;
  String? _modelUrl;
  String? _selectedProductId;
  List<Map<String, dynamic>> _products = [];
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _loadingProducts = true;
    });
    try {
      final baseEnv =
          dotenv.env['SERVER_URL'] ??
          dotenv.env['BACKEND_URL'] ??
          'http://127.0.0.1:8000';
      final base = baseEnv.endsWith('/')
          ? baseEnv.substring(0, baseEnv.length - 1)
          : baseEnv;
      final uri = Uri.parse('$base/sellers/${widget.sellerAuthId}/products');
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final list = (data['products'] as List?) ?? [];
        setState(() {
          _products = list.cast<Map<String, dynamic>>();
          if (_products.isNotEmpty) {
            _selectedProductId = _products.first['id'].toString();
          }
        });
      } else {
        setState(() {
          _status = 'Failed to load products (${resp.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error loading products: $e';
      });
    } finally {
      setState(() {
        _loadingProducts = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    if ((_selectedProductId ?? '').isEmpty) {
      setState(() => _status = 'Select a product');
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['glb', 'gltf', 'usdz'],
      );
      if (result == null || result.files.isEmpty) return; // cancelled
      final picked = result.files.first;
      final fileName = picked.name;
      final ext = (picked.extension ?? fileName.split('.').last).toLowerCase();
      if (!['glb', 'gltf', 'usdz'].contains(ext)) {
        setState(() => _status = 'Unsupported file type: .$ext');
        return;
      }
      setState(() {
        _uploading = true;
        _status = 'Uploading...';
      });
      final baseEnv =
          dotenv.env['SERVER_URL'] ??
          dotenv.env['BACKEND_URL'] ??
          'http://127.0.0.1:8000';
      final base = baseEnv.endsWith('/')
          ? baseEnv.substring(0, baseEnv.length - 1)
          : baseEnv;
      final uri = Uri.parse(
        '$base/products/${_selectedProductId!.trim()}/3dmodel',
      );
      final session = Supabase.instance.client.auth.currentSession;
      final req = http.MultipartRequest('POST', uri);
      if (session != null) {
        req.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      if (picked.path != null) {
        req.files.add(
          await http.MultipartFile.fromPath(
            'file',
            picked.path!,
            filename: fileName,
          ),
        );
      } else if (picked.bytes != null) {
        req.files.add(
          http.MultipartFile.fromBytes(
            'file',
            picked.bytes!,
            filename: fileName,
          ),
        );
      } else {
        setState(() {
          _uploading = false;
          _status = 'No file data available';
        });
        return;
      }
      final resp = await req.send();
      final body = await resp.stream.bytesToString();
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final data = json.decode(body) as Map<String, dynamic>;
          setState(() {
            _modelUrl = data['model_link'] as String?;
            _status = 'Uploaded';
          });
        } catch (_) {
          setState(() => _status = 'Uploaded (parse error)');
        }
      } else {
        setState(() => _status = 'Failed (${resp.statusCode})');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff6a11cb), Color(0xff2575fc)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.view_in_ar,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '3D / AR Models',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingProducts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 4),
            ),
          if (!_loadingProducts && _products.isEmpty)
            const Text(
              'No products found. Add a product first.',
              style: TextStyle(color: Colors.white54),
            )
          else if (_products.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedProductId,
              items: _products.map((p) {
                final name = (p['name'] ?? 'Unnamed').toString();
                final id = p['id'].toString();
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              dropdownColor: Colors.grey[850],
              decoration: const InputDecoration(
                labelText: 'Select Product',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
              onChanged: (v) => setState(() {
                _selectedProductId = v;
              }),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Refresh list',
              onPressed: _loadingProducts ? null : _fetchProducts,
              icon: const Icon(Icons.refresh, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            icon: const Icon(Icons.upload_file),
            label: Text(_uploading ? 'Uploading...' : 'Upload 3D Model'),
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(
              _status!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (_modelUrl != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {},
              child: Text(
                _modelUrl!,
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
