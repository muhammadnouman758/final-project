import 'dart:math';

import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:ui';

import '../chatbot.dart';
import '../main.dart';
import '../onboarding/info.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  late AnimationController _backgroundAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _iconScaleAnimation;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: "Welcome to PDF Chat",
      description: "Your intelligent assistant for PDF documents, powered by advanced AI technology.",
      icon: Icons.menu_book,
      secondaryIcon: Icons.smart_toy_rounded,
      gradientColors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
      iconData: Icons.smart_toy_rounded,
    ),
    OnboardingItem(
      title: "Upload & Analyze",
      description: "Instantly upload your PDF documents and get AI-powered summaries and insights.",
      icon: Icons.upload_file,
      secondaryIcon: Icons.analytics,
      gradientColors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
      iconData: Icons.cloud_upload_rounded,
    ),
    OnboardingItem(
      title: "Chat with Documents",
      description: "Ask questions about your PDFs and receive intelligent, context-aware responses.",
      icon: Icons.question_answer,
      secondaryIcon: Icons.chat,
      gradientColors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      iconData: Icons.chat_bubble_outline_rounded,
    ),
    OnboardingItem(
      title: "AI-Powered Features",
      description: "Extract key information, generate summaries, and get citation references automatically.",
      icon: Icons.lightbulb,
      secondaryIcon: Icons.auto_awesome,
      gradientColors: [Color(0xFFFE5196), Color(0xFFFF8E53)],
      iconData: Icons.auto_awesome,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Background animation controller
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    // Content animation controller
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentAnimationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentAnimationController, curve: Curves.easeOutCubic),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _contentAnimationController, curve: Curves.elasticOut),
    );

    _contentAnimationController.forward();

    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
          _isLastPage = _currentPage == _onboardingItems.length - 1;
        });

        // Reset and play content animation when page changes
        _contentAnimationController.reset();
        _contentAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentAnimationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onSkip() {
    _pageController.animateToPage(
      _onboardingItems.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onGetStarted() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const UserInfoScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutQuint,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
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

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header with skip button and app logo
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App logo/brand
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _onboardingItems[_currentPage].gradientColors[0].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _onboardingItems[_currentPage].iconData,
                              color: _onboardingItems[_currentPage].gradientColors[0],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "PDF Chat",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Skip button
                      if (!_isLastPage)
                        TextButton(
                          onPressed: _onSkip,
                          style: TextButton.styleFrom(
                            backgroundColor: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade200.withOpacity(0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: _onboardingItems[_currentPage].gradientColors[0],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Main content with page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _onboardingItems.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _contentAnimationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _currentPage == index ? _slideAnimation.value : 0),
                              child: OnboardingPage(
                                item: _onboardingItems[index],
                                isActive: _currentPage == index,
                                isDarkMode: isDarkMode,
                                scaleAnimation: _iconScaleAnimation,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Bottom navigation with page indicator and buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Page indicator dots
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _onboardingItems.length,
                        effect: JumpingDotEffect(
                          activeDotColor: _onboardingItems[_currentPage].gradientColors[0],
                          dotColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          dotHeight: 8,
                          dotWidth: 8,
                          jumpScale: 2,
                          verticalOffset: 10,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Next/Get Started button
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: _onboardingItems[_currentPage].gradientColors[0].withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: _onboardingItems[_currentPage].gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _onNextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLastPage ? 'Get Started' : 'Next',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Go directly to chat button (on last page)
                      if (_isLastPage)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const PdfChatScreen()),
                              );
                            },
                            child: Text(
                              'Skip onboarding and go to Chat',
                              style: TextStyle(
                                color: _onboardingItems[_currentPage].gradientColors[0],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        final List<Color> colors = _onboardingItems[_currentPage].gradientColors;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black : Colors.white,
          ),
          child: CustomPaint(
            painter: BackgroundPainter(
              animation: _backgroundAnimationController.value,
              colors: colors,
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;
  final bool isDarkMode;

  BackgroundPainter({required this.animation, required this.colors, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw first blob
    paint.shader = RadialGradient(
      colors: [
        colors[0].withOpacity(0.5),
        colors[0].withOpacity(0.0),
      ],
      radius: 0.8,
    ).createShader(Rect.fromCircle(
      center: Offset(
        centerX + sin(animation * 2 * 3.14) * centerX * 0.5,
        centerY * 0.5 + cos(animation * 2 * 3.14) * centerY * 0.3,
      ),
      radius: size.width * 0.6,
    ));

    canvas.drawCircle(
      Offset(
        centerX + sin(animation * 2 * 3.14) * centerX * 0.5,
        centerY * 0.5 + cos(animation * 2 * 3.14) * centerY * 0.3,
      ),
      size.width * 0.6,
      paint,
    );

    // Draw second blob
    paint.shader = RadialGradient(
      colors: [
        colors[1].withOpacity(0.5),
        colors[1].withOpacity(0.0),
      ],
      radius: 0.8,
    ).createShader(Rect.fromCircle(
      center: Offset(
        centerX - cos(animation * 2 * 3.14) * centerX * 0.5,
        centerY + size.height * 0.3 + sin(animation * 2 * 3.14) * centerY * 0.3,
      ),
      radius: size.width * 0.5,
    ));

    canvas.drawCircle(
      Offset(
        centerX - cos(animation * 2 * 3.14) * centerX * 0.5,
        centerY + size.height * 0.3 + sin(animation * 2 * 3.14) * centerY * 0.3,
      ),
      size.width * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
    return animation != oldDelegate.animation ||
        colors != oldDelegate.colors ||
        isDarkMode != oldDelegate.isDarkMode;
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final bool isActive;
  final bool isDarkMode;
  final Animation<double> scaleAnimation;

  const OnboardingPage({
    super.key,
    required this.item,
    required this.isActive,
    required this.isDarkMode,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon animation container
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey.shade900.withOpacity(0.5)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            item.gradientColors[0].withOpacity(0.1),
                            item.gradientColors[1].withOpacity(0.01),
                          ],
                          radius: 0.8,
                        ),
                      ),
                    ),

                    // Secondary smaller icons floating around
                    ...List.generate(5, (index) {
                      final angle = index * (2 * pi / 5);
                      return AnimatedBuilder(
                        animation: scaleAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: MediaQuery.of(context).size.width * 0.25 * cos(angle + scaleAnimation.value * pi) + MediaQuery.of(context).size.width * 0.15,
                            top: MediaQuery.of(context).size.height * 0.12 * sin(angle + scaleAnimation.value * pi) + MediaQuery.of(context).size.height * 0.1,
                            child: Opacity(
                              opacity: 0.5,
                              child: Icon(
                                index % 2 == 0 ? item.icon : item.secondaryIcon,
                                size: 24.0 + 8.0 * (index % 3),
                                color: item.gradientColors[index % 2],
                              ),
                            ),
                          );
                        },
                      );
                    }),

                    // Main icon with pulse animation
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: AnimatedBuilder(
                              animation: scaleAnimation,
                              builder: (context, _) {
                                return Transform.scale(
                                  scale: scaleAnimation.value,
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: item.gradientColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: item.gradientColors[0].withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 1.0 * scaleAnimation.value,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Text content
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Animated title with gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: item.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        item.title,
                        textStyle: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        speed: const Duration(milliseconds: 70),
                      ),
                    ],
                    isRepeatingAnimation: false,
                    totalRepeatCount: 1,
                    displayFullTextOnTap: true,
                  ),
                ),
                const SizedBox(height: 30),

                // Description with card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey.shade900.withOpacity(0.7)
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final IconData secondaryIcon;
  final List<Color> gradientColors;
  final IconData iconData;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.secondaryIcon,
    required this.gradientColors,
    required this.iconData,
  });
}