import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:smart_pdf_chat/home_page.dart';
import 'package:smart_pdf_chat/onboarding/splash.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:ui';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class UserInfo {
  String? username;
  String? email;
  String? password;
  String? gender;
  String? profession;
  List<String> interests = [];
  bool receiveNotifications = true;
  bool isGoogleSignIn = false;
  bool isGuest = false;

  bool isComplete() {
    if (isGoogleSignIn || isGuest) {
      return gender != null && profession != null;
    }
    return username != null &&
        username!.isNotEmpty &&
        email != null &&
        email!.isNotEmpty &&
        password != null &&
        password!.isNotEmpty &&
        gender != null &&
        profession != null;
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
  late Database _database;

  // Form keys for validation
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final List<GlobalKey<FormState>> _formKeys = [];

  // Controllers for text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Interest options
  final List<String> _interestOptions = [
    'Books', 'Technology', 'Science', 'Education',
    'Business', 'News', 'Research', 'Academic Papers',
    'Journals', 'Documents', 'Legal'
  ];

  // Profession options
  final List<String> _professionOptions = [
    'Student',
    'Worker',
    'Manager',
    'Teacher',
    'Engineer',
    'Doctor',
    'Other'
  ];

  // Fake Google accounts
  final List<Map<String, dynamic>> _fakeGoogleAccounts = [
    {
      'name': 'Muhammad Ali',
      'email': 'ali7889@gmail.com',
      'avatar': 'assets/acc-1.jpg',
    },
    {
      'name': 'Muhammad Nouman',
      'email': 'mnoumangu782@gmail.com',
      'avatar': 'assets/acc-2.jpg',
    },
    {
      'name': 'Muhammad Nouman',
      'email': 'm.nouman5710@gmail.com',
      'avatar': 'assets/acc-3.jpg',
    },
  ];

  late AnimationController _backgroundAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _iconScaleAnimation;

  late List<UserInfoItem> _userInfoItems;

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _formKeys.addAll([_formKey1, _formKey2, _formKey3]);

    _userInfoItems = [
      UserInfoItem(
        title: "Authentication",
        description: "Create an account, sign in with Google, or continue as guest to proceed.",
        icon: Icons.lock,
        secondaryIcon: Icons.security,
        gradientColors: [const Color(0xFF00C6FB), const Color(0xFF005BEA)],
        iconData: Icons.lock_rounded,
      ),
      UserInfoItem(
        title: "Personal Details",
        description: "These details help us customize the experience to better suit your needs.",
        icon: Icons.face,
        secondaryIcon: Icons.accessibility,
        gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
        iconData: Icons.face_rounded,
      ),
      UserInfoItem(
        title: "Preferences",
        description: "Select topics that interest you to help us suggest relevant content.",
        icon: Icons.favorite,
        secondaryIcon: Icons.bookmark,
        gradientColors: [const Color(0xFFFE5196), const Color(0xFFFF8E53)],
        iconData: Icons.favorite_rounded,
      ),
    ];

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

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

        _contentAnimationController.reset();
        _contentAnimationController.forward();
      }
    });
  }

  Future<void> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/users.db';
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            email TEXT UNIQUE,
            password TEXT,
            profession TEXT
          )
        ''');
      },
    );
  }

  Future<bool> _signUp() async {
    try {
      await _database.insert('users', {
        'username': _userInfo.username,
        'email': _userInfo.email,
        'password': _userInfo.password,
        'profession': _userInfo.profession,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _signIn() async {
    final result = await _database.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [_userInfo.email, _userInfo.password],
    );
    if (result.isNotEmpty) {
      _userInfo.username = result.first['username'] as String?;
      _userInfo.profession = result.first['profession'] as String?;
      return true;
    }
    return false;
  }

  Future<bool> _providerSignIn(String email, String username) async {
    try {
      _userInfo.email = email;
      _userInfo.username = username;
      _userInfo.isGoogleSignIn = true;

      final exists = await _database.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (exists.isEmpty) {
        await _database.insert('users', {
          'username': username,
          'email': email,
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _guestSignIn() async {
    try {
      _userInfo.isGuest = true;
      _userInfo.username = 'Guest_${Random().nextInt(10000)}';
      _userInfo.email = 'guest_${Random().nextInt(10000)}@example.com';
      return true;
    } catch (e) {
      return false;
    }
  }

  void _showGooglePermissionDialog(String email, String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/icon-2.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Google Account Access',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'NexPDFChat wants to access your Google Account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Text(
                'This will allow NexPDFChat to:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              const Text('• View your email address'),
              const Text('• View your basic profile info'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await _providerSignIn(email, name);
                      if (success) {
                        _onNextPage();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google sign-in failed')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Allow',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoogleAccountPicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/icon-2.png',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Choose an account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'to continue to NexPDFChat',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _fakeGoogleAccounts.length,
                  itemBuilder: (context, index) {
                    final account = _fakeGoogleAccounts[index];
                    return AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300 + index * 100),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(account['avatar']),
                          ),
                          title: Text(
                            account['name'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(account['email']),
                          onTap: () {
                            Navigator.pop(context);
                            _showGooglePermissionDialog(account['email'], account['name']);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.blue),
                title: const Text('Use another account'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature not implemented')),
                  );
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _database.close();
    super.dispose();
  }

  bool _validateCurrentPage() {
    if (_currentPage == 0 && (_userInfo.isGoogleSignIn || _userInfo.isGuest)) {
      return true;
    }
    if (_formKeys[_currentPage].currentState?.validate() ?? false) {
      _formKeys[_currentPage].currentState?.save();
      return true;
    }
    return false;
  }

  void _onNextPage() async {
    if (!_validateCurrentPage()) {
      return;
    }

    if (_currentPage == 0) {
      bool success;
      if (_userInfo.isGoogleSignIn || _userInfo.isGuest) {
        success = true;
      } else {
        final existingUser = await _database.query(
          'users',
          where: 'email = ?',
          whereArgs: [_userInfo.email],
        );
        if (existingUser.isNotEmpty) {
          success = await _signIn();
        } else {
          success = await _signUp();
        }
      }

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed')),
        );
        return;
      }
    }

    if (_currentPage < _userInfoItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      saveDataFirst();
      _onComplete();
    }
  }
  void saveDataFirst(){
    UserPreferences.setFirstTimeUser(false);
  }

  void _onComplete()  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.check, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                "Profile Complete!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Welcome, ${_userInfo.username}!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
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

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildAnimatedBackground(isDarkMode),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: bgColor.withOpacity(isDarkMode ? 0.75 : 0.7),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
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
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildAuthPage(isDarkMode),
                      _buildPersonalDetailsPage(isDarkMode),
                      _buildPreferencesPage(isDarkMode),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
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

  Widget _buildAuthPage(bool isDarkMode) {
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
                  _buildPageIcon(_userInfoItems[0], isDarkMode),
                  Expanded(
                    child: Form(
                      key: _formKey1,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: _userInfoItems[0].gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Text(
                                'Authentication',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Create an account, sign in with Google, or continue as guest.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 32),
                            if (!_userInfo.isGoogleSignIn && !_userInfo.isGuest) ...[
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
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: "Email Address",
                                icon: Icons.email,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an email address';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  _userInfo.email = value;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: "Password",
                                icon: Icons.lock,
                                controller: _passwordController,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  _userInfo.password = value;
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: _showGoogleAccountPicker,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/icon-2.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Sign in with Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final success = await _guestSignIn();
                                  if (success) {
                                    _onNextPage();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Guest sign-in failed')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: Colors.black87,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue as Guest',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
                  _buildPageIcon(_userInfoItems[1], isDarkMode),
                  Expanded(
                    child: Form(
                      key: _formKey2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
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
                                      color: _userInfoItems[1].gradientColors[0],
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
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
                                    "Profession",
                                    style: TextStyle(
                                      color: _userInfoItems[1].gradientColors[0],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: _professionOptions
                                        .map((profession) => _buildProfessionOption(profession, Icons.work, isDarkMode))
                                        .toList(),
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

  Widget _buildGenderOption(String gender, IconData icon, bool isDarkMode) {
    final isSelected = _userInfo.gender == gender;
    final colors = _userInfoItems[1].gradientColors;

    return GestureDetector(
      onTap: () {
        setState(() {
          _userInfo.gender = gender;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              offset: const Offset(0, 3),
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
            const SizedBox(width: 8),
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

  Widget _buildProfessionOption(String profession, IconData icon, bool isDarkMode) {
    final isSelected = _userInfo.profession == profession;
    final colors = _userInfoItems[1].gradientColors;

    return GestureDetector(
      onTap: () {
        setState(() {
          _userInfo.profession = profession;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              offset: const Offset(0, 3),
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
            const SizedBox(width: 8),
            Text(
              profession,
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
                  _buildPageIcon(_userInfoItems[2], isDarkMode),
                  Expanded(
                    child: Form(
                      key: _formKey3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: ShaderMask(
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
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              _userInfoItems[2].description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Select your interests",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    colors: _userInfoItems[2].gradientColors,
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
                                          ? _userInfoItems[2].gradientColors[0]
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
                            activeColor: _userInfoItems[2].gradientColors[0],
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

  Widget _buildAnimatedBackground(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        final List<Color> colors = isDarkMode
            ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D), const Color(0xFF131313)]
            : [const Color(0xFFE5F2FF), const Color(0xFFF5F0FF), const Color(0xFFFFEDF5)];

        return Stack(
          children: [
            Container(
              color: isDarkMode ? Colors.black : Colors.white,
            ),
            ...List.generate(20, (index) {
              final random = Random(index);
              final size = random.nextDouble() * 100 + 50;
              final color = colors[random.nextInt(colors.length)].withOpacity(0.4);

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
      title: "Welcome to NexPDFChat",
      description: "Your intelligent assistant for PDF documents, powered by advanced AI technology.",
      icon: Icons.menu_book,
      secondaryIcon: Icons.smart_toy_rounded,
      gradientColors: [const Color(0xFF4776E6), const Color(0xFF8E54E9)],
      iconData: Icons.smart_toy_rounded,
    ),
    OnboardingItem(
      title: "Upload & Analyze",
      description: "Instantly upload your PDF documents and get AI-powered summaries and insights.",
      icon: Icons.upload_file,
      secondaryIcon: Icons.analytics,
      gradientColors: [const Color(0xFF00C6FB), const Color(0xFF005BEA)],
      iconData: Icons.cloud_upload_rounded,
    ),
    OnboardingItem(
      title: "Chat with Documents",
      description: "Ask questions about your PDFs and receive intelligent, context-aware responses.",
      icon: Icons.question_answer,
      secondaryIcon: Icons.chat,
      gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      iconData: Icons.chat_bubble_outline_rounded,
    ),
    OnboardingItem(
      title: "AI-Powered Features",
      description: "Extract key information, generate summaries, and get citation references automatically.",
      icon: Icons.lightbulb,
      secondaryIcon: Icons.auto_awesome,
      gradientColors: [const Color(0xFFFE5196), const Color(0xFFFF8E53)],
      iconData: Icons.auto_awesome,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

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
          _buildAnimatedBackground(isDarkMode),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: bgColor.withOpacity(isDarkMode ? 0.75 : 0.7),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
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
                        "NexPDFChat",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
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
                  )],
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
                    ...List.generate(5, (index) {
                      final angle = index * (2 * pi / 5);
                      return AnimatedBuilder(
                        animation: scaleAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: MediaQuery.of(context).size.width * 0.25 * cos(angle + scaleAnimation.value * pi) +
                                MediaQuery.of(context).size.width * 0.15,
                            top: MediaQuery.of(context).size.height * 0.12 * sin(angle + scaleAnimation.value * pi) +
                                MediaQuery.of(context).size.height * 0.1,
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
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
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