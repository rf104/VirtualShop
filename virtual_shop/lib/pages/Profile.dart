import 'package:flutter/material.dart';
import 'package:virtual_shop/pages/ChatBot.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top half image
              Container(
                height: MediaQuery.of(context).size.height * 0.5,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/profile.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              // Bottom half glassy effect
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 77, 99, 81).withOpacity(0.3),
                      const Color.fromARGB(255, 81, 71, 71).withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sajedullah Aref',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Merriweather',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 24),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Level of Customer: Gold',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Referral Points: 120',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Total Purchases: \$1500',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Referral Code: SAJED123',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      // Uploaded Pictures Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Posts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  // Example images
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/profile.jpg',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/profile.jpg',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/profile.jpg',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/profile.jpg',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/profile.jpg',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/profile.jpg',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Add more images here
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      // Reels Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reels',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  // Example reels (use images or video thumbnails)
                                  Container(
                                    width: 100,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.play_circle,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    width: 100,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.play_circle,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  // Add more reels here
                                  SizedBox(width: 8),
                                  Container(
                                    width: 100,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 122, 131, 127).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // TODO: Navigate to all uploads page
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChatBot(),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text(
                                          'See More',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  // Container(
                                  //   width: 100,
                                  //   height: 120,
                                  //   decoration: BoxDecoration(
                                  //     color: Colors.white24,
                                  //     borderRadius: BorderRadius.circular(
                                  //       12,
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      //SizedBox(height: 32),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Do something, like open Edit Profile, Share Referral, etc.
        },
        backgroundColor: const Color.fromARGB(255, 108, 205, 194),
        child: Icon(Icons.edit),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
