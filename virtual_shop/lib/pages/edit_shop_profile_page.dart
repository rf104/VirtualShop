import 'package:flutter/material.dart';

class EditShopProfilePage extends StatefulWidget {
  const EditShopProfilePage({super.key});

  @override
  State<EditShopProfilePage> createState() => _EditShopProfilePageState();
}

class _EditShopProfilePageState extends State<EditShopProfilePage> {
  final TextEditingController shopNameController = TextEditingController(
    text: "Urban Drift",
  );
  final TextEditingController categoryController = TextEditingController(
    text: "Grocery & Daily Essentials",
  );
  final TextEditingController phoneController = TextEditingController(
    text: "+880 1700-123456",
  );
  final TextEditingController emailController = TextEditingController(
    text: "contact@urbanDrift.com",
  );
  final TextEditingController addressController = TextEditingController(
    text: "123 Commerce Street, Dhaka 1205",
  );
  final TextEditingController websiteController = TextEditingController(
    text: "www.urbandrift.com",
  );
  final TextEditingController descriptionController = TextEditingController(
    text: "Premium Grocery Store",
  );

  @override
  void dispose() {
    shopNameController.dispose();
    categoryController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    websiteController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 768;
    final isMobile = screenSize.width < 600;

    // Responsive padding
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 32.0 : 24.0);
    final verticalPadding = isMobile ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Edit Shop Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff667eea),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "EDIT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
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
        child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfilePhotoSection(),
        const SizedBox(height: 20),
        _buildBasicInformationSection(),
        const SizedBox(height: 20),
        _buildContactInformationSection(),
        const SizedBox(height: 20),
        _buildBusinessHoursSection(),
        const SizedBox(height: 20),
        _buildActionButtons(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        // Profile section full width on top
        _buildProfilePhotoSection(),
        const SizedBox(height: 24),

        // Two column layout for forms
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: [
                  _buildBasicInformationSection(),
                  const SizedBox(height: 24),
                  _buildBusinessHoursSection(),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Right column
            Expanded(
              child: Column(
                children: [
                  _buildContactInformationSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfilePhotoSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final avatarRadius = isMobile ? 50.0 : 60.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
              Icon(Icons.camera_alt, color: Color(0xff667eea), size: 20),
              SizedBox(width: 8),
              Text(
                "Shop Logo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xff667eea), Color(0xff764ba2)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: const AssetImage(
                          "assets/images/shopLogo.png",
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _changeShopLogo(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xff667eea),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _changeShopLogo(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xff667eea)),
                    ),
                    child: const Text(
                      "Change Logo",
                      style: TextStyle(
                        color: Color(0xff667eea),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
              Icon(Icons.store, color: Color(0xff667eea), size: 20),
              SizedBox(width: 8),
              Text(
                "Basic Information",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildEditField("Shop Name", shopNameController, Icons.store),
          SizedBox(height: isMobile ? 12 : 16),
          _buildEditField(
            "Description",
            descriptionController,
            Icons.description,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildEditField("Category", categoryController, Icons.category),
        ],
      ),
    );
  }

  Widget _buildContactInformationSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
              Icon(Icons.contact_phone, color: Color(0xff667eea), size: 20),
              SizedBox(width: 8),
              Text(
                "Contact Information",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildEditField("Phone Number", phoneController, Icons.phone),
          SizedBox(height: isMobile ? 12 : 16),
          _buildEditField("Email Address", emailController, Icons.email),
          SizedBox(height: isMobile ? 12 : 16),
          _buildEditField(
            "Address",
            addressController,
            Icons.location_on,
            maxLines: 2,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildEditField("Website", websiteController, Icons.language),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
              Icon(Icons.access_time, color: Color(0xff667eea), size: 20),
              SizedBox(width: 8),
              Text(
                "Business Hours",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildBusinessHourEditor("Monday - Friday", "9:00 AM", "10:00 PM"),
          _buildBusinessHourEditor("Saturday", "9:00 AM", "11:00 PM"),
          _buildBusinessHourEditor("Sunday", "10:00 AM", "9:00 PM"),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 14 : 16,
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
            onTap: () => _saveShopProfile(),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 14 : 16),
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
                  const Icon(Icons.save, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Save Changes",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for edit fields
  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xff667eea), size: 20),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xff667eea), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 10 : 12,
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for business hours editor
  Widget _buildBusinessHourEditor(
    String day,
    String openTime,
    String closeTime,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTimeSelector(openTime)),
                    const SizedBox(width: 8),
                    const Text("-", style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTimeSelector(closeTime)),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(flex: 2, child: _buildTimeSelector(openTime)),
                const SizedBox(width: 8),
                const Text("-", style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _buildTimeSelector(closeTime)),
              ],
            ),
    );
  }

  Widget _buildTimeSelector(String time) {
    return GestureDetector(
      onTap: () => _selectTime(time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, color: Color(0xff667eea), size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                time,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Time picker helper
  void _selectTime(String currentTime) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xff667eea),
              surface: Colors.grey,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  // Change shop logo functionality
  void _changeShopLogo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Change Shop Logo",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xff667eea),
              ),
              title: const Text(
                "Choose from Gallery",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xff667eea)),
              title: const Text(
                "Take Photo",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _takePhotoWithCamera();
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

  // Image picker methods
  void _pickImageFromGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening gallery..."),
        backgroundColor: Color(0xff667eea),
      ),
    );
  }

  void _takePhotoWithCamera() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening camera..."),
        backgroundColor: Color(0xff667eea),
      ),
    );
  }

  // Save shop profile changes
  void _saveShopProfile() {
    // Show saving dialog
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
            Text("Saving Changes...", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    // Simulate saving
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close saving dialog
      Navigator.pop(context); // Go back to profile page

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Shop profile updated successfully!"),
            ],
          ),
          backgroundColor: Color(0xff38A169),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}
