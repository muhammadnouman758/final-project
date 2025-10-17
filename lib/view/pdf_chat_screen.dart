import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/pdf_chat_view_model.dart';
import '../widgets/animated_background.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';


class PdfChatScreen extends StatefulWidget {
  const PdfChatScreen({super.key});

  @override
  State<PdfChatScreen> createState() => _PdfChatScreenState();
}

class _PdfChatScreenState extends State<PdfChatScreen>
    with TickerProviderStateMixin {
  late PdfChatViewModel _viewModel;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = PdfChatViewModel(tickerProvider: this);
    _viewModel.initialize();
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<PdfChatViewModel>(
        builder: (context, viewModel, child) {
          return _buildScaffold(context, viewModel);
        },
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, PdfChatViewModel viewModel) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final bool canSendMessage = !viewModel.isLoading &&
        _messageController.text.trim().isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.7),
            ),
          ),
        ),
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back)
        ),
        title: Row(
          children: [
            Text(
              'NexPDFChat Assistant',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(isDarkMode, viewModel),
          _buildFrostedGlass(isDarkMode, bgColor),
          _buildMainContent(context, viewModel, isDarkMode, textColor, canSendMessage),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDarkMode, PdfChatViewModel viewModel) {
    return AnimatedBackground(
      animationController: viewModel.backgroundAnimationController,
      isDarkMode: isDarkMode,
    );
  }

  Widget _buildFrostedGlass(bool isDarkMode, Color bgColor) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        color: bgColor.withOpacity(isDarkMode ? 0.75 : 0.7),
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context,
      PdfChatViewModel viewModel,
      bool isDarkMode,
      Color textColor,
      bool canSendMessage
      ) {
    return SafeArea(
      child: Column(
        children: [
          if (viewModel.isLoading) _buildLoadingIndicator(viewModel),
          _buildChatMessages(viewModel, isDarkMode),
          _buildMessageInput(context, viewModel, isDarkMode, textColor, canSendMessage),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(PdfChatViewModel viewModel) {
    return LinearProgressIndicator(
      minHeight: 3,
      backgroundColor: Colors.transparent,
      valueColor: AlwaysStoppedAnimation<Color>(viewModel.gradientColors[0]),
    );
  }

  Widget _buildChatMessages(PdfChatViewModel viewModel, bool isDarkMode) {
    return Expanded(
      child: viewModel.messages.isEmpty
          ? _buildEmptyState(viewModel, isDarkMode)
          : ListView.builder(
        controller: viewModel.chatScrollController,
        itemCount: viewModel.messages.length + (viewModel.isTyping ? 1 : 0),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        itemBuilder: (context, index) {
          if (index == viewModel.messages.length && viewModel.isTyping) {
            return const TypingIndicator();
          }
          final message = viewModel.messages[index];
          return ChatBubble(
            message: message.text,
            isUser: message.isUser,
            timestamp: message.timestamp,
            isIntro: message.isIntro,
            gradientColors: viewModel.gradientColors,
            isDarkMode: isDarkMode,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(PdfChatViewModel viewModel, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  viewModel.gradientColors[0].withOpacity(0.1),
                  viewModel.gradientColors[1].withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 80,
              color: viewModel.gradientColors[0],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            viewModel.selectedFile == null ? 'No PDF Selected' : 'Processing Your PDF',
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
              viewModel.isLoading
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
          if (viewModel.isLoading)
            Container(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(viewModel.gradientColors[0]),
                strokeWidth: 3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(
      BuildContext context,
      PdfChatViewModel viewModel,
      bool isDarkMode,
      Color textColor,
      bool canSendMessage,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            SizedBox(
              height: 35,
              width: 40,
              child: viewModel.fileContext.isEmpty
                  ? IconButton(
                iconSize: 24,
                onPressed: viewModel.isLoading ? null : () => viewModel.pickFile(),
                icon: const Icon(Icons.attach_file),
              )
                  : Icon(Icons.attach_file, color: Colors.grey),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      viewModel.gradientColors[0].withOpacity(0.1),
                      viewModel.gradientColors[1].withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: viewModel.gradientColors[0].withOpacity(0.3),
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
                          contentPadding: const EdgeInsets.symmetric(
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
                        onSubmitted: (_) => canSendMessage
                            ? _sendMessage(viewModel, _messageController.text)
                            : null,
                        enabled: !viewModel.isLoading,
                      ),
                    ),
                    IconButton(
                      icon: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: viewModel.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: canSendMessage
                          ? () => _sendMessage(viewModel, _messageController.text)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(PdfChatViewModel viewModel, String message) {
    viewModel.sendMessage(message);
    _messageController.clear();
  }
}