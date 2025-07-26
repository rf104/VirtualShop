import 'package:flutter/material.dart';

class TermsConditionsDialog extends StatelessWidget {
  const TermsConditionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2C2E),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF6D9379),
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE5E5E5)),
            const SizedBox(height: 10),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader('Virtual Shop - Terms and Conditions'),
                    _buildSubHeader('Effective Date: January 1, 2025'),
                    _buildSubHeader('Last Updated: January 1, 2025'),
                    
                    const SizedBox(height: 16),
                    _buildParagraph(
                      'Welcome to Virtual Shop. These Terms and Conditions govern your access to and use of our mobile application.'
                    ),
                    _buildParagraph(
                      'By accessing or using the Platform, you agree to be bound by these Terms. If you do not agree to all of these Terms, you must not use our services.'
                    ),
                    
                    _buildSectionTitle('1. User Eligibility'),
                    _buildParagraph('To use our Platform, you must:'),
                    _buildBulletPoint('Be at least 13 years old (or the minimum legal age in your country)'),
                    _buildBulletPoint('Provide accurate, complete registration information'),
                    _buildBulletPoint('Be responsible for all activity under your account'),
                    _buildParagraph('You are solely responsible for maintaining the confidentiality of your login credentials.'),
                    
                    _buildSectionTitle('2. User Conduct'),
                    _buildParagraph('By using our Platform, you agree not to:'),
                    _buildBulletPoint('Violate any laws or regulations'),
                    _buildBulletPoint('Upload or share unlawful, harmful, or misleading content'),
                    _buildBulletPoint('Infringe upon the intellectual property rights of others'),
                    _buildBulletPoint('Use the platform to harm, abuse, harass, stalk, or threaten others'),
                    _buildBulletPoint('Attempt to disrupt or compromise the security or integrity of our systems'),
                    _buildParagraph('We reserve the right to suspend or terminate accounts that violate these rules.'),
                    
                    _buildSectionTitle('3. Use of Services'),
                    _buildParagraph('You may use the Platform for personal, non-commercial purposes, including:'),
                    _buildBulletPoint('Browsing and purchasing products'),
                    _buildBulletPoint('Using virtual or AI-based features'),
                    _buildBulletPoint('Submitting reviews and feedback'),
                    _buildBulletPoint('Participating in promotions or referral programs'),
                    _buildParagraph('We may update or remove features at any time without prior notice.'),
                    
                    _buildSectionTitle('4. Orders, Payments & Refunds'),
                    _buildBulletPoint('All purchases made through the Platform are subject to product availability and payment confirmation'),
                    _buildBulletPoint('We use secure third-party payment gateways to process transactions'),
                    _buildBulletPoint('Refund and return policies are governed by our Refund Policy, available on the Platform'),
                    _buildParagraph('We are not responsible for payment errors caused by third-party providers.'),
                    
                    _buildSectionTitle('5. Intellectual Property'),
                    _buildParagraph(
                      'All content on the Platform, including but not limited to logos, product images, software, designs, and texts, are owned by us or licensed to us. You may not:'
                    ),
                    _buildBulletPoint('Copy, reproduce, distribute, or modify any part of the Platform without permission'),
                    _buildBulletPoint('Use our trademarks or branding without written consent'),
                    
                    _buildSectionTitle('6. Privacy'),
                    _buildParagraph(
                      'We value your privacy. Our use of your personal data is governed by our Privacy Policy, which explains how we collect, use, and protect your data. By using our Platform, you consent to these practices.'
                    ),
                    
                    _buildSectionTitle('7. Limitation of Liability'),
                    _buildParagraph('To the maximum extent permitted by law, we are not liable for:'),
                    _buildBulletPoint('Any indirect, incidental, or consequential damages'),
                    _buildBulletPoint('Losses resulting from unauthorized access, interruptions, or bugs'),
                    _buildParagraph('Our total liability in any matter related to the Platform shall not exceed the amount you paid us in the previous 6 months (if any).'),
                    
                    _buildSectionTitle('8. Changes to Terms'),
                    _buildParagraph(
                      'We may revise these Terms at any time. When we do, we\'ll update the "Last Updated" date. Continued use of the Platform after changes constitutes your acceptance of the revised Terms.'
                    ),
                    
                    _buildSectionTitle('9. Governing Law'),
                    _buildParagraph(
                      'These Terms are governed by and construed in accordance with the laws of Bangladesh. Any disputes will be resolved in the courts of Bangladesh.'
                    ),
                    
                    _buildSectionTitle('10. Contact Us'),
                    _buildParagraph('For questions, feedback, or support, contact us at:'),
                    _buildContactInfo('📧 Email: support@virtualshop.com'),
                    _buildContactInfo('📍 Address: Dhaka, Bangladesh'),
                    _buildContactInfo('📞 Phone: +8801234567890'),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Accept Button
            Container(
              width: double.infinity,
              height: 48,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF6D9379),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I Understand and Agree',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2C2C2E),
        ),
      ),
    );
  }
  
  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C2C2E),
        ),
      ),
    );
  }
  
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Color(0xFF2C2C2E),
        ),
      ),
    );
  }
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6D9379),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF2C2C2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactInfo(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6D9379),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}