import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_pdf_chat/history/chat_his_repo.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

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
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadSessions();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fabAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
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
          // Filter sessions to only include those where the PDF file exists
          _sessions = sessions.where((session) => File(session.filePath).existsSync()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load chat history. Please try again.');
      }
    }
  }

  Future<void> _deleteSession(int sessionId) async {
    try {
      setState(() => _isLoading = true);
      await _repository.deleteSession(sessionId);
      await _loadSessions();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to delete session. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        elevation: 6,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _startNewChat() {
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
        ? const Color(0xFF121212)
        : Colors.grey.shade100;

    return Theme(
      data: Theme.of(context).copyWith(
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
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
      leading: IconButton(onPressed: ()=> Navigator.pop(context), icon: Icon(Icons.arrow_back,color: Colors.white,)),
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
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
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
            setState(() => _isLoading = true);
            _loadSessions();
          },
          tooltip: 'Refresh',
          color: Colors.white,
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
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        label: Row(
          children: [
            Icon(Icons.add_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'New Chat',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading your chats...',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: widget.gradientColors[0],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    widget.gradientColors[0].withOpacity(0.2),
                    widget.gradientColors[1].withOpacity(0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black26
                        : widget.gradientColors[0].withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.history_rounded,
                size: 90,
                color: widget.gradientColors[0].withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Chat History Yet',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Your previous NexPDFChats will appear here once you start a new conversation',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Start New Chat',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.gradientColors[0],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(bool isDarkMode) {
    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: widget.gradientColors[0],
      child: ListView.builder(
        itemCount: _sessions.length,
        padding: const EdgeInsets.only(top: 16, bottom: 100, left: 16, right: 16),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: _buildSessionCard(session, isDarkMode),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(SessionInfo session, bool isDarkMode) {
    final fileExists = File(session.filePath).existsSync();
    final cardColor = isDarkMode
        ? const Color(0xFF1A1A2E)
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: widget.gradientColors[0].withOpacity(0.3),
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
          splashColor: widget.gradientColors[0].withOpacity(0.2),
          highlightColor: widget.gradientColors[0].withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: fileExists
                    ? widget.gradientColors[0].withOpacity(0.4)
                    : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black12
                      : widget.gradientColors[0].withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
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
                                ? widget.gradientColors
                                : [
                              Colors.grey.shade400,
                              Colors.grey.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: fileExists
                                  ? widget.gradientColors[0].withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 28,
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
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: fileExists
                                  ? (isDarkMode ? Colors.white : Colors.black87)
                                  : Colors.grey,
                              decoration: fileExists ? null : TextDecoration.lineThrough,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formatDate(session.createdAt),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PDF file no longer exists at this location',
                            style: GoogleFonts.inter(
                              color: Colors.amber[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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
              size: 24,
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
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
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
                  Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: GoogleFonts.inter(color: Colors.red.shade600),
                  ),
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
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              title: Text(
                'Delete Chat History',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              content: Text(
                'Are you sure you want to delete the chat history for "${session.fileName}"? This action cannot be undone.',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteSession(session.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'DELETE',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}