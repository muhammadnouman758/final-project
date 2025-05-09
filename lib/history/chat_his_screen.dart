import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_pdf_chat/history/chat_his_repo.dart';
import 'dart:io';

class ChatHistoryScreen extends StatefulWidget {
  final List<Color> gradientColors;

  const ChatHistoryScreen({
    super.key,
    required this.gradientColors,
  });

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> with SingleTickerProviderStateMixin {
  final _repository = ChatHistoryRepository();
  List<SessionInfo> _sessions = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _loadSessions();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fabAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _repository.getSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading sessions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load chat history');
      }
    }
  }

  Future<void> _deleteSession(int sessionId) async {
    try {
      // Show a loading indicator
      setState(() {
        _isLoading = true;
      });

      await _repository.deleteSession(sessionId);

      // Refresh the list
      _loadSessions();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to delete session');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _startNewChat() {
    // Navigate back with special flag to indicate new chat request
    Navigator.pop(context, {'startNewChat': true});
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (sessionDate == today) {
      return 'Today, ${DateFormat.jm().format(dateTime)}';
    } else if (sessionDate == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? const Color(0xFF1E1E2E)
        : Colors.grey.shade50;

    return Theme(
      data: Theme.of(context).copyWith(
        // Set custom card theme
        cardTheme: CardTheme(
          elevation: 3,
          shadowColor: widget.gradientColors[0].withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(isDarkMode),
        body: _isLoading
            ? _buildLoadingView()
            : _sessions.isEmpty
            ? _buildEmptyState(isDarkMode)
            : _buildSessionsList(isDarkMode),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  AppBar _buildAppBar(bool isDarkMode) {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.history_rounded,
            size: 28,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            'Chat History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ],
      ),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _loadSessions();
          },
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton.extended(
        onPressed: _startNewChat,
        backgroundColor: widget.gradientColors[0],
        label: Row(
          children: [
            Icon(Icons.add_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'New Chat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.gradientColors[0]),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading chats...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: widget.gradientColors[0],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated container with custom painter
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.gradientColors[0].withOpacity(0.1),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 80,
                color: widget.gradientColors[0].withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Chat History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Your previous PDF chats will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Start New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.gradientColors[0],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(bool isDarkMode) {
    return ListView.builder(
      itemCount: _sessions.length,
      padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final session = _sessions[index];
        // Create staggered animation effect using TweenAnimationBuilder
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildSessionCard(session, isDarkMode),
        );
      },
    );
  }

  Widget _buildSessionCard(SessionInfo session, bool isDarkMode) {
    // Check if the file still exists
    final fileExists = File(session.filePath).existsSync();
    final cardColor = isDarkMode ? const Color(0xFF2D2D3F) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: widget.gradientColors[0].withOpacity(0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: fileExists
              ? () {
            Navigator.pop(context, {
              'sessionId': session.id,
              'filePath': session.filePath,
              'fileName': session.fileName,
            });
          }
              : null,
          splashColor: widget.gradientColors[0].withOpacity(0.1),
          highlightColor: widget.gradientColors[0].withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: fileExists
                    ? widget.gradientColors[0].withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'pdf_icon_${session.id}',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: fileExists
                                ? [
                              widget.gradientColors[0].withOpacity(0.8),
                              widget.gradientColors[1].withOpacity(0.8),
                            ]
                                : [
                              Colors.grey.withOpacity(0.5),
                              Colors.grey.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: fileExists
                                  ? widget.gradientColors[0].withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.fileName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: fileExists
                                  ? (isDarkMode ? Colors.white : Colors.black87)
                                  : Colors.grey,
                              decoration: fileExists ? null : TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(session.createdAt),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildCardActions(session, fileExists, isDarkMode),
                  ],
                ),
                if (!fileExists)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PDF file no longer exists at this location',
                            style: TextStyle(
                              color: Colors.amber[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardActions(SessionInfo session, bool fileExists, bool isDarkMode) {
    return Row(
      children: [
        if (fileExists)
          IconButton(
            icon: Icon(
              Icons.chat_rounded,
              color: widget.gradientColors[0],
            ),
            onPressed: () {
              Navigator.pop(context, {
                'sessionId': session.id,
                'filePath': session.filePath,
                'fileName': session.fileName,
              });
            },
            tooltip: 'Continue Chat',
            splashRadius: 24,
          ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteConfirmation(session);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation(SessionInfo session) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              title: const Text('Delete Chat History'),
              content: Text('Are you sure you want to delete the chat history for "${session.fileName}"?'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteSession(session.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('DELETE'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}