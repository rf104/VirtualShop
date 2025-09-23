import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Analytics Details for the Seller (dynamic)
class AnalyticsDetailsPage extends StatefulWidget {
  const AnalyticsDetailsPage({super.key});

  @override
  State<AnalyticsDetailsPage> createState() => _AnalyticsDetailsPageState();
}

class _AnalyticsDetailsPageState extends State<AnalyticsDetailsPage> {
  String _selectedPeriod = 'Monthly'; // Daily | Weekly | Monthly

  bool _loading = false;
  String? _error;

  // Raw data
  List<Map<String, dynamic>> _transactions = [];

  static String get _baseUrl {
    final fromServer = dotenv.env['SERVER_URL']?.trim();
    final fromBackend = dotenv.env['BACKEND_URL']?.trim();
    String raw = (fromServer != null && fromServer.isNotEmpty)
        ? fromServer
        : (fromBackend != null && fromBackend.isNotEmpty
              ? fromBackend
              : 'http://127.0.0.1:8000');
    raw = raw.replaceAll(RegExp(r'\s+'), '');
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
    } catch (_) {}
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _error = 'Not signed in');
        return;
      }

      final base = _baseUrl;
      debugPrint('[Analytics] Using base URL: $base');

      // Fast health check to fail quickly if server is unreachable
      final ok = await _ensureBackendUp(base);
      if (!ok) {
        setState(
          () => _error =
              'Backend unreachable at $base. Set BACKEND_URL in your .env to a reachable host.',
        );
        return;
      }

      await _fetchTransactions(user.id);
    } catch (e) {
      setState(() => _error = 'Failed to load analytics: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _ensureBackendUp(String base) async {
    try {
      final uri = Uri.parse('$base/sellers/health');
      final r = await http.get(uri).timeout(const Duration(seconds: 3));
      return r.statusCode == 200;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchTransactions(String sellerId) async {
    try {
      final uri = Uri.parse('$_baseUrl/sellers/$sellerId/transactions');
      final headers = <String, String>{'Content-Type': 'application/json'};
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
      }

      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final map = json.decode(resp.body) as Map<String, dynamic>;
        final list = (map['transactions'] as List? ?? [])
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
        setState(() => _transactions = List<Map<String, dynamic>>.from(list));
      } else {
        setState(() => _error = 'Transactions error: HTTP ${resp.statusCode}');
      }
    } on TimeoutException catch (_) {
      setState(
        () => _error =
            'Request timed out. Check server at $_baseUrl and network.',
      );
    } on SocketException catch (e) {
      setState(
        () => _error =
            'Network error: ${e.osError?.message ?? e.message}. Host $_baseUrl',
      );
    } catch (e) {
      setState(() => _error = 'Failed to fetch transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    final isLargeScreen = screenWidth >= 1200;

    final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 24.0 : 16.0);
    final verticalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Analytics Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [_buildPeriodMenu(isTablet)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _init,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: _buildResponsiveLayout(
                context,
                isTablet,
                isDesktop,
                isLargeScreen,
              ),
            ),
    );
  }

  Widget _buildPeriodMenu(bool isTablet) {
    return PopupMenuButton<String>(
      color: Colors.grey[900],
      initialValue: _selectedPeriod,
      onSelected: (value) => setState(() => _selectedPeriod = value),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'Daily', child: Text('Daily')),
        PopupMenuItem(value: 'Weekly', child: Text('Weekly')),
        PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
      ],
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          children: [
            Text(_selectedPeriod, style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(
    BuildContext context,
    bool isTablet,
    bool isDesktop,
    bool isLargeScreen,
  ) {
    if (isDesktop) {
      return _buildDesktopLayout(context, isLargeScreen);
    } else if (isTablet) {
      return _buildTabletLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewCards(2),
        const SizedBox(height: 24),
        _buildChartSection(200),
        const SizedBox(height: 20),
        _buildEarningsBreakdownSection(),
        const SizedBox(height: 20),
        _buildTopProductsSection(),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewCards(2),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildChartSection(250)),
            const SizedBox(width: 20),
            Expanded(flex: 1, child: _buildEarningsBreakdownSection()),
          ],
        ),
        const SizedBox(height: 24),
        _buildTopProductsSection(),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewCards(4),
        const SizedBox(height: 40),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildChartSection(isLargeScreen ? 300 : 280)),
            const SizedBox(width: 24),
            Expanded(child: _buildEarningsBreakdownSection()),
          ],
        ),
        const SizedBox(height: 24),
        _buildTopProductsSection(),
      ],
    );
  }

  // Overview Cards
  Widget _buildOverviewCards(int cardsPerRow) {
    final revenueStr = _getPeriodEarnings();
    final earningsChange = _getEarningsChange();
    final orders = _getOrderCount();
    final orderChange = _getOrderChange();
    final aov = _getAvgOrderValue();
    final aovChange = _getAvgOrderChange();
    final conv = _getConversionRate();
    final convChange = _getConversionChange();

    final cards = [
      _buildAnalyticsOverviewCard(
        'Total Revenue',
        revenueStr,
        earningsChange,
        Icons.attach_money,
        const Color(0xff667eea),
        !earningsChange.startsWith('-'),
      ),
      _buildAnalyticsOverviewCard(
        'Orders',
        orders,
        orderChange,
        Icons.shopping_bag,
        const Color(0xff764ba2),
        !orderChange.startsWith('-'),
      ),
      _buildAnalyticsOverviewCard(
        'Avg Order Value',
        aov,
        aovChange,
        Icons.trending_up,
        const Color(0xff4facfe),
        !aovChange.startsWith('-'),
      ),
      _buildAnalyticsOverviewCard(
        'Conversion Rate',
        conv,
        convChange,
        Icons.percent,
        const Color(0xff38A169),
        !convChange.startsWith('-'),
      ),
    ];

    if (cardsPerRow == 4) {
      return Row(
        children:
            cards
                .map((card) => Expanded(child: card))
                .expand((w) => [w, const SizedBox(width: 16)])
                .toList()
              ..removeLast(),
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildChartSection(double height) {
    final series = _chartSeries();
    final labels = series.labels;
    final data = series.values;
    final maxValue = data.isEmpty ? 0.0 : data.reduce((a, b) => a > b ? a : b);

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales · ${_getChartPeriodLabel()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(children: _buildLegend()),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels
                SizedBox(
                  width: 48,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(maxValue),
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                      Text(
                        _formatCurrency(maxValue / 2),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      Text(
                        '0',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    children: [
                      // grid lines
                      Positioned.fill(
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CustomPaint(
                            painter: _SalesChartPainter(
                              data,
                              maxValue == 0 ? 1 : maxValue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map(
                    (e) => Expanded(
                      child: Center(
                        child: Text(
                          e,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLegend() {
    final breakdown = _earningsBreakdownForRange();
    return breakdown.take(3).map((b) {
      return Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: b['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              b['method'] as String,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildEarningsBreakdownSection() {
    final items = _earningsBreakdownForRange();
    final total = items.fold<double>(
      0.0,
      (p, e) => p + (e['amount'] as double),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings Breakdown',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (e) => _buildBreakdownItem({
              'color': e['color'],
              'label': e['method'],
              'amount': e['amount'],
              'percent': total > 0
                  ? ((e['amount'] as double) * 100.0 / total)
                  : 0.0,
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection() {
    final products = _topProductsForRange();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Products',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...products.take(4).map(_buildTopProductItem),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // Overview Card
  Widget _buildAnalyticsOverviewCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
    bool isPositive,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 10,
            color: Colors.black54,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Breakdown item
  Widget _buildBreakdownItem(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final color = item['color'] as Color;
    final amount = (item['amount'] as double?) ?? 0.0;
    final percent = (item['percent'] as double?) ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 8, color: Colors.grey[800]),
                  FractionallySizedBox(
                    widthFactor: (percent.clamp(0.0, 100.0)) / 100.0,
                    child: Container(height: 8, color: color.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(color: Colors.white70),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Top product item
  Widget _buildTopProductItem(Map<String, dynamic> product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final name = (product['name'] ?? 'Product') as String;
    final sold = (product['sold'] ?? 0).toString();
    final revenue = (product['revenue'] ?? 0.0) as double;
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xff667eea),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$sold sold',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(revenue),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Data computations
  ({DateTime start, DateTime end}) _currentRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Daily':
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start: start, end: end);
      case 'Weekly':
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final start = end.subtract(const Duration(days: 7 * 7 - 1));
        return (start: start, end: end);
      case 'Monthly':
      default:
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final start = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(days: 30 * 5));
        return (start: start, end: end);
    }
  }

  ({DateTime start, DateTime end}) _previousRange() {
    final cur = _currentRange();
    final delta = cur.end.difference(cur.start).inDays + 1;
    final start = cur.start.subtract(Duration(days: delta));
    final end = cur.end.subtract(Duration(days: delta));
    return (start: start, end: end);
  }

  bool _inRange(DateTime dt, DateTime start, DateTime end) =>
      !dt.isBefore(start) && !dt.isAfter(end);

  bool _isSuccess(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    return s == 'completed' || s == 'paid' || s == 'succeeded';
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

  double _amountForTx(Map<String, dynamic> tx) {
    final raw = tx['seller_item_total'] ?? tx['amount'];
    if (raw == null) return 0.0;
    try {
      return double.parse(raw.toString());
    } catch (_) {
      return 0.0;
    }
  }

  // Metrics
  String _formatCurrency(num v) => '৳${NumberFormat.compact().format(v)}';

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

  String _getOrderCount() {
    final r = _currentRange();
    final txs = _transactions.where((t) {
      final dt = _txDate(t);
      return dt != null &&
          _inRange(dt, r.start, r.end) &&
          _isSuccess(t['payment_status']?.toString());
    }).toList();
    return txs.length.toString();
  }

  String _getOrderChange() {
    final cur = _currentRange();
    final prev = _previousRange();
    int cnt(DateTime s, DateTime e) => _transactions.where((t) {
      final dt = _txDate(t);
      return dt != null &&
          _inRange(dt, s, e) &&
          _isSuccess(t['payment_status']?.toString());
    }).length;
    final d = cnt(cur.start, cur.end) - cnt(prev.start, prev.end);
    final sign = d >= 0 ? '+' : '-';
    return '$sign ${d.abs()}';
  }

  String _getAvgOrderValue() {
    final r = _currentRange();
    double sum = 0.0;
    int count = 0;
    for (final t in _transactions) {
      final dt = _txDate(t);
      if (dt == null || !_inRange(dt, r.start, r.end)) continue;
      if (!_isSuccess(t['payment_status']?.toString())) continue;
      sum += _amountForTx(t);
      count++;
    }
    final aov = count == 0 ? 0.0 : sum / count;
    return _formatCurrency(aov);
  }

  String _getAvgOrderChange() {
    final cur = _currentRange();
    final prev = _previousRange();
    double avg(DateTime s, DateTime e) {
      double sum = 0.0;
      int count = 0;
      for (final t in _transactions) {
        final dt = _txDate(t);
        if (dt == null || !_inRange(dt, s, e)) continue;
        if (!_isSuccess(t['payment_status']?.toString())) continue;
        sum += _amountForTx(t);
        count++;
      }
      return count == 0 ? 0.0 : sum / count;
    }

    final d = avg(cur.start, cur.end) - avg(prev.start, prev.end);
    final sign = d >= 0 ? '+' : '-';
    return '$sign ${_formatCurrency(d.abs())}';
  }

  String _getConversionRate() {
    final r = _currentRange();
    final inRange = _transactions.where((t) {
      final dt = _txDate(t);
      return dt != null && _inRange(dt, r.start, r.end);
    }).toList();
    if (inRange.isEmpty) return '0.0%';
    final total = inRange.length;
    final success = inRange
        .where((t) => _isSuccess(t['payment_status']?.toString()))
        .length;
    final pct = success * 100.0 / total;
    return '${pct.toStringAsFixed(1)}%';
  }

  String _getConversionChange() {
    final cur = _currentRange();
    final prev = _previousRange();
    double rate(DateTime s, DateTime e) {
      final inRange = _transactions.where((t) {
        final dt = _txDate(t);
        return dt != null && _inRange(dt, s, e);
      }).toList();
      if (inRange.isEmpty) return 0.0;
      final total = inRange.length;
      final success = inRange
          .where((t) => _isSuccess(t['payment_status']?.toString()))
          .length;
      return success * 100.0 / total;
    }

    final d = rate(cur.start, cur.end) - rate(prev.start, prev.end);
    final sign = d >= 0 ? '+' : '-';
    return '$sign ${d.abs().toStringAsFixed(1)}%';
  }

  double _sumForRange(DateTime start, DateTime end) {
    double total = 0.0;
    for (final t in _transactions) {
      final dt = _txDate(t);
      if (dt == null || !_inRange(dt, start, end)) continue;
      if (!_isSuccess(t['payment_status']?.toString())) continue;
      total += _amountForTx(t);
    }
    return total;
  }

  // Chart series
  ({List<String> labels, List<double> values}) _chartSeries() {
    final now = DateTime.now();
    if (_selectedPeriod == 'Daily') {
      // last 7 days
      final days = List.generate(
        7,
        (i) => DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: 6 - i)),
      );
      final labels = days.map((d) => DateFormat('E').format(d)).toList();
      final values = days.map((d) {
        final start = DateTime(d.year, d.month, d.day);
        final end = DateTime(d.year, d.month, d.day, 23, 59, 59);
        return _sumForRange(start, end);
      }).toList();
      return (labels: labels, values: values);
    } else if (_selectedPeriod == 'Weekly') {
      // last 7 weeks, rolling windows
      final List<String> labels = [];
      final List<double> values = [];
      DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      for (int i = 6; i >= 0; i--) {
        final start = end.subtract(const Duration(days: 6));
        labels.add('W${7 - i}');
        values.add(_sumForRange(start, end));
        end = start.subtract(const Duration(days: 1));
      }
      return (labels: labels, values: values);
    } else {
      // Monthly: last 6 months
      final months = List<DateTime>.generate(6, (i) {
        final d = DateTime(now.year, now.month - (5 - i), 1);
        return DateTime(d.year, d.month, 1);
      });
      final labels = months.map((d) => DateFormat('MMM').format(d)).toList();
      final values = months.map((m) {
        final start = DateTime(m.year, m.month, 1);
        final end = DateTime(
          m.year,
          m.month + 1,
          1,
        ).subtract(const Duration(seconds: 1));
        return _sumForRange(start, end);
      }).toList();
      return (labels: labels, values: values);
    }
  }

  String _getChartPeriodLabel() {
    switch (_selectedPeriod) {
      case 'Daily':
        return 'Last 7 Days';
      case 'Weekly':
        return 'Last 7 Weeks';
      case 'Monthly':
      default:
        return 'Last 6 Months';
    }
  }

  // Earnings breakdown by payment method in current range
  List<Map<String, dynamic>> _earningsBreakdownForRange() {
    final r = _currentRange();
    final map = <String, double>{};
    for (final t in _transactions) {
      final dt = _txDate(t);
      if (dt == null || !_inRange(dt, r.start, r.end)) continue;
      if (!_isSuccess(t['payment_status']?.toString())) continue;
      final method = (t['payment_method'] ?? 'Other').toString();
      map[method] = (map[method] ?? 0.0) + _amountForTx(t);
    }
    final colors = [
      const Color(0xff667eea),
      const Color(0xff764ba2),
      const Color(0xff4facfe),
      const Color(0xff38A169),
      Colors.orange,
      Colors.teal,
    ];
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final out = <Map<String, dynamic>>[];
    for (int i = 0; i < entries.length; i++) {
      out.add({
        'method': entries[i].key,
        'amount': entries[i].value,
        'color': colors[i % colors.length],
      });
    }
    return out;
  }

  // Top products aggregation from seller_items
  List<Map<String, dynamic>> _topProductsForRange() {
    final r = _currentRange();
    final Map<String, Map<String, dynamic>> agg = {};
    for (final t in _transactions) {
      final dt = _txDate(t);
      if (dt == null || !_inRange(dt, r.start, r.end)) continue;
      if (!_isSuccess(t['payment_status']?.toString())) continue;
      final items = (t['seller_items'] as List?) ?? [];
      for (final it in items.whereType<Map>()) {
        final id = it['id']?.toString() ?? it['product_id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final name = (it['name'] ?? 'Product').toString();
        final qty =
            (it['quantity'] as num?)?.toInt() ??
            int.tryParse(it['quantity']?.toString() ?? '') ??
            0;
        final itemTotal =
            double.tryParse(it['item_total']?.toString() ?? '') ??
            ((double.tryParse(it['unit_price']?.toString() ?? '') ?? 0.0) *
                qty);
        final cur = agg[id];
        if (cur == null) {
          agg[id] = {'name': name, 'sold': qty, 'revenue': itemTotal};
        } else {
          cur['sold'] = (cur['sold'] as int) + qty;
          cur['revenue'] = (cur['revenue'] as double) + itemTotal;
        }
      }
    }
    final list = agg.values
        .map(
          (e) => {
            'name': e['name'],
            'sold': e['sold'],
            'revenue': (e['revenue'] as double),
          },
        )
        .toList();
    list.sort(
      (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
    );
    return list;
  }
}

// Grid background for chart
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    final rows = 3;
    final rowH = size.height / rows;
    for (int i = 1; i < rows; i++) {
      final y = i * rowH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for the sales chart (smooth line + area fill)
class _SalesChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;

  _SalesChartPainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xff667eea)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55667eea), Color(0x11667eea)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final len = data.length;
    final stepX = len == 1 ? size.width : size.width / (len - 1);

    double yAt(int i) =>
        size.height -
        ((data[i] / (maxValue <= 0 ? 1 : maxValue)) * size.height);

    path.moveTo(0, yAt(0));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, yAt(0));

    for (int i = 1; i < len; i++) {
      final x = i * stepX;
      final y = yAt(i);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = const Color(0xff667eea);
    final centerPaint = Paint()..color = Colors.white;
    for (int i = 0; i < len; i++) {
      final x = i * stepX;
      final y = yAt(i);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 2, centerPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
