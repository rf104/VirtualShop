import 'dart:io';

import 'package:flutter/material.dart';
import '../models/message.dart';

/// A widget to display a single chat message bubble.
class Bubble extends StatelessWidget {
  final ChatMessage message;

  const Bubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.author == Role.user;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.android, color: Colors.white),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 15.0,
              ),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[800] : Colors.grey[800],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20.0),
                  topRight: const Radius.circular(20.0),
                  bottomLeft: Radius.circular(isUser ? 20.0 : 5.0),
                  bottomRight: Radius.circular(isUser ? 5.0 : 20.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display image if attached
                  if (message.image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        File(message.image!.path),
                        fit: BoxFit.cover,
                        width: 200,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                  // Display text message
                  Text(
                    message.text,
                    style: const TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8.0),
            CircleAvatar(
              backgroundColor: Colors.blue[600],
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
