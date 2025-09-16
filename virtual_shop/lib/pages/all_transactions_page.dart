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

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  final String _selectedPeriod = "this month";
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _error;
  String? _authToken;
  String? _sellerId; // To store the logged-in seller's ID

  // API configuration using your existing base URL logic
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
          print(
            'DEBUG: Replaced localhost with: $hostIp, final URL: $url',
          ); // Debug logging
        }
      }
    } catch (e) {
      print('DEBUG: Error in URL construction: $e'); // Debug logging
    }
    print('DEBUG: Final base URL: $url'); // Debug logging
    return url;
  }

  @override
  void initState() {
    super.initState();
    print(
      'DEBUG: SERVER_URL from env: ${dotenv.env['SERVER_URL']}',
    ); // Debug logging
    print('DEBUG: hostIp from env: ${dotenv.env['hostIp']}'); // Debug logging
    _loadUserDataAndFetchTransactions();
  }

  Future<void> _loadUserDataAndFetchTransactions() async {
    await _loadUserData();
    if (mounted) {
      _fetchTransactions();
    }
  }

  /// Loads auth/session using Supabase SDK first with SharedPreferences fallback.
  Future<void> _loadUserData() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _authToken = session.accessToken;
        if (_authToken != null) {
          try {
            final decoded = JwtDecoder.decode(_authToken!);
            _sellerId = decoded['sub'] ?? decoded['user_id'] ?? decoded['uid'];
            print('DEBUG: Seller ID from Supabase session: $_sellerId');
          } catch (e) {
            print('DEBUG: Failed to decode Supabase JWT: $e');
          }
        }
      }

      if (_sellerId == null) {
        final prefs = await SharedPreferences.getInstance();
        final sessionData = prefs.getString('supabase_auth_token');
        if (sessionData != null) {
          try {
            final stored = json.decode(sessionData);
            final token = stored['access_token'];
            if (token != null) {
              _authToken = token;
              final decoded = JwtDecoder.decode(token);
              _sellerId =
                  decoded['sub'] ?? decoded['user_id'] ?? decoded['uid'];
              print('DEBUG: Seller ID from SharedPreferences: $_sellerId');
            }
          } catch (e) {
            print('DEBUG: Error reading stored session: $e');
          }
        }
      }

      if (_sellerId == null) {
        print('DEBUG: Seller ID still null after attempts.');
      }
    } catch (e) {
      print('DEBUG: _loadUserData unexpected error: $e');
    }
  }

  /// Fetches transactions for the logged-in seller.
  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_sellerId == null) {
      setState(() {
        _error = 'Seller ID not found. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Correctly form the URL with the seller's ID
      final uri = Uri.parse('$_baseUrl/sellers/$_sellerId/transactions');
      print('DEBUG: Making request to: $uri'); // Debug logging
      print('DEBUG: Base URL is: $_baseUrl'); // Debug logging

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';
      print('DEBUG: Request headers keys: ${headers.keys}');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _transactions = data['transactions'] ?? [];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Authentication failed. Please log in again.';
          _isLoading = false;
        });
      } else {
        final errorBody = json.decode(response.body);
        setState(() {
          _error =
              'Failed to load transactions: ${errorBody['detail'] ?? response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '৳0';
    try {
      final double value = double.parse(amount.toString());
      return '৳${value.toStringAsFixed(0)}';
    } catch (e) {
      return '৳0';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final DateTime date = DateTime.parse(dateString).toLocal();
      return DateFormat('EEEE, d MMMM').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _getCustomerName(Map<String, dynamic> transaction) {
    final buyerInfo = transaction['buyer_info'] as Map<String, dynamic>? ?? {};
    final fullName = buyerInfo['full_name']?.toString();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    // Fallback if buyer name is not available
    final orderId = transaction['order_id']?.toString() ?? 'N/A';
    return 'Order #$orderId';
  }

  IconData _getPaymentIcon(String? paymentMethod) {
    switch (paymentMethod?.toLowerCase()) {
      case 'credit_card':
      case 'card':
        return Icons.credit_card;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'mobile_payment':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(String? paymentMethod) {
    switch (paymentMethod?.toLowerCase()) {
      case 'credit_card':
      case 'card':
        return const Color(0xff764ba2);
      case 'bank_transfer':
        return const Color(0xff4facfe);
      case 'mobile_payment':
        return Colors.orange;
      default:
        return const Color(0xff667eea);
    }
  }

  String _getPaymentStatus(String? status) {
    if (status == null) return "UNKNOWN";
    return status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: screenHeight * 0.01),
                height: 4,
                width: screenWidth * 0.1,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "All Transactions",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff38A169),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedPeriod.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.025,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    GestureDetector(
                      onTap: _fetchTransactions,
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),
              ),
              // Transactions List
              Expanded(
                child: _buildTransactionsList(screenWidth, screenHeight),
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(double screenWidth, double screenHeight) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff667eea)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: screenWidth * 0.12,
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: _fetchTransactions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff667eea),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: Colors.grey,
              size: screenWidth * 0.12,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'No transactions found',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Container(
          margin: EdgeInsets.only(bottom: screenHeight * 0.02),
          child: GestureDetector(
            onTap: () => _showTransactionDetails(context, transaction),
            child: _buildTransactionItem(context, transaction),
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final paymentMethod =
        transaction['payment_method']?.toString() ?? 'payment';
    // Use seller_item_total as this is what the seller receives
    final amount = _formatAmount(transaction['seller_item_total']);
    final date = _formatDate(
      transaction['paid_at'] ?? transaction['created_at'],
    );
    final customerName = _getCustomerName(transaction);
    final icon = _getPaymentIcon(paymentMethod);
    final color = _getPaymentColor(paymentMethod);
    final itemCount = transaction['seller_item_count'] ?? 0;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: screenWidth * 0.05),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment from $customerName",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.04,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: screenWidth * 0.033,
                  ),
                ),
                if (itemCount > 0) ...[
                  SizedBox(height: screenHeight * 0.003),
                  Text(
                    "$itemCount item${itemCount > 1 ? 's' : ''}",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                  color: const Color(0xff38A169),
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.02,
                  vertical: screenHeight * 0.003,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction['payment_status']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPaymentStatus(transaction['payment_status']),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.025,
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'succeeded':
        return const Color(0xff38A169);
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showTransactionDetails(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
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
                margin: EdgeInsets.only(top: 10),
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
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Transaction Details",
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
                        color: _getStatusColor(transaction['payment_status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPaymentStatus(transaction['payment_status']),
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
              // Transaction Details Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTransactionDetailsContent(
                    context,
                    transaction,
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionDetailsContent(
    BuildContext context,
    Map<String, dynamic> transaction,
    double screenWidth,
    double screenHeight,
  ) {
    final paymentMethod =
        transaction['payment_method']?.toString() ?? 'payment';
    final color = _getPaymentColor(paymentMethod);
    final icon = _getPaymentIcon(paymentMethod);
    final items = transaction['seller_items'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transaction Overview Card
        Container(
          padding: EdgeInsets.all(screenWidth * 0.06),
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
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: screenWidth * 0.06,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatAmount(transaction['seller_item_total']),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.08,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "Payment from ${_getCustomerName(transaction)}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.025),
              Row(
                children: [
                  Expanded(
                    child: _buildTransactionInfoItem(
                      context,
                      "Transaction ID",
                      "#${transaction['transaction_id'] ?? transaction['id'] ?? 'N/A'}",
                      Icons.receipt_long,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: _buildTransactionInfoItem(
                      context,
                      "Date & Time",
                      "${_formatDate(transaction['paid_at'] ?? transaction['created_at'])}\n${_formatTime(transaction['paid_at'] ?? transaction['created_at'])}",
                      Icons.access_time,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.025),

        // Order Details
        if (items.isNotEmpty) ...[
          _buildSectionContainer(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  context,
                  "Your Items in this Order",
                  Icons.shopping_bag,
                ),
                SizedBox(height: screenHeight * 0.02),
                ...items.map(
                  (item) => _buildOrderItem(context, item, screenWidth),
                ),
                SizedBox(height: screenHeight * 0.02),
                _buildOrderSummary(
                  context,
                  transaction,
                  screenWidth,
                  screenHeight,
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.025),
        ],

        // Payment Information
        _buildPaymentInformation(
          context,
          transaction,
          screenWidth,
          screenHeight,
        ),
        SizedBox(height: screenHeight * 0.025),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                "Download Receipt",
                Icons.download,
                const Color(0xff667eea),
                () => _downloadReceipt(context, transaction),
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: _buildActionButton(
                context,
                "Initiate Refund",
                Icons.refresh,
                Colors.orange,
                () => _initiateRefund(context, transaction),
                outlined: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 180),
      ],
    );
  }

  Widget _buildOrderItem(
    BuildContext context,
    Map<String, dynamic> item,
    double screenWidth,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? 'Unknown Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.04,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Quantity: ${item['quantity'] ?? 'N/A'}",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatAmount(item['unit_price']),
            style: TextStyle(
              color: const Color(0xff38A169),
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(
    BuildContext context,
    Map<String, dynamic> transaction,
    double screenWidth,
    double screenHeight,
  ) {
    final orderInfo = transaction['order_info'] as Map<String, dynamic>? ?? {};
    final sellerItemTotal =
        double.tryParse(transaction['seller_item_total']?.toString() ?? '0') ??
        0;
    final totalOrderAmount =
        double.tryParse(orderInfo['total']?.toString() ?? '0') ?? 0;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildOrderSummaryRow(
            context,
            "Your Items Total",
            _formatAmount(sellerItemTotal),
          ),
          if (totalOrderAmount > sellerItemTotal)
            _buildOrderSummaryRow(
              context,
              "Total Order Amount",
              _formatAmount(totalOrderAmount),
            ),
          const Divider(color: Colors.grey),
          _buildOrderSummaryRow(
            context,
            "Your Revenue",
            _formatAmount(sellerItemTotal),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInformation(
    BuildContext context,
    Map<String, dynamic> payment,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, "Payment Information", Icons.payment),
          SizedBox(height: screenHeight * 0.02),
          _buildPaymentInfoRow(
            context,
            "Payment Method",
            payment['payment_method']?.toString() ?? 'N/A',
          ),
          _buildPaymentInfoRow(
            context,
            "Transaction ID",
            payment['transaction_id']?.toString() ?? 'N/A',
          ),
          _buildPaymentInfoRow(
            context,
            "Order ID",
            payment['order_id']?.toString() ?? 'N/A',
          ),
          _buildPaymentInfoRow(
            context,
            "Payment Status",
            _getPaymentStatus(payment['payment_status']),
          ),
          if (payment['paid_at'] != null)
            _buildPaymentInfoRow(
              context,
              "Paid At",
              _formatDateTime(payment['paid_at']),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool outlined = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: outlined ? Colors.grey[800] : color,
          borderRadius: BorderRadius.circular(12),
          border: outlined ? Border.all(color: color) : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: outlined ? color : Colors.white,
              size: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.02),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: outlined ? color : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth * 0.035,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final DateTime date = DateTime.parse(dateString).toLocal();
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString).toLocal();
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  // Helper widget for transaction info items
  Widget _buildTransactionInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: screenWidth * 0.05,
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: screenWidth * 0.03,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: screenHeight * 0.005),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Helper widget to build section container
  Widget _buildSectionContainer(BuildContext context, {required Widget child}) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: child,
    );
  }

  // Helper widget to build section header
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Icon(icon, color: const Color(0xff667eea), size: screenWidth * 0.05),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper widget for order summary rows
  Widget _buildOrderSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: isTotal ? screenWidth * 0.04 : screenWidth * 0.035,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: isTotal ? const Color(0xff38A169) : Colors.white,
                fontSize: isTotal ? screenWidth * 0.045 : screenWidth * 0.035,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for payment info rows
  Widget _buildPaymentInfoRow(
    BuildContext context,
    String label,
    String value,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: screenWidth * 0.035,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // Download receipt functionality (placeholder)
  void _downloadReceipt(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final transactionId =
        transaction['transaction_id'] ?? transaction['id'] ?? 'Unknown';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Receipt download started for #$transactionId"),
        backgroundColor: const Color(0xff667eea),
      ),
    );
  }

  // Initiate refund functionality (placeholder)
  void _initiateRefund(BuildContext context, Map<String, dynamic> transaction) {
    final amount = _formatAmount(transaction['seller_item_total']);
    final transactionId =
        transaction['transaction_id'] ?? transaction['id'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Initiate Refund",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Are you sure you want to initiate a refund for $amount for transaction #$transactionId?",
              style: const TextStyle(color: Colors.white),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Refund initiated for transaction #$transactionId",
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              "Confirm Refund",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
