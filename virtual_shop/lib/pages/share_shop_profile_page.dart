import 'package:flutter/material.dart';

class ShareShopProfilePage extends StatefulWidget {
  const ShareShopProfilePage({super.key});

  @override
  State<ShareShopProfilePage> createState() => _ShareShopProfilePageState();
}

class _ShareShopProfilePageState extends State<ShareShopProfilePage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    
    // Responsive padding
    final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 30.0 : 20.0);
    final verticalSpacing = isDesktop ? 30.0 : (isTablet ? 25.0 : 20.0);
    
    // Responsive grid
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 3);
    final childAspectRatio = isDesktop ? 1.1 : (isTablet ? 1.0 : 0.9);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Share Shop Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 22 : 18,
          ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff667eea), Color(0xff764ba2)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.share,
                    color: Colors.white,
                    size: isDesktop ? 36 : (isTablet ? 34 : 32),
                  ),
                  SizedBox(width: isTablet ? 20 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Share Your Shop",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isTablet ? 6 : 4),
                        Text(
                          "Reach more customers by sharing your profile",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: verticalSpacing),

            // Shop Link Preview
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 18 : 16)),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.link,
                        color: Color(0xff667eea),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Shop Profile Link",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "https://virtualshop.com/urbandrift",
                            style: TextStyle(
                              color: const Color(0xff667eea),
                              fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _copyShopLink(),
                          child: Container(
                            padding: EdgeInsets.all(isDesktop ? 10 : 8),
                            decoration: BoxDecoration(
                              color: const Color(0xff667eea),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: isDesktop ? 18 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: verticalSpacing),

            // Share Options Title
            Row(
              children: [
                Icon(
                  Icons.share,
                  color: const Color(0xff667eea),
                  size: isDesktop ? 24 : (isTablet ? 22 : 20),
                ),
                const SizedBox(width: 8),
                Text(
                  "Share via",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 20 : 16),

            // Share Options Grid
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: isDesktop ? 20 : (isTablet ? 18 : 16),
                  crossAxisSpacing: isDesktop ? 20 : (isTablet ? 18 : 16),
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildShareOption(
                      Icons.whatshot,  // More distinctive WhatsApp icon
                      "WhatsApp",
                      const Color(0xff25D366),
                      () => _shareViaWhatsApp(),
                    ),
                    _buildShareOption(
                      Icons.facebook,  // Standard Facebook icon
                      "Facebook",
                      const Color(0xff1877F2),
                      () => _shareViaFacebook(),
                    ),
                    _buildShareOption(
                      Icons.telegram,  // Standard Telegram icon
                      "Telegram",
                      const Color(0xff0088CC),
                      () => _shareViaTelegram(),
                    ),
                    _buildShareOption(
                      Icons.alternate_email,  // More professional email icon
                      "Email",
                      const Color(0xffEA4335),
                      () => _shareViaEmail(),
                    ),
                    _buildShareOption(
                      Icons.message,  // Clean SMS icon
                      "SMS",
                      const Color(0xff34A853),
                      () => _shareViaSMS(),
                    ),
                    _buildShareOption(
                      Icons.qr_code_scanner,  // More modern QR icon
                      "QR Code",
                      const Color(0xff667eea),
                      () => _generateQRCode(),
                    ),
                    _buildShareOption(
                      Icons.print,  // Standard print icon
                      "Print",
                      const Color(0xff9E9E9E),
                      () => _printShopProfile(),
                    ),
                    _buildShareOption(
                      Icons.file_download,  // Clean download icon
                      "Download",
                      const Color(0xff795548),
                      () => _downloadProfile(),
                    ),
                    if (crossAxisCount > 3 || !isDesktop)  // Show more only if not desktop or if there's space
                      _buildShareOption(
                        Icons.more_horiz,
                        "More",
                        const Color(0xff757575),
                        () => _showMoreShareOptions(),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: verticalSpacing + 10),

            // Generate Share Card Button
            GestureDetector(
              onTap: () => _generateShareCard(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 20 : (isTablet ? 18 : 16),
                  horizontal: isDesktop ? 24 : (isTablet ? 20 : 16),
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff667eea), Color(0xff764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff667eea).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: isDesktop ? 24 : (isTablet ? 22 : 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Generate Share Card",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 18 : (isTablet ? 17 : 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: verticalSpacing),

            // Quick Share Templates
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 22 : 20)),
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
                      Icon(
                        Icons.article_outlined,
                        color: const Color(0xff667eea),
                        size: isDesktop ? 24 : (isTablet ? 22 : 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Quick Share Templates",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 20 : 16),
                  _buildTemplateOption(
                    "Social Media Post",
                    "Ready-to-post content for Facebook, Instagram",
                    Icons.campaign_outlined,
                  ),
                  SizedBox(height: isDesktop ? 16 : 12),
                  _buildTemplateOption(
                    "WhatsApp Status",
                    "Perfect for WhatsApp status updates",
                    Icons.message_outlined,
                  ),
                  SizedBox(height: isDesktop ? 16 : 12),
                  _buildTemplateOption(
                    "Business Card",
                    "Digital business card with contact details",
                    Icons.badge_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for share options
  Widget _buildShareOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final isDesktop = screenWidth > 900;
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clean icon without extra container
                Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isDesktop ? 32 : (isTablet ? 28 : 26),
                  ),
                ),
                SizedBox(height: isDesktop ? 12 : (isTablet ? 10 : 8)),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper widget for template options
  Widget _buildTemplateOption(String title, String description, IconData icon) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final isDesktop = screenWidth > 900;
        
        return GestureDetector(
          onTap: () => _selectTemplate(title),
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 14)),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 12 : (isTablet ? 10 : 8)),
                  decoration: BoxDecoration(
                    color: const Color(0xff667eea).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xff667eea),
                    size: isDesktop ? 24 : (isTablet ? 22 : 20),
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 6 : 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isDesktop ? 8 : 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: isDesktop ? 16 : (isTablet ? 14 : 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Share methods implementation
  void _copyShopLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text("Shop link copied to clipboard!"),
          ],
        ),
        backgroundColor: Color(0xff38A169),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareViaWhatsApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening WhatsApp..."),
        backgroundColor: Color(0xff25D366),
      ),
    );
  }

  void _shareViaFacebook() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening Facebook..."),
        backgroundColor: Color(0xff1877F2),
      ),
    );
  }

  void _shareViaTelegram() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening Telegram..."),
        backgroundColor: Color(0xff0088CC),
      ),
    );
  }

  void _shareViaEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening email client..."),
        backgroundColor: Color(0xffEA4335),
      ),
    );
  }

  void _shareViaSMS() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening SMS..."),
        backgroundColor: Color(0xff34A853),
      ),
    );
  }

  void _generateQRCode() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final qrSize = isTablet ? 250.0 : 200.0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "QR Code Generated",
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: qrSize,
              height: qrSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_scanner,
                  size: qrSize * 0.75,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Scan this QR code to visit Urban Drift",
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("QR Code saved to gallery!"),
                  backgroundColor: Color(0xff38A169),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff667eea),
            ),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _printShopProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Preparing shop profile for printing..."),
        backgroundColor: Color(0xff9E9E9E),
      ),
    );
  }

  void _downloadProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Downloading profile as PDF..."),
        backgroundColor: Color(0xff795548),
      ),
    );
  }

  void _showMoreShareOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "More Share Options",
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.link,
                color: const Color(0xff667eea),
                size: isTablet ? 26 : 24,
              ),
              title: Text(
                "Copy Link",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyShopLink();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.file_download,
                color: const Color(0xff667eea),
                size: isTablet ? 26 : 24,
              ),
              title: Text(
                "Download Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _downloadProfile();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.nfc,
                color: const Color(0xff667eea),
                size: isTablet ? 26 : 24,
              ),
              title: Text(
                "Share via NFC",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("NFC sharing activated..."),
                    backgroundColor: Color(0xff667eea),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _generateShareCard() {
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
              "Generating Share Card...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Share card generated and ready to share!"),
          backgroundColor: Color(0xff38A169),
        ),
      );
    });
  }

  void _selectTemplate(String templateName) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          templateName,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Preview of $templateName:",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isTablet ? 16 : 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "🏪 Visit Urban Drift - Your Premium Grocery Store!\n\n✅ 1,245+ Products\n⭐ 4.8/5 Rating\n🚚 Free Delivery on orders above ৳500\n\nhttps://virtualshop.com/urbandrift",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 14 : 12,
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
                SnackBar(
                  content: Text("$templateName copied to clipboard!"),
                  backgroundColor: const Color(0xff38A169),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff667eea),
            ),
            child: const Text("Copy", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
