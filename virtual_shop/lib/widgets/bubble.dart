import 'dart:io';
import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import '../models/message.dart';
import 'glass_container.dart';

/// A widget to display a single chat message bubble.
class Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool
  captionStyle; // If true, render a lighter caption style (for model text responses)

  const Bubble({super.key, required this.message, this.captionStyle = false});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.author == Role.user;

    final baseRadius = 22.0;
    final bubbleColor = isUser
        ? Colors.blueAccent.withOpacity(0.35)
        : (captionStyle
              ? Colors.white.withOpacity(0.18)
              : Colors.purpleAccent.withOpacity(0.18));

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: captionStyle ? 14 : 16,
      fontWeight: captionStyle ? FontWeight.w500 : FontWeight.w400,
      height: 1.3,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: captionStyle ? 16 : 18,
              backgroundColor: Colors.deepPurple.withOpacity(0.25),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.purpleAccent.shade100,
                size: captionStyle ? 16 : 20,
              ),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: GlassContainer(
              borderRadius: baseRadius,
              color: bubbleColor,
              settings: const OCLiquidGlassSettings(
                blurRadiusPx: 12,
                lightbandColor: Colors.white24,
                specAngle: 65,
                specStrength: 0.35,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: captionStyle ? 8 : 12,
                  horizontal: captionStyle ? 12 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.image != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.file(
                          File(message.image!.path),
                          fit: BoxFit.cover,
                          width: 220,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                    ],
                    Text(message.text.trim(), style: textStyle),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8.0),
            CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.35),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
