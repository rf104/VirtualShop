import 'dart:ui';

import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.person_add,
      'title': 'New Follower',
      'message': 'John Doe started following you.',
      'time': '5m ago',
      'iconColor': Colors.blue,
    },
    {
      'icon': Icons.favorite,
      'title': 'New Like',
      'message': 'Your post received a like.',
      'time': '3h ago',
      'iconColor': Colors.red,
    },
    {
      'icon': Icons.favorite,
      'title': 'New Like',
      'message': 'Your post received a like.',
      'time': '4h ago',
      'iconColor': Colors.red,
    },
    {
      'icon': Icons.person_add,
      'title': 'New Follower',
      'message': 'John Doe started following you.',
      'time': '5m ago',
      'iconColor': Colors.blue,
    },
    {
      'icon': Icons.favorite,
      'title': 'New Like',
      'message': 'Your post received a like.',
      'time': '13h ago',
      'iconColor': Colors.red,
    },
    {
      'icon': Icons.person_add,
      'title': 'New Follower',
      'message': 'John Doe started following you.',
      'time': '5m ago',
      'iconColor': Colors.blue,
    },
    {
      'icon': Icons.favorite,
      'title': 'New Like',
      'message': 'Your post received a like.',
      'time': '1d ago',
      'iconColor': Colors.red,
    },
  ];

  void _clearNotifications() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _clearNotifications,
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                'No new notifications',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return NotificationItem(
                  icon: notification['icon'],
                  title: notification['title'],
                  message: notification['message'],
                  time: notification['time'],
                  iconColor: notification['iconColor'],
                );
              },
            ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color iconColor;

  const NotificationItem({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor,
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        message,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
