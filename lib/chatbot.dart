import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_pdf_chat/pdf_gemini.dart';
import 'dart:io';
import 'package:smart_pdf_chat/src/genai_generated_response_model.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:smart_pdf_chat/voice/voice_chat.dart' as voice;

import 'history/chat_his_repo.dart';
import 'history/chat_his_screen.dart';
class PdfChatScreen extends StatefulWidget {
  const PdfChatScreen({super.key});

  @override
  State<PdfChatScreen> createState() => _PdfChatScreenState();
}

class _PdfChatScreenState extends State<PdfChatScreen>
    with TickerProviderStateMixin {
  final String _geminiApiKey = 'A';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;
  bool _isTyping = false;
  String _statusMessage = 'Upload a PDF to start chatting';
  String _fileContext = '';
  List<ChatMessage> _messages = [];

  // Chat history repository
  final ChatHistoryRepository _historyRepository = ChatHistoryRepository();
  int? _currentSessionId;
  bool _isRestoredSession = false;

  // Animation controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _messageInputAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _messageInputAnimation;

  // Theme colors
  final List<Color> _gradientColors = [const Color(0xFF4776E6), const Color(0xFF8E54E9)];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _messageInputAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    _messageInputAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _messageInputAnimationController, curve: Curves.easeOutCubic),
    );

    // Show upload FAB with animation
    _fabAnimationController.forward();

    // Add welcome message
    _addWelcomeMessage();

    // Add listener to message controller to update UI when text changes
    _messageController.addListener(_onTextChanged);
  }

  // Add this method to handle text changes
  void _onTextChanged() {
    setState(() {
      // This will force a rebuild of the widget, updating the send button state
    });
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text:
      "# Welcome to PDF Chat Assistant! 👋\n\nI'm here to help you interact with your PDFs and provide insights. Upload a document to get started, or let me know how I can assist you today.",
      isUser: false,
      timestamp: DateTime.now(),
      isIntro: true,
    ));
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _fabAnimationController.dispose();
    _messageInputAnimationController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Selecting file...';
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No file selected';
        });
        return;
      }

      PlatformFile platformFile = result.files.first;
      setState(() {
        _selectedFile = File(platformFile.path!);
        _fileName = platformFile.name;
        _statusMessage = 'Processing ${platformFile.name}...';
      });

      await _processFile();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
      _showErrorSnackBar('Failed to select file: ${e.toString()}');
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) return;

    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Processing PDF file...';
      });

      // Check if we need to create a new session or use the restored one
      if (!_isRestoredSession) {
        // Create a new chat session in the database
        _currentSessionId = await _historyRepository.createSession(
          _fileName!,
          _selectedFile!.path,
          DateTime.now(),
        );
      }

      final genaiClient = GenaiClient(geminiApiKey: _geminiApiKey);

      // First extract the document content
      GenaiGeneratedResponseModel response = await genaiClient.promptDocument(
        _fileName!,
        'pdf',
        await _selectedFile!.readAsBytes(),
        "Extract and summarize the key content from this document that will be used as context for future questions. Include all important details, figures, and relationships between concepts.",
      );

      setState(() {
        _fileContext = response.text;
        _statusMessage = 'PDF processed successfully';
      });

      // Initialize chat if this is not a restored session
      if (!_isRestoredSession) {
        _initializeChat();
      }

      // Show the message input with animation once file is processed
      _messageInputAnimationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error processing file';
      });
      _showErrorSnackBar('Failed to process PDF: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeChat() {
    final introMessage = "# Document Loaded Successfully! 📄\n\nI've processed your document '${_fileName!}'. You can now ask me any questions about its content. How can I help you understand this document better?";

    setState(() {
      _messages.add(ChatMessage(
        text: introMessage,
        isUser: false,
        timestamp: DateTime.now(),
        isIntro: true,
      ));
    });

    // Save the intro message to history
    if (_currentSessionId != null) {
      _historyRepository.addMessage(
        _currentSessionId!,
        introMessage,
        false, // isUser
        DateTime.now(),
        true, // isIntro
      );
    }

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
        isIntro: false,
      ));
      _messageController.clear();
      _scrollToBottom();
      _isTyping = true; // Show typing indicator
    });

    // Save the user message to history
    if (_currentSessionId != null) {
      await _historyRepository.addMessage(
        _currentSessionId!,
        userMessage,
        true, // isUser
        DateTime.now(),
        false, // isIntro
      );
    }

    // If no PDF is loaded, provide a general response
    if (_fileContext.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      final response = _generateGeneralResponse(userMessage);

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          isIntro: false,
        ));
        _scrollToBottom();
      });

      // Save the AI response to history
      if (_currentSessionId != null) {
        await _historyRepository.addMessage(
          _currentSessionId!,
          response,
          false, // isUser
          DateTime.now(),
          false, // isIntro
        );
      }

      return;
    }

    try {
      final genaiClient = GenaiClient(geminiApiKey: _geminiApiKey);

      // Combine the original context with the conversation history
      String conversationHistory = _messages
          .where((m) => !m.isIntro) // Skip intro messages for context
          .take(4) // Take more context for better responses
          .map((m) => "${m.isUser ? 'User' : 'Assistant'}: ${m.text}")
          .join('\n\n');

      String fullPrompt = """
      Document Context:
      $_fileContext
      
      Conversation History:
      $conversationHistory
      
      Instruction: Answer the user's question based on the document context above. 
      If the question can't be answered from the document, say so politely.
      Keep your answers concise but informative. Format your response in Markdown with headers, bold for key points, and lists when appropriate.
      User Question: $userMessage
      """;

      GenaiGeneratedResponseModel response = await genaiClient.promptDocument(
        _fileName!,
        'pdf',
        await _selectedFile!.readAsBytes(),
        fullPrompt,
      );

      // Add a small delay to make the typing indicator look more realistic
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: response.text,
          isUser: false,
          timestamp: DateTime.now(),
          isIntro: false,
        ));
        _scrollToBottom();
      });

      // Save the AI response to history
      if (_currentSessionId != null) {
        await _historyRepository.addMessage(
          _currentSessionId!,
          response.text,
          false, // isUser
          DateTime.now(),
          false, // isIntro
        );
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text:
          "Sorry, I encountered an error processing your request. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
          isIntro: false,
        ));
        _scrollToBottom();
      });
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _openChatHistory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatHistoryScreen(
          gradientColors: _gradientColors,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      // User selected a previous session
      if (result.containsKey('sessionId') &&
          result.containsKey('filePath') &&
          result.containsKey('fileName')) {
        _restoreChatSession(
          result['sessionId'] as int,
          result['filePath'] as String,
          result['fileName'] as String,
        );
      }
    }
  }

  Future<void> _restoreChatSession(int sessionId, String filePath, String fileName) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading previous session...';
    });

    try {
      // Load the file
      _selectedFile = File(filePath);
      _fileName = fileName;
      _currentSessionId = sessionId;
      _isRestoredSession = true;

      // Process the file to extract context
      await _processFile();

      // Load previous messages
      final messages = await _historyRepository.getMessagesForSession(sessionId);
      setState(() {
        _messages = messages.map((dbMessage) => ChatMessage(
          text: dbMessage.text,
          isUser: dbMessage.isUser,
          timestamp: dbMessage.timestamp,
          isIntro: dbMessage.isIntro,
        )).toList();
      });

      // Show message input if it wasn't already visible
      if (!_messageInputAnimationController.isCompleted) {
        _messageInputAnimationController.forward();
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error restoring session';
      });
      _showErrorSnackBar('Failed to restore chat session: ${e.toString()}');
    }
  }

  String _generateGeneralResponse(String text) {
    final lowercaseText = text.toLowerCase();

    // Check if user is asking about the bot's identity
    if (lowercaseText.contains('who are you') ||
        lowercaseText.contains('what are you') ||
        lowercaseText.contains('introduce yourself') ||
        lowercaseText.contains('about you')) {
      return "# About Me\n\nI am a PDF Chat Assistant designed to help you interact with and understand your PDF documents. I can analyze content, answer questions about your documents, and provide relevant information based on document context.\n\n**How can I help you today?**";
    }

    // Example responses for document-related queries
    if (lowercaseText.contains('pdf') || lowercaseText.contains('document')) {
      return "# Document Analysis\n\nTo analyze your document, please upload it using the button at the bottom of the screen. Once uploaded, I can help you extract information, summarize content, and answer specific questions about your document.";
    }

    // General response
    return "I'm here to assist with your documents. Please upload a PDF using the button at the bottom of the screen to get started, or let me know if you have any other questions.";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        final List<Color> colors = isDarkMode
            ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D), const Color(0xFF131313)]
            : [const Color(0xFFE5F2FF), const Color(0xFFF5F0FF), const Color(0xFFFFEDF5)];

        return Stack(
          children: [
            // Base background
            Container(
              color: isDarkMode ? Colors.black : Colors.white,
            ),

            // Animated shapes
            ...List.generate(15, (index) {
              final random = Random(index);
              final size = random.nextDouble() * 120 + 50;
              final color =
              colors[random.nextInt(colors.length)].withOpacity(0.3);

              // Position calculation with animation
              final startX =
                  random.nextDouble() * MediaQuery.of(context).size.width;
              final startY =
                  random.nextDouble() * MediaQuery.of(context).size.height;

              final animValue = _backgroundAnimationController.value;
              final wave = sin(animValue * 2 * pi + index) * 30;

              return Positioned(
                left: startX + wave,
                top: startY + wave,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(size / 2),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

    // Check if message can be sent
    final bool canSendMessage =
        !_isLoading && _messageController.text.trim().isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color:
              (isDarkMode ? Colors.black : Colors.white).withOpacity(0.7),
            ),
          ),
        ),
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => voice.VoiceChatBotPdf(),)),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _gradientColors[0].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: _gradientColors[0],
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PDF Chat Assistant',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(
                Icons.history,
                color: Colors.white,
              ),
            ),
            tooltip: 'Chat History',
            onPressed: _openChatHistory,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(isDarkMode),

          // Frosted glass effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: bgColor.withOpacity(isDarkMode ? 0.75 : 0.7),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Loading indicator
                if (_isLoading)
                  LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(_gradientColors[0]),
                  ),

                // Chat messages
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState(isDarkMode)
                      : ListView.builder(
                    controller: _chatScrollController,
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        // Typing indicator
                        return _buildTypingIndicator();
                      }

                      final message = _messages[index];
                      return ChatBubble(
                        message: message.text,
                        isUser: message.isUser,
                        timestamp: message.timestamp,
                        isIntro: message.isIntro,
                        gradientColors: _gradientColors,
                        isDarkMode: isDarkMode,
                      );
                    },
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey.shade900.withOpacity(0.7)
                        : Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _gradientColors[0].withOpacity(0.1),
                                  _gradientColors[1].withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _gradientColors[0].withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    focusNode: _messageFocusNode,
                                    decoration: InputDecoration(
                                      hintText: 'Ask about your document...',
                                      border: InputBorder.none,
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 0,
                                        vertical: 16,
                                      ),
                                      hintStyle: TextStyle(
                                        color: isDarkMode
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    style: TextStyle(color: textColor),
                                    maxLines: 5,
                                    minLines: 1,
                                    onSubmitted: (_) =>
                                    canSendMessage ? _sendMessage() : null,
                                    enabled: !_isLoading,
                                  ),
                                ),
                                IconButton(
                                  icon: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: _gradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed:
                                  canSendMessage ? _sendMessage : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Upload FAB with scale animation when no file is loaded
      floatingActionButton: _fileContext.isEmpty
          ? ScaleTransition(
        scale: _fabScaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _gradientColors[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _isLoading ? null : _pickFile,
            backgroundColor: Colors.transparent,
            elevation: 0,
            label: const Row(
              children: [
                Icon(Icons.upload_file_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Upload PDF', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add a simple animation container here for better UX
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _gradientColors[0].withOpacity(0.1),
                  _gradientColors[1].withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 80,
              color: _gradientColors[0],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFile == null ? 'No PDF Selected' : 'Processing Your PDF',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _isLoading
                  ? "Please wait while we analyze your document..."
                  : "Upload a PDF document to start a conversation about its contents",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            Container(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_gradientColors[0]),
                strokeWidth: 3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _gradientColors[0],
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            radius: 18,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedTextKit(
                  animatedTexts: [
                    WavyAnimatedText(
                      'Typing',
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  isRepeatingAnimation: true,
                  totalRepeatCount: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isIntro; // Flag for intro/welcome messages

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isIntro,
  });
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final bool isIntro;
  final List<Color> gradientColors;
  final bool isDarkMode;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    required this.isIntro,
    required this.gradientColors,
    required this.isDarkMode,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(timestamp);
    final maxWidth = MediaQuery.of(context).size.width;

    return Container(
        padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isUser ? 60 : 0, // No left padding for assistant messages
        right: isUser
        ? 0
        : 0, // No right padding for any messages to use full width
    ),
    child: Column(
    crossAxisAlignment:
    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment:
    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!isUser)
        CircleAvatar(
          backgroundColor: isIntro
              ? gradientColors[0].withOpacity(0.7)
              : gradientColors[0],
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          radius: 18,
        ),
      if (!isUser) const SizedBox(width: 8),

      // Message content
      Flexible(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isIntro ? 16 : 16,
            vertical: isIntro ? 16 : 12,
          ),
          decoration: BoxDecoration(
            gradient: isUser
                ? LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isUser
                ? null
                : isIntro
                ? (isDarkMode
                ? Colors.grey.shade800.withOpacity(0.7)
                : Colors.grey.shade100)
                : (isDarkMode
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade200.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(18),
            boxShadow: isUser
                ? [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // For Markdown rendering
              MarkdownBody(
                data: message,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                    fontSize: 15,
                  ),
                  h1: TextStyle(
                    color: isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  h2: TextStyle(
                    color: isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  h3: TextStyle(
                    color: isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  code: TextStyle(
                    backgroundColor: isDarkMode
                        ? Colors.grey.shade900
                        : Colors.grey.shade100,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey.shade900
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  blockquote: TextStyle(
                    color: isUser
                        ? Colors.white.withOpacity(0.9)
                        : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                    fontStyle: FontStyle.italic,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isUser
                            ? Colors.white.withOpacity(0.5)
                            : gradientColors[0].withOpacity(0.5),
                        width: 4,
                      ),
                    ),
                  ),
                  listBullet: TextStyle(
                    color: isUser ? Colors.white : gradientColors[0],
                    fontSize: 15,
                  ),
                  em: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
                  ),
                  a: TextStyle(
                    color: isUser ? Colors.white : gradientColors[0],
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTapLink: (text, href, title) {
                  // Open URL if needed
                  if (href != null) {
                    // Implement URL handling
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link functionality not implemented'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),

      if (isUser) const SizedBox(width: 8),
      if (isUser)
        CircleAvatar(
          backgroundColor: gradientColors[1],
          child: const Icon(Icons.person, color: Colors.white, size: 20),
          radius: 18,
        ),
    ],
    ),

      // Timestamp
      Padding(
        padding: EdgeInsets.only(
          top: 4,
          left: isUser ? 0 : 46,
          right: isUser ? 46 : 0,
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ),
    ],
    ),
    );
  }
  // Add this method to your ChatBubble class to enable message copying
  void _copyMessageToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message));

    // Show a snackbar confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied to clipboard'),
        backgroundColor: gradientColors[0],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }


}