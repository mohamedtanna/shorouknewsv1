import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _textController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startAnimations();

    // Navigate after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    _textController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/Shorouk-Logo-White2.png',
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 60),

              // Animated Loading Text
              AnimatedBuilder(
                animation: _textFadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'Getting the latest news...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Enhanced Loading Animation
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulsing circle
                            AnimatedBuilder(
                              animation: _scaleController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_scaleController.value * 0.3),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Main loading indicator
                            const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Loading dots animation
                        LoadingDots(),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 80),

              // App tagline
              AnimatedBuilder(
                animation: _textFadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textFadeAnimation,
                    child: const Text(
                      'Stay Updated, Stay Informed',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Loading Dots Widget
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  _LoadingDotsState createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final value = _animationController.value;
            final animationValue = (value + (index * 0.3)) % 1.0;
            final opacity = animationValue < 0.5
                ? (animationValue * 2)
                : (2 - animationValue * 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
