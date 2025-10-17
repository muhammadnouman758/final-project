import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

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

  void _copyMessageToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message));
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

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(timestamp);

    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 0,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _copyMessageToClipboard(context),
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
                            if (href != null) {
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
}