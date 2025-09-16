import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AllReviewPage extends StatefulWidget {
  final String sellerId;
  const AllReviewPage({super.key, required this.sellerId});

  @override
  State<AllReviewPage> createState() => _AllReviewPageState();
}

class _AllReviewPageState extends State<AllReviewPage> {
  // Data
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _error;
  double _averageRating = 0.0;
  Map<String, int> _ratingCounts = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0};

  // Auth/session
  String? _authToken;
  String? _sellerId; // resolved seller id

  // Base URL logic mirrored from transactions page
  static String get _baseUrl {
    final fromServer = const String.fromEnvironment('API_BASE_URL');
    // Fallback chain (env var, then default)
    String raw = fromServer.isNotEmpty ? fromServer : 'http://127.0.0.1:8000';
    raw = raw.trim();
    if (raw.endsWith('/')) raw = raw.substring(0, raw.length - 1);
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final uri = Uri.parse(raw);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          // Allow manual override via env hostIp (optional) else 10.0.2.2 for emulator
          final hostIp = dotenv.env['hostIp'] ?? '192.168.0.154';
          raw = uri.replace(host: hostIp).toString();
          debugPrint('REVIEWS DEBUG: Replaced localhost with: $hostIp => $raw');
        }
      }
    } catch (e) {
      debugPrint('REVIEWS DEBUG: URL parse error: $e');
    }
    debugPrint('REVIEWS DEBUG: Final base URL: $raw');
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetch();
  }

  Future<void> _loadUserDataAndFetch() async {
    await _loadUserData();
    if (mounted) {
      _fetchReviews();
    }
  }

  Future<void> _loadUserData() async {
    // If sellerId explicitly provided use it; else attempt session + fallback
    if (widget.sellerId.isNotEmpty) {
      _sellerId = widget.sellerId;
    }
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _authToken = session.accessToken;
        if (_sellerId == null) {
          try {
            final decoded = JwtDecoder.decode(_authToken!);
            _sellerId = decoded['sub'] ?? decoded['user_id'] ?? decoded['uid'];
            debugPrint(
              'REVIEWS DEBUG: Seller ID from Supabase session: $_sellerId',
            );
          } catch (e) {
            debugPrint('REVIEWS DEBUG: JWT decode error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('REVIEWS DEBUG: session error: $e');
    }
    if (_sellerId == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('supabase_auth_token');
        if (stored != null) {
          final decodedJson = json.decode(stored);
          final token = decodedJson['access_token'];
          if (token != null) {
            _authToken = token;
            try {
              final decoded = JwtDecoder.decode(token);
              _sellerId =
                  decoded['sub'] ?? decoded['user_id'] ?? decoded['uid'];
              debugPrint(
                'REVIEWS DEBUG: Seller ID from SharedPreferences: $_sellerId',
              );
            } catch (e) {
              debugPrint('REVIEWS DEBUG: fallback JWT decode error: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('REVIEWS DEBUG: SharedPreferences error: $e');
      }
    }
    if (_sellerId == null) {
      debugPrint('REVIEWS DEBUG: Seller ID unresolved.');
    }
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    if (_sellerId == null || _sellerId!.isEmpty) {
      setState(() {
        _error = 'Seller ID not found. Please log in again.';
        _isLoading = false;
      });
      return;
    }
    try {
      final uri = Uri.parse('$_baseUrl/sellers/$_sellerId/reviews');
      debugPrint('REVIEWS DEBUG: Requesting $uri with sellerId=$_sellerId');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';
      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      debugPrint('REVIEWS DEBUG: Status ${resp.statusCode}');
      debugPrint('REVIEWS DEBUG: Body length ${resp.body.length}');
      debugPrint(
        'REVIEWS DEBUG: Raw body (first 400 chars): ' +
            (resp.body.length > 400
                ? resp.body.substring(0, 400) + '...'
                : resp.body),
      );
      if (resp.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = json.decode(resp.body);
        } catch (e) {
          setState(() {
            _error = 'Parse error: $e';
            _isLoading = false;
          });
          return;
        }
        if (data.isEmpty) {
          debugPrint('REVIEWS DEBUG: Empty JSON object received');
        }
        final serverTotal = data['total_reviews'];
        final serverAvg = data['average_rating'];
        final serverCounts = data['rating_counts'];
        debugPrint(
          'REVIEWS DEBUG: server total_reviews=$serverTotal avg=$serverAvg counts=$serverCounts',
        );

        final rawReviews = data['reviews'];
        if (rawReviews == null) {
          debugPrint('REVIEWS DEBUG: reviews field missing');
        }
        final reviews = List<Map<String, dynamic>>.from(rawReviews ?? []);
        debugPrint('REVIEWS DEBUG: Parsed reviews length=${reviews.length}');
        if (serverTotal != null && serverTotal != reviews.length) {
          debugPrint(
            'REVIEWS DEBUG: MISMATCH server total_reviews ($serverTotal) != parsed (${reviews.length})',
          );
        }

        // Prefer server stats if provided & valid
        if (serverAvg is num) {
          _averageRating = serverAvg.toDouble();
        }
        if (serverCounts is Map) {
          try {
            _ratingCounts = {
              '1': (serverCounts['1'] ?? serverCounts[1] ?? 0) as int,
              '2': (serverCounts['2'] ?? serverCounts[2] ?? 0) as int,
              '3': (serverCounts['3'] ?? serverCounts[3] ?? 0) as int,
              '4': (serverCounts['4'] ?? serverCounts[4] ?? 0) as int,
              '5': (serverCounts['5'] ?? serverCounts[5] ?? 0) as int,
            };
          } catch (e) {
            debugPrint('REVIEWS DEBUG: rating_counts parse error: $e');
          }
        }

        // If no server stats, compute locally
        if (serverAvg == null || serverCounts == null) {
          double totalRating = 0;
          final localCounts = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0};
          for (final r in reviews) {
            final raw = r['rating'];
            int rating;
            if (raw is int) {
              rating = raw;
            } else if (raw is double) {
              rating = raw.round();
            } else if (raw is String) {
              rating = int.tryParse(raw) ?? 0;
            } else {
              rating = 0;
            }
            r['rating'] = rating; // normalize
            if (rating >= 1 && rating <= 5) {
              totalRating += rating;
              localCounts['$rating'] = (localCounts['$rating'] ?? 0) + 1;
            }
            r.putIfAbsent('name', () => 'Anonymous');
            r.putIfAbsent('verified', () => true);
          }
          if (serverAvg == null) {
            _averageRating = reviews.isEmpty
                ? 0.0
                : totalRating / reviews.length;
          }
          if (serverCounts == null) {
            _ratingCounts = localCounts.map((k, v) => MapEntry(k, v));
          }
        } else {
          // Even if server stats present, still normalize each review's rating & required fields
          for (final r in reviews) {
            final raw = r['rating'];
            if (raw is double) r['rating'] = raw.round();
            if (r['name'] == null) r['name'] = 'Anonymous';
            if (r['verified'] == null) r['verified'] = true;
          }
        }

        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      } else if (resp.statusCode == 401) {
        setState(() {
          _error = 'Authentication failed. Please log in again!';
          _isLoading = false;
        });
      } else {
        String detail = 'HTTP ${resp.statusCode}';
        try {
          detail = (json.decode(resp.body)['detail'] ?? detail).toString();
        } catch (_) {}
        setState(() {
          _error = 'Failed to load reviews: $detail';
          _isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _error = 'Request timed out. Check network/server.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Replace existing build with list builder pattern
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildReviewsList(context)),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'All Reviews',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xffFFD700),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _averageRating.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff667eea)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 56),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchReviews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff667eea),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_reviews.isEmpty) {
      return const Center(
        child: Text('No reviews yet', style: TextStyle(color: Colors.white)),
      );
    }
    return RefreshIndicator(
      color: const Color(0xff667eea),
      backgroundColor: Colors.black,
      onRefresh: _fetchReviews,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          _buildRatingSummary(),
          const SizedBox(height: 16),
          ..._reviews.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => _showReviewDetails(context, r),
                child: _buildReviewItem(r, showArrow: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show detailed review
  void _showReviewDetails(BuildContext context, Map<String, dynamic> review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: const Text(
                        "Review Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getRatingColor(review['rating'] ?? 0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${review['rating'] ?? 0}/5",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Review Details Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getRatingColor(review['rating'] ?? 0),
                              _getRatingColor(
                                review['rating'] ?? 0,
                              ).withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _getRatingColor(
                                review['rating'] ?? 0,
                              ).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: _buildAvatar(review['avatar'], radius: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review['name'] ?? 'Anonymous',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Row(
                                        children: List.generate(
                                          5,
                                          (index) => Icon(
                                            index < (review['rating'] ?? 0)
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                            color: const Color(0xffFFD700),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getRatingText(review['rating'] ?? 0),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Reviewed on ${_formatDate(review['date'])}",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Review Content
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.rate_review,
                                  color: Color(0xffFFD700),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: const Text(
                                    "Customer Review",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: review['verified'] == true
                                        ? const Color(0xff38A169)
                                        : Colors.grey[600],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        review['verified'] == true
                                            ? Icons.verified
                                            : Icons.person,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        review['verified'] == true
                                            ? "Verified"
                                            : "Unverified",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              review['review'] ?? 'No review text',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Product Information
                      if (review['product'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag,
                                    color: Color(0xff667eea),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Reviewed Product",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review['product']['name'] ??
                                              'Unknown Product',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Category: ${review['product']['category'] ?? 'N/A'}",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "৳${review['product']['price'] ?? '0'}",
                                          style: const TextStyle(
                                            color: Color(0xff38A169),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 20),
                      ],

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Handle reply to review
                                _showReplyDialog(context, review);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xff667eea),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.reply,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Reply",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Handle contact customer
                                _contactCustomer(context, review);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xff667eea),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.message,
                                      color: Color(0xff667eea),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Contact",
                                      style: TextStyle(
                                        color: Color(0xff667eea),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                      // Add bottom spacing at the end of the sheet content
                      const SizedBox(height: 180),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return const Color(0xff38A169);
      case 4:
        return const Color(0xff4facfe);
      case 3:
        return const Color(0xffFFD700);
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return "Excellent";
      case 4:
        return "Very Good";
      case 3:
        return "Good";
      case 2:
        return "Fair";
      case 1:
        return "Poor";
      default:
        return "Not Rated";
    }
  }

  void _showReplyDialog(BuildContext context, Map<String, dynamic> review) {
    final TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Reply to ${review['name']}",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Original Review:",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                review['review'],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Write your reply...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xff667eea)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle send reply
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Reply sent successfully!"),
                  backgroundColor: Color(0xff38A169),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff667eea),
            ),
            child: const Text(
              "Send Reply",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _contactCustomer(BuildContext context, Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Contact ${review['name']}",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xff667eea)),
              title: const Text(
                "Send Email",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                review['email'] ?? "customer@email.com",
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              onTap: () {
                Navigator.pop(context);
                // Handle email
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xff667eea)),
              title: const Text(
                "Call Customer",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                review['phone'] ?? "+880 1700000000",
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              onTap: () {
                Navigator.pop(context);
                // Handle phone call
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xff667eea)),
              title: const Text(
                "Start Chat",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Direct message",
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                // Handle chat
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Helper method to build a review item
  Widget _buildReviewItem(
    Map<String, dynamic> review, {
    bool showArrow = false,
  }) {
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
          _buildAvatar(review['avatar'], radius: 22),
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
                  _formatDate(review['date']),
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
                if (review['product'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    review['product']['name'] ?? 'Unknown Product',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (showArrow)
            const Padding(
              padding: EdgeInsets.only(left: 8.0, top: 8.0),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    final total = _reviews.length;
    if (total == 0) {
      return const SizedBox.shrink();
    }
    Widget bar(int stars) {
      final count = _ratingCounts['$stars'] ?? 0;
      final pct = total > 0 ? count / total : 0.0;
      return Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$stars★',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getRatingColor(stars),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < _averageRating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xffFFD700),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$total reviews',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [5, 4, 3, 2, 1]
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: bar(s),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // Helper to build avatar safely without triggering assertion
  Widget _buildAvatar(dynamic urlRaw, {double radius = 22}) {
    // Prefer profile_image if map provided
    if (urlRaw is Map) {
      final dynamic p = urlRaw['profile_image'];
      if (p is String && p.trim().isNotEmpty) {
        urlRaw = p.trim();
      }
    }
    final String? url = (urlRaw is String && urlRaw.trim().isNotEmpty)
        ? urlRaw.trim()
        : null;
    if (url != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[700],
        backgroundImage: NetworkImage(url),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[700],
      child: Icon(
        Icons.person,
        color: Colors.white.withOpacity(0.9),
        size: radius * 0.9,
      ),
    );
  }
}
