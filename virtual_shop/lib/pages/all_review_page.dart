import 'package:flutter/material.dart';

class AllReviewPage extends StatelessWidget {
  const AllReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          "All Reviews",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xffFFD700),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "4.8",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 15, // Mock data
        itemBuilder: (context, index) {
          final review = _getReviewData(index);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => _showReviewDetails(context, review),
              child: _buildReviewItem(review, showArrow: true),
            ),
          );
        },
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
                              _getRatingColor(review['rating']),
                              _getRatingColor(
                                review['rating'],
                              ).withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _getRatingColor(
                                review['rating'],
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
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                  review['avatar'] ?? '',
                                ),
                                onBackgroundImageError:
                                    (exception, stackTrace) {
                                      // Handle image loading error
                                    },
                                child: review['avatar'] == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 30,
                                      )
                                    : null,
                              ),
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
                                    "Reviewed on ${review['date'] ?? 'Unknown date'}",
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
                              review['review'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            if (review['pros'] != null ||
                                review['cons'] != null) ...[
                              const SizedBox(height: 20),
                              if (review['pros'] != null) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xff38A169),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.thumb_up,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "What they liked:",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  review['pros'],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (review['cons'] != null) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.thumb_down,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Areas for improvement:",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  review['cons'],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
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
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        review['product']['image'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review['product']['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Category: ${review['product']['category']}",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "৳${review['product']['price']}",
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

                      // Customer Insights
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
                                  Icons.insights,
                                  color: Color(0xff4facfe),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Customer Insights",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInsightRow(
                              "Total Reviews",
                              "${review['totalReviews'] ?? 5}",
                            ),
                            _buildInsightRow(
                              "Average Rating",
                              "${review['avgRating'] ?? 4.2}/5",
                            ),
                            _buildInsightRow(
                              "Customer Since",
                              review['customerSince'] ?? "Jan 2023",
                            ),
                            _buildInsightRow(
                              "Order History",
                              "${review['orderCount'] ?? 12} orders",
                            ),
                            _buildInsightRow(
                              "Response Rate",
                              "${review['responseRate'] ?? 95}%",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

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

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  // Helper method to provide enhanced review data
  Map<String, dynamic> _getReviewData(int index) {
    final reviewers = [
      {
        'name': 'Ibnu Rahman',
        'avatar': 'https://randomuser.me/api/portraits/men/2.jpg',
        'rating': 5,
        'date': 'March 21, 2024',
        'review':
            'Great product quality and fast delivery! The wireless headphones exceeded my expectations. Sound quality is crystal clear and battery life is amazing.',
        'verified': true,
        'pros':
            'Excellent sound quality, comfortable fit, long battery life, fast shipping',
        'cons': null,
        'totalReviews': 12,
        'avgRating': 4.6,
        'customerSince': 'Jan 2023',
        'orderCount': 8,
        'responseRate': 98,
        'email': 'ibnu.rahman@email.com',
        'phone': '+880 1700000001',
        'product': {
          'name': 'Premium Wireless Headphones',
          'category': 'Electronics',
          'price': '4,500',
          'image':
              'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=100&h=100&fit=crop',
        },
      },
      {
        'name': 'Sarah Ahmed',
        'avatar': 'https://randomuser.me/api/portraits/women/3.jpg',
        'rating': 4,
        'date': 'March 20, 2024',
        'review':
            'Good service overall, but packaging could be improved. The product arrived safely but the box was a bit damaged.',
        'verified': true,
        'pros': 'Good product quality, reasonable price',
        'cons':
            'Packaging needs improvement, delivery was slower than expected',
        'totalReviews': 5,
        'avgRating': 4.2,
        'customerSince': 'Mar 2023',
        'orderCount': 3,
        'responseRate': 85,
        'email': 'sarah.ahmed@email.com',
        'phone': '+880 1700000002',
        'product': {
          'name': 'Smartphone Protective Case',
          'category': 'Accessories',
          'price': '850',
          'image':
              'https://images.unsplash.com/photo-1556656793-08538906a9f8?w=100&h=100&fit=crop',
        },
      },
      {
        'name': 'John Doe',
        'avatar': 'https://randomuser.me/api/portraits/men/4.jpg',
        'rating': 5,
        'date': 'March 19, 2024',
        'review':
            'Amazing experience! Will definitely order again. The customer service was outstanding and the product quality is top-notch.',
        'verified': true,
        'pros':
            'Excellent customer service, high quality product, fast response time',
        'cons': null,
        'totalReviews': 18,
        'avgRating': 4.8,
        'customerSince': 'Sep 2022',
        'orderCount': 15,
        'responseRate': 95,
        'email': 'john.doe@email.com',
        'phone': '+880 1700000003',
        'product': {
          'name': 'Bluetooth Wireless Speaker',
          'category': 'Electronics',
          'price': '2,800',
          'image':
              'https://images.unsplash.com/photo-1608043152269-4236a9f8?w=100&h=100&fit=crop',
        },
      },
      {
        'name': 'Alice Smith',
        'avatar': 'https://randomuser.me/api/portraits/women/5.jpg',
        'rating': 3,
        'date': 'March 18, 2024',
        'review':
            'Product is okay, delivery was a bit slow. Expected better quality for the price point.',
        'verified': false,
        'pros': 'Decent functionality',
        'cons': 'Slow delivery, quality could be better for the price',
        'totalReviews': 2,
        'avgRating': 3.5,
        'customerSince': 'Feb 2024',
        'orderCount': 2,
        'responseRate': 70,
        'email': 'alice.smith@email.com',
        'phone': '+880 1700000004',
        'product': {
          'name': 'Fitness Tracker Watch',
          'category': 'Wearables',
          'price': '3,200',
          'image':
              'https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?w=100&h=100&fit=crop',
        },
      },
    ];
    return reviewers[index % reviewers.length];
  }
}
