import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_pdf_chat/pdf_gemini.dart';
import 'dart:io';
import 'package:smart_pdf_chat/src/genai_generated_response_model.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../history/chat_his_repo.dart';

class VoiceChatBotPdf extends StatefulWidget {
  const VoiceChatBotPdf({super.key});

  @override
  State<VoiceChatBotPdf> createState() => _VoiceChatBotPdfState();
}

class _VoiceChatBotPdfState extends State<VoiceChatBotPdf>
    with TickerProviderStateMixin {
<<<<<<< HEAD
  final String _geminiApiKey = '';
=======
  final String _geminiApiKey = 'A';
>>>>>>> ef61391823bb2e13be3f90f42114a62d3041b6ea
  final ScrollController _chatScrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final math.Random _random = math.Random();

  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _showSuggestionsOverlay = false;
  bool _micActivated = false;
  String _statusMessage = 'Upload a PDF to start chatting';
  String _fileContext = '';
  List<VoiceChatMessage> _messages = [];
  String _currentTranscript = '';
  List<String> _suggestedQuestions = [];

  double _soundLevel = 0.0;
  late AnimationController _levelAnimationController;

  late AnimationController _aiVoiceAnimationController;
  final List<double> _waveHeights = List.generate(20, (_) => 0.0);
  Timer? _waveUpdateTimer;
  Timer? _noSoundTimer;

  late AnimationController _overlayAnimationController;
  late Animation<double> _overlayScaleAnimation;
  late Animation<double> _overlayOpacityAnimation;
  late Animation<double> _botScaleAnimation;
  late Animation<double> _botRotationAnimation;

  final ChatHistoryRepository _historyRepository  = ChatHistoryRepository();
  int? _currentSessionId;
  bool _isRestoredSession = false;

  final List<Color> _gradientColors = [
    const Color(0xFF4776E6),
    const Color(0xFF8E54E9)
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTTS();
    _initAnimations();
    _addWelcomeMessage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAIVoiceAnimation();
      Future.delayed(const Duration(seconds: 3), () {
        _stopAIVoiceAnimation();
      });
    });
  }

  void _initAnimations() {
    _levelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _aiVoiceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
      if (mounted) setState(() {});
    });

    _overlayAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
      if (_overlayAnimationController.value < 0.0 || _overlayAnimationController.value > 1.0) {
        print('Warning: _overlayAnimationController value out of bounds: ${_overlayAnimationController.value}');
      }
    });

    _overlayScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _overlayOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _botScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 60),
    ]).animate(
      CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _botRotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAIVoiceAnimation() {
    if (!_aiVoiceAnimationController.isAnimating) {
      _aiVoiceAnimationController.repeat(reverse: true);
    }
    _waveUpdateTimer?.cancel();
    _waveUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _waveHeights.length; i++) {
            _waveHeights[i] = _random.nextDouble() * (_isSpeaking ? 1.0 : 0.5);
          }
        });
      }
    });
  }

  void _stopAIVoiceAnimation() {
    _aiVoiceAnimationController.stop();
    _waveUpdateTimer?.cancel();
    if (mounted) {
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 0.0;
        }
      });
    }
  }

  void _showSuggestionsFullScreen() {
    if (_suggestedQuestions.isEmpty) return;

    setState(() {
      _showSuggestionsOverlay = true;
    });

    _overlayAnimationController.reset();
    _overlayAnimationController.forward();
    _startAIVoiceAnimation();
  }

  void _hideSuggestionsFullScreen() {
    _overlayAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showSuggestionsOverlay = false;
        });
      }
    });
    _stopAIVoiceAnimation();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
          if (_micActivated && mounted && !_isSpeaking && !_isProcessing) {
            _noSoundTimer?.cancel();
            _noSoundTimer = Timer(const Duration(seconds: 3), () {
              if (mounted && !_isSpeaking && !_isProcessing && _currentTranscript.isEmpty) {
                _handleNoSoundDetected();
              }
            });
          }
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
        _showErrorSnackbar('Speech recognition error: ${error.errorMsg}');
        if (_micActivated && mounted) {
          _noSoundTimer?.cancel();
          _noSoundTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && !_isSpeaking && !_isProcessing && _currentTranscript.isEmpty) {
              _handleNoSoundDetected();
            }
          });
        }
      },
    );
    if (!available && mounted) {
      setState(() {
        _statusMessage = 'Speech recognition unavailable';
      });
      _showErrorSnackbar('Speech recognition unavailable');
    }
  }

  Future<void> _initTTS() async {
    await _tts.setSharedInstance(true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    _tts.setStartHandler(() {
      setState(() => _isSpeaking = true);
      _startAIVoiceAnimation();
    });
    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
      _stopAIVoiceAnimation();
      if (_micActivated && mounted && !_isProcessing) {
        _noSoundTimer?.cancel();
        _noSoundTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && !_isSpeaking && !_isProcessing && _currentTranscript.isEmpty) {
            _handleNoSoundDetected();
          }
        });
      }
    });
    _tts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      _stopAIVoiceAnimation();
      _showErrorSnackbar('TTS error: $msg');
      if (_micActivated && mounted) {
        _noSoundTimer?.cancel();
        _noSoundTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && !_isSpeaking && !_isProcessing && _currentTranscript.isEmpty) {
            _handleNoSoundDetected();
          }
        });
      }
    });
  }

  void _addWelcomeMessage() {
    _messages.add(VoiceChatMessage(
      text: "# Welcome to Voice PDF Assistant! 🎤\n\nPress the microphone button to start listening. Upload a PDF document to discuss its contents.",
      isUser: false,
      timestamp: DateTime.now(),
      isIntro: true,
    ));
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (_isListening || _isSpeaking || _isProcessing) return;

    setState(() {
      _isListening = true;
      _currentTranscript = '';
      _micActivated = true;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _currentTranscript = result.recognizedWords;
              if (result.finalResult && _currentTranscript.isNotEmpty) {
                _speech.stop();
                setState(() {
                  _isListening = false;
                  _micActivated = false;
                });
                _noSoundTimer?.cancel();
                _handleVoiceInput(_currentTranscript);
              }
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        onSoundLevelChange: (level) {
          if (mounted) {
            setState(() => _soundLevel = level);
            if (!_levelAnimationController.isAnimating) {
              _levelAnimationController.repeat(reverse: true);
            }
          }
        },
      );
    } catch (e) {
      setState(() {
        _isListening = false;
        _micActivated = false;
      });
      _showErrorSnackbar('Failed to start listening: $e');
      _noSoundTimer?.cancel();
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _levelAnimationController.stop();
    setState(() {
      _isListening = false;
      _micActivated = false;
    });
    _noSoundTimer?.cancel();
    if (_currentTranscript.isNotEmpty) {
      _handleVoiceInput(_currentTranscript);
    }
  }

  void _handleNoSoundDetected() async {
    if (_isProcessing || _isSpeaking || _isListening) return;

    const responseText = "How can I assist you? I'm waiting for your response.";
    setState(() {
      _messages.add(VoiceChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
        isIntro: false,
      ));
      _isProcessing = true;
      _scrollToBottom();
    });

    if (_currentSessionId != null) {
      await _historyRepository.addMessage(
        _currentSessionId!,
        responseText,
        false,
        DateTime.now(),
        false,
      );
    }

    await _tts.speak(responseText);
    setState(() => _isProcessing = false);
  }

  void _handleVoiceInput(String transcript) async {
    if (transcript.trim().isEmpty) {
      if (_micActivated && mounted && !_isSpeaking && !_isProcessing) {
        _noSoundTimer?.cancel();
        _noSoundTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && !_isSpeaking && !_isProcessing && _currentTranscript.isEmpty) {
            _handleNoSoundDetected();
          }
        });
      }
      return;
    }

    setState(() {
      _messages.add(VoiceChatMessage(
        text: transcript,
        isUser: true,
        timestamp: DateTime.now(),
        isIntro: false,
      ));
      _isProcessing = true;
      _currentTranscript = '';
      _scrollToBottom();
    });

    if (_currentSessionId != null) {
      await _historyRepository.addMessage(
        _currentSessionId!,
        transcript,
        true,
        DateTime.now(),
        false,
      );
    }

    _startAIVoiceAnimation();
    await _processVoiceInput(transcript);
  }

  Future<void> _processVoiceInput(String input) async {
    try {
      String responseText;
      if (_fileContext.isEmpty) {
        responseText = _generateGeneralResponse(input);
      } else {
        final genaiClient = GenaiClient(geminiApiKey: _geminiApiKey);
        String conversationHistory = _messages
            .where((m) => !m.isIntro)
            .take(4)
            .map((m) => "${m.isUser ? 'User' : 'Assistant'}: ${m.text}")
            .join('\n\n');

        String fullPrompt = """
        Document Context: $_fileContext
        Conversation History: $conversationHistory
        Instruction: Respond concisely for voice output. Avoid markdown. Keep under 3 sentences.
        If the question is unrelated to the document, respond with: "I apologize to answer, I am unable to answer the questions."
        User Question: $input
        """;

        GenaiGeneratedResponseModel response = await genaiClient.promptDocument(
          _fileName!,
          'pdf',
          await _selectedFile!.readAsBytes(),
          fullPrompt,
        );
        responseText = response.text;

        if (responseText.toLowerCase().contains('not finding this in the document') ||
            responseText.toLowerCase().contains('unrelated to the document')) {
          responseText = "I apologize to answer, I am unable to answer the questions.";
        }
      }

      setState(() {
        _messages.add(VoiceChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
          isIntro: false,
        ));
        _isProcessing = false;
        _scrollToBottom();
      });

      if (_currentSessionId != null) {
        await _historyRepository.addMessage(
          _currentSessionId!,
          responseText,
          false,
          DateTime.now(),
          false,
        );
      }

      await _tts.speak(responseText.replaceAll(RegExp(r'\*+'), ''));

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _messages.add(VoiceChatMessage(
          text: "Sorry, I encountered an error. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
          isIntro: false,
        ));
        _scrollToBottom();
      });
      _showErrorSnackbar('Error: ${e.toString()}');
      _stopAIVoiceAnimation();
      if (_micActivated && mounted) {
        _noSoundTimer?.cancel();
        _noSoundTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && !_isSpeaking && !_isProcessing && _currentTranscript.isEmpty) {
            _handleNoSoundDetected();
          }
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Selecting file...';
        _suggestedQuestions = [];
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
          _statusMessage = 'Processing $_fileName...';
        });

        _startAIVoiceAnimation();
        await _processFile(file);
        _stopAIVoiceAnimation();

        _showSuggestionsFullScreen();
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No file selected';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error selecting file';
      });
      _showErrorSnackbar('Error selecting file: ${e.toString()}');
      _stopAIVoiceAnimation();
    }
  }

  Future<void> _processFile(File file) async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Processing file...';
      });

      final genaiClient = GenaiClient(geminiApiKey: _geminiApiKey);

      GenaiGeneratedResponseModel summaryResponse = await genaiClient.promptDocument(
        _fileName!,
        'pdf',
        await file.readAsBytes(),
        "Generate a brief summary of this document in 2-3 sentences.",
      );

      GenaiGeneratedResponseModel questionsResponse = await genaiClient.promptDocument(
        _fileName!,
        'pdf',
        await file.readAsBytes(),
        "Generate 3-5 concise questions someone might ask about this document. "
            "Format as a bullet list with each question in quotes separated by commas.",
      );

      setState(() {
        _fileContext = summaryResponse.text;
        _suggestedQuestions = _parseGeneratedQuestions(questionsResponse.text);
        _statusMessage = 'Ready to chat about $_fileName';
        _isLoading = false;

        _messages.add(VoiceChatMessage(
          text: "📄 $_fileName loaded. I'm ready to answer questions about this document.",
          isUser: false,
          timestamp: DateTime.now(),
          isIntro: false,
        ));
      });

      if (!_isRestoredSession) {
        _currentSessionId = await _historyRepository.createSession(
          _fileName!,
          '',
          DateTime.now(),
        );

        await _historyRepository.addMessage(
          _currentSessionId!,
          "📄 $_fileName loaded. I'm ready to answer questions about this document.",
          false,
          DateTime.now(),
          false,
        );
      }

      await _tts.speak("${_fileName} loaded. I'm ready to answer questions about this document.");

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error processing file';
      });
      _showErrorSnackbar('Error processing file: ${e.toString()}');
    }
  }

  List<String> _parseGeneratedQuestions(String response) {
    try {
      final regex = RegExp(r'"([^"]+)"');
      return regex.allMatches(response).map((m) => m.group(1)!).toList();
    } catch (e) {
      return [
        "What is the main purpose of this document?",
        "Can you summarize the key points?",
        "Who is the intended audience?"
      ];
    }
  }

  Widget _buildSuggestedQuestionsOverlay() {
    final suggestionContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: _botRotationAnimation.value,
          child: ScaleTransition(
            scale: _botScaleAnimation,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gradientColors[0].withOpacity(0.8),
                    _gradientColors[1].withOpacity(0.4),
                  ],
                ),
              ),
              child: Center(
                child: CustomPaint(
                  painter: VoiceWavePainter(
                    waveHeights: _waveHeights,
                    color: Colors.white,
                    isActive: true,
                    isLarge: true,
                  ),
                  size: const Size(120, 120),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          _fileName ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _fileContext,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Text(
          'Suggested Questions',
          style: TextStyle(
            color: _gradientColors[0],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestedQuestions.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  _hideSuggestionsFullScreen();
                  _handleVoiceInput(_suggestedQuestions[index]);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gradientColors[1].withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: _gradientColors[0]),
                  ),
                ),
                child: Text(
                  _suggestedQuestions[index],
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          icon: const Icon(Icons.close, color: Colors.white70),
          label: const Text(
            'Close',
            style: TextStyle(color: Colors.white70),
          ),
          onPressed: _hideSuggestionsFullScreen,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: _overlayAnimationController,
      builder: (context, _) {
        return Positioned.fill(
          child: FadeTransition(
            opacity: _overlayOpacityAnimation,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ScaleTransition(
                    scale: _overlayScaleAnimation,
                    child: suggestionContent,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedQuestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Suggested Questions:',
                  style: TextStyle(
                    color: _gradientColors[0],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )),
              IconButton(
                icon: Icon(Icons.fullscreen, color: _gradientColors[0]),
                onPressed: _showSuggestionsFullScreen,
                tooltip: 'Show all suggestions',
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestedQuestions
                  .map((q) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(q,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      )),
                  backgroundColor: _gradientColors[0].withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: _gradientColors[0]),
                  ),
                  onPressed: () => _handleVoiceInput(q),
                ),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('Voice PDF Assistant', style: TextStyle(color: textColor,fontWeight: FontWeight.bold)),
        ),
        body: Stack(
          children: [
            Container(
              color: isDarkMode ? Colors.black : Colors.white,
            ),
            SafeArea(
              child: Column(
                children: [
                  if (_isLoading)
                    LinearProgressIndicator(
                      minHeight: 3,
                      valueColor: AlwaysStoppedAnimation(_gradientColors[0]),
                    ),
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState(isDarkMode)
                        : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _chatScrollController,
                            itemCount: _messages.length + (_isProcessing ? 1 : 0),
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              if (index == _messages.length && _isProcessing) {
                                return _buildProcessingIndicator();
                              }
                              return VoiceChatBubble(
                                message: _messages[index],
                                gradientColors: _gradientColors,
                                isDarkMode: isDarkMode,
                                isSpeaking: _isSpeaking && index == _messages.length - 1,
                                onPlay: () => _tts.speak(_messages[index].text),
                                showVoiceWave: !_messages[index].isUser && index == _messages.length - 1,
                                waveHeights: _waveHeights,
                              );
                            },
                          ),
                        ),
                        if (_suggestedQuestions.isNotEmpty && !_isProcessing && !_showSuggestionsOverlay)
                          _buildSuggestedQuestions(),
                      ],
                    ),
                  ),
                  _buildVoiceInputUI(isDarkMode),
                ],
              ),
            ),
            if (_showSuggestionsOverlay) _buildSuggestedQuestionsOverlay(),
          ],
        ),
        // CIRCUIT BREAKER: FloatingActionButton was found in the code and needs to be checked if it needs to be sandboxed for security purposes.
    floatingActionButton: Padding(
    padding: const EdgeInsets.only(bottom: 80.0),
    child: _buildFloatingActionButtons(isDarkMode),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildFloatingActionButtons(bool isDarkMode) {
    if (_fileContext.isEmpty) {
      return FloatingActionButton.extended(
        onPressed: _isLoading ? null : _pickFile,
        backgroundColor: _gradientColors[0],
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload PDF', style: TextStyle(color: Colors.white)),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            onPressed: _showSuggestionsFullScreen,
            backgroundColor: _gradientColors[1],
            heroTag: 'suggestions',
            child: const Icon(Icons.lightbulb_outline, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _isListening ? _stopListening : _startListening,
            backgroundColor: _isListening ? Colors.red : _gradientColors[0],
            heroTag: 'mic',
            child: Icon(
              _isListening ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic,
            size: 80,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_isLoading) const SizedBox(height: 32),
          if (!_isLoading)
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gradientColors[0],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _pickFile,
            ),
        ],
      ),
    );
  }

  Widget _buildVoiceInputUI(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            if (_isListening || _currentTranscript.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isListening
                        ? _gradientColors[0]
                        : isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _currentTranscript.isEmpty
                          ? Text(
                        'Listening...',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                          : Text(
                        _currentTranscript,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    if (_isListening)
                      AnimatedBuilder(
                      animation: _levelAnimationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: VoiceWavePainter(
                            waveHeights: List.generate(
                              5,
                                  (i) => _random.nextDouble() * _soundLevel * 2,
                            ),
                            color: _gradientColors[0],
                            isActive: true,
                            isLarge: false,
                          ),
                          size: const Size(24, 24),
                        );
                      },
                    ),
                  ],
                ),
              ),
            if (_isListening || _currentTranscript.isNotEmpty) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _fileContext.isEmpty
                        ? 'Upload a PDF to start the conversation'
                        : 'Ask a question about $_fileName',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey : Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (_fileContext.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.lightbulb_outline,
                      color: _gradientColors[0],
                    ),
                    onPressed: _showSuggestionsFullScreen,
                    tooltip: 'Show suggestions',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_gradientColors[0]),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Processing...',
            style: TextStyle(
              color: _gradientColors[1],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _generateGeneralResponse(String input) {
    input = input.toLowerCase();
    if (input.contains('hello') || input.contains('hi') || input.contains('hey')) {
      return "Hello! Upload a PDF document to start asking questions about it.";
    } else if (input.contains('how are you')) {
      return "I'm ready to assist with your PDF documents. Please upload one.";
    } else if (input.contains('what can you do') || input.contains('help me')) {
      return "I can analyze PDFs and answer questions about their content. Upload a PDF to begin.";
    } else if (input.contains('thank')) {
      return "You're welcome! Upload a PDF to continue.";
    } else if (input.contains('upload') || input.contains('pdf') || input.contains('document')) {
      return "Tap the upload button to select a PDF file.";
    } else {
      return "Please upload a PDF document to ask specific questions.";
    }
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    _chatScrollController.dispose();
    _levelAnimationController.dispose();
    _aiVoiceAnimationController.dispose();
    _overlayAnimationController.dispose();
    _waveUpdateTimer?.cancel();
    _noSoundTimer?.cancel();

    super.dispose();
  }
}

class VoiceChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isIntro;

  VoiceChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isIntro,
  });
}

class VoiceWavePainter extends CustomPainter {
  final List<double> waveHeights;
  final Color color;
  final bool isActive;
  final bool isLarge;

  VoiceWavePainter({
    required this.waveHeights,
    required this.color,
    required this.isActive,
    required this.isLarge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLarge ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = isLarge ? size.width * 0.4 : size.width * 0.35;

    if (!isActive) {
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final path = Path();
    final waveCount = waveHeights.length;
    final angleStep = 2 * math.pi / waveCount;

    for (int i = 0; i < waveCount; i++) {
      final angle = i * angleStep;
      final waveHeight = isActive ? waveHeights[i] : 0.1;
      final waveRadius = radius + (radius * waveHeight * 0.5);

      final x = center.dx + waveRadius * math.cos(angle);
      final y = center.dy + waveRadius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant VoiceWavePainter oldDelegate) {
    return oldDelegate.isActive != isActive ||
        oldDelegate.color != color ||
        oldDelegate.waveHeights != waveHeights;
  }
}

class VoiceChatBubble extends StatelessWidget {
  final VoiceChatMessage message;
  final List<Color> gradientColors;
  final bool isDarkMode;
  final bool isSpeaking;
  final VoidCallback onPlay;
  final bool showVoiceWave;
  final List<double> waveHeights;

  const VoiceChatBubble({
    Key? key,
    required this.message,
    required this.gradientColors,
    required this.isDarkMode,
    required this.isSpeaking,
    required this.onPlay,
    required this.showVoiceWave,
    required this.waveHeights,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: showVoiceWave
                  ? CustomPaint(
                painter: VoiceWavePainter(
                  waveHeights: waveHeights,
                  color: Colors.white,
                  isActive: isSpeaking,
                  isLarge: false,
                ),
              )
                  : const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDarkMode ? Colors.grey[800] : Colors.grey[300])
                    : null,
                gradient: !isUser
                    ? LinearGradient(
                  colors: [
                    gradientColors[0].withOpacity(0.8),
                    gradientColors[1].withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                  bottomRight: !isUser ? const Radius.circular(20) : const Radius.circular(0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isIntro)
                    MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        h1: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        p: TextStyle(
                          color: isUser
                              ? (isDarkMode ? Colors.white : Colors.black87)
                              : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser
                            ? (isDarkMode ? Colors.white : Colors.black87)
                            : Colors.white,
                      ),
                    ),
                  if (!isUser && !message.isIntro)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: isUser
                                ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                                : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onPlay,
                          child: Icon(
                            Icons.volume_up,
                            size: 16,
                            color: isUser
                                ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                                : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message.text));
                            _showToast(context, 'Copied to clipboard');
                          },
                          child: Icon(
                            Icons.copy,
                            size: 16,
                            color: isUser
                                ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }
<<<<<<< HEAD
}
=======

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: isDarkMode ? Colors.grey : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No chat history yet',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final isActive = session['id'] == widget.currentSessionId;

          return Dismissible(
            key: Key('session_${session['id']}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Session'),
                  content: const Text('Are you sure you want to delete this chat session?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              _deleteSession(session['id']);
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isActive ? Colors.blue : Colors.grey.shade200,
                child: Icon(
                  Icons.description,
                  color: isActive ? Colors.white : Colors.grey.shade600,
                ),
              ),
              title: Text(
                session['name'] ?? 'Unnamed Document',
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : null,
                ),
              ),
              subtitle: Text(
                _formatDateTime(session['timestamp']),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isActive ? Colors.blue : null,
              ),
              onTap: () {
                Navigator.of(context).pop(session);
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final List<String> weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      return '${weekdays[dateTime.weekday - 1]} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
>>>>>>> ef61391823bb2e13be3f90f42114a62d3041b6ea
