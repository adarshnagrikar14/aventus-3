import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Voice-related variables
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = "";
  int _pregnancyWeek = 1;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initSpeech();
    _initTts();
    _loadPregnancyWeek();

    // Add welcome message
    _addMessage(
      "Hi there! I'm your pregnancy assistant. You can type or tap the mic to ask me anything.",
      false,
    );
  }

  // Initialize speech recognition
  void _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
          if (_text.isNotEmpty) {
            _handleSubmitted(_text);
          }
        }
      },
      onError: (errorNotification) {
        print('Speech recognition error: $errorNotification');
        setState(() {
          _isListening = false;
        });
      },
    );
  }

  // Initialize text-to-speech
  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    // Example: Try to set a female voice
    // You'll need to discover available voices on your target device/platform
    // and use the correct identifier.
    try {
      // Get available voices
      List<dynamic> voices = await _flutterTts.getVoices;
      print("Available voices: $voices");

      // Attempt to find and set a female voice (example identifiers)
      // These identifiers are examples and might not work on your specific device.
      // You should inspect the `voices` list printed above to find suitable female voices.
      Map? femaleVoice;

      // Try to find a voice with "female" in its name (common but not guaranteed)
      femaleVoice = voices.firstWhere(
        (voice) =>
            voice['name'] != null &&
            voice['name'].toLowerCase().contains('female'),
        orElse: () => null,
      );

      // If not found by name, you might try by other properties if available,
      // or a known good identifier for a specific platform.
      // Example for a specific voice identifier (replace with an actual one)
      // if (femaleVoice == null) {
      //   femaleVoice = voices.firstWhere(
      //     (voice) => voice['name'] == 'en-us-x-sfg#female_1-local', // Example identifier
      //     orElse: () => null,
      //   );
      // }

      if (femaleVoice != null) {
        await _flutterTts.setVoice({
          "name": femaleVoice['name'],
          "locale": femaleVoice['locale'],
        });
        print("Selected voice: ${femaleVoice['name']}");
      } else {
        print("Female voice not found, using default.");
      }
    } catch (e) {
      print("Error setting voice: $e");
    }

    _flutterTts.setCompletionHandler(() {
      setState(() {
        // Update UI if needed when speech completes
      });
    });
  }

  // Load pregnancy week from shared preferences
  Future<void> _loadPregnancyWeek() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pregnancyWeek = prefs.getInt('pregnancyWeek') ?? 1;
    });
  }

  // Start listening to voice input
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _text = "";
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              _textController.text = _text;
            });
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }

  // Speak text aloud
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  // Clean text from markdown formatting
  String _cleanText(String text) {
    // Remove markdown ** formatting
    String cleaned = text.replaceAll(RegExp(r'\*\*'), '');
    return cleaned;
  }

  // Handle message submission
  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() {
      _isLoading = true;
    });

    // Add user message
    _addMessage(text, true);

    try {
      final response = await _sendMessageToBot(text);
      final cleanedResponse = _cleanText(response);
      _addMessage(cleanedResponse, false);
      // Speak the response
      await _speak(cleanedResponse);
    } catch (e) {
      _addMessage(
        "Sorry, I couldn't connect to the server. Please try again.",
        false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add a message to the chat
  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Send message to backend API
  Future<String> _sendMessageToBot(String text) async {
    final url = Uri.parse('http://192.168.105.156:8000/gemini_chatbot');

    try {
      // Include pregnancy week in the message
      final requestBody = {'text': 'week: $_pregnancyWeek. $text'};

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['response'];
      } else {
        throw Exception(
          'Failed to get response from bot: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to connect to the bot: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages area
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(color: Colors.grey.shade100),
                child:
                    _messages.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.pink.shade200,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ask me anything about your pregnancy!',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          itemBuilder: (context, index) => _messages[index],
                        ),
              ),
            ),

            // Loading indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.pink.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Thinking...',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // Input area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // Voice input button
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.grey.shade700,
                    ),
                    onPressed: _listen,
                  ),
                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  // Send button
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.pink.shade400),
                    onPressed: () {
                      if (_textController.text.trim().isNotEmpty) {
                        _handleSubmitted(_textController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chat message bubble
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({Key? key, required this.text, required this.isUser})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.pink.shade100,
              child: Icon(
                Icons.health_and_safety,
                color: Colors.pink.shade700,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? Colors.pink.shade400 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      style: GoogleFonts.poppins(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        final FlutterTts tts = FlutterTts();
                        tts.speak(text);
                      },
                      child: Icon(
                        Icons.volume_up,
                        size: 16,
                        color: Colors.pink.shade300,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.pink.shade300,
              child: const Icon(Icons.person, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}
