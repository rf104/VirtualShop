import 'package:flutter/material.dart';
import 'dart:async';
import 'package:virtual_shop/utils/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatAssistantPage extends StatefulWidget {
  const ChatAssistantPage({super.key});

  @override
  State<ChatAssistantPage> createState() => _ChatAssistantPageState();
}

class _ChatAssistantPageState extends State<ChatAssistantPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "You can do anything with Syncra, just ask!",
      isUser: false,
    ),
  ];
  bool _isSending = false;

  String _displayName = 'User';
  String? _profileImageUrl;
  ImageProvider? _avatarProvider;

  Map<String, String>? _headersForUrl(String url) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;
    if (url.contains('supabase.co') && url.contains('/storage/v1/object/')) {
      return {'Authorization': 'Bearer ${session.accessToken}'};
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final meta = user.userMetadata ?? {};
        final dynamic avatarCandidate =
            meta['avatar_url_custom'] ?? meta['picture'] ?? meta['avatarUrl'];
        final dynamic nameCandidate =
            meta['name'] ?? meta['fullName'] ?? user.email;

        if (avatarCandidate is String && avatarCandidate.trim().isNotEmpty) {
          final url = avatarCandidate.trim();
          final provider = CachedNetworkImageProvider(
            url,
            maxHeight: 150,
            cacheKey: url,
            headers: _headersForUrl(url),
          );
          if (!mounted) return;
          setState(() {
            _profileImageUrl = url;
            _avatarProvider = provider;
          });
          unawaited(precacheImage(provider, context).catchError((_) {}));
        }

        if (!mounted) return;
        setState(() {
          _displayName =
              nameCandidate is String && nameCandidate.trim().isNotEmpty
              ? nameCandidate.trim()
              : 'User';
        });
      }
    } catch (_) {}
  }

  void _handleSendPressed() async {
    final text = _textController.text;
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(_ChatMessage(text: text, isUser: true));
        _textController.clear();
        _isSending = true;
      });
      _scrollToBottom();
      try {
        final history = _messages
            .map(
              (m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              },
            )
            .toList();
        final reply = await ApiService.assistantChat(history);
        if (!mounted) return;
        setState(() {
          _messages.add(
            _ChatMessage(text: reply.isEmpty ? '...' : reply, isUser: false),
          );
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _messages.add(
            _ChatMessage(text: 'Assistant error: $e', isUser: false),
          );
        });
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
          _scrollToBottom();
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 14, 51, 20).withOpacity(0.8),
              const Color.fromARGB(255, 46, 190, 111).withOpacity(0.9),
              Colors.black.withOpacity(1.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(child: _buildMessageList()),
              if (!_messages.any((m) => m.isUser)) ...[_buildSuggestions()],
              _buildInputBar(),
              const SizedBox(height: 85),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final ImageProvider avatar =
        _avatarProvider ??
        (_profileImageUrl != null
            ? CachedNetworkImageProvider(
                _profileImageUrl!,
                maxHeight: 150,
                cacheKey: _profileImageUrl!,
                headers: _headersForUrl(_profileImageUrl!),
              )
            : const AssetImage('assets/images/profile2.jpg'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundImage: avatar),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning,',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              Text(
                _displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSuggestionCard(
              icon: Icons.lightbulb_outline,
              text: 'Unique and Fun Birthday Surprise Ideas',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSuggestionCard(
              icon: Icons.games_outlined,
              text: 'Epic and Affordable Outfit Ideas',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSuggestionCard(
              icon: Icons.group_work_outlined,
              text: 'Best Group Gift Ideas for Your Friends',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard({required IconData icon, required String text}) {
    return GestureDetector(
      onTap: () {
        _textController.text = text;
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessage(message);
      },
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: message.isUser
            ? Text(message.text, style: const TextStyle(color: Colors.white))
            : MarkdownBody(
                data: message.text,
                selectable: false,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.white),
                  h1: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  code: const TextStyle(color: Colors.white),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: Colors.white24, width: 3),
                    ),
                  ),
                  a: const TextStyle(
                    color: Colors.lightBlueAccent,
                    decoration: TextDecoration.underline,
                  ),
                  listBullet: const TextStyle(color: Colors.white),
                ),
                onTapLink: (text, href, title) async {
                  if (href == null) return;
                  final uri = Uri.tryParse(href);
                  if (uri == null) return;
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Tap here to start work with Syncra',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (text) {
                  setState(() {});
                },
              ),
            ),
            GestureDetector(
              onTap: _isSending ? null : _handleSendPressed,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(
                    _isSending
                        ? Icons.hourglass_bottom
                        : (_textController.text.isEmpty
                              ? Icons.mic
                              : Icons.send),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
