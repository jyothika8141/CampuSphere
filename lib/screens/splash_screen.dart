import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.bounceOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Navigate to login page after delay
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var tween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut));
            return FadeTransition(
              opacity: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo[900]!,
              Colors.indigo[700]!,
              Colors.indigo[500]!,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with decorative elements
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring
                          RotationTransition(
                            turns: _rotateAnimation,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.indigo[300]!, Colors.indigo[100]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Inner ring
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),

                          // Logo icon
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Icon(
                                Icons.school_rounded,
                                size: 80,
                                color: Colors.indigo[800],
                              ),
                            ),
                          ),

                          // Subtle decorative elements
                          Positioned(
                            top: 20,
                            right: 20,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.indigo[200],
                            ),
                          ),
                          Positioned(
                            bottom: 25,
                            left: 15,
                            child: CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.indigo[300],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // App Name with subtle glow
                      Text(
                        'CampuSphere',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.5,
                          shadows: [
                            Shadow(
                              blurRadius: 15.0,
                              color: Colors.indigo[300]!.withOpacity(0.5),
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'Connect. Learn. Thrive.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.indigo[100],
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Loading Indicator with smooth animation
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.9, end: 1.1),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[100]!),
                                strokeWidth: 3,
                              ),
                            ),
                          );
                        },
                        onEnd: () {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}