// import 'package:flutter/material.dart';
// import 'package:smart_pdf_chat/chatbot.dart';
// import 'package:lottie/lottie.dart';
// import 'package:animated_text_kit/animated_text_kit.dart';
// import 'package:smooth_page_indicator/smooth_page_indicator.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Smart NexPDFChat',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         brightness: Brightness.light,
//         useMaterial3: true,
//         fontFamily: 'Poppins',
//       ),
//       darkTheme: ThemeData(
//         brightness: Brightness.dark,
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//         fontFamily: 'Poppins',
//       ),
//       themeMode: ThemeMode.system,
//       home: const OnboardingScreen(),
//     );
//   }
// }
//
// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});
//
//   @override
//   State<OnboardingScreen> createState() => _OnboardingScreenState();
// }
//
// class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;
//   bool _isLastPage = false;
//
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   final List<OnboardingItem> _onboardingItems = [
//     OnboardingItem(
//       title: "Welcome to Smart NexPDFChat",
//       description: "Your intelligent assistant for PDF documents, powered by advanced AI.",
//       lottieAsset: "assets/animations/welcome_animation.json",
//     ),
//     OnboardingItem(
//       title: "Upload & Analyze",
//       description: "Instantly upload your PDF documents and get AI-powered summaries and insights.",
//       lottieAsset: "assets/animations/upload_animation.json",
//     ),
//     OnboardingItem(
//       title: "Chat with Your Documents",
//       description: "Ask questions about your PDFs and receive intelligent, context-aware responses.",
//       lottieAsset: "assets/animations/chat_animation.json",
//     ),
//     OnboardingItem(
//       title: "Advanced AI Features",
//       description: "Extract key information, generate summaries, and get citation references automatically.",
//       lottieAsset: "assets/animations/ai_animation.json",
//     ),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
//     );
//
//     _animationController.forward();
//
//     _pageController.addListener(() {
//       int next = _pageController.page!.round();
//       if (_currentPage != next) {
//         setState(() {
//           _currentPage = next;
//           _isLastPage = _currentPage == _onboardingItems.length - 1;
//         });
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   void _onNextPage() {
//     if (_currentPage < _onboardingItems.length - 1) {
//       _pageController.nextPage(
//         duration: const Duration(milliseconds: 500),
//         curve: Curves.easeInOut,
//       );
//     } else {
//       _onGetStarted();
//     }
//   }
//
//   void _onSkip() {
//     _pageController.animateToPage(
//       _onboardingItems.length - 1,
//       duration: const Duration(milliseconds: 500),
//       curve: Curves.easeInOut,
//     );
//   }
//
//   void _onGetStarted() {
//     Navigator.of(context).pushReplacement(
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => const FileUploadScreen(),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           const begin = Offset(1.0, 0.0);
//           const end = Offset.zero;
//           const curve = Curves.easeInOut;
//           var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
//           var offsetAnimation = animation.drive(tween);
//           return SlideTransition(position: offsetAnimation, child: child);
//         },
//         transitionDuration: const Duration(milliseconds: 750),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;
//
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   if (!_isLastPage)
//                     TextButton(
//                       onPressed: _onSkip,
//                       child: Text(
//                         'Skip',
//                         style: TextStyle(
//                           color: primaryColor,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: PageView.builder(
//                 controller: _pageController,
//                 itemCount: _onboardingItems.length,
//                 itemBuilder: (context, index) {
//                   return AnimatedBuilder(
//                     animation: _pageController,
//                     builder: (context, child) {
//                       double value = 1.0;
//                       if (_pageController.position.haveDimensions) {
//                         value = (_pageController.page! - index).abs();
//                         value = (1 - (value * 0.5)).clamp(0.0, 1.0);
//                       }
//                       return Transform.scale(
//                         scale: Curves.easeOut.transform(value),
//                         child: OnboardingPage(item: _onboardingItems[index]),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 children: [
//                   SmoothPageIndicator(
//                     controller: _pageController,
//                     count: _onboardingItems.length,
//                     effect: ExpandingDotsEffect(
//                       activeDotColor: primaryColor,
//                       dotColor: Colors.grey.shade400,
//                       dotHeight: 8,
//                       dotWidth: 8,
//                       expansionFactor: 4,
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   SizedBox(
//                     width: MediaQuery.of(context).size.width * 0.8,
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed: _onNextPage,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryColor,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 4,
//                       ),
//                       child: Text(
//                         _isLastPage ? 'Get Started' : 'Next',
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   if (_isLastPage)
//                     TextButton(
//                       onPressed: () {
//                         Navigator.of(context).pushReplacement(
//                           MaterialPageRoute(builder: (_) => const PdfChatScreen()),
//                         );
//                       },
//                       child: Text(
//                         'Go directly to Chat',
//                         style: TextStyle(
//                           color: primaryColor,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class OnboardingPage extends StatelessWidget {
//   final OnboardingItem item;
//
//   const OnboardingPage({super.key, required this.item});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Expanded(
//             flex: 5,
//             child: Lottie.asset(
//               item.lottieAsset,
//               fit: BoxFit.contain,
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Column(
//               children: [
//                 AnimatedTextKit(
//                   animatedTexts: [
//                     TypewriterAnimatedText(
//                       item.title,
//                       textStyle: const TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         height: 1.2,
//                       ),
//                       speed: const Duration(milliseconds: 80),
//                     ),
//                   ],
//                   totalRepeatCount: 1,
//                   displayFullTextOnTap: true,
//                 ),
//                 const SizedBox(height: 24),
//                 Text(
//                   item.description,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     height: 1.5,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class OnboardingItem {
//   final String title;
//   final String description;
//   final String lottieAsset;
//
//   OnboardingItem({
//     required this.title,
//     required this.description,
//     required this.lottieAsset,
//   });
// }
//
// class FileUploadScreen extends StatefulWidget {
//   const FileUploadScreen({super.key});
//
//   @override
//   State<FileUploadScreen> createState() => _FileUploadScreenState();
// }
//
// class _FileUploadScreenState extends State<FileUploadScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeIn)),
//     );
//
//     _controller.forward();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//     final backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
//     final primaryColor = isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;
//
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       body: SafeArea(
//         child: AnimatedBuilder(
//           animation: _controller,
//           builder: (context, child) {
//             return FadeTransition(
//               opacity: _fadeAnimation,
//               child: ScaleTransition(
//                 scale: _scaleAnimation,
//                 child: child,
//               ),
//             );
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 24),
//                 Text(
//                   "Let's get started",
//                   style: TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     color: isDarkMode ? Colors.white : Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Upload a PDF to start analyzing",
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
//                   ),
//                 ),
//                 const SizedBox(height: 48),
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(24),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: isDarkMode ? Colors.grey.shade800 : Colors.white,
//                         borderRadius: BorderRadius.circular(24),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 16,
//                             offset: const Offset(0, 8),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Lottie.asset(
//                             'assets/animations/upload_file.json',
//                             width: MediaQuery.of(context).size.width * 0.6,
//                             fit: BoxFit.contain,
//                           ),
//                           const SizedBox(height: 32),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 32),
//                             child: Text(
//                               "Drag & drop your PDF file here or click to browse",
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 24),
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               // Add file picking logic here
//                               // For demo purposes, navigate to chat screen after a delay
//                               Future.delayed(const Duration(milliseconds: 800), () {
//                                 Navigator.of(context).push(
//                                   PageRouteBuilder(
//                                     pageBuilder: (context, animation, secondaryAnimation) => const PdfChatScreen(),
//                                     transitionsBuilder: (context, animation, secondaryAnimation, child) {
//                                       return FadeTransition(
//                                         opacity: animation,
//                                         child: child,
//                                       );
//                                     },
//                                     transitionDuration: const Duration(milliseconds: 500),
//                                   ),
//                                 );
//                               });
//                             },
//                             icon: const Icon(Icons.file_upload_outlined),
//                             label: const Text("Browse Files"),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: primaryColor,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 OutlinedButton(
//                   onPressed: () {
//                     Navigator.of(context).push(
//                       MaterialPageRoute(builder: (context) => const PdfChatScreen()),
//                     );
//                   },
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: primaryColor,
//                     side: BorderSide(color: primaryColor),
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: Text(
//                     "Skip to NexPDFChat",
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: primaryColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_pdf_chat/view/pdf_chat_screen.dart';
import 'package:smart_pdf_chat/voice/voice_chat.dart';

import 'onboarding/splash.dart';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        title: 'Smart NexPDFChat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          brightness: Brightness.light,
          useMaterial3: true,
          fontFamily: 'Poppins',
        ),

        // themeMode: ThemeMode.system,
        initialRoute: '/home',
        routes: {
          '/home': (context) => const SplashScreen(),
          '/voice' : (context) => VoiceChatBotPdf(),
        },
      ),
    );
  }
}

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  bool _isDragging = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeInOut)),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.7, curve: Curves.easeOut)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startProcessing() {
    setState(() {
      _isProcessing = true;
    });

    // Simulate processing
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PdfChatScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                    .animate(curvedAnimation),
                child: FadeTransition(opacity: curvedAnimation, child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = isDarkMode ? const Color(0xFF4DABF7) : const Color(0xFF1A73E8);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF202124);
    final secondaryTextColor = isDarkMode ? const Color(0xFFBBBBBB) : const Color(0xFF5F6368);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.description_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "PDF Analyzer",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  "Let's get started",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Upload a PDF file to begin analyzing its contents",
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 36),
                Expanded(
                  child: DragTarget<Object>(
                    onWillAccept: (data) {
                      setState(() => _isDragging = true);
                      return true;
                    },
                    onAccept: (data) {
                      setState(() => _isDragging = false);
                      _startProcessing();
                    },
                    onLeave: (data) {
                      setState(() => _isDragging = false);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return GestureDetector(
                        onTap: _isProcessing ? null : _startProcessing,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isDragging ? primaryColor : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isProcessing
                                ? _buildProcessingIndicator(primaryColor, textColor, isDarkMode)
                                : _buildUploadContent(primaryColor, textColor, secondaryTextColor, isDarkMode),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _startProcessing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: primaryColor.withOpacity(0.6),
                        ),
                        child: Text(
                          _isProcessing ? "Processing..." : "Browse Files",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const PdfChatScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      disabledForegroundColor: primaryColor.withOpacity(0.4),
                    ),
                    child: Text(
                      "Skip to NexPDFChat",
                      style: TextStyle(
                        fontSize: 14,
                        color: _isProcessing ? primaryColor.withOpacity(0.6) : primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadContent(Color primaryColor, Color textColor, Color secondaryTextColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom upload icon animation
          _buildUploadAnimation(primaryColor, isDarkMode),
          const SizedBox(height: 32),
          Text(
            "Drag & Drop PDF File",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Drop your file here or click to browse your device",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF303030) : const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  "PDF files only",
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadAnimation(Color primaryColor, bool isDarkMode) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing circle animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.1),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
            // Make animation repeat
            onEnd: () => setState(() {}),
          ),
          // Upload icon with arrow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF252525) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.file_upload_outlined,
              size: 32,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator(Color primaryColor, Color textColor, bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Custom loading animation
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating circle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 2 * 3.14159),
                duration: const Duration(seconds: 1),
                curve: Curves.linear,
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.transparent,
                          width: 4,
                        ),
                        gradient: SweepGradient(
                          center: Alignment.center,
                          startAngle: 0.0,
                          endAngle: 3.14159 * 2,
                          colors: [
                            primaryColor.withOpacity(0.0),
                            primaryColor,
                          ],
                          stops: const [0.7, 1.0],
                          transform: const GradientRotation(3.14159 / 2),
                        ),
                      ),
                    ),
                  );
                },
                // Make animation repeat
                onEnd: () => setState(() {}),
              ),
              // Document icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF252525) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 24,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "Processing PDF...",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            "Getting your document ready for analysis",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: textColor.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}