import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_pdf_chat/src/onboarding.dart';
import 'dart:async';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoAnimController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;

  late AnimationController _textAnimController;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _particleAnimController;

  // Particle system
  List<Particle> particles = [];
  int particleCount = 35;

  // App theme colors
  final List<Color> _gradientColors = [
    const Color(0xFF1A2980),
    const Color(0xFF26D0CE),
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();

    // Configure logo animation
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeOutBack),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeIn),
    );

    // Configure text animation
    _textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textAnimController, curve: Curves.easeOutCubic),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textAnimController, curve: Curves.easeIn),
    );

    // Configure pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Particle system animation
    _particleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    // Initialize particles
    _initParticles();

    // Start animation sequence
    _logoAnimController.forward().then((_) {
      _textAnimController.forward();
    });

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initParticles() {
    final random = math.Random();
    particles.clear();

    for (int i = 0; i < particleCount; i++) {
      particles.add(
        Particle(
          position: Offset(
            random.nextDouble() * 1.sw,
            random.nextDouble() * 1.sh,
          ),
          speed: Offset(
            (random.nextDouble() - 0.5) * 0.8,  // Slower movement for elegant feel
            (random.nextDouble() - 0.5) * 0.8,
          ),
          radius: random.nextDouble() * 6 + 2,  // Particle sizes between 2-8
          opacity: random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }
  }

  Future<void> _initializeApp() async {
    await UserPreferences.init();

    // Simulate app initialization with a minimum delay
    await Future.delayed(const Duration(seconds: 3));

    // Navigate to appropriate screen
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Navigate after a short delay for animations to complete
      Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          if (UserPreferences.isFirstTimeUser()) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: const OnboardingScreen(),
                ),
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => FadeTransition(
                  opacity: animation,
                  child: const OnboardingScreen(),
                ),
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    _textAnimController.dispose();
    _pulseController.dispose();
    _particleAnimController.dispose();
    particles.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          // Animated background with particles
          AnimatedBuilder(
            animation: _particleAnimController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: particles,
                  animationValue: _particleAnimController.value,
                  gradientColors: _gradientColors,
                ),
                size: Size(1.sw, 1.sh),
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo with animations
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: FadeTransition(
                    opacity: _logoOpacityAnimation,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 140.w,
                          height: 140.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _gradientColors[0].withOpacity(0.6),
                                blurRadius: _pulseAnimation.value,
                                spreadRadius: _pulseAnimation.value / 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 130.w,
                              height: 130.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _gradientColors,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.chat_rounded,
                                  size: 70.w,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: 36.h),

                // App name and slogan with slide animation
                SlideTransition(
                  position: _textSlideAnimation,
                  child: FadeTransition(
                    opacity: _textOpacityAnimation,
                    child: Column(
                      children: [
                        Text(
                          "NexChat",
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              const Shadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),

                        SizedBox(height: 10.h),

                        Text(
                          "Connect & Chat Seamlessly",
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 50.h),

                // Animated loading indicator
                if (_isLoading)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: SizedBox(
                          width: 40.w,
                          height: 40.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  Offset position;
  Offset speed;
  double radius;
  double opacity;

  Particle({
    required this.position,
    required this.speed,
    required this.radius,
    required this.opacity,
  });

  void update(Size size) {
    position += speed;

    // Bounce off edges
    if (position.dx < 0 || position.dx > size.width) {
      speed = Offset(-speed.dx, speed.dy);
    }

    if (position.dy < 0 || position.dy > size.height) {
      speed = Offset(speed.dx, -speed.dy);
    }

    // Keep particles within bounds
    position = Offset(
      position.dx.clamp(0, size.width),
      position.dy.clamp(0, size.height),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final List<Color> gradientColors;
  final double connectionThreshold = 120.0;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint background gradient
    final Rect rect = Offset.zero & size;
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);

    // Calculate pulse effect once for optimization
    final pulseEffect = math.sin(animationValue * 2 * math.pi) * 0.3 + 0.7;

    // Update and draw particles
    for (var particle in particles) {
      particle.update(size);

      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * pulseEffect)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.radius, paint);

      // Enhanced glow effect
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * 0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(particle.position, particle.radius * 1.8, glowPaint);
    }

    // Draw connecting lines between particles
    for (int i = 0; i < particles.length - 1; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final distance = (particles[i].position - particles[j].position).distance;

        if (distance < connectionThreshold) {
          final opacity = (1 - distance / connectionThreshold) * 0.3;

          final linePaint = Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke;

          canvas.drawLine(particles[i].position, particles[j].position, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// User preferences manager
class UserPreferences {
  static SharedPreferences? _preferences;
  static const String _firstTimeKey = 'first_time_user';

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static bool isFirstTimeUser() {
    return _preferences?.getBool(_firstTimeKey) ?? true;
  }

  static Future<void> setFirstTimeUser(bool isFirstTime) async {
    await _preferences?.setBool(_firstTimeKey, isFirstTime);
  }
}