import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_pdf_chat/pdf_gemini.dart';

import '../history/chat_his_repo.dart';
import '../model/chat_text_message.dart';
import '../src/genai_generated_response_model.dart';


class PdfChatViewModel with ChangeNotifier {
  final String _geminiApiKey = '';
  final TickerProvider tickerProvider;

  final ScrollController chatScrollController = ScrollController();
  final List<Color> gradientColors = [const Color(0xFF4776E6), const Color(0xFF8E54E9)];

  late AnimationController backgroundAnimationController;
  late AnimationController fabAnimationController;
  late AnimationController messageInputAnimationController;
  late Animation<double> fabScaleAnimation;
  late Animation<double> messageInputAnimation;

  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;
  bool _isTyping = false;
  String _statusMessage = 'Upload a PDF to start chatting';
  String _fileContext = '';
  List<ChatMessage> _messages = [];
  final ChatHistoryRepository _historyRepository = ChatHistoryRepository();
  int? _currentSessionId;
  bool _isRestoredSession = false;

  File? get selectedFile => _selectedFile;
  String? get fileName => _fileName;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String get statusMessage => _statusMessage;
  String get fileContext => _fileContext;
  List<ChatMessage> get messages => _messages;

  PdfChatViewModel({required this.tickerProvider});

  void initialize() {
    _initializeAnimations();
    _addWelcomeMessage();
  }

  void _initializeAnimations() {
    backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: tickerProvider,
    )..repeat(reverse: true);

    fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: tickerProvider,
    );

    messageInputAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: tickerProvider,
    );

    fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    messageInputAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: messageInputAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    fabAnimationController.forward();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: "# Welcome to NexPDFChat Assistant! 👋\n\nI'm here to help you interact with your PDFs and provide insights. Upload a document to get started, or let me know how I can assist you today.",
      isUser: false,
      timestamp: DateTime.now(),
      isIntro: true,
    ));
    notifyListeners();
  }

  Future<void> pickFile() async {
    _updateState(isLoading: true, statusMessage: 'Selecting file...');

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _updateState(isLoading: false, statusMessage: 'No file selected');
        return;
      }

      PlatformFile platformFile = result.files.first;
      _selectedFile = File(platformFile.path!);
      _fileName = platformFile.name;
      _updateState(statusMessage: 'Processing ${platformFile.name}...');

      await _processFile();
    } catch (e) {
      _updateState(isLoading: false, statusMessage: 'Error: ${e.toString()}');
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) return;

    try {
      _updateState(isLoading: true, statusMessage: 'Processing PDF file...');

      if (!_isRestoredSession) {
        _currentSessionId = await _historyRepository.createSession(
          _fileName!,
          _selectedFile!.path,
          DateTime.now(),
        );
      }

      final genaiClient = GenaiClient(geminiApiKey: _geminiApiKey);

      GenaiGeneratedResponseModel response = await genaiClient.promptDocument(
        _fileName!,
        'pdf',
        await _selectedFile!.readAsBytes(),
        "Extract and summarize the key content from this document that will be used as context for future questions. Include all important details, figures, and relationships between concepts.",
      );

      _fileContext = response.text;
      _updateState(statusMessage: 'PDF processed successfully');

      if (!_isRestoredSession) {
        _initializeChat();
      }

      messageInputAnimationController.forward();
    } catch (e) {
      _updateState(isLoading: false, statusMessage: 'Error processing file');
    } finally {
      _updateState(isLoading: false);
    }
  }

  void _initializeChat() {
    final introMessage = "# Document Loaded Successfully! 📄\n\nI've processed your document '${_fileName!}'. You can now ask me any questions about its content. How can I help you understand this document better?";

    _messages.add(ChatMessage(
      text: introMessage,
      isUser: false,
      timestamp: DateTime.now(),
      isIntro: true,
    ));

    if (_currentSessionId != null) {
      _historyRepository.addMessage(
        _currentSessionId!,
        introMessage,
        false,
        DateTime.now(),
        true,
      );
    }

    _scrollToBottom();
    notifyListeners();
  }

  Future<void> sendMessage(String messageText) async {
    if (messageText.isEmpty) return;

    final userMessage = messageText.trim();
    _messages.add(ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      isIntro: false,
    ));
    _updateState(isTyping: true);
    _scrollToBottom();
    notifyListeners();

    if (_currentSessionId != null) {
      await _historyRepository.addMessage(
        _currentSessionId!,
        userMessage,
        true,
        DateTime.now(),
        false,
      );
    }

    if (_fileContext.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      final response = _generateGeneralResponse(userMessage);

      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        isIntro: false,
      ));
      _updateState(isTyping: false);
      _scrollToBottom();
      notifyListeners();

      if (_currentSessionId != null) {
        await _historyRepository.addMessage(
          _currentSessionId!,
          response,
          false,
          DateTime.now(),
          false,
        );
      }
      return;
    }

    try {
      final genaiClient = GenaiClient(geminiApiKey: _geminiApiKey);

      String conversationHistory = _messages
          .where((m) => !m.isIntro)
          .take(4)
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

      await Future.delayed(const Duration(milliseconds: 800));

      _messages.add(ChatMessage(
        text: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        isIntro: false,
      ));
      _updateState(isTyping: false);
      _scrollToBottom();
      notifyListeners();

      if (_currentSessionId != null) {
        await _historyRepository.addMessage(
          _currentSessionId!,
          response.text,
          false,
          DateTime.now(),
          false,
        );
      }
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Sorry, I encountered an error processing your request. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
        isIntro: false,
      ));
      _updateState(isTyping: false);
      _scrollToBottom();
      notifyListeners();
    }
  }

  String _generateGeneralResponse(String text) {
    final lowercaseText = text.toLowerCase();

    if (lowercaseText.contains('who are you') ||
        lowercaseText.contains('what are you') ||
        lowercaseText.contains('introduce yourself') ||
        lowercaseText.contains('about you')) {
      return "# About Me\n\nI am a NexPDFChat Assistant designed to help you interact with and understand your PDF documents. I can analyze content, answer questions about your documents, and provide relevant information based on document context.\n\n**How can I help you today?**";
    }

    if (lowercaseText.contains('pdf') || lowercaseText.contains('document')) {
      return "# Document Analysis\n\nTo analyze your document, please upload it using the button at the bottom of the screen. Once uploaded, I can help you extract information, summarize content, and answer specific questions about your document.";
    }

    return "I'm here to assist with your documents. Please upload a PDF using the button at the bottom of the screen to get started, or let me know if you have any other questions.";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatScrollController.hasClients) {
        chatScrollController.animateTo(
          chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updateState({
    bool? isLoading,
    bool? isTyping,
    String? statusMessage,
  }) {
    if (isLoading != null) _isLoading = isLoading;
    if (isTyping != null) _isTyping = isTyping;
    if (statusMessage != null) _statusMessage = statusMessage;
    notifyListeners();
  }

  void dispose() {
    backgroundAnimationController.dispose();
    fabAnimationController.dispose();
    messageInputAnimationController.dispose();
    chatScrollController.dispose();
    super.dispose();
  }
}