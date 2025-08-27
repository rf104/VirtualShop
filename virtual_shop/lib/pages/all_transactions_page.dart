import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String?
  _authToken; // You need to implement getting this from your auth system

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
          url = uri
              .replace(host: dotenv.env['hostIp'] ?? '192.168.0.154')
              .toString();
        }
      }
    } catch (_) {}
    return url;
  }

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    _fetchTransactions();
  }

  Future<void> _loadAuthToken() async {
    // TODO: Implement your token retrieval logic here
    // This could be from SharedPreferences, SecureStorage, etc.
    // For now, this is a placeholder
    _authToken = await _getStoredAuthToken();
  }

  Future<String?> _getStoredAuthToken() async {
    // TODO: Replace with your actual token storage implementation
    // Example using SharedPreferences:
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getString('auth_token');
    return 'your-jwt-token-here';
  }

  Future<void> _fetchTransactions({
    int limit = 50,
    int offset = 0,
    String? paymentStatus,
    String? startDate,
    String? endDate,
  }) async {
    if (_authToken == null) {
      setState(() {
        _error = 'Authentication token not found';
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$_baseUrl/sellers/transactions').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
          if (paymentStatus != null) 'payment_status': paymentStatus,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _transactions = data['transactions'] ?? [];
          _isLoading = false;
          _error = null;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Authentication failed. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load transactions: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
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
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('EEEE, d MMMM').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _getCustomerName(Map<String, dynamic> transaction) {
    // Since the API doesn't provide customer details directly,
    // we'll need to extract from transaction ID or use a placeholder
    final paymentId = transaction['payment']?['id']?.toString() ?? '';
    return 'Customer #${paymentId.substring(0, 8)}';
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
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'success':
        return 'COMPLETED';
      case 'pending':
        return 'PENDING';
      case 'failed':
        return 'FAILED';
      default:
        return 'UNKNOWN';
    }
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
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
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

    final payment = transaction['payment'] ?? {};
    final orderMeta = transaction['order_meta'] ?? {};
    final items = transaction['items'] as List<dynamic>? ?? [];

    final paymentMethod = payment['payment_method']?.toString() ?? 'payment';
    final amount = _formatAmount(payment['amount']);
    final date = _formatDate(payment['paid_at'] ?? payment['created_at']);
    final customerName = _getCustomerName(transaction);
    final icon = _getPaymentIcon(paymentMethod);
    final color = _getPaymentColor(paymentMethod);

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
                if (items.isNotEmpty) ...[
                  SizedBox(height: screenHeight * 0.003),
                  Text(
                    "${items.length} item${items.length > 1 ? 's' : ''}",
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
                  color: _getStatusColor(payment['payment_status']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getPaymentStatus(payment['payment_status']),
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
      case 'completed':
      case 'success':
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final payment = transaction['payment'] ?? {};
    final orderMeta = transaction['order_meta'] ?? {};
    final items = transaction['items'] as List<dynamic>? ?? [];

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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: screenWidth * 0.04,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        "Transaction Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
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
                        color: _getStatusColor(payment['payment_status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPaymentStatus(payment['payment_status']),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.025,
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
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: _buildTransactionDetailsContent(
                    context,
                    transaction,
                    screenWidth,
                    screenHeight,
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
    final payment = transaction['payment'] ?? {};
    final orderMeta = transaction['order_meta'] ?? {};
    final items = transaction['items'] as List<dynamic>? ?? [];

    final paymentMethod = payment['payment_method']?.toString() ?? 'payment';
    final color = _getPaymentColor(paymentMethod);
    final icon = _getPaymentIcon(paymentMethod);

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
                            _formatAmount(payment['amount']),
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
                      "#${payment['transaction_id'] ?? payment['id'] ?? 'N/A'}",
                      Icons.receipt_long,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: _buildTransactionInfoItem(
                      context,
                      "Date & Time",
                      "${_formatDate(payment['paid_at'] ?? payment['created_at'])}\n${_formatTime(payment['paid_at'] ?? payment['created_at'])}",
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
                _buildSectionHeader(context, "Order Items", Icons.shopping_bag),
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
        _buildPaymentInformation(context, payment, screenWidth, screenHeight),
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
              Icons.inventory,
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
                  item['product_name']?.toString() ?? 'Unknown Product',
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
    final payment = transaction['payment'] ?? {};
    final items = transaction['items'] as List<dynamic>? ?? [];

    // Calculate totals from items
    double subtotal = 0;
    for (final item in items) {
      final quantity =
          double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      final unitPrice =
          double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
      subtotal += quantity * unitPrice;
    }

    final totalAmount =
        double.tryParse(payment['amount']?.toString() ?? '0') ?? 0;
    final shippingTax = totalAmount - subtotal;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildOrderSummaryRow(context, "Subtotal", _formatAmount(subtotal)),
          if (shippingTax > 0)
            _buildOrderSummaryRow(
              context,
              "Fees & Tax",
              _formatAmount(shippingTax),
            ),
          const Divider(color: Colors.grey),
          _buildOrderSummaryRow(
            context,
            "Total",
            _formatAmount(totalAmount),
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
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dateString);
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
            ),
          ),
        ],
      ),
    );
  }

  // Download receipt functionality
  void _downloadReceipt(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Download Receipt",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Choose receipt format:",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text(
                "PDF Format",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Detailed receipt with company logo",
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                _generatePDFReceipt(context, transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xff667eea)),
              title: const Text(
                "Email Receipt",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Send to customer's email",
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                _emailReceipt(context, transaction);
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

  // Generate PDF receipt
  void _generatePDFReceipt(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xff667eea)),
            SizedBox(height: 16),
            Text(
              "Generating PDF Receipt...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      final payment = transaction['payment'] ?? {};
      final transactionId =
          payment['transaction_id'] ?? payment['id'] ?? 'Unknown';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Receipt downloaded for transaction #$transactionId",
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xff38A169),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  // Email receipt
  void _emailReceipt(BuildContext context, Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Email Receipt",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter email address",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.email, color: Color(0xff667eea)),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Receipt sent successfully!"),
                  backgroundColor: Color(0xff38A169),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff667eea),
            ),
            child: const Text("Send", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Initiate refund functionality
  void _initiateRefund(BuildContext context, Map<String, dynamic> transaction) {
    final payment = transaction['payment'] ?? {};
    final amount = _formatAmount(payment['amount']);

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
              "Are you sure you want to initiate a refund for $amount?",
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              "This action cannot be undone and will process the refund to the customer's original payment method.",
              style: TextStyle(color: Colors.grey),
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
              final transactionId =
                  payment['transaction_id'] ?? payment['id'] ?? 'Unknown';
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
              "Initiate Refund",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
