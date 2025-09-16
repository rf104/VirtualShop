import 'package:image_picker/image_picker.dart';

/// Enum to define the role of the message sender.
enum Role { user, model }

/// Data class for a chat message.
class ChatMessage {
  final String text;
  final Role author;
  final XFile? image; // Optional image file attached to the message.

  ChatMessage({required this.text, required this.author, this.image});
}
