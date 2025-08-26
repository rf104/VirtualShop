import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as legacy_gai;
import 'package:gemini_live/gemini_live.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;
  // Backward compatibility (kept but unused after migration)
  late final legacy_gai.GenerativeModel _legacyModel;
  late final legacy_gai.ChatSession _legacyChat;

  // Live API
  LiveSession? _liveSession;
  late final GoogleGenAI _genAI;
  bool _connected = false;
  bool _micOn = false; // default muted

  // STT and TTS
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttAvailable = false;
  // track speaking state via TTS handlers only

  // API key from .env (GEMINI_API_KEY)
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    // Keep legacy for fallback, but focus is gemini_live
    _legacyModel = legacy_gai.GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: _apiKey,
    );
    _legacyChat = _legacyModel.startChat();
    if (_apiKey.isEmpty) {
      // Surface a visible warning
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing GEMINI_API_KEY in .env')),
        );
      });
    }
    _genAI = GoogleGenAI(apiKey: _apiKey);
    _initSpeechTts();
    _connectLive();
  }

  @override
  void dispose() {
    _liveSession?.close();
    _speech.stop();
    _tts.stop();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initSpeechTts() async {
    // TTS basic setup
    await _tts.setSpeechRate(0.95);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // Handlers not needed for now

    // STT availability check
    _sttAvailable = await _speech.initialize(onStatus: (s) {}, onError: (e) {});
    setState(() {});
  }

  Future<void> _connectLive() async {
    setState(() => _connected = false);
    try {
      final session = await _genAI.live.connect(
        LiveConnectParameters(
          model: 'gemini-2.0-flash-live-001',
          callbacks: LiveCallbacks(
            onOpen: () => setState(() => _connected = true),
            onMessage: (msg) {
              final textChunk = msg.text;
              if (textChunk != null && textChunk.isNotEmpty) {
                // Stream the caption
                if (_chatHistory.isEmpty ||
                    _chatHistory.last['role'] != 'model_stream') {
                  setState(() {
                    _chatHistory.add({
                      'role': 'model_stream',
                      'text': textChunk,
                    });
                  });
                } else {
                  setState(() {
                    _chatHistory.last.update('text', (v) => v + textChunk);
                  });
                }
              }
              if (msg.serverContent?.turnComplete ?? false) {
                // finalize stream bubble to model
                if (_chatHistory.isNotEmpty &&
                    _chatHistory.last['role'] == 'model_stream') {
                  setState(() {
                    final t = _chatHistory.removeLast()['text'] ?? '';
                    _chatHistory.add({'role': 'model', 'text': t});
                  });
                  // Speak out the final response
                  final t = _chatHistory.last['text'] ?? '';
                  _speak(t);
                }
                setState(() => _isLoading = false);
              }
            },
            onError: (e, s) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Live error: $e')));
            },
            onClose: (code, reason) {
              setState(() => _connected = false);
            },
          ),
          config: GenerationConfig(responseModalities: [Modality.TEXT]),
          systemInstruction: Content(
            parts: [
              Part(
                text:
                    'You are a persuasive, friendly sales assistant for an online fashion store. Answer concisely, highlight benefits, suggest matching items, and be helpful.',
              ),
            ],
          ),
        ),
      );
      setState(() => _liveSession = session);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect live session: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _chatHistory.add({'role': 'user', 'text': _textController.text});
    });

    try {
      if (_liveSession != null && _connected) {
        _liveSession!.sendMessage(
          LiveClientMessage(
            clientContent: LiveClientContent(
              turns: [
                Content(
                  role: 'user',
                  parts: [Part(text: _textController.text)],
                ),
              ],
              turnComplete: true,
            ),
          ),
        );
      } else {
        // Fallback to legacy text-only model if live not connected
        final response = await _legacyChat.sendMessage(
          legacy_gai.Content.text(_textController.text),
        );
        final text = response.text;
        if (text != null) {
          setState(() {
            _chatHistory.add({'role': 'model', 'text': text});
          });
          await _speak(text);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
      _textController.clear();
    }
  }

  Future<void> _toggleMic() async {
    if (!_micOn) {
      final granted = await Permission.microphone.request().isGranted;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );
        return;
      }
      if (!_sttAvailable) {
        _sttAvailable = await _speech.initialize();
      }
      if (_sttAvailable) {
        setState(() => _micOn = true);
        _speech.listen(
          onResult: (res) {
            // live caption of user speech in input field
            _textController.text = res.recognizedWords;
          },
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
        );
      }
    } else {
      setState(() => _micOn = false);
      await _speech.stop();
      // Auto-send when user stops talking and there is content
      if (_textController.text.trim().isNotEmpty) {
        await _sendMessage();
      }
    }
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    // Stop any current speaking
    try {
      await _tts.stop();
    } catch (_) {}
    await _tts.speak(text);
  }

  // Reusable input row
  Widget _buildInputRow() {
    return Row(
      children: [
        IconButton(
          tooltip: _micOn ? 'Stop microphone' : 'Start microphone',
          icon: Icon(
            _micOn ? Icons.mic : Icons.mic_off,
            color: _micOn ? Colors.redAccent : Colors.white70,
          ),
          onPressed: _toggleMic,
        ),
        Expanded(
          child: TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ask me anything...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) => _sendMessage(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.white),
          onPressed: _sendMessage,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Sales Assistant',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _chatHistory.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/images/animation.json',
                        width: 200,
                        height: 200,
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: CircularProgressIndicator(),
                        ),
                      const SizedBox(height: 16),
                      _buildInputRow(),
                    ],
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _chatHistory.length,
                    itemBuilder: (context, index) {
                      final message = _chatHistory[index];
                      final role = message['role'];
                      final isUser = role == 'user';
                      final isStream = role == 'model_stream';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 15,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blue[800]
                                : (isStream
                                      ? Colors.green[800]
                                      : Colors.grey[800]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message['text']!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _buildInputRow(),
                  ),
                ),
              ],
            ),
    );
  }
}
