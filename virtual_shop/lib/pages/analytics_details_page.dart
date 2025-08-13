import 'package:flutter/material.dart';

class AnalyticsDetailsPage extends StatefulWidget {
  const AnalyticsDetailsPage({super.key});

  @override
  State<AnalyticsDetailsPage> createState() => _AnalyticsDetailsPageState();
}

class _AnalyticsDetailsPageState extends State<AnalyticsDetailsPage> {
  String _selectedPeriod = "Monthly";

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    final isLargeScreen = screenWidth >= 1200;

    // Responsive padding
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "Daily", child: Text("Daily")),
              const PopupMenuItem(value: "Weekly", child: Text("Weekly")),
              const PopupMenuItem(value: "Monthly", child: Text("Monthly")),
            ],
            child: Container(
              margin: EdgeInsets.only(right: horizontalPadding / 2),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 8 : 6,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _selectedPeriod,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
        // Overview Cards - 2x2 grid for mobile
        _buildOverviewCards(2),
        const SizedBox(height: 24),
        // Chart section
        _buildChartSection(200),
        const SizedBox(height: 20),
        // Earnings Breakdown
        _buildEarningsBreakdownSection(),
        const SizedBox(height: 20),
        // Top Products
        _buildTopProductsSection(),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Cards - 2x2 grid for tablet
        _buildOverviewCards(2),
        const SizedBox(height: 32),
        // Chart and breakdown side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildChartSection(250)),
            const SizedBox(width: 20),
            Expanded(flex: 1, child: _buildEarningsBreakdownSection()),
          ],
        ),
        const SizedBox(height: 24),
        // Top Products
        _buildTopProductsSection(),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Cards - 4 in a row for desktop
        _buildOverviewCards(4),
        const SizedBox(height: 40),
        // Chart and sections in a row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isLargeScreen ? 3 : 2,
              child: _buildChartSection(isLargeScreen ? 300 : 280),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildEarningsBreakdownSection(),
                  const SizedBox(height: 20),
                  _buildTopProductsSection(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCards(int cardsPerRow) {
    final cards = [
      _buildAnalyticsOverviewCard(
        "Total Revenue",
        _getPeriodEarnings(),
        _getEarningsChange(),
        Icons.attach_money,
        const Color(0xff667eea),
        true,
      ),
      _buildAnalyticsOverviewCard(
        "Orders",
        _getOrderCount(),
        _getOrderChange(),
        Icons.shopping_bag,
        const Color(0xff764ba2),
        true,
      ),
      _buildAnalyticsOverviewCard(
        "Avg Order Value",
        _getAvgOrderValue(),
        _getAvgOrderChange(),
        Icons.trending_up,
        const Color(0xff4facfe),
        _selectedPeriod != "Daily",
      ),
      _buildAnalyticsOverviewCard(
        "Conversion Rate",
        _getConversionRate(),
        _getConversionChange(),
        Icons.percent,
        const Color(0xff38A169),
        true,
      ),
    ];

    if (cardsPerRow == 4) {
      // Desktop: single row with 4 cards
      return Row(
        children:
            cards
                .map((card) => Expanded(child: card))
                .expand((widget) => [widget, const SizedBox(width: 16)])
                .toList()
              ..removeLast(),
      );
    } else {
      // Mobile/Tablet: 2x2 grid
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
            children: [
              const Text(
                "Earnings Trend",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff667eea).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getChartPeriodLabel(),
                  style: const TextStyle(
                    color: Color(0xff667eea),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Chart with earnings data
          SizedBox(height: height, child: _buildEnhancedSalesChart()),
          const SizedBox(height: 16),
          // Chart Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff667eea), Color(0xff764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Earnings (৳)",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsBreakdownSection() {
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
            "Earnings Breakdown",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._getEarningsBreakdown().map((item) => _buildBreakdownItem(item)),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection() {
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
            "Top Earning Products",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._getTopProducts().map((product) => _buildTopProductItem(product)),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // Helper method for getting period earnings
  String _getPeriodEarnings() {
    switch (_selectedPeriod) {
      case "Daily":
        return "৳25,300";
      case "Weekly":
        return "৳1,47,200";
      case "Monthly":
        return "৳5,59,200";
      default:
        return "৳5,59,200";
    }
  }

  String _getEarningsChange() {
    switch (_selectedPeriod) {
      case "Daily":
        return "+৳2,400";
      case "Weekly":
        return "+৳18,200";
      case "Monthly":
        return "+৳65,800";
      default:
        return "+৳65,800";
    }
  }

  // Helper methods for additional analytics data
  String _getOrderCount() {
    switch (_selectedPeriod) {
      case "Daily":
        return "142";
      case "Weekly":
        return "827";
      case "Monthly":
        return "3,245";
      default:
        return "3,245";
    }
  }

  String _getOrderChange() {
    switch (_selectedPeriod) {
      case "Daily":
        return "+12";
      case "Weekly":
        return "+87";
      case "Monthly":
        return "+245";
      default:
        return "+245";
    }
  }

  String _getAvgOrderValue() {
    switch (_selectedPeriod) {
      case "Daily":
        return "৳178";
      case "Weekly":
        return "৳198";
      case "Monthly":
        return "৳225";
      default:
        return "৳225";
    }
  }

  String _getAvgOrderChange() {
    switch (_selectedPeriod) {
      case "Daily":
        return "-৳15";
      case "Weekly":
        return "+৳12";
      case "Monthly":
        return "+৳28";
      default:
        return "+৳28";
    }
  }

  String _getConversionRate() {
    switch (_selectedPeriod) {
      case "Daily":
        return "3.2%";
      case "Weekly":
        return "3.8%";
      case "Monthly":
        return "4.1%";
      default:
        return "4.1%";
    }
  }

  String _getConversionChange() {
    switch (_selectedPeriod) {
      case "Daily":
        return "+0.2%";
      case "Weekly":
        return "+0.5%";
      case "Monthly":
        return "+0.8%";
      default:
        return "+0.8%";
    }
  }

  // Enhanced Sales Chart Widget
  Widget _buildEnhancedSalesChart() {
    final data = _getSalesEarningsData();
    final labels = _getChartLabels();
    final maxValue = data.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Y-axis labels and chart
        Expanded(
          child: Row(
            children: [
              // Y-axis labels
              SizedBox(
                width: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "৳${(maxValue.toInt())}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      "৳${(maxValue * 0.75).toInt()}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      "৳${(maxValue * 0.5).toInt()}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      "৳${(maxValue * 0.25).toInt()}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      "৳0",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Chart area
              Expanded(
                child: CustomPaint(
                  painter: _SalesChartPainter(data, maxValue),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // X-axis labels
        Padding(
          padding: const EdgeInsets.only(left: 60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: labels
                .map(
                  (label) => Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // Helper methods for chart data
  List<double> _getSalesEarningsData() {
    switch (_selectedPeriod) {
      case "Daily":
        return [1200.0, 1800.0, 1500.0, 2200.0, 1900.0, 2800.0, 2500.0];
      case "Weekly":
        return [8500.0, 12000.0, 9800.0, 15200.0, 13400.0, 18500.0, 16200.0];
      case "Monthly":
        return [35000.0, 42000.0, 38000.0, 51000.0, 47000.0, 58000.0];
      default:
        return [35000.0, 42000.0, 38000.0, 51000.0, 47000.0, 58000.0];
    }
  }

  List<String> _getChartLabels() {
    switch (_selectedPeriod) {
      case "Daily":
        return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      case "Weekly":
        return ["W1", "W2", "W3", "W4", "W5", "W6", "W7"];
      case "Monthly":
        return ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
      default:
        return ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
    }
  }

  String _getChartPeriodLabel() {
    switch (_selectedPeriod) {
      case "Daily":
        return "Last 7 Days";
      case "Weekly":
        return "Last 7 Weeks";
      case "Monthly":
        return "Last 6 Months";
      default:
        return "Last 6 Months";
    }
  }

  // Earnings Breakdown Data
  List<Map<String, dynamic>> _getEarningsBreakdown() {
    switch (_selectedPeriod) {
      case "Daily":
        return [
          {
            'label': 'Product Sales',
            'amount': '৳22,500',
            'percentage': '89%',
            'color': const Color(0xff667eea),
          },
          {
            'label': 'Shipping Fees',
            'amount': '৳1,800',
            'percentage': '7%',
            'color': const Color(0xff764ba2),
          },
          {
            'label': 'Service Charges',
            'amount': '৳1,000',
            'percentage': '4%',
            'color': const Color(0xff4facfe),
          },
        ];
      case "Weekly":
        return [
          {
            'label': 'Product Sales',
            'amount': '৳1,31,200',
            'percentage': '89%',
            'color': const Color(0xff667eea),
          },
          {
            'label': 'Shipping Fees',
            'amount': '৳10,800',
            'percentage': '7%',
            'color': const Color(0xff764ba2),
          },
          {
            'label': 'Service Charges',
            'amount': '৳5,200',
            'percentage': '4%',
            'color': const Color(0xff4facfe),
          },
        ];
      case "Monthly":
        return [
          {
            'label': 'Product Sales',
            'amount': '৳4,96,000',
            'percentage': '89%',
            'color': const Color(0xff667eea),
          },
          {
            'label': 'Shipping Fees',
            'amount': '৳41,200',
            'percentage': '7%',
            'color': const Color(0xff764ba2),
          },
          {
            'label': 'Service Charges',
            'amount': '৳22,000',
            'percentage': '4%',
            'color': const Color(0xff4facfe),
          },
        ];
      default:
        return [
          {
            'label': 'Product Sales',
            'amount': '৳4,96,000',
            'percentage': '89%',
            'color': const Color(0xff667eea),
          },
          {
            'label': 'Shipping Fees',
            'amount': '৳41,200',
            'percentage': '7%',
            'color': const Color(0xff764ba2),
          },
          {
            'label': 'Service Charges',
            'amount': '৳22,000',
            'percentage': '4%',
            'color': const Color(0xff4facfe),
          },
        ];
    }
  }

  // Top Products Data
  List<Map<String, dynamic>> _getTopProducts() {
    return [
      {
        'name': 'Wireless Headphones',
        'sold': '245',
        'revenue': '৳49,000',
        'icon': Icons.headphones,
        'color': const Color(0xff667eea),
      },
      {
        'name': 'Smartphone Case',
        'sold': '189',
        'revenue': '৳28,350',
        'icon': Icons.phone_android,
        'color': const Color(0xff764ba2),
      },
      {
        'name': 'Bluetooth Speaker',
        'sold': '156',
        'revenue': '৳31,200',
        'icon': Icons.speaker,
        'color': const Color(0xff4facfe),
      },
      {
        'name': 'Smart Watch',
        'sold': '78',
        'revenue': '৳39,000',
        'icon': Icons.watch,
        'color': const Color(0xff38A169),
      },
    ];
  }

  // Analytics Overview Card Widget
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
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: isTablet ? 24 : 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: isTablet ? 14 : 12,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isTablet ? 14 : 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isTablet ? 12 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Breakdown Item Widget
  Widget _buildBreakdownItem(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      child: Row(
        children: [
          Container(
            width: isTablet ? 16 : 12,
            height: isTablet ? 16 : 12,
            decoration: BoxDecoration(
              color: item['color'],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              item['label'],
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            item['percentage'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isTablet ? 14 : 12,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Text(
            item['amount'],
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Top Products Item Widget
  Widget _buildTopProductItem(Map<String, dynamic> product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

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
            width: isTablet ? 48 : 40,
            height: isTablet ? 48 : 40,
            decoration: BoxDecoration(
              color: product['color'],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              product['icon'],
              color: Colors.white,
              size: isTablet ? 24 : 20,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                Text(
                  "${product['sold']} sold",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            product['revenue'],
            style: TextStyle(
              color: const Color(0xff38A169),
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}

// Custom painter for the sales chart
class _SalesChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;

  _SalesChartPainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff667eea)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xff667eea).withOpacity(0.3),
          const Color(0xff667eea).withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    if (data.isNotEmpty) {
      final stepWidth = size.width / (data.length - 1);

      // Start the path
      final startX = 0.0;
      final startY = size.height - (data[0] / maxValue) * size.height;
      path.moveTo(startX, startY);
      fillPath.moveTo(startX, size.height);
      fillPath.lineTo(startX, startY);

      // Draw the line
      for (int i = 1; i < data.length; i++) {
        final x = i * stepWidth;
        final y = size.height - (data[i] / maxValue) * size.height;
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Complete the fill path
      fillPath.lineTo(size.width, size.height);
      fillPath.close();

      // Draw the filled area
      canvas.drawPath(fillPath, fillPaint);

      // Draw the line
      canvas.drawPath(path, paint);

      // Draw points
      final pointPaint = Paint()
        ..color = const Color(0xff667eea)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < data.length; i++) {
        final x = i * stepWidth;
        final y = size.height - (data[i] / maxValue) * size.height;
        canvas.drawCircle(Offset(x, y), 4, pointPaint);

        // Draw white center
        canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
