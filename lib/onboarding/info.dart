import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:ui';

import '../chatbot.dart';


// User model to store collected information
class UserInfo {
  String? username;
  String? email;
  String? gender;
  int? age;
  List<String> interests = [];
  bool receiveNotifications = true;

  // Method to check if all required fields are filled
  bool isComplete() {
    return username != null &&
        username!.isNotEmpty &&
        email != null &&
        email!.isNotEmpty &&
        gender != null &&
        age != null;
  }
}

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;
  final UserInfo _userInfo = UserInfo();

  // Form keys for validation
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _formKey4 = GlobalKey<FormState>();
  final List<GlobalKey<FormState>> _formKeys = [];

  // Controllers for text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Interest options
  final List<String> _interestOptions = [
    'Books', 'Technology', 'Science', 'Education',
    'Business', 'News', 'Research', 'Academic Papers',
    'Journals', 'Documents', 'Legal'
  ];

  late AnimationController _backgroundAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _iconScaleAnimation;

  // Pages data with matching style to onboarding
  late List<UserInfoItem> _userInfoItems;

  @override
  void initState() {
    super.initState();

    // Initialize form keys list
    _formKeys.addAll([_formKey1, _formKey2, _formKey3, _formKey4]);

    // Initialize page data
    _userInfoItems = [
      UserInfoItem(
        title: "Your Identity",
        description: "Let's get to know you better. Please provide your username to personalize your experience.",
        icon: Icons.person,
        secondaryIcon: Icons.person_outline,
        gradientColors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
        iconData: Icons.person_rounded,
      ),
      UserInfoItem(
        title: "Contact Information",
        description: "We'll use this email to send important notifications and updates about your documents.",
        icon: Icons.email,
        secondaryIcon: Icons.mail_outline,
        gradientColors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
        iconData: Icons.email_rounded,
      ),
      UserInfoItem(
        title: "Personal Details",
        description: "These details help us customize the experience to better suit your needs.",
        icon: Icons.face,
        secondaryIcon: Icons.accessibility,
        gradientColors: [Color(0xFF11998E), Color(0xFF38EF7D)],
        iconData: Icons.face_rounded,
      ),
      UserInfoItem(
        title: "Preferences",
        description: "Select topics that interest you to help us suggest relevant features and content.",
        icon: Icons.favorite,
        secondaryIcon: Icons.bookmark,
        gradientColors: [Color(0xFFFE5196), Color(0xFFFF8E53)],
        iconData: Icons.favorite_rounded,
      ),
    ];

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
          _isLastPage = _currentPage == _userInfoItems.length - 1;
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
    _usernameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // Validate current page before proceeding
  bool _validateCurrentPage() {
    if (_formKeys[_currentPage].currentState?.validate() ?? false) {
      _formKeys[_currentPage].currentState?.save();
      return true;
    }
    return false;
  }

  void _onNextPage() {
    if (!_validateCurrentPage()) return;

    if (_currentPage < _userInfoItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _onComplete();
    }
  }

  void _onSkip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Skip Profile Setup?"),
        content: Text("You can always complete your profile later in the settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _onComplete();
            },
            child: Text("Skip"),
          ),
        ],
      ),
    );
  }

  void _onComplete() {
    // Show completion animation/message
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.check, size: 50, color: Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                "Profile Complete!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                _userInfo.username != null
                    ? "Welcome, ${_userInfo.username}! Your profile has been saved."
                    : "Your profile has been saved.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to the next screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const PdfChatScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to create text fields with consistent styling
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  })
  {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 16,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: _userInfoItems[_currentPage].gradientColors[0],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _userInfoItems[_currentPage].gradientColors[0],
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _userInfoItems[_currentPage].gradientColors[0],
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 2,
          ),
        ),
        fillColor: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.white.withOpacity(0.7),
        filled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                              color: _userInfoItems[_currentPage].gradientColors[0].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _userInfoItems[_currentPage].iconData,
                              color: _userInfoItems[_currentPage].gradientColors[0],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Profile Setup",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Skip button
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
                            color: _userInfoItems[_currentPage].gradientColors[0],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content with page view
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swiping to ensure form validation
                    children: [
                      // Page 1: Username
                      _buildUsernamePage(isDarkMode),

                      // Page 2: Email
                      _buildEmailPage(isDarkMode),

                      // Page 3: Gender and Age
                      _buildPersonalDetailsPage(isDarkMode),

                      // Page 4: Interests and Preferences
                      _buildPreferencesPage(isDarkMode),
                    ],
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
                        count: _userInfoItems.length,
                        effect: JumpingDotEffect(
                          activeDotColor: _userInfoItems[_currentPage].gradientColors[0],
                          dotColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          dotHeight: 8,
                          dotWidth: 8,
                          jumpScale: 2,
                          verticalOffset: 10,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Next/Complete button
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: _userInfoItems[_currentPage].gradientColors[0].withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: _userInfoItems[_currentPage].gradientColors,
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
                                _isLastPage ? 'Complete' : 'Continue',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isLastPage ? Icons.check_circle : Icons.arrow_forward_rounded,
                                color: Colors.white,
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
          ),
        ],
      ),
    );
  }

  // Page 1: Username
  Widget _buildUsernamePage(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _contentAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Icon section
                  _buildPageIcon(_userInfoItems[0], isDarkMode),

                  // Form section
                  Expanded(
                    child: Form(
                      key: _formKey1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: _userInfoItems[0].gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              _userInfoItems[0].title,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            _userInfoItems[0].description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Username field
                          _buildTextField(
                            label: "Username",
                            icon: Icons.person,
                            controller: _usernameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username';
                              }
                              if (value.length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _userInfo.username = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Page 2: Email
  Widget _buildEmailPage(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _contentAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Icon section
                  _buildPageIcon(_userInfoItems[1], isDarkMode),

                  // Form section
                  Expanded(
                    child: Form(
                      key: _formKey2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: _userInfoItems[1].gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              _userInfoItems[1].title,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            _userInfoItems[1].description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email field
                          _buildTextField(
                            label: "Email Address",
                            icon: Icons.email,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email address';
                              }
                              // Simple email validation
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _userInfo.email = value;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Privacy note
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.privacy_tip_outlined,
                                  color: _userInfoItems[1].gradientColors[0],
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Your email is kept private and used only for account purposes.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Page 3: Gender and Age
  Widget _buildPersonalDetailsPage(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _contentAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Icon section
                  _buildPageIcon(_userInfoItems[2], isDarkMode),

                  // Form section
                  Expanded(
                    child: Form(
                      key: _formKey3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: _userInfoItems[2].gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              _userInfoItems[2].title,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            _userInfoItems[2].description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Gender selection
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 8),
                                  child: Text(
                                    "Gender",
                                    style: TextStyle(
                                      color: _userInfoItems[2].gradientColors[0],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildGenderOption("Male", Icons.male, isDarkMode),
                                      _buildGenderOption("Female", Icons.female, isDarkMode),
                                      _buildGenderOption("Other", Icons.person, isDarkMode),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Age field
                          _buildTextField(
                            label: "Age",
                            icon: Icons.cake,
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your age';
                              }
                              final age = int.tryParse(value);
                              if (age == null || age < 13 || age > 120) {
                                return 'Please enter a valid age (13-120)';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                _userInfo.age = int.tryParse(value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build gender selection option
  Widget _buildGenderOption(String gender, IconData icon, bool isDarkMode) {
    final isSelected = _userInfo.gender == gender;
    final colors = _userInfoItems[2].gradientColors;

    return GestureDetector(
      onTap: () {
        setState(() {
          _userInfo.gender = gender;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSelected
              ? null
              : isDarkMode ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : colors[0],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? Colors.white : isDarkMode ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 4: Interests and Preferences
  Widget _buildPreferencesPage(bool isDarkMode) {
    return AnimatedBuilder(
        animation: _contentAnimationController,
        builder: (context, child) {
      return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Icon section
                  _buildPageIcon(_userInfoItems[3], isDarkMode),

                  // Form section
                  Expanded(
                    child: Form(
                      key: _formKey4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: _userInfoItems[3].gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                _userInfoItems[3].title,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Center(
                            child: Text(
                              _userInfoItems[3].description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Interests selection
                          Text(
                            "Select your interests",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Interests grid
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _interestOptions.length,
                              itemBuilder: (context, index) {
                                final interest = _interestOptions[index];
                                final isSelected = _userInfo.interests.contains(interest);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _userInfo.interests.remove(interest);
                                      } else {
                                        _userInfo.interests.add(interest);
                                      }
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                        colors: _userInfoItems[3].gradientColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                          : null,
                                      color: isSelected
                                          ? null
                                          : isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? _userInfoItems[3].gradientColors[0]
                                            : isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      interest,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : isDarkMode ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Notifications preference
                          SwitchListTile(
                            title: Text(
                              "Receive notifications",
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              "Get updates about new features and content",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            value: _userInfo.receiveNotifications,
                            activeColor: _userInfoItems[3].gradientColors[0],
                            onChanged: (value) {
                              setState(() {
                                _userInfo.receiveNotifications = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      );
        },
    );
  }

  // Helper method to build the page icon with animation
  Widget _buildPageIcon(UserInfoItem item, bool isDarkMode) {
    return AnimatedBuilder(
      animation: _iconScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _iconScaleAnimation.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: item.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.gradientColors[0].withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              color: Colors.white,
              size: 40,
            ),
          ),
        );
      },
    );
  }

  // Helper method to build the animated background
  Widget _buildAnimatedBackground(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        final List<Color> colors = isDarkMode
            ? [Color(0xFF1A1A1A), Color(0xFF2D2D2D), Color(0xFF131313)]
            : [Color(0xFFE5F2FF), Color(0xFFF5F0FF), Color(0xFFFFEDF5)];

        return Stack(
          children: [
            // Base background
            Container(
              color: isDarkMode ? Colors.black : Colors.white,
            ),

            // Animated shapes
            ...List.generate(20, (index) {
              final random = Random(index);
              final size = random.nextDouble() * 100 + 50;
              final color = colors[random.nextInt(colors.length)].withOpacity(0.4);

              // Position calculation with animation
              final startX = random.nextDouble() * MediaQuery.of(context).size.width;
              final startY = random.nextDouble() * MediaQuery.of(context).size.height;

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
}

// Data class for user info pages
class UserInfoItem {
  final String title;
  final String description;
  final IconData icon;
  final IconData secondaryIcon;
  final List<Color> gradientColors;
  final IconData iconData;

  UserInfoItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.secondaryIcon,
    required this.gradientColors,
    required this.iconData,
  });
}