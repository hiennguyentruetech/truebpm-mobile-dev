// Flutter Package Imports
import 'dart:async';
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
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoOpacityAnimation;
  
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
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Logo slide animation from bottom to center
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5), // Start from bottom
      end: Offset.zero, // End at center
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _logoAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Minimum splash screen duration
    final minimumDuration = Duration(seconds: 2);
    final stopwatch = Stopwatch()..start();

    try {
      // Simulate app initialization without auth
      // logger.i('SplashScreen: Initializing app...');
      
      // Add any basic initialization here if needed
      await Future.delayed(Duration(milliseconds: 500)); // Simulate some work
      
      // Ensure minimum splash duration
      final elapsed = stopwatch.elapsed;
      if (elapsed < minimumDuration) {
        await Future.delayed(minimumDuration - elapsed);
      }
      
      // Navigate to login screen after splash
      if (mounted) {
        // logger.i('SplashScreen: Navigating to login screen');
        // Add slight delay to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 200));
        NavigationService.replaceWith(AppRoutes.login);
      }
    } catch (e) {
      // logger.w('SplashScreen: Error during initialization: $e');
      
      // Ensure minimum splash duration even on error
      final elapsed = stopwatch.elapsed;
      if (elapsed < minimumDuration) {
        await Future.delayed(minimumDuration - elapsed);
      }
      
      // Navigate to login screen on error
      if (mounted) {
        // Add slight delay to ensure smooth transition
        await Future.delayed(const Duration(milliseconds: 200));
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
          // Full screen background image
          Positioned.fill(
            child: Image.asset(
              assets.startBackground,
              fit: BoxFit.cover,
            ),
          ),
          // Overlay màu đen với opacity
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          // Animated logo in center
          Center(
            child: AnimatedBuilder(
              animation: _logoAnimationController,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoOpacityAnimation,
                      child: SlideTransition(
                        position: _logoSlideAnimation,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Hero(
                            tag: 'app_logo',
                            child: Image.asset(
                              assets.appLogo,
                              width: 150,
                              height: 150,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const SpinKitFadingCircle(
                      color: Colors.white,
                      size: 32.0,
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
