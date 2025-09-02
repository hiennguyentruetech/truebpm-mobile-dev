// Flutter Package Imports
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// Local Project Package Imports
import 'package:truebpm/navigation/navigation_service.dart';
import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/utils/global_store.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _loadingAnimationController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _backgroundOpacityAnimation;
  late Animation<double> _loadingOpacityAnimation;
  late Animation<double> _shimmerAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
      _initializeApp();
    });
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Background animation controller
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Loading animation controller
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Background fade in
    _backgroundOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeIn,
    ));
    
    // Logo scale with bounce effect
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
    ]).animate(_logoAnimationController);
    
    // Logo rotation with smooth spin
    _logoRotationAnimation = Tween<double>(
      begin: -math.pi * 2,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    
    // Logo opacity fade in
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));
    
    // Loading indicator fade in
    _loadingOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Shimmer effect for logo
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));
  }

  void _startAnimations() {
    // Start background animation immediately
    _backgroundAnimationController.forward();
    
    // Start logo animation after brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _logoAnimationController.forward();
      }
    });
    
    // Start loading animation after logo appears
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _loadingAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Minimum splash screen duration for smooth animation
    final minimumDuration = Duration(milliseconds: 2500);
    final stopwatch = Stopwatch()..start();

    try {
      // Simulate app initialization
      await Future.delayed(Duration(milliseconds: 800));
      
      // Ensure minimum splash duration for animations to complete
      final elapsed = stopwatch.elapsed;
      if (elapsed < minimumDuration) {
        await Future.delayed(minimumDuration - elapsed);
      }
      
      // Start fade out before navigation
      if (mounted) {
        _logoAnimationController.reverse();
        _loadingAnimationController.reverse();
        
        // Wait for fade out to complete
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Navigate with smooth transition
        NavigationService.replaceWith(AppRoutes.login);
      }
    } catch (e) {
      // Ensure minimum splash duration even on error
      final elapsed = stopwatch.elapsed;
      if (elapsed < minimumDuration) {
        await Future.delayed(minimumDuration - elapsed);
      }
      
      // Navigate to login screen on error
      if (mounted) {
        NavigationService.replaceWith(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS
    ));
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _backgroundOpacityAnimation.value,
                child: Stack(
                  children: [
                    // Background image
                    Positioned.fill(
                      child: Image.asset(
                        assets.startBackground,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.purple.withOpacity(0.4),
                              Colors.deepPurple.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Centered content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated logo
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _logoAnimationController,
                    _backgroundAnimationController,
                  ]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _logoOpacityAnimation,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..scale(_logoScaleAnimation.value)
                          ..rotateZ(_logoRotationAnimation.value),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(
                                  0.5 * _shimmerAnimation.value,
                                ),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Stack(
                              children: [
                                Hero(
                                  tag: 'app_logo',
                                  child: Image.asset(
                                    assets.appLogo,
                                    width: 150,
                                    height: 150,
                                  ),
                                ),
                                // Shimmer overlay
                                if (_shimmerAnimation.value > 0)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0),
                                            Colors.white.withOpacity(
                                              0.2 * _shimmerAnimation.value,
                                            ),
                                            Colors.white.withOpacity(0),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
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
                  },
                ),
                
                const SizedBox(height: 50),
                
                // Loading indicator
                FadeTransition(
                  opacity: _loadingOpacityAnimation,
                  child: Column(
                    children: [
                      SpinKitDoubleBounce(
                        color: Colors.white.withOpacity(0.8),
                        size: 35.0,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w300,
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
}
